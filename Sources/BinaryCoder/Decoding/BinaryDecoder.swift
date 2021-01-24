//
//  BinaryDecoder.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

/**
 Decode a `Codable` type from binary data.
 
 To decode a `Codable` type from binary data, simply use the convenience method provided on the `BinaryDecoder` type:
 ```swift
 struct MyCodable: Codable {
     var name: String
     var numbers: [Int]
 }
 
 // Data previously encoded with `BinaryEncoder`
 let data = ...
 
 let value = try BinaryDecoder.decode(MyCodable.self, from: data)
 ```
 */
public final class BinaryDecoder {
    
    /// The data to decode
    var data: [UInt8]
    
    /// The current index into `data` where the next byte should be read.
    var cursor = 0
    
    /// The chosen stategy to decode keys for each property
    let keyEncoding: KeyEncodingStrategy
    
    /**
     Any contextual information set by the user for encoding.
     - Note: For `BinaryEncoder` types, this value is always an empty dictionary.
     */
    public var userInfo: [CodingUserInfoKey : Any] { [:] }

    /**
     The path of coding keys taken to get to this point in encoding.
     - Note: For `BinaryEncoder` types, this value is always an empty array.
     */
    public var codingPath: [CodingKey] { [] }
    
    /**
     Create a decoder from binary data.
     - Parameter data: The binary data to decode
     - Parameter keyEncoding: The strategy to encode keys for each property.
     */
    public init(data: Data, keyEncoding: KeyEncodingStrategy = .preferIntegerOverStringKeys) {
        self.data = Array(data)
        self.keyEncoding = keyEncoding
    }
    
    /**
     Decode a type from the binary data.
     - Returns: The decoded value
     - Throws: Errors of type `BinaryDecodingError` if the decoding failed.
     */
    public func decode<T: Decodable>() throws -> T {
        return try decode(T.self)
    }
    
}

// MARK: Convenience methods

/// A convenience function for creating a decoder and decoding from some data into a value all in one shot.
public extension BinaryDecoder {
    
    /**
     Convenience method to decode a value from data.
     - Parameter type: The type of the value to decode.
     - Parameter data: The binary data to decode.
     - Parameter keyEncoding: The key encoding strategy to use.
     */
    static func decode<T: Decodable>(_ type: T.Type, from data: Data, keyEncoding: KeyEncodingStrategy = .preferIntegerOverStringKeys) throws -> T {
        try BinaryDecoder(data: data, keyEncoding: keyEncoding).decode()
    }
}

// MARK: Actual decoding

extension BinaryDecoder {
    
    private func encodeKey(_ key: CodingKey) throws -> Data? {
        do {
            return try key.encode(using: keyEncoding)
        } catch BinaryEncodingError.stringNotRepresentableInUTF8 {
            throw BinaryDecodingError.codingKeyNotRepresentableInUTF8(key)
        } catch BinaryEncodingError.codingKeyRequiresIntegerValue {
            throw BinaryDecodingError.codingKeyRequiresIntegerValue(key)
        }
    }
    
    func readNextIntegerKey() -> Int? {
        guard hasBytesLeftToDecode else {
            return nil
        }
        
        // Mark original position to revert changes
        let oldCursor = cursor
        defer { cursor = oldCursor }
        
        return try? decodeVariableLength(Int.self)
    }
    
    /**
     Check if the key exists et the current decoding position.
     - Parameter key: The key to check.
     - Returns: `true`, if the key exists or the `excludeKeys` option is set.
     - Throws: `BinaryDecodingError.codingKeyNotInteger` if the `CodingKey` has no integer representation and the `failForMissingIntegerKeys` key decoding option is set.
     */
    func keyIsPresentForOptionalValue(for key: CodingKey) throws -> Bool {
        guard hasBytesLeftToDecode else {
            return false
        }
        // Mark original position to revert changes
        let oldCursor = cursor
        defer { cursor = oldCursor }
        
        guard let keyData = try encodeKey(key) else {
            // We only get nil for a key when excluding keys
            // In this case, optionals are encoded using default values
            return true
        }
        guard (try? decode(key: key, data: keyData)) != nil else {
            // When the buffer ends or the format is invalid, we assume that the expected key is missing
            return false
        }
        return true
    }
    
    /**
     Decode a key using variable length encoding.
     - Parameter key: The expected key to decode.
     */
    func decode(_ key: CodingKey) throws {
        guard let keyData = try encodeKey(key) else {
            // Keys are excluded from data
            return
        }
        try decode(key: key, data: keyData)
    }
    
    /**
     Attempt to decode a key and match it against the expected key data.
     - Parameter key: The expected coding key
     - Parameter data: The expected key representation.
     - Throws:`BinaryDecodingError.prematureEndOfData` if no more bytes can be read. `BinaryDecodingError.keyMismatch` if the actual data doesn't match the expected key data.
     */
    func decode(key: CodingKey, data: Data) throws {
        for byte in data {
            guard try readByte() == byte else {
                throw BinaryDecodingError.keyMismatch(key)
            }
        }
    }
    
