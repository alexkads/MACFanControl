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
    
    private var provider: FanProvider?
    private var timer: Timer?
    
    public init() {
        setupProvider()
        startMonitoring()
    }
    
    private func setupProvider() {
        print("DEBUG: Setting up Fan Provider...")
        
        // Try SMC Provider first (Intel)
        let smcProvider = SMCFanProvider()
        if smcProvider.isConnected() && smcProvider.getFanCount() > 0 {
            print("DEBUG: Using SMC Provider")
            self.provider = smcProvider
            self.isConnected = true
            loadFans()
            return
        }
        
        print("DEBUG: SMC Provider failed or found no fans. Trying Powermetrics (Apple Silicon)...")
        
        // Try Powermetrics Provider (Apple Silicon)
        let powerProvider = PowermetricsFanProvider()
        if powerProvider.isConnected() {
            print("DEBUG: Using Powermetrics Provider")
            self.provider = powerProvider
            self.isConnected = true
            loadFans()
        } else {
            // If not connected (likely not root), still set it but show error
            self.provider = powerProvider
            self.isConnected = false
            self.errorMessage = powerProvider.getError()
            print("WARNING: Powermetrics provider requires root")
        }
    }
    
    private func loadFans() {
        guard let provider = provider else { return }
        
        let fanCount = provider.getFanCount()
        print("DEBUG: Loading \(fanCount) fans...")
        
        var loadedFans: [FanInfo] = []
        
        for i in 0..<fanCount {
            let name = provider.getFanName(index: i)
            let currentRPM = provider.getFanRPM(index: i)
            
            // Defaults for Apple Silicon since we can't read min/max easily yet
            let minRPM = 0
            let maxRPM = 6000
            
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
        guard let provider = provider else { return }
        
        // For Powermetrics, we need to trigger a refresh if it's that type
        if let powerProvider = provider as? PowermetricsFanProvider {
            powerProvider.refresh()
        }
        
        // Update fan speeds
        for i in 0..<fans.count {
            let currentRPM = provider.getFanRPM(index: i)
            fans[i].currentRPM = currentRPM
        }
        
        // Update temperatures
        let temps = provider.getAllTemperatures()
        temperatures = temps.map { TemperatureSensor(name: $0.key, temperature: $0.value) }
            .sorted { $0.temperature > $1.temperature }
        
        // Apply automatic control if enabled
        if autoMode {
            applyAutoControl()
        }
    }
    
    public func setFanSpeed(fanIndex: Int, rpm: Int) {
        guard let provider = provider, fanIndex < fans.count else { return }
        
        // Set to manual mode (mode 1)
        _ = provider.setFanMode(index: fanIndex, mode: 1)
        
        // Set target RPM
        if provider.setFanRPM(index: fanIndex, rpm: rpm) {
            fans[fanIndex].targetRPM = rpm
            fans[fanIndex].isManual = true
            autoMode = false
        }
    }
    
    public func setAutoMode(enabled: Bool) {
        guard let provider = provider else { return }
        
        autoMode = enabled
        
        if enabled {
            // Set all fans back to auto mode (mode 0)
            for i in 0..<fans.count {
                _ = provider.setFanMode(index: i, mode: 0)
                fans[i].isManual = false
                fans[i].targetRPM = nil
            }
        }
    }
    
    private func applyAutoControl() {
        guard let provider = provider, let maxTemp = temperatures.first?.temperature else { return }
        
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
            
            _ = provider.setFanMode(index: i, mode: 1)
            _ = provider.setFanRPM(index: i, rpm: targetRPM)
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
