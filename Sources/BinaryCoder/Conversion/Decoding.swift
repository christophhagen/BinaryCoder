//
//  Decoding.swift
//  BinaryCoder
//
//  Created by CH on 22.01.21.
//

import Foundation

extension UInt64 {
    
    /**
     Decode a 64 bit unsigned integer using variable length encoding.
     
     The first bit of each byte indicates if another byte follows.
     The remaining 7 bit are the first 7 bit of the number.
     - Throws: `BinaryDecodingError.prematureEndOfData`, `BinaryDecodingError.invalidVariableLengthEncoding`
     - Returns: The decoded unsigned integer.
     */
    static func decode(_ byteProvider: () throws -> UInt8) throws -> UInt64 {
        var result: UInt64 = 0
        
        var shift = 0
        while true {
            let nextByte = UInt64(try byteProvider())
            // Insert the last 7 bit of the byte at the end
            result += UInt64(nextByte & 0x7F) << shift
            shift += 7
            // Check if an additional byte is coming
            guard nextByte & 0x80 > 0 else {
                return result
            }
            guard shift < 64 else {
                // The 9th byte has the additional byte flag set
                throw BinaryDecodingError.invalidVariableLengthEncoding
            }
        }
    }
}

extension Int64 {
    
    /**
     Decode a 64 bit signed integer using variable-length encoding.
     
     Decodes an unsigned integer, where the last bit indicates the sign, and the absolute value is half of the decoded value
     - Parameter byteProvider: A closure providing the next byte in the data.
     - Throws: `BinaryDecodingError.prematureEndOfData`, `BinaryDecodingError.valueOutOfRange`
     - Returns: The decoded signed integer.
     */
    static func decode(_ byteProvider: () throws -> UInt8) throws -> Int64 {
        let result = try UInt64.decode(byteProvider)
        // Check the last bit to get sign and divide by two to get absolute value
        return (result & 1 > 0) ? -Int64(result >> 1) : Int64(result >> 1)
    }
}

extension SignedInteger {
    
    /**
     Decode a signed integer using variable-length encoding.
     
     - Parameter byteProvider: A callback to read bytes from the data stream.
     - Throws: `BinaryDecodingError.variableLengthEncodedValueOutOfRange` if the decoded value doesn't fit into the type
     */
    static func decode(_ byteProvider: () throws -> UInt8) throws -> Self {
        let value = try Int64.decode(byteProvider)
        guard let result = Self.init(exactly: value) else {
            throw BinaryDecodingError.variableLengthEncodedValueOutOfRange
        }
        return result
    }
}

extension UnsignedInteger {
    
    static func decode(_ byteProvider: () throws -> UInt8) throws -> Self {
        let value = try UInt64.decode(byteProvider)
        guard let result = Self.init(exactly: value) else {
            throw BinaryDecodingError.variableLengthEncodedValueOutOfRange
        }
        return result
    }
}