    /**
     Decode different primitive types.
     - Parameter type: The type to decode.
     - Parameter key: The optional coding key associated with the type.
     - Returns: The decoded value.
     - Throws: Errors of type `BinaryDecodingError`
     */
    func decode<T: Decodable>(_ type: T.Type, forKey key: CodingKey? = nil) throws -> T {
        if let key = key {
            try decode(key)
        }
        switch type {
        case is Float.Type: return try decodeFloat() as! T
        case is Double.Type: return try decodeDouble() as! T
        case is Bool.Type: return (try decodeVariableLength(UInt.self) > UInt(0)) as! T
        case is String.Type: return try decodeString() as! T
            
        case is UInt8.Type: return try readByte() as! T
        case is UInt16.Type: return try decodeVariableLength(UInt16.self) as! T
        case is UInt32.Type: return try decodeVariableLength(UInt32.self) as! T
        case is UInt64.Type: return try decodeVariableLength(UInt64.self) as! T
        case is UInt.Type: return try decodeVariableLength(UInt.self) as! T
        
        case is Int8.Type: return Int8(bitPattern: try readByte()) as! T
        case is Int16.Type: return try decodeVariableLength(Int16.self) as! T
        case is Int32.Type: return try decodeVariableLength(Int32.self) as! T
        case is Int64.Type: return try decodeVariableLength(Int64.self) as! T
        case is Int.Type: return try decodeVariableLength(Int.self) as! T
        
        default:
            return try T.init(from: self)
        }
    }
    
    /**
     Decode a string.
     
     For a string, the length is encoded as a variable-length unsigned integer.
     The appropriate number of bytes is then read and converted to a UTF8 string.
     */
    private func decodeString() throws -> String {
        let length: UInt = try decodeVariableLength(UInt.self)
        let utf8 = try read(Int(length))
        guard let str = String(bytes: utf8, encoding: .utf8) else {
            throw BinaryDecodingError.invalidUTF8(Array(utf8))
        }
        return str
    }
    
    private func decodeFloat() throws -> Float {
        let result = try read(into: CFSwappedFloat32())
        return CFConvertFloatSwappedToHost(result)
    }
    
    private func decodeDouble() throws -> Double {
        let result = try read(into: CFSwappedFloat64())
        return CFConvertDoubleSwappedToHost(result)
    }
    
    private func decodeVariableLength<T: SignedInteger>(_ type: T.Type) throws -> T {
        return try T.decode(readByte)
    }
    
    private func decodeVariableLength<T: UnsignedInteger>(_ type: T.Type) throws -> T {
        return try T.decode(readByte)
    }
}

extension BinaryDecoder {
    
    /// Indicates if the cursor has reached the end of the binary data
    var hasBytesLeftToDecode: Bool {
        cursor < totalBytes
    }
    
    /// The total number of bytes in the binary data
    var totalBytes: Int {
        data.count
    }
    
    /**
     Read an appropriate number of bytes into the memory of a type.
     - Parameter value: An initial value for the type to extract.
     - Throws: `BinaryDecodingError.prematureEndOfData`
     - Returns: The value which was read from the binary data.
     */
    func read<T>(into value: T) throws -> T {
        let byteCount = MemoryLayout<T>.size
        guard cursor + byteCount <= data.count else {
            throw BinaryDecodingError.unexpectedEndOfData
        }
        var result = value
        data.withUnsafeBytes {
            let from = $0.baseAddress! + cursor
            memcpy(&result, from, byteCount)
        }
        cursor += byteCount
        return result
    }
    
    /**
     Read a number of bytes into an array.
     - Parameter byteCount: The number of bytes to read.
     - Returns: An array slice with the requested number of bytes.
     - Throws: `BinaryDecodingError.unexpectedEndOfData` if insufficient bytes are available.
     */
    func read(_ byteCount: Int) throws -> ArraySlice<UInt8> {
        let end = cursor + byteCount
        guard end <= data.count else {
            throw BinaryDecodingError.unexpectedEndOfData
        }
        let result = data[cursor..<end]
        cursor += byteCount
        return result
    }
    
    /**
     Extract the next byte from the data.
     - Throws: `BinaryDecodingError.prematureEndOfData` if no byte could be read.
     - Returns: The next byte in the buffer
     */
    func readByte() throws -> UInt8 {
        guard hasBytesLeftToDecode else {
            throw BinaryDecodingError.unexpectedEndOfData
        }
        let byte = data[cursor]
        cursor += 1
        return byte
    }
    
}

// MARK: Traversing

extension BinaryDecoder: Decoder {
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(DictionaryDecodingNode<Key>(decoder: self))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        RepeatedDecodingNode(decoder: self)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueDecodingNode(decoder: self)
    }
    
    
}
