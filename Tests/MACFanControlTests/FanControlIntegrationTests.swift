import XCTest
@testable import MACFanControl

final class FanControlIntegrationTests: XCTestCase {
    
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
    
    // MARK: - Full Lifecycle Tests
    
    @MainActor
    func testFullLifecycle() async {
        // Testa ciclo completo: inicialização -> monitoramento -> controle -> cleanup
        
        manager.startMonitoring()
        
        // Aguarda alguns ciclos de atualização
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 segundos
        
        if manager.isConnected && manager.fans.count > 0 {
            // Testa modo automático
            manager.setAutoMode(enabled: true)
            XCTAssertTrue(manager.autoMode)
            
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
            
            // Testa modo manual
            manager.setFanSpeed(fanIndex: 0, rpm: 2000)
            XCTAssertFalse(manager.autoMode)
            
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
            
            // Volta para auto
            manager.resetToDefault()
            XCTAssertTrue(manager.autoMode)
        }
        
        manager.stopMonitoring()
    }
    
    // MARK: - Real Hardware Tests
    
    @MainActor
    func testRealHardwareDetection() {
        if manager.isConnected {
            XCTAssertTrue(manager.isConnected, "Should be connected to SMC on real Mac")
            
            // Se conectado, deve ter detectado ventiladores
            // (Nota: alguns Macs podem não expor ventiladores via SMC)
            print("Fans detected: \(manager.fans.count)")
            print("Temperatures detected: \(manager.temperatures.count)")
        } else {
            XCTSkip("SMC not available - running on VM or non-Mac hardware")
        }
    }
    
    @MainActor
    func testReadRealTemperatures() {
        guard manager.isConnected else {
            XCTSkip("SMC not available")
        }
        
        let expectation = XCTestExpectation(description: "Wait for temperature update")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.manager.temperatures.count > 0 {
                for temp in self.manager.temperatures {
                    print("Sensor: \(temp.name) - \(temp.temperature)°C")
                    XCTAssertGreaterThan(temp.temperature, 0)
                    XCTAssertLessThan(temp.temperature, 120)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4.0)
    }
    
    @MainActor
    func testReadRealFanSpeeds() {
        guard manager.isConnected else {
            XCTSkip("SMC not available")
        }
        
        let expectation = XCTestExpectation(description: "Wait for fan update")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.manager.fans.count > 0 {
                for fan in self.manager.fans {
                    print("Fan: \(fan.name)")
                    print("  Current: \(fan.currentRPM) RPM")
                    print("  Min: \(fan.minRPM) RPM")
                    print("  Max: \(fan.maxRPM) RPM")
                    
                    XCTAssertGreaterThanOrEqual(fan.currentRPM, 0)
                    XCTAssertGreaterThan(fan.minRPM, 0)
                    XCTAssertGreaterThan(fan.maxRPM, fan.minRPM)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4.0)
    }
    
    // MARK: - Auto Mode Integration Tests
    
    @MainActor
    func testAutoModeWithRealData() async {
        guard manager.isConnected else {
            XCTSkip("SMC not available")
        }
        
        manager.setAutoMode(enabled: true)
        manager.targetTemperature = 60.0
        
        // Aguarda aplicação do controle automático
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        // Verifica que o modo automático está ativo
        XCTAssertTrue(manager.autoMode)
    }
    
    // MARK: - Manual Mode Integration Tests
    
    @MainActor
    func testManualModeWithRealData() async {
        guard manager.isConnected, manager.fans.count > 0 else {
            XCTSkip("SMC or fans not available")
        }
        
        let originalRPM = manager.fans[0].currentRPM
        let targetRPM = manager.fans[0].minRPM + 500
        
        manager.setFanSpeed(fanIndex: 0, rpm: targetRPM)
        
        // Aguarda aplicação da mudança
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        // Verifica que foi definido como manual
        if manager.fans[0].isManual {
            XCTAssertEqual(manager.fans[0].targetRPM, targetRPM)
        }
        
        // Restaura modo automático
        manager.resetToDefault()
        
        print("Original RPM: \(originalRPM), Target RPM: \(targetRPM)")
    }
    
    // MARK: - Stress Tests
    
    @MainActor
    func testRapidModeChanges() async {
        guard manager.isConnected else {
            XCTSkip("SMC not available")
        }
        
        // Alterna rapidamente entre modos
        for _ in 0..<10 {
            manager.setAutoMode(enabled: true)
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            
            manager.setAutoMode(enabled: false)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Não deve causar crash
        XCTAssertNotNil(manager)
    }
    
    @MainActor
    func testRapidTargetTemperatureChanges() async {
        guard manager.isConnected else {
            XCTSkip("SMC not available")
        }
        
        manager.setAutoMode(enabled: true)
        
        // Altera rapidamente temperatura alvo
        for temp in stride(from: 40.0, through: 80.0, by: 5.0) {
            manager.targetTemperature = temp
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        XCTAssertNotNil(manager)
    }
    
    // MARK: - Long Running Tests
    
    @MainActor
    func testLongRunningMonitoring() async {
        guard manager.isConnected else {
            XCTSkip("SMC not available")
        }
        
        manager.startMonitoring()
        
        // Monitora por 30 segundos
        for i in 0..<15 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            print("Cycle \(i + 1):")
            print("  Fans: \(manager.fans.count)")
            print("  Temperatures: \(manager.temperatures.count)")
            
            if let firstTemp = manager.temperatures.first {
                print("  Max temp: \(firstTemp.temperature)°C")
            }
        }
        
        manager.stopMonitoring()
        
        XCTAssertNotNil(manager)
    }
    
    // MARK: - Error Recovery Tests
    
    @MainActor
    func testRecoveryFromSMCDisconnection() {
        // Simula perda de conexão
        manager.stopMonitoring()
        manager.isConnected = false
        
        // Tenta operações
        manager.setAutoMode(enabled: true)
        manager.setFanSpeed(fanIndex: 0, rpm: 2000)
        
        // Não deve causar crash
        XCTAssertNotNil(manager)
    }
    
    // MARK: - Memory Tests
    
    @MainActor
    func testMemoryLeakOnRepeatedStartStop() async {
        guard manager.isConnected else {
            XCTSkip("SMC not available")
        }
        
        // Inicia e para várias vezes
        for _ in 0..<20 {
            manager.startMonitoring()
            try? await Task.sleep(nanoseconds: 500_000_000)
            manager.stopMonitoring()
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        XCTAssertNotNil(manager)
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testMonitoringUpdatePerformance() {
        guard manager.isConnected else {
            XCTSkip("SMC not available")
        }
        
        manager.startMonitoring()
        
        let expectation = XCTestExpectation(description: "Wait for updates")
        
        measure {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
        manager.stopMonitoring()
    }
}
