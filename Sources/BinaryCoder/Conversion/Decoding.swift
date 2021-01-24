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
     - Throws: `BinaryDecodingError.unexpectedEndOfData`
     - Returns: The decoded unsigned integer.
     */
    static func decode(_ byteProvider: () throws -> UInt8) rethrows -> UInt64 {
        var result: UInt64 = 0
        
        var shift = 0
        while true {
            guard shift < 56 else {
                // 9th byte has no indicator bit
                // Use all 8 bits to get to 64 (8*7 + 8)
                result += UInt64(try byteProvider()) << shift
                return result
            }
            let nextByte = UInt64(try byteProvider())
            // Insert the last 7 bit of the byte at the end
            result += UInt64(nextByte & 0x7F) << shift
            shift += 7
            // Check if an additional byte is coming
            guard nextByte & 0x80 > 0 else {
                return result
            }
        }
    }
    
    static func decode<T: RandomAccessCollection>(from data: T) throws -> (value: UInt64, bytesConsumed: Int) where T.Element == UInt8, T.Indices.Element == Int {
        var index = 0
        let value = try decode {
            guard index < data.count else {
                throw BinaryDecodingError.unexpectedEndOfData
            }
            let byte = data[index]
            index += 1
            return byte
        }
        return (value, index)
    }
}

extension Int64 {
    
    /**
     Decode a 64 bit signed integer using variable-length encoding.
     
     Decodes an unsigned integer, where the last bit indicates the sign, and the absolute value is half of the decoded value
     - Parameter byteProvider: A closure providing the next byte in the data.
     - Throws: `BinaryDecodingError.unexpectedEndOfData`
     - Returns: The decoded signed integer.
     */
    static func decode(_ byteProvider: () throws -> UInt8) throws -> Int64 {
        let result = try UInt64.decode(byteProvider)
        // Check the last bit to get sign
        guard result & 1 > 0 else {
            // Divide by two to get absolute value of positive values
            return Int64(result >> 1)
        }
        // Divide by 2 and subtract one to get absolute value of negative values.
        return -Int64(result >> 1) - 1
    }
    
    static func decode<T: RandomAccessCollection>(from data: T) throws -> (value: Int64, bytesConsumed: Int) where T.Element == UInt8, T.Indices.Element == Int {
        var index = 0
        let value = try decode {
            guard index < data.count else {
                throw BinaryDecodingError.unexpectedEndOfData
            }
            let byte = data[index]
            index += 1
            return byte
        }
        return (value, index)
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
    
    /**
     Decode an unsigned integer using variable-length encoding.
     
     - Parameter byteProvider: A callback to read bytes from the data stream.
     - Throws: `BinaryDecodingError.variableLengthEncodedValueOutOfRange` if the decoded value doesn't fit into the type
     */
    static func decode(_ byteProvider: () throws -> UInt8) throws -> Self {
        let value = try UInt64.decode(byteProvider)
        guard let result = Self.init(exactly: value) else {
            throw BinaryDecodingError.variableLengthEncodedValueOutOfRange
        }
        return result
    }
}
