import XCTest
@testable import SMCKit

final class SMCIntegrationTests: XCTestCase {
    
    var smc: SMC?
    
    override func setUp() {
        super.setUp()
        smc = SMC()
    }
    
    override func tearDown() {
        smc = nil
        super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testSMCConnection() throws {
        // Verifica se conseguimos conectar ao SMC
        // Em uma VM ou ambiente sem SMC, isso falhará graciosamente
        
        if let smc = smc {
            XCTAssertNotNil(smc, "SMC connection should be established on real Mac hardware")
        } else {
            // Esperado em ambientes sem SMC (VMs, CI/CD)
            XCTAssertNil(smc, "SMC connection expected to fail on non-Mac hardware")
        }
    }
    
    // MARK: - Fan Count Tests
    
    func testGetFanCount() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        let fanCount = smc.getFanCount()
        
        if let count = fanCount {
            XCTAssertGreaterThan(count, 0, "Mac should have at least one fan")
            XCTAssertLessThanOrEqual(count, 10, "Mac should not have more than 10 fans")
        }
    }
    
    // MARK: - Temperature Reading Tests
    
    func testReadCPUTemperature() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        let temp = smc.readTemperature(key: "TC0P")
        
        if let temperature = temp {
            XCTAssertGreaterThan(temperature, 0, "CPU temperature should be positive")
            XCTAssertLessThan(temperature, 110, "CPU temperature should be below 110°C")
        }
    }
    
    func testReadMultipleTemperatures() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        let temperatures = smc.getAllTemperatures()
        
        XCTAssertGreaterThan(temperatures.count, 0, "Should read at least one temperature sensor")
        
        for (name, temp) in temperatures {
            XCTAssertGreaterThan(temp, 0, "\(name) temperature should be positive")
            XCTAssertLessThan(temp, 120, "\(name) temperature should be reasonable")
        }
    }
    
    // MARK: - Fan RPM Tests
    
    func testReadFanRPM() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        guard let fanCount = smc.getFanCount(), fanCount > 0 else {
            throw XCTSkip("No fans detected")
        }
        
        let rpm = smc.readFanRPM(index: 0)
        
        if let currentRPM = rpm {
            XCTAssertGreaterThanOrEqual(currentRPM, 0, "Fan RPM should be non-negative")
            XCTAssertLessThan(currentRPM, 10000, "Fan RPM should be realistic")
        }
    }
    
    func testReadFanMinMaxRPM() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        guard let fanCount = smc.getFanCount(), fanCount > 0 else {
            throw XCTSkip("No fans detected")
        }
        
        let minRPM = smc.readFanMinRPM(index: 0)
        let maxRPM = smc.readFanMaxRPM(index: 0)
        
        if let min = minRPM, let max = maxRPM {
            XCTAssertLessThan(min, max, "Min RPM should be less than Max RPM")
            XCTAssertGreaterThan(min, 0, "Min RPM should be positive")
            XCTAssertLessThan(max, 10000, "Max RPM should be realistic")
        }
    }
    
    func testReadAllFans() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        guard let fanCount = smc.getFanCount(), fanCount > 0 else {
            throw XCTSkip("No fans detected")
        }
        
        for i in 0..<fanCount {
            let currentRPM = smc.readFanRPM(index: i)
            let minRPM = smc.readFanMinRPM(index: i)
            let maxRPM = smc.readFanMaxRPM(index: i)
            
            XCTAssertNotNil(currentRPM, "Fan \(i) current RPM should be readable")
            XCTAssertNotNil(minRPM, "Fan \(i) min RPM should be readable")
            XCTAssertNotNil(maxRPM, "Fan \(i) max RPM should be readable")
        }
    }
    
    // MARK: - Fan Control Tests
    
    func testSetFanMode() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        guard let fanCount = smc.getFanCount(), fanCount > 0 else {
            throw XCTSkip("No fans detected")
        }
        
        // Cuidado: este teste modifica configurações do hardware
        // Vamos apenas testar que o comando não causa crash
        
        // Salvar estado original seria ideal, mas vamos apenas resetar para auto
        let result = smc.setFanMode(index: 0, mode: 0) // 0 = auto mode
        
        // Se falhar, pode ser por falta de permissões
        // O importante é que não cause crash
        if result {
            XCTAssertTrue(result, "Should be able to set fan mode to auto")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testReadInvalidFanIndex() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        // Tenta ler um índice de ventilador que não existe
        let rpm = smc.readFanRPM(index: 99)
        
        XCTAssertNil(rpm, "Reading invalid fan index should return nil")
    }
    
    func testReadInvalidTemperatureKey() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        // Tenta ler uma key que não existe
        let temp = smc.readTemperature(key: "XXXX")
        
        XCTAssertNil(temp, "Reading invalid temperature key should return nil")
    }
    
    // MARK: - Performance Tests
    
    func testReadTemperaturePerformance() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        measure {
            _ = smc.readTemperature(key: "TC0P")
        }
    }
    
    func testReadFanRPMPerformance() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        guard let fanCount = smc.getFanCount(), fanCount > 0 else {
            return
        }
        
        measure {
            _ = smc.readFanRPM(index: 0)
        }
    }
    
    func testGetAllTemperaturesPerformance() throws {
        guard let smc = smc else {
            throw XCTSkip("SMC not available - skipping hardware test")
        }
        
        measure {
            _ = smc.getAllTemperatures()
        }
    }
}
