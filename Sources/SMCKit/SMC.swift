import Foundation
import IOKit

// MARK: - SMC Key Structure
struct SMCKey {
    let code: UInt32
    let info: SMCKeyData_t
}

// MARK: - SMC Data Structures
struct SMCKeyData_t {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

struct SMCVal_t {
    var key: UInt32 = 0
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0,
                                                                             0, 0, 0, 0, 0, 0, 0, 0,
                                                                             0, 0, 0, 0, 0, 0, 0, 0,
                                                                             0, 0, 0, 0, 0, 0, 0, 0)
}

// MARK: - SMC Class
public class SMC {
    private var connection: io_connect_t = 0
    
    public init?() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return nil }
        
        let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
        IOObjectRelease(service)
        
        guard result == kIOReturnSuccess else { return nil }
    }
    
    deinit {
        if connection != 0 {
            IOServiceClose(connection)
        }
    }
    
    // MARK: - Public Methods
    
    /// Read temperature from SMC
    public func readTemperature(key: String) -> Double? {
        guard let value = readKey(key) else { return nil }
        return decodeTemperature(value)
    }
    
    /// Get number of fans
    public func getFanCount() -> Int? {
        guard let value = readKey("FNum") else { return nil }
        return Int(value.bytes.0)
    }
    
    /// Read fan RPM
    public func readFanRPM(index: Int) -> Int? {
        let key = String(format: "F%dAc", index)
        guard let value = readKey(key) else { return nil }
        return decodeFPE2(value)
    }
    
    /// Read fan minimum RPM
    public func readFanMinRPM(index: Int) -> Int? {
        let key = String(format: "F%dMn", index)
        guard let value = readKey(key) else { return nil }
        return decodeFPE2(value)
    }
    
    /// Read fan maximum RPM
    public func readFanMaxRPM(index: Int) -> Int? {
        let key = String(format: "F%dMx", index)
        guard let value = readKey(key) else { return nil }
        return decodeFPE2(value)
    }
    
    /// Set fan to manual mode
    public func setFanMode(index: Int, mode: UInt8) -> Bool {
        let key = String(format: "F%dMd", index)
        return writeKey(key, value: mode)
    }
    
    /// Set fan target RPM
    public func setFanRPM(index: Int, rpm: Int) -> Bool {
        let key = String(format: "F%dTg", index)
        return writeFPE2(key, value: rpm)
    }
    
    /// Get all temperature sensors
    public func getAllTemperatures() -> [String: Double] {
        var temps: [String: Double] = [:]
        
        let tempKeys = [
            "TC0P": "CPU Proximity",
            "TC0D": "CPU Die",
            "TC0E": "CPU Core 1",
            "TC0F": "CPU Core 2",
            "TG0D": "GPU Die",
            "TG0P": "GPU Proximity",
            "Th0H": "HDD Bay 1",
            "Tm0P": "Memory Proximity",
            "TN0D": "Northbridge Die",
            "TN0P": "Northbridge Proximity",
            "To0P": "Optical Drive",
            "Ts0P": "Palm Rest"
        ]
        
        for (key, name) in tempKeys {
            if let temp = readTemperature(key: key) {
                temps[name] = temp
            }
        }
        
        return temps
    }
    
    // MARK: - Private Methods
    
    private func readKey(_ key: String) -> SMCVal_t? {
        let keyCode = fourCharCode(key)
        var inputStruct = SMCVal_t()
        var outputStruct = SMCVal_t()
        
        inputStruct.key = keyCode
        inputStruct.dataSize = 32
        
        let inputStructSize = MemoryLayout<SMCVal_t>.size
        var outputStructSize = inputStructSize
        
        let result = IOConnectCallStructMethod(
            connection,
            5, // kSMCUserClientRead
            &inputStruct,
            inputStructSize,
            &outputStruct,
            &outputStructSize
        )
        
        guard result == kIOReturnSuccess else { return nil }
        return outputStruct
    }
    
    private func writeKey(_ key: String, value: UInt8) -> Bool {
        let keyCode = fourCharCode(key)
        var inputStruct = SMCVal_t()
        
        inputStruct.key = keyCode
        inputStruct.dataSize = 1
        inputStruct.dataType = fourCharCode("ui8 ")
        inputStruct.bytes.0 = value
        
        let inputStructSize = MemoryLayout<SMCVal_t>.size
        var outputStructSize = inputStructSize
        var outputStruct = SMCVal_t()
        
        let result = IOConnectCallStructMethod(
            connection,
            6, // kSMCUserClientWrite
            &inputStruct,
            inputStructSize,
            &outputStruct,
            &outputStructSize
        )
        
        return result == kIOReturnSuccess
    }
    
    private func writeFPE2(_ key: String, value: Int) -> Bool {
        let keyCode = fourCharCode(key)
        var inputStruct = SMCVal_t()
        
        inputStruct.key = keyCode
        inputStruct.dataSize = 2
        inputStruct.dataType = fourCharCode("fpe2")
        
        let encoded = encodeFPE2(value)
        inputStruct.bytes.0 = UInt8((encoded >> 8) & 0xFF)
        inputStruct.bytes.1 = UInt8(encoded & 0xFF)
        
        let inputStructSize = MemoryLayout<SMCVal_t>.size
        var outputStructSize = inputStructSize
        var outputStruct = SMCVal_t()
        
        let result = IOConnectCallStructMethod(
            connection,
            6, // kSMCUserClientWrite
            &inputStruct,
            inputStructSize,
            &outputStruct,
            &outputStructSize
        )
        
        return result == kIOReturnSuccess
    }
    
    private func fourCharCode(_ str: String) -> UInt32 {
        let chars = Array(str.utf8.prefix(4))
        var result: UInt32 = 0
        for (i, char) in chars.enumerated() {
            result |= UInt32(char) << (24 - i * 8)
        }
        return result
    }
    
    private func decodeTemperature(_ value: SMCVal_t) -> Double {
        let highByte = value.bytes.0
        let lowByte = value.bytes.1
        let intValue = (Int(highByte) << 8) | Int(lowByte)
        return Double(intValue) / 256.0
    }
    
    private func decodeFPE2(_ value: SMCVal_t) -> Int {
        let highByte = value.bytes.0
        let lowByte = value.bytes.1
        let intValue = (Int(highByte) << 8) | Int(lowByte)
        return intValue >> 2
    }
    
    private func encodeFPE2(_ value: Int) -> UInt16 {
        return UInt16(value << 2)
    }
}
