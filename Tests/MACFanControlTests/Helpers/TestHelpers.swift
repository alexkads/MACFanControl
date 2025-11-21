import XCTest
@testable import MACFanControl

/// Helpers para criação de dados de teste
public class TestHelpers {
    
    // MARK: - Fan Info Factories
    
    public static func createMockFan(
        id: Int = 0,
        name: String = "Test Fan",
        currentRPM: Int = 2000,
        minRPM: Int = 1000,
        maxRPM: Int = 6000,
        targetRPM: Int? = nil,
        isManual: Bool = false
    ) -> FanInfo {
        return FanInfo(
            id: id,
            name: name,
            currentRPM: currentRPM,
            minRPM: minRPM,
            maxRPM: maxRPM,
            targetRPM: targetRPM,
            isManual: isManual
        )
    }
    
    public static func createMockFans(count: Int) -> [FanInfo] {
        return (0..<count).map { i in
            createMockFan(
                id: i,
                name: "Fan \(i)",
                currentRPM: 2000 + (i * 100),
                minRPM: 1000,
                maxRPM: 6000
            )
        }
    }
    
    // MARK: - Temperature Sensor Factories
    
    public static func createMockTemperatureSensor(
        name: String = "CPU",
        temperature: Double = 65.0
    ) -> TemperatureSensor {
        return TemperatureSensor(name: name, temperature: temperature)
    }
    
    public static func createMockTemperatureSensors() -> [TemperatureSensor] {
        return [
            TemperatureSensor(name: "CPU Die", temperature: 65.0),
            TemperatureSensor(name: "CPU Proximity", temperature: 60.0),
            TemperatureSensor(name: "GPU Die", temperature: 70.0),
            TemperatureSensor(name: "GPU Proximity", temperature: 68.0),
            TemperatureSensor(name: "Memory", temperature: 50.0),
            TemperatureSensor(name: "Northbridge", temperature: 55.0)
        ]
    }
    
    // MARK: - Auto Control Calculation Helpers
    
    public static func calculateExpectedRPM(
        currentTemp: Double,
        targetTemp: Double,
        minRPM: Int,
        maxRPM: Int
    ) -> Int {
        let tempDiff = currentTemp - targetTemp
        
        if tempDiff <= 0 {
            return minRPM
        } else if tempDiff >= 20 {
            return maxRPM
        } else {
            let range = Double(maxRPM - minRPM)
            let ratio = tempDiff / 20.0
            return minRPM + Int(range * ratio)
        }
    }
    
    // MARK: - Validation Helpers
    
    public static func isValidTemperature(_ temp: Double) -> Bool {
        return temp > 0 && temp < 120
    }
    
    public static func isValidRPM(_ rpm: Int, min: Int, max: Int) -> Bool {
        return rpm >= 0 && rpm <= max * 2 // Allow some overshoot
    }
    
    public static func isRPMInRange(_ rpm: Int, min: Int, max: Int) -> Bool {
        return rpm >= min && rpm <= max
    }
    
    // MARK: - Async Test Helpers
    
    public static func waitForCondition(
        timeout: TimeInterval = 5.0,
        interval: TimeInterval = 0.1,
        condition: () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        
        return false
    }
    
    // MARK: - Mock Data Generators
    
    public static func generateRandomTemperature(min: Double = 30.0, max: Double = 90.0) -> Double {
        return Double.random(in: min...max)
    }
    
    public static func generateRandomRPM(min: Int = 1000, max: Int = 6000) -> Int {
        return Int.random(in: min...max)
    }
    
    // MARK: - Temperature Simulation
    
    public static func simulateTemperatureRise(
        from startTemp: Double,
        to endTemp: Double,
        steps: Int
    ) -> [Double] {
        guard steps > 0 else { return [] }
        let increment = (endTemp - startTemp) / Double(steps)
        return (0...steps).map { startTemp + Double($0) * increment }
    }
    
    public static func simulateCoolingCurve(
        from startTemp: Double,
        to targetTemp: Double,
        coolingRate: Double = 0.1
    ) -> [Double] {
        var temps: [Double] = [startTemp]
        var currentTemp = startTemp
        
        while abs(currentTemp - targetTemp) > 0.5 {
            let diff = currentTemp - targetTemp
            currentTemp -= diff * coolingRate
            temps.append(currentTemp)
            
            // Previne loop infinito
            if temps.count > 100 {
                break
            }
        }
        
        return temps
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    
    /// Aguarda condição assíncrona
    public func waitForCondition(
        timeout: TimeInterval = 5.0,
        description: String = "Condition to be met",
        condition: @escaping () -> Bool
    ) {
        let expectation = self.expectation(description: description)
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if condition() {
                expectation.fulfill()
                timer.invalidate()
            }
        }
        
        waitForExpectations(timeout: timeout) { error in
            timer.invalidate()
            if let error = error {
                XCTFail("Timeout waiting for condition: \(error)")
            }
        }
    }
    
    /// Aguarda tempo específico
    public func wait(seconds: TimeInterval) {
        let expectation = self.expectation(description: "Wait \(seconds) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: seconds + 1.0)
    }
}

// MARK: - Custom Assertions

public func XCTAssertTemperatureValid(
    _ temperature: Double,
    _ message: String = "Temperature should be in valid range",
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertGreaterThan(temperature, 0, "Temperature should be positive - \(message)", file: file, line: line)
    XCTAssertLessThan(temperature, 120, "Temperature should be below 120°C - \(message)", file: file, line: line)
}

public func XCTAssertRPMValid(
    _ rpm: Int,
    min: Int,
    max: Int,
    _ message: String = "RPM should be in valid range",
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertGreaterThanOrEqual(rpm, 0, "RPM should be non-negative - \(message)", file: file, line: line)
    XCTAssertLessThanOrEqual(rpm, max * 2, "RPM should be reasonable - \(message)", file: file, line: line)
}

public func XCTAssertRPMInRange(
    _ rpm: Int,
    min: Int,
    max: Int,
    _ message: String = "RPM should be within min/max range",
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertGreaterThanOrEqual(rpm, min, "RPM should be >= min - \(message)", file: file, line: line)
    XCTAssertLessThanOrEqual(rpm, max, "RPM should be <= max - \(message)", file: file, line: line)
}
