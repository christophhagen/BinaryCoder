//
//  EncodingStorage.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

/**
 The `EncodingStorage` protocol provides a tree structure while traversing the `Codable` type,
 so that the data can be encoded in the correct order.
 This is mainly needed since the number of elements in an unkeyed container needs to be prepended to the actual elements.
 Otherwise it would be possible to simply construct the binary data directly when each element is encoded.
 */
protocol EncodingStorage {
    
    /// The encoder used for all conversions to data.
    var encoder: BinaryEncoder { get }
    
    /**
     The other storage nodes contained in this node.
     */
    var storage: [EncodingStorage] { get }
    
    /**
     The storage node converted to data.
     */
    var data: Data { get }
}

extension EncodingStorage {
    
    /**
     Encode the current node to data.
     
     Traverses the full sub-tree and concatenates all data from the leaves.
     */
    var data: Data {
        storage.reduce(Data()) { $0 + $1.data }
    }
}

/// Extension to `Data` so that it can be stored in the `storage` property of `EncodingStorage` types.
extension Data: EncodingStorage {
    
    var encoder: BinaryEncoder {
        // The encoder of a Data value will never be accessed.
        fatalError()
    }
    
    
    var storage: [EncodingStorage] {
        // The data type is always a leaf and has no children,
        // so this property is always an empty array.
        []
    }
    
    /**
     The actual data.
     
     This property overrides the default implementation of `EncodingStorage`
     to stop the recursion and provide the encoded data.
     */
    var data: Data { self }
}

// MARK: Encoding

extension EncodingStorage {
    
    /// The key encoding to use
    var keyEncoding: KeyEncodingStrategy {
        encoder.keyEncoding
    }
    
    /**
     Encode a nil value.
     
     Does nothing, or throws an error for the `excludeKeys` option.
     - Throws: `BinaryEncodingError.foundOptionalValueWhileExcludingKeys` if the `excludeKeys` option is specified.
     */
    func encodeNil() throws {
        func encodeNil() throws {
            guard keyEncoding == .excludeKeys else {
                // Nothing to do for nil values
                return
            }
            throw BinaryEncodingError.foundOptionalValueWhileExcludingKeys
        }
    }
    
    
    
    /**
     Encode a value for a key.
     - Parameter value: The value to encode for the key.
     - Parameter key: The (optional) key to encode.
     - Returns: The binary data of the key followed by the value.
     - Note: The key is encoded according to the key encoding strategy set by the decoder.
     */
    func encodeValueAndKey<T>(_ value: T, forKey key: CodingKey? = nil) throws -> Data where T: Encodable {
        try encodeKey(key) + encodeOnlyValue(value)
    }
    
    /**
     Encode a key using the key encoding strategy set by the decoder.
     - Parameter key: The key to encode (can be nil)
     - Returns: The binary data of the encoded key.
     - Note: If the `key` value is `nil`, or the `excludeKeys` strategy is used, then the returned data is empty.
     */
    private func encodeKey(_ key: CodingKey?) throws -> Data {
        try key?.encode(using: keyEncoding) ?? Data()
    }
    
    /**
     Encode a value without a key.
     - Parameter value: The value to encode.
     - Returns: The binary data of the value.
     - Note: Integer values (except `UInt8` and `Int8`) are encoded using variable-length encoding.
     */
    func encodeOnlyValue<T>(_ value: T) throws -> Data where T: Encodable {
        switch value {
        case let value as UInt8: return value.encoded
        case let value as UInt16: return value.variableLengthEncoding
        case let value as UInt32: return value.variableLengthEncoding
        case let value as UInt64: return value.variableLengthEncoding
        case let value as UInt: return value.variableLengthEncoding
        
        case let value as Int8: return value.encoded
        case let value as Int16: return value.variableLengthEncoding
        case let value as Int32: return value.variableLengthEncoding
        case let value as Int64: return value.variableLengthEncoding
        case let value as Int: return value.variableLengthEncoding
        
        case let value as Bool: return value.encoded
        case let value as Float: return value.encoded
        case let value as Double: return value.encoded
        case let value as String: return try value.encoded()
            
        default: return try BinaryEncoder.encode(value, keyEncoding: keyEncoding)
        }
    }
}
