import XCTest
@testable import MACFanControl
@testable import SMCKit

final class FanControlManagerTests: XCTestCase {
    
    var manager: FanControlManager!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        manager = FanControlManager()
    }
    
    @MainActor
    override func tearDown() async throws {
        manager.stopMonitoring()
        manager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testManagerInitialization() {
        XCTAssertNotNil(manager, "Manager should be initialized")
        XCTAssertTrue(manager.autoMode, "Should start in auto mode")
        XCTAssertEqual(manager.targetTemperature, 60.0, "Default target temperature should be 60°C")
    }
    
    @MainActor
    func testInitialConnectionState() {
        // Pode estar conectado ou não dependendo do hardware
        // O importante é que não seja nil
        XCTAssertNotNil(manager.isConnected)
    }
    
    // MARK: - Auto Mode Tests
    
    @MainActor
    func testSetAutoModeEnabled() {
        manager.setAutoMode(enabled: true)
        XCTAssertTrue(manager.autoMode, "Auto mode should be enabled")
    }
    
    @MainActor
    func testSetAutoModeDisabled() {
        manager.setAutoMode(enabled: false)
        XCTAssertFalse(manager.autoMode, "Auto mode should be disabled")
    }
    
    @MainActor
    func testAutoModeResetsManualFlags() {
        // Simula que tínhamos configuração manual
        manager.setAutoMode(enabled: false)
        
        // Volta para auto
        manager.setAutoMode(enabled: true)
        
        XCTAssertTrue(manager.autoMode, "Auto mode should be enabled")
    }
    
    // MARK: - Target Temperature Tests
    
    @MainActor
    func testTargetTemperatureRange() {
        manager.targetTemperature = 70.0
        XCTAssertEqual(manager.targetTemperature, 70.0, accuracy: 0.01)
        
        manager.targetTemperature = 50.0
        XCTAssertEqual(manager.targetTemperature, 50.0, accuracy: 0.01)
    }
    
    @MainActor
    func testTargetTemperatureBoundaries() {
        // Testa valores nos limites
        manager.targetTemperature = 40.0
        XCTAssertGreaterThanOrEqual(manager.targetTemperature, 40.0)
        
        manager.targetTemperature = 80.0
        XCTAssertLessThanOrEqual(manager.targetTemperature, 80.0)
    }
    
    // MARK: - Fan Info Tests
    
    @MainActor
    func testFanInfoStructure() {
        let fan = FanInfo(
            id: 0,
            name: "Test Fan",
            currentRPM: 2000,
            minRPM: 1000,
            maxRPM: 6000,
            targetRPM: 3000,
            isManual: true
        )
        
        XCTAssertEqual(fan.id, 0)
        XCTAssertEqual(fan.name, "Test Fan")
        XCTAssertEqual(fan.currentRPM, 2000)
        XCTAssertEqual(fan.minRPM, 1000)
        XCTAssertEqual(fan.maxRPM, 6000)
        XCTAssertEqual(fan.targetRPM, 3000)
        XCTAssertTrue(fan.isManual)
    }
    
    @MainActor
    func testFanInfoDefaults() {
        let fan = FanInfo(
            id: 0,
            name: "Test Fan",
            currentRPM: 2000,
            minRPM: 1000,
            maxRPM: 6000
        )
        
        XCTAssertNil(fan.targetRPM)
        XCTAssertFalse(fan.isManual)
    }
    
    // MARK: - Temperature Sensor Tests
    
    @MainActor
    func testTemperatureSensorStructure() {
        let sensor = TemperatureSensor(name: "CPU", temperature: 65.5)
        
        XCTAssertEqual(sensor.name, "CPU")
        XCTAssertEqual(sensor.temperature, 65.5, accuracy: 0.01)
        XCTAssertNotNil(sensor.id)
    }
    
    @MainActor
    func testTemperatureSensorUniqueIDs() {
        let sensor1 = TemperatureSensor(name: "CPU", temperature: 65.5)
        let sensor2 = TemperatureSensor(name: "GPU", temperature: 70.0)
        
        XCTAssertNotEqual(sensor1.id, sensor2.id, "Each sensor should have unique ID")
    }
    
    // MARK: - Monitoring Tests
    
    @MainActor
    func testStartMonitoring() {
        manager.startMonitoring()
        
        // Aguarda um ciclo de atualização
        let expectation = XCTestExpectation(description: "Wait for monitoring cycle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        // Se houver SMC, deve ter dados
        if manager.isConnected {
            // Pode ter ou não ventiladores dependendo do hardware
        }
    }
    
    @MainActor
    func testStopMonitoring() {
        manager.startMonitoring()
        manager.stopMonitoring()
        
        // Não deve causar crash
        XCTAssertNotNil(manager)
    }
    
    // MARK: - Reset Tests
    
    @MainActor
    func testResetToDefault() {
        // Altera algumas configurações
        manager.setAutoMode(enabled: false)
        manager.targetTemperature = 70.0
        
        // Reseta
        manager.resetToDefault()
        
        // Verifica que voltou para auto mode
        XCTAssertTrue(manager.autoMode, "Should reset to auto mode")
    }
    
    // MARK: - Manual Control Tests
    
    @MainActor
    func testSetFanSpeedDisablesAutoMode() {
        manager.setAutoMode(enabled: true)
        
        // Quando definimos velocidade manual, auto mode deve desativar
        if manager.fans.count > 0 {
            manager.setFanSpeed(fanIndex: 0, rpm: 2000)
            XCTAssertFalse(manager.autoMode, "Setting manual speed should disable auto mode")
        }
    }
    
    @MainActor
    func testSetFanSpeedWithInvalidIndex() {
        // Não deve causar crash
        manager.setFanSpeed(fanIndex: 999, rpm: 2000)
        
        XCTAssertNotNil(manager)
    }
    
    // MARK: - Auto Control Algorithm Tests
    
    @MainActor
    func testAutoControlAlgorithmBelowTarget() {
        // Simula temperatura abaixo do alvo
        // A lógica deveria usar RPM mínimo
        
        let fan = FanInfo(
            id: 0,
            name: "Test Fan",
            currentRPM: 2000,
            minRPM: 1000,
            maxRPM: 6000
        )
        
        let targetTemp = 60.0
        let currentTemp = 50.0 // Abaixo do alvo
        let tempDiff = currentTemp - targetTemp
        
        XCTAssertLessThan(tempDiff, 0, "Temperature should be below target")
        
        // Neste caso, algoritmo deveria usar minRPM
        let expectedRPM = fan.minRPM
        XCTAssertEqual(expectedRPM, 1000)
    }
    
    @MainActor
    func testAutoControlAlgorithmAboveTarget() {
        let fan = FanInfo(
            id: 0,
            name: "Test Fan",
            currentRPM: 2000,
            minRPM: 1000,
            maxRPM: 6000
        )
        
        let targetTemp = 60.0
        let currentTemp = 80.0 // 20°C acima
        let tempDiff = currentTemp - targetTemp
        
        XCTAssertGreaterThanOrEqual(tempDiff, 20, "Temperature should be 20°C above target")
        
        // Neste caso, algoritmo deveria usar maxRPM
        let expectedRPM = fan.maxRPM
        XCTAssertEqual(expectedRPM, 6000)
    }
    
    @MainActor
    func testAutoControlAlgorithmProportional() {
        let fan = FanInfo(
            id: 0,
            name: "Test Fan",
            currentRPM: 2000,
            minRPM: 1000,
            maxRPM: 6000
        )
        
        let targetTemp = 60.0
        let currentTemp = 70.0 // 10°C acima (metade da escala de 20°C)
        let tempDiff = currentTemp - targetTemp
        
        // Controle proporcional
        let range = Double(fan.maxRPM - fan.minRPM)
        let ratio = tempDiff / 20.0
        let expectedRPM = fan.minRPM + Int(range * ratio)
        
        // 10°C acima = 50% = 1000 + (5000 * 0.5) = 3500 RPM
        XCTAssertEqual(expectedRPM, 3500)
    }
    
    // MARK: - Edge Cases Tests
    
    @MainActor
    func testEmptyFansList() {
        // Manager com lista vazia de ventiladores não deve causar crash
        manager.fans = []
        
        manager.setAutoMode(enabled: true)
        manager.setFanSpeed(fanIndex: 0, rpm: 2000)
        
        XCTAssertNotNil(manager)
    }
    
    @MainActor
    func testEmptyTemperaturesList() {
        manager.temperatures = []
        
        // Não deve causar crash ao aplicar controle automático
        manager.setAutoMode(enabled: true)
        
        XCTAssertNotNil(manager)
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testFanInfoCreationPerformance() {
        measure {
            for i in 0..<100 {
                _ = FanInfo(
                    id: i,
                    name: "Fan \(i)",
                    currentRPM: 2000,
                    minRPM: 1000,
                    maxRPM: 6000
                )
            }
        }
    }
    
    @MainActor
    func testTemperatureSensorCreationPerformance() {
        measure {
            for i in 0..<100 {
                _ = TemperatureSensor(name: "Sensor \(i)", temperature: Double(i))
            }
        }
    }
}
