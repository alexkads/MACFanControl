import XCTest
@testable import MACFanControl

final class MockSMCTests: XCTestCase {
    
    var mockSMC: MockSMC!
    
    override func setUp() {
        super.setUp()
        mockSMC = MockSMC()
    }
    
    override func tearDown() {
        mockSMC = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testMockSMCInitialization() {
        XCTAssertNotNil(mockSMC)
        XCTAssertTrue(mockSMC.isConnected)
        XCTAssertEqual(mockSMC.fanCount, 2)
        XCTAssertEqual(mockSMC.mockFans.count, 2)
        XCTAssertGreaterThan(mockSMC.mockTemperatures.count, 0)
    }
    
    // MARK: - Fan Count Tests
    
    func testGetFanCount() {
        let count = mockSMC.getFanCount()
        XCTAssertEqual(count, 2)
    }
    
    func testGetFanCountWhenDisconnected() {
        mockSMC.disconnect()
        let count = mockSMC.getFanCount()
        XCTAssertNil(count)
    }
    
    // MARK: - Fan RPM Tests
    
    func testReadFanRPM() {
        let rpm = mockSMC.readFanRPM(index: 0)
        XCTAssertEqual(rpm, 2000)
    }
    
    func testReadFanMinRPM() {
        let minRPM = mockSMC.readFanMinRPM(index: 0)
        XCTAssertEqual(minRPM, 1000)
    }
    
    func testReadFanMaxRPM() {
        let maxRPM = mockSMC.readFanMaxRPM(index: 0)
        XCTAssertEqual(maxRPM, 6000)
    }
    
    func testReadInvalidFanIndex() {
        let rpm = mockSMC.readFanRPM(index: 99)
        XCTAssertNil(rpm)
    }
    
    // MARK: - Fan Control Tests
    
    func testSetFanMode() {
        let result = mockSMC.setFanMode(index: 0, mode: 1)
        XCTAssertTrue(result)
        XCTAssertEqual(mockSMC.mockFans[0].mode, 1)
    }
    
    func testSetFanRPM() {
        let result = mockSMC.setFanRPM(index: 0, rpm: 3000)
        XCTAssertTrue(result)
        XCTAssertEqual(mockSMC.mockFans[0].targetRPM, 3000)
        XCTAssertEqual(mockSMC.mockFans[0].currentRPM, 3000)
    }
    
    func testSetFanRPMInvalidIndex() {
        let result = mockSMC.setFanRPM(index: 99, rpm: 3000)
        XCTAssertFalse(result)
    }
    
    // MARK: - Temperature Tests
    
    func testReadTemperature() {
        let temp = mockSMC.readTemperature(key: "TC0P")
        XCTAssertEqual(temp, 55.0)
    }
    
    func testReadInvalidTemperatureKey() {
        let temp = mockSMC.readTemperature(key: "XXXX")
        XCTAssertNil(temp)
    }
    
    func testGetAllTemperatures() {
        let temps = mockSMC.getAllTemperatures()
        XCTAssertGreaterThan(temps.count, 0)
        XCTAssertEqual(temps["TC0P"], 55.0)
    }
    
    // MARK: - Temperature Simulation Tests
    
    func testSetTemperature() {
        mockSMC.setTemperature(key: "TC0P", value: 75.0)
        let temp = mockSMC.readTemperature(key: "TC0P")
        XCTAssertEqual(temp, 75.0)
    }
    
    func testSimulateTemperatureIncrease() {
        let originalTemp = mockSMC.readTemperature(key: "TC0P")!
        mockSMC.simulateTemperatureIncrease(amount: 10.0)
        let newTemp = mockSMC.readTemperature(key: "TC0P")!
        
        XCTAssertEqual(newTemp, originalTemp + 10.0, accuracy: 0.01)
    }
    
    func testSimulateTemperatureDecrease() {
        let originalTemp = mockSMC.readTemperature(key: "TC0P")!
        mockSMC.simulateTemperatureDecrease(amount: 10.0)
        let newTemp = mockSMC.readTemperature(key: "TC0P")!
        
        XCTAssertEqual(newTemp, originalTemp - 10.0, accuracy: 0.01)
    }
    
    func testSimulateTemperatureDecreaseDoesNotGoBelowZero() {
        mockSMC.setTemperature(key: "TC0P", value: 5.0)
        mockSMC.simulateTemperatureDecrease(amount: 10.0)
        let temp = mockSMC.readTemperature(key: "TC0P")!
        
        XCTAssertGreaterThanOrEqual(temp, 0.0)
    }
    
    // MARK: - Connection Tests
    
    func testDisconnect() {
        mockSMC.disconnect()
        XCTAssertFalse(mockSMC.isConnected)
        
        let rpm = mockSMC.readFanRPM(index: 0)
        XCTAssertNil(rpm)
    }
    
    func testReconnect() {
        mockSMC.disconnect()
        XCTAssertFalse(mockSMC.isConnected)
        
        mockSMC.reconnect()
        XCTAssertTrue(mockSMC.isConnected)
        
        let rpm = mockSMC.readFanRPM(index: 0)
        XCTAssertNotNil(rpm)
    }
}
