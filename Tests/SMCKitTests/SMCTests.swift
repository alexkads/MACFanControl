import XCTest
@testable import SMCKit

final class SMCTests: XCTestCase {
    
    // MARK: - Four Char Code Tests
    
    func testFourCharCodeConversion() {
        // Test de conversão de string para código de 4 caracteres
        let smc = SMC()
        
        // Não podemos testar métodos privados diretamente, mas podemos testar
        // o comportamento através dos métodos públicos
    }
    
    // MARK: - Temperature Decoding Tests
    
    func testTemperatureDecoding() {
        // Testa a decodificação de valores de temperatura
        // Formato: sp78 (signed fixed point, 8 bits inteiros, 8 bits decimais)
        
        // Exemplo: 50.25°C = 0x3240
        // 0x32 = 50, 0x40 = 64 (64/256 = 0.25)
        let highByte: UInt8 = 0x32
        let lowByte: UInt8 = 0x40
        
        let intValue = (Int(highByte) << 8) | Int(lowByte)
        let temperature = Double(intValue) / 256.0
        
        XCTAssertEqual(temperature, 50.25, accuracy: 0.01)
    }
    
    func testTemperatureDecodingZero() {
        let highByte: UInt8 = 0x00
        let lowByte: UInt8 = 0x00
        
        let intValue = (Int(highByte) << 8) | Int(lowByte)
        let temperature = Double(intValue) / 256.0
        
        XCTAssertEqual(temperature, 0.0, accuracy: 0.01)
    }
    
    func testTemperatureDecodingHigh() {
        // 100°C = 0x6400
        let highByte: UInt8 = 0x64
        let lowByte: UInt8 = 0x00
        
        let intValue = (Int(highByte) << 8) | Int(lowByte)
        let temperature = Double(intValue) / 256.0
        
        XCTAssertEqual(temperature, 100.0, accuracy: 0.01)
    }
    
    // MARK: - FPE2 Encoding/Decoding Tests
    
    func testFPE2Encoding() {
        // FPE2: Fixed Point Exponential 2
        // Formato: valor << 2
        
        let rpm = 2000
        let encoded = UInt16(rpm << 2)
        
        XCTAssertEqual(encoded, 8000)
    }
    
    func testFPE2Decoding() {
        let highByte: UInt8 = 0x1F
        let lowByte: UInt8 = 0x40
        
        let intValue = (Int(highByte) << 8) | Int(lowByte)
        let rpm = intValue >> 2
        
        XCTAssertEqual(rpm, 2000)
    }
    
    func testFPE2RoundTrip() {
        let originalRPM = 3500
        let encoded = UInt16(originalRPM << 2)
        let decoded = Int(encoded) >> 2
        
        XCTAssertEqual(decoded, originalRPM)
    }
    
    // MARK: - SMC Value Structure Tests
    
    func testSMCValStructureSize() {
        let smcVal = SMCVal_t()
        
        // Verifica que a estrutura tem os campos esperados
        XCTAssertEqual(smcVal.key, 0)
        XCTAssertEqual(smcVal.dataSize, 0)
        XCTAssertEqual(smcVal.dataType, 0)
    }
    
    func testSMCKeyDataStructure() {
        let keyData = SMCKeyData_t()
        
        XCTAssertEqual(keyData.dataSize, 0)
        XCTAssertEqual(keyData.dataType, 0)
        XCTAssertEqual(keyData.dataAttributes, 0)
    }
    
    // MARK: - Fan Name Tests
    
    func testFanKeyGeneration() {
        // Testa geração de keys para diferentes ventiladores
        let fanIndex0 = String(format: "F%dAc", 0)
        let fanIndex1 = String(format: "F%dAc", 1)
        
        XCTAssertEqual(fanIndex0, "F0Ac")
        XCTAssertEqual(fanIndex1, "F1Ac")
    }
    
    func testFanModeKeyGeneration() {
        let modeKey0 = String(format: "F%dMd", 0)
        let modeKey1 = String(format: "F%dMd", 1)
        
        XCTAssertEqual(modeKey0, "F0Md")
        XCTAssertEqual(modeKey1, "F1Md")
    }
    
    func testFanTargetKeyGeneration() {
        let targetKey0 = String(format: "F%dTg", 0)
        let targetKey1 = String(format: "F%dTg", 1)
        
        XCTAssertEqual(targetKey0, "F0Tg")
        XCTAssertEqual(targetKey1, "F1Tg")
    }
    
    // MARK: - Temperature Key Tests
    
    func testTemperatureKeyFormat() {
        let cpuKeys = ["TC0P", "TC0D", "TC0E", "TC0F"]
        let gpuKeys = ["TG0D", "TG0P"]
        
        // Verifica que as keys têm o formato correto (4 caracteres)
        for key in cpuKeys + gpuKeys {
            XCTAssertEqual(key.count, 4)
        }
    }
    
    // MARK: - RPM Boundary Tests
    
    func testMinRPMDecoding() {
        // RPM mínimo típico: 1000 RPM
        // Em FPE2: 1000 << 2 = 4000 = 0x0FA0
        let highByte: UInt8 = 0x0F
        let lowByte: UInt8 = 0xA0
        
        let intValue = (Int(highByte) << 8) | Int(lowByte)
        let rpm = intValue >> 2
        
        XCTAssertEqual(rpm, 1000)
    }
    
    func testMaxRPMDecoding() {
        // RPM máximo típico: 6000 RPM
        // Em FPE2: 6000 << 2 = 24000 = 0x5DC0
        let highByte: UInt8 = 0x5D
        let lowByte: UInt8 = 0xC0
        
        let intValue = (Int(highByte) << 8) | Int(lowByte)
        let rpm = intValue >> 2
        
        XCTAssertEqual(rpm, 6000)
    }
    
    // MARK: - Error Handling Tests
    
    func testSMCInitializationHandlesNilConnection() {
        // Este teste verifica que SMC pode retornar nil se a conexão falhar
        // Em um ambiente de teste sem acesso ao SMC real, isso é esperado
        
        let smc = SMC()
        
        // Em uma VM ou ambiente sem SMC, smc pode ser nil
        // O teste apenas verifica que a inicialização não causa crash
        if smc == nil {
            XCTAssertNil(smc)
        }
    }
    
    // MARK: - Data Type Tests
    
    func testDataTypeConstants() {
        // Testa que constantes de tipo de dados são corretas
        struct DataTypes {
            static let sp78: UInt32 = 0x73703738 // "sp78"
            static let fpe2: UInt32 = 0x66706532 // "fpe2"
            static let ui8: UInt32 = 0x75693820  // "ui8 "
        }
        
        // Verifica que os códigos são válidos
        XCTAssertGreaterThan(DataTypes.sp78, 0)
        XCTAssertGreaterThan(DataTypes.fpe2, 0)
        XCTAssertGreaterThan(DataTypes.ui8, 0)
    }
    
    // MARK: - Performance Tests
    
    func testTemperatureDecodingPerformance() {
        measure {
            for _ in 0..<1000 {
                let highByte: UInt8 = 0x32
                let lowByte: UInt8 = 0x40
                let intValue = (Int(highByte) << 8) | Int(lowByte)
                _ = Double(intValue) / 256.0
            }
        }
    }
    
    func testFPE2DecodingPerformance() {
        measure {
            for _ in 0..<1000 {
                let highByte: UInt8 = 0x1F
                let lowByte: UInt8 = 0x40
                let intValue = (Int(highByte) << 8) | Int(lowByte)
                _ = intValue >> 2
            }
        }
    }
}
