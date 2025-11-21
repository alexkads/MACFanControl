import Foundation
import SMCKit

public struct FanInfo: Identifiable {
    public let id: Int
    public let name: String
    public var currentRPM: Int
    public var minRPM: Int
    public var maxRPM: Int
    public var targetRPM: Int?
    public var isManual: Bool
    
    public init(id: Int, name: String, currentRPM: Int, minRPM: Int, maxRPM: Int, targetRPM: Int? = nil, isManual: Bool = false) {
        self.id = id
        self.name = name
        self.currentRPM = currentRPM
        self.minRPM = minRPM
        self.maxRPM = maxRPM
        self.targetRPM = targetRPM
        self.isManual = isManual
    }
}

public struct TemperatureSensor: Identifiable {
    public let id = UUID()
    public let name: String
    public let temperature: Double
    
    public init(name: String, temperature: Double) {
        self.name = name
        self.temperature = temperature
    }
}

@MainActor
public class FanControlManager: ObservableObject {
    @Published public var fans: [FanInfo] = []
    @Published public var temperatures: [TemperatureSensor] = []
    @Published public var autoMode: Bool = true
    @Published public var targetTemperature: Double = 60.0
    @Published public var isConnected: Bool = false
    @Published public var errorMessage: String?
    
    private var smc: SMC?
    private var timer: Timer?
    
    public init() {
        setupSMC()
        startMonitoring()
    }
    
    private func setupSMC() {
        print("DEBUG: Setting up SMC...")
        smc = SMC()
        isConnected = smc != nil
        
        if let smc = smc {
            if let error = smc.getConnectionError() {
                errorMessage = error
                print("WARNING: SMC has connection issues: \(error)")
            }
            loadFans(smc: smc)
        } else {
            errorMessage = "Não foi possível conectar ao SMC. Verifique se você está executando em um Mac real (não funciona em máquinas virtuais) e se tem as permissões necessárias."
            print("ERROR: Failed to initialize SMC")
        }
    }
    
    private func loadFans(smc: SMC) {
        print("DEBUG: loadFans called")
        guard let fanCount = smc.getFanCount() else { 
            print("DEBUG: getFanCount returned nil")
            errorMessage = "Não foi possível detectar ventiladores. Este Mac pode não suportar controle de ventiladores via SMC, ou você pode estar usando Apple Silicon com restrições de acesso ao hardware."
            return 
        }
        print("DEBUG: Loading \(fanCount) fans...")
        
        var loadedFans: [FanInfo] = []
        
        for i in 0..<fanCount {
            let name = getFanName(index: i)
            let currentRPM = smc.readFanRPM(index: i) ?? 0
            let minRPM = smc.readFanMinRPM(index: i) ?? 1000
            let maxRPM = smc.readFanMaxRPM(index: i) ?? 6000
            
            let fan = FanInfo(
                id: i,
                name: name,
                currentRPM: currentRPM,
                minRPM: minRPM,
                maxRPM: maxRPM
            )
            loadedFans.append(fan)
        }
        
        fans = loadedFans
    }
    
    private func getFanName(index: Int) -> String {
        switch index {
        case 0: return "Ventilador CPU"
        case 1: return "Ventilador GPU"
        default: return "Ventilador \(index + 1)"
        }
    }
    
    public func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateData()
            }
        }
        updateData()
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateData() {
        guard let smc = smc else { return }
        
        // Update fan speeds
        for i in 0..<fans.count {
            if let currentRPM = smc.readFanRPM(index: i) {
                fans[i].currentRPM = currentRPM
            }
        }
        
        // Update temperatures
        let temps = smc.getAllTemperatures()
        temperatures = temps.map { TemperatureSensor(name: $0.key, temperature: $0.value) }
            .sorted { $0.temperature > $1.temperature }
        
        // Apply automatic control if enabled
        if autoMode {
            applyAutoControl()
        }
    }
    
    public func setFanSpeed(fanIndex: Int, rpm: Int) {
        guard let smc = smc, fanIndex < fans.count else { return }
        
        // Set to manual mode (mode 1)
        _ = smc.setFanMode(index: fanIndex, mode: 1)
        
        // Set target RPM
        if smc.setFanRPM(index: fanIndex, rpm: rpm) {
            fans[fanIndex].targetRPM = rpm
            fans[fanIndex].isManual = true
            autoMode = false
        }
    }
    
    public func setAutoMode(enabled: Bool) {
        guard let smc = smc else { return }
        
        autoMode = enabled
        
        if enabled {
            // Set all fans back to auto mode (mode 0)
            for i in 0..<fans.count {
                _ = smc.setFanMode(index: i, mode: 0)
                fans[i].isManual = false
                fans[i].targetRPM = nil
            }
        }
    }
    
    private func applyAutoControl() {
        guard let smc = smc, let maxTemp = temperatures.first?.temperature else { return }
        
        // Simple control algorithm
        let tempDiff = maxTemp - targetTemperature
        
        for i in 0..<fans.count {
            let fan = fans[i]
            let range = Double(fan.maxRPM - fan.minRPM)
            
            var targetRPM: Int
            
            if tempDiff <= 0 {
                // Below target, use minimum speed
                targetRPM = fan.minRPM
            } else if tempDiff >= 20 {
                // 20°C above target, use maximum speed
                targetRPM = fan.maxRPM
            } else {
                // Proportional control
                let ratio = tempDiff / 20.0
                targetRPM = fan.minRPM + Int(range * ratio)
            }
            
            // Only update if changed significantly
            if let current = fans[i].targetRPM, abs(current - targetRPM) < 100 {
                continue
            }
            
            _ = smc.setFanMode(index: i, mode: 1)
            _ = smc.setFanRPM(index: i, rpm: targetRPM)
            fans[i].targetRPM = targetRPM
        }
    }
    
    public func resetToDefault() {
        setAutoMode(enabled: true)
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}
