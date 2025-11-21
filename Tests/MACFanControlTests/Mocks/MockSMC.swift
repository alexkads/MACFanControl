import Foundation
@testable import SMCKit

/// Mock SMC para testes sem acesso a hardware real
public class MockSMC {
    
    public var isConnected: Bool = true
    public var fanCount: Int = 2
    public var mockFans: [MockFan] = []
    public var mockTemperatures: [String: Double] = [:]
    
    public init() {
        setupDefaultMockData()
    }
    
    private func setupDefaultMockData() {
        // Configura ventiladores mock
        mockFans = [
            MockFan(index: 0, name: "CPU Fan", currentRPM: 2000, minRPM: 1000, maxRPM: 6000),
            MockFan(index: 1, name: "GPU Fan", currentRPM: 2500, minRPM: 1200, maxRPM: 5500)
        ]
        
        // Configura temperaturas mock
        mockTemperatures = [
            "TC0P": 55.0,  // CPU Proximity
            "TC0D": 60.0,  // CPU Die
            "TG0D": 65.0,  // GPU Die
            "TG0P": 62.0,  // GPU Proximity
            "Tm0P": 45.0,  // Memory
            "TN0D": 50.0   // Northbridge
        ]
    }
    
    public func getFanCount() -> Int? {
        guard isConnected else { return nil }
        return fanCount
    }
    
    public func readFanRPM(index: Int) -> Int? {
        guard isConnected, index < mockFans.count else { return nil }
        return mockFans[index].currentRPM
    }
    
    public func readFanMinRPM(index: Int) -> Int? {
        guard isConnected, index < mockFans.count else { return nil }
        return mockFans[index].minRPM
    }
    
    public func readFanMaxRPM(index: Int) -> Int? {
        guard isConnected, index < mockFans.count else { return nil }
        return mockFans[index].maxRPM
    }
    
    public func setFanMode(index: Int, mode: UInt8) -> Bool {
        guard isConnected, index < mockFans.count else { return false }
        mockFans[index].mode = mode
        return true
    }
    
    public func setFanRPM(index: Int, rpm: Int) -> Bool {
        guard isConnected, index < mockFans.count else { return false }
        mockFans[index].targetRPM = rpm
        // Simula que o RPM atual gradualmente alcança o alvo
        mockFans[index].currentRPM = rpm
        return true
    }
    
    public func readTemperature(key: String) -> Double? {
        guard isConnected else { return nil }
        return mockTemperatures[key]
    }
    
    public func getAllTemperatures() -> [String: Double] {
        guard isConnected else { return [:] }
        return mockTemperatures
    }
    
    // Métodos auxiliares para testes
    
    public func setTemperature(key: String, value: Double) {
        mockTemperatures[key] = value
    }
    
    public func simulateTemperatureIncrease(amount: Double) {
        for key in mockTemperatures.keys {
            mockTemperatures[key]! += amount
        }
    }
    
    public func simulateTemperatureDecrease(amount: Double) {
        for key in mockTemperatures.keys {
            mockTemperatures[key]! = max(0, mockTemperatures[key]! - amount)
        }
    }
    
    public func disconnect() {
        isConnected = false
    }
    
    public func reconnect() {
        isConnected = true
    }
}

public struct MockFan {
    public var index: Int
    public var name: String
    public var currentRPM: Int
    public var minRPM: Int
    public var maxRPM: Int
    public var targetRPM: Int?
    public var mode: UInt8 = 0 // 0 = auto, 1 = manual
    
    public init(index: Int, name: String, currentRPM: Int, minRPM: Int, maxRPM: Int) {
        self.index = index
        self.name = name
        self.currentRPM = currentRPM
        self.minRPM = minRPM
        self.maxRPM = maxRPM
    }
}
