//
//  Encoding.swift
//  BinaryCoder
//
//  Created by CH on 22.01.21.
//

import Foundation

extension Int64 {
    
    /**
     Encode a 64 bit signed integer using variable-length encoding.
     
        The sign of the value is extracted and appended as an additional bit.
     Positive signed values are thus encoded as `UInt(value) * 2`, and negative values as `UInt(abs(value) * 2 + 1`
     
     - Parameter value: The value to encode.
     - Returns: The value encoded as binary data (1 to 9 byte)
     */
    var variableLengthEncoding: Data {
        // Set the first bit according to the sign
        let sign: UInt64 = (self < 0) ? 1 : 0
        // Encode the absolute value in the remaining bytes
        let unsigned = (UInt64(abs(self)) << 1) + sign
        return unsigned.variableLengthEncoding
    }
}

extension UInt64 {
    
    /**
     Encode a 64 bit unsigned integer using variable-length encoding.
     
     The first bit in each byte is used to indicate that another byte will follow it.
     So values from 0 to 2^7 - 1 (i.e. 127) will be encoded in a single byte.
     In general, `n` bytes are needed to encode values from ` 2^(n-1) ` to ` 2^n - 1 `
     The maximum encodable value ` 2^64 - 1 ` is encoded as 9 byte.
     
     - Parameter value: The value to encode.
     - Returns: The value encoded as binary data (1 to 9 byte)
     */
    var variableLengthEncoding: Data {
        var result = Data()
        var value = self
        while true {
            // Extract 7 bit from value
            let nextByte = UInt8(value & 0x7F)
            value = value >> 7
            guard value > 0 else {
                result.append(nextByte)
                break
            }
            // Set 8th bit to indicate another byte
            result.append(nextByte | 0x80)
        }
        return result
    }
}

extension UInt8 {
    
    /// The value converted to a single byte
    var encoded: Data {
        Data([self])
    }
}

extension Int8 {
    
    /// The value converted to a single byte
    var encoded: Data {
        toData(self)
    }
}

extension UnsignedInteger {
    
    /**
     Encode the value using variable-length encoding.
     
        The sign of the value is extracted and appended as an additional bit.
     Positive signed values are thus encoded as `UInt(value) * 2`, and negative values as `UInt(abs(value) * 2 + 1`
     
     - Returns: The value encoded as binary data (1 to 9 byte)
     */
    var variableLengthEncoding: Data {
        UInt64(self).variableLengthEncoding
    }
}

extension SignedInteger {
    
    /**
     Encode the value using variable-length encoding.
     
     The first bit in each byte is used to indicate that another byte will follow it.
     So values from 0 to 2^7 - 1 (i.e. 127) will be encoded in a single byte.
     In general, `n` bytes are needed to encode values from ` 2^(n-1) ` to ` 2^n - 1 `
     The maximum encodable value ` 2^64 - 1 ` is encoded as 9 byte.
     
     - Returns: The value encoded as binary data (1 to 9 byte)
     */
    var variableLengthEncoding: Data {
        Int64(self).variableLengthEncoding
    }
}

extension Bool {
    
    /// Encode the value as a single byte of either `1` for  `true` or `0` for `false`
    var encoded: Data {
        return (self ? UInt8(1) : 0).variableLengthEncoding
    }
}

extension Float {
    
    /// Encode the value into a platform-independent binary format.
    var encoded: Data {
        toData(CFConvertFloatHostToSwapped(self))
    }
}

extension Double {
    
    /// Encode the value into a platform-independent binary format.
    var encoded: Data {
        toData(CFConvertDoubleHostToSwapped(self))
    }
}

extension String {
    
    /**
     Encodes a string using the UTF8 representation.
     
     - Note: The length of the string is prepended to the data encoded as a variable-length unsigned integer.
     - Throws: `BinaryEncodingError.stringNotRepresentableInUTF8` if the string can't be converted to UTF8
     */
    func encoded() throws -> Data {
        guard let data = data(using: .utf8) else {
            throw BinaryEncodingError.stringNotRepresentableInUTF8(self)
        }
        let size = UInt64(data.count).variableLengthEncoding
        return size + data
    }
}


private func toData<T>(_ value: T) -> Data {
    var target = value
    return withUnsafeBytes(of: &target) {
        Data($0)
    }
}
