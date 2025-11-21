import Foundation
import SMCKit

protocol FanProvider {
    func getFanCount() -> Int
    func getFanRPM(index: Int) -> Int
    func getFanName(index: Int) -> String
    func isConnected() -> Bool
    func getError() -> String?
    func setFanMode(index: Int, mode: Int) -> Bool
    func setFanRPM(index: Int, rpm: Int) -> Bool
    func getAllTemperatures() -> [String: Double]
}

class SMCFanProvider: FanProvider {
    private var smc: SMC?
    private var connectionError: String?
    
    init() {
        smc = SMC()
        if let smc = smc {
            connectionError = smc.getConnectionError()
        } else {
            connectionError = "Failed to initialize SMC"
        }
    }
    
    func getFanCount() -> Int {
        return smc?.getFanCount() ?? 0
    }
    
    func getFanRPM(index: Int) -> Int {
        return smc?.readFanRPM(index: index) ?? 0
    }
    
    func getFanName(index: Int) -> String {
        switch index {
        case 0: return "Ventilador CPU"
        case 1: return "Ventilador GPU"
        default: return "Ventilador \(index + 1)"
        }
    }
    
    func isConnected() -> Bool {
        return smc?.isConnected() ?? false
    }
    
    func getError() -> String? {
        return connectionError
    }
    
    func setFanMode(index: Int, mode: Int) -> Bool {
        return smc?.setFanMode(index: index, mode: UInt8(mode)) ?? false
    }
    
    func setFanRPM(index: Int, rpm: Int) -> Bool {
        return smc?.setFanRPM(index: index, rpm: rpm) ?? false
    }
    
    func getAllTemperatures() -> [String: Double] {
        return smc?.getAllTemperatures() ?? [:]
    }
}

class PowermetricsFanProvider: FanProvider {
    private var lastOutput: String = ""
    private var fanSpeeds: [Int] = []
    
    func refresh() {
        // Run powermetrics to get SMC data
        // Note: This requires root privileges
        let task = Process()
        task.launchPath = "/usr/bin/powermetrics"
        task.arguments = ["-n", "1", "--samplers", "smc", "-i", "1"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                parseOutput(output)
            }
        } catch {
            print("ERROR: Failed to run powermetrics: \(error)")
        }
    }
    
    private func parseOutput(_ output: String) {
        // Example output parsing logic
        // Look for lines like "Fan: 1200 rpm" or similar
        // This is a simplified parser and might need adjustment based on actual output
        var speeds: [Int] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            if line.lowercased().contains("fan") && line.lowercased().contains("rpm") {
                // Extract number
                let components = line.components(separatedBy: CharacterSet.decimalDigits.inverted)
                for component in components {
                    if let speed = Int(component), speed > 0 {
                        speeds.append(speed)
                    }
                }
            }
        }
        
        if !speeds.isEmpty {
            fanSpeeds = speeds
        }
    }
    
    func getFanCount() -> Int {
        refresh() // Refresh data on count check
        return fanSpeeds.count
    }
    
    func getFanRPM(index: Int) -> Int {
        if index < fanSpeeds.count {
            return fanSpeeds[index]
        }
        return 0
    }
    
    func getFanName(index: Int) -> String {
        return "Ventilador \(index + 1) (Apple Silicon)"
    }
    
    func isConnected() -> Bool {
        // Check if we are running as root
        return getuid() == 0
    }
    
    func getError() -> String? {
        if !isConnected() {
            return "Acesso negado. Execute com 'sudo swift run' para acessar os ventiladores no Apple Silicon."
        }
        return nil
    }
    
    func setFanMode(index: Int, mode: Int) -> Bool {
        // Control not supported via powermetrics
        return false
    }
    
    func setFanRPM(index: Int, rpm: Int) -> Bool {
        // Control not supported via powermetrics
        return false
    }
    
    func getAllTemperatures() -> [String: Double] {
        // Temperature parsing not implemented yet for powermetrics
        return [:]
    }
}
