import XCTest
@testable import MACFanControl

final class TestHelpersTests: XCTestCase {
    
    // MARK: - Factory Tests
    
    func testCreateMockFan() {
        let fan = TestHelpers.createMockFan()
        
        XCTAssertEqual(fan.id, 0)
        XCTAssertEqual(fan.name, "Test Fan")
        XCTAssertEqual(fan.currentRPM, 2000)
        XCTAssertEqual(fan.minRPM, 1000)
        XCTAssertEqual(fan.maxRPM, 6000)
        XCTAssertNil(fan.targetRPM)
        XCTAssertFalse(fan.isManual)
    }
    
    func testCreateMockFanWithCustomValues() {
        let fan = TestHelpers.createMockFan(
            id: 5,
            name: "Custom Fan",
            currentRPM: 3500,
            minRPM: 1500,
            maxRPM: 7000,
            targetRPM: 4000,
            isManual: true
        )
        
        XCTAssertEqual(fan.id, 5)
        XCTAssertEqual(fan.name, "Custom Fan")
        XCTAssertEqual(fan.currentRPM, 3500)
        XCTAssertEqual(fan.targetRPM, 4000)
        XCTAssertTrue(fan.isManual)
    }
    
    func testCreateMockFans() {
        let fans = TestHelpers.createMockFans(count: 3)
        
        XCTAssertEqual(fans.count, 3)
        XCTAssertEqual(fans[0].id, 0)
        XCTAssertEqual(fans[1].id, 1)
        XCTAssertEqual(fans[2].id, 2)
        XCTAssertEqual(fans[0].currentRPM, 2000)
        XCTAssertEqual(fans[1].currentRPM, 2100)
        XCTAssertEqual(fans[2].currentRPM, 2200)
    }
    
    func testCreateMockTemperatureSensor() {
        let sensor = TestHelpers.createMockTemperatureSensor()
        
        XCTAssertEqual(sensor.name, "CPU")
        XCTAssertEqual(sensor.temperature, 65.0)
        XCTAssertNotNil(sensor.id)
    }
    
    func testCreateMockTemperatureSensors() {
        let sensors = TestHelpers.createMockTemperatureSensors()
        
        XCTAssertEqual(sensors.count, 6)
        XCTAssertTrue(sensors.contains { $0.name == "CPU Die" })
        XCTAssertTrue(sensors.contains { $0.name == "GPU Die" })
    }
    
    // MARK: - Auto Control Calculation Tests
    
    func testCalculateExpectedRPMBelowTarget() {
        let rpm = TestHelpers.calculateExpectedRPM(
            currentTemp: 50.0,
            targetTemp: 60.0,
            minRPM: 1000,
            maxRPM: 6000
        )
        
        XCTAssertEqual(rpm, 1000)
    }
    
    func testCalculateExpectedRPMAboveTarget() {
        let rpm = TestHelpers.calculateExpectedRPM(
            currentTemp: 85.0,
            targetTemp: 60.0,
            minRPM: 1000,
            maxRPM: 6000
        )
        
        XCTAssertEqual(rpm, 6000)
    }
    
    func testCalculateExpectedRPMProportional() {
        let rpm = TestHelpers.calculateExpectedRPM(
            currentTemp: 70.0,
            targetTemp: 60.0,
            minRPM: 1000,
            maxRPM: 6000
        )
        
        // 10°C above = 50% = 1000 + 2500 = 3500
        XCTAssertEqual(rpm, 3500)
    }
    
    // MARK: - Validation Tests
    
    func testIsValidTemperature() {
        XCTAssertTrue(TestHelpers.isValidTemperature(50.0))
        XCTAssertTrue(TestHelpers.isValidTemperature(100.0))
        XCTAssertFalse(TestHelpers.isValidTemperature(0.0))
        XCTAssertFalse(TestHelpers.isValidTemperature(-10.0))
        XCTAssertFalse(TestHelpers.isValidTemperature(150.0))
    }
    
    func testIsValidRPM() {
        XCTAssertTrue(TestHelpers.isValidRPM(2000, min: 1000, max: 6000))
        XCTAssertTrue(TestHelpers.isValidRPM(0, min: 1000, max: 6000))
        XCTAssertFalse(TestHelpers.isValidRPM(-100, min: 1000, max: 6000))
        XCTAssertTrue(TestHelpers.isValidRPM(10000, min: 1000, max: 6000)) // Within 2x max
    }
    
    func testIsRPMInRange() {
        XCTAssertTrue(TestHelpers.isRPMInRange(2000, min: 1000, max: 6000))
        XCTAssertTrue(TestHelpers.isRPMInRange(1000, min: 1000, max: 6000))
        XCTAssertTrue(TestHelpers.isRPMInRange(6000, min: 1000, max: 6000))
        XCTAssertFalse(TestHelpers.isRPMInRange(500, min: 1000, max: 6000))
        XCTAssertFalse(TestHelpers.isRPMInRange(7000, min: 1000, max: 6000))
    }
    
    // MARK: - Random Generation Tests
    
    func testGenerateRandomTemperature() {
        for _ in 0..<100 {
            let temp = TestHelpers.generateRandomTemperature()
            XCTAssertGreaterThanOrEqual(temp, 30.0)
            XCTAssertLessThanOrEqual(temp, 90.0)
        }
    }
    
    func testGenerateRandomRPM() {
        for _ in 0..<100 {
            let rpm = TestHelpers.generateRandomRPM()
            XCTAssertGreaterThanOrEqual(rpm, 1000)
            XCTAssertLessThanOrEqual(rpm, 6000)
        }
    }
    
    // MARK: - Temperature Simulation Tests
    
    func testSimulateTemperatureRise() {
        let temps = TestHelpers.simulateTemperatureRise(from: 50.0, to: 80.0, steps: 10)
        
        XCTAssertEqual(temps.count, 11) // 0 to 10 inclusive
        XCTAssertEqual(temps.first!, 50.0, accuracy: 0.01)
        XCTAssertEqual(temps.last!, 80.0, accuracy: 0.01)
        
        // Verifica que está aumentando
        for i in 0..<temps.count - 1 {
            XCTAssertLessThanOrEqual(temps[i], temps[i + 1])
        }
    }
    
    func testSimulateCoolingCurve() {
        let temps = TestHelpers.simulateCoolingCurve(from: 90.0, to: 60.0, coolingRate: 0.2)
        
        XCTAssertGreaterThan(temps.count, 0)
        XCTAssertEqual(temps.first!, 90.0, accuracy: 0.01)
        XCTAssertLessThan(abs(temps.last! - 60.0), 1.0) // Dentro de 1°C do alvo
        
        // Verifica que está diminuindo
        for i in 0..<temps.count - 1 {
            XCTAssertGreaterThanOrEqual(temps[i], temps[i + 1])
        }
    }
    
    // MARK: - Custom Assertions Tests
    
    func testXCTAssertTemperatureValid() {
        XCTAssertTemperatureValid(50.0)
        XCTAssertTemperatureValid(100.0)
    }
    
    func testXCTAssertRPMValid() {
        XCTAssertRPMValid(2000, min: 1000, max: 6000)
        XCTAssertRPMValid(0, min: 1000, max: 6000)
    }
    
    func testXCTAssertRPMInRange() {
        XCTAssertRPMInRange(2000, min: 1000, max: 6000)
        XCTAssertRPMInRange(1000, min: 1000, max: 6000)
        XCTAssertRPMInRange(6000, min: 1000, max: 6000)
    }
}
