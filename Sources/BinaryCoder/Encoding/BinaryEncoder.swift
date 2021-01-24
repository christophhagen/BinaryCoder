//
//  BinaryEncoder.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

/**
 An encoder to convert `Codable` types to binary data in an efficient manner.
 
 Integers are encoded using variable-length encoding, which shrinks the binary data in cases where small values are encoded.
 
 To convert any `Codable` type to `Data`, simply use the convenience method provided on the `BinaryEncoder` type:
 ```swift
 struct MyCodable: Codable {
     var name: String
     var numbers: [Int]
 }
 
 let value = MyCodable(
     name: "Eve",
     numbers: [4,8,15,16,23,42]
 
 let data = try BinaryEncoder.encode(value)
 ```
 
 It's also possible to encode multiple values one after another:
 ```swift
 let encoder = BinaryEncoder()
 try value1.encode(to: encoder)
 // Equivalent way of encoding
 try encoder.encode(value2)
 let data = encoder.encodedData
 ```
 
 Decoding then works similarly:
 ```swift
 let decoder = BinaryDecoder()
 let value1 = try decoder.decode(MyCodable.self)
 // Equivalent way of decoding
 let value2: MyCodable = try decoder.decode()
 ```
 
 - Note: For efficient packing, `Codable` types should provide integer representations for each `CodingKey`, which can be achieved by providing an `enum` on the type with the raw type `Int` and conforming to `CodingKey`:
 
 ```swift
 extension MyCodable {
     enum CodingsKeys: Int, CodingKey {
         case name // Implicit key ids starting at 0
         case numbers = 2 // Explicit key id
     }
 }
 ```
 */
public final class BinaryEncoder: EncodingStorage {
    
    /// The encoder to convert basic types
    var encoder: BinaryEncoder { self }
    
    /// The storage which holds all processed keys
    var storage: [EncodingStorage] = []
    
    /// The chosen stategy to encode keys for each property
    public let keyEncoding: KeyEncodingStrategy
    
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
     Create a binary encoder.
     
     - Parameter keyEncoding: The strategy to encode keys for each property.
     */
    public init(keyEncoding: KeyEncodingStrategy = .preferIntegerOverStringKeys) {
        self.keyEncoding = keyEncoding
    }
    
    /**
     Encode a value and add it to the encoder.
     - Parameter value: The value to encode.
     - Throws: Errors of type `BinaryEncodingError` if the value can't be encoded
     - Note: The encoded data for all values currently encoded can be accessed through the `encodedData` property.
     */
    public func encode<T: Encodable>(_ value: T) throws {
        try value.encode(to: encoder)
    }
    
    /**
     The encoded data for all values currently encoded in the encoder.
     */
    public var encodedData: Data {
        data
    }
    
}

// MARK: Convencience methods

/**
 A convenience function for creating an encoder, encoding a value,
 and extracting the resulting data.
 */
public extension BinaryEncoder {
    
    /**
     Encode a value to binary data.
     - Parameter value: The value to encode.
     - Parameter keyEncoding: The strategy for encoding keys for each property.
     - Returns: The binary data.
     - Throws: Errors of type `BinaryEncodingError`, if the type can't be encoded.
     */
    static func encode(_ value: Encodable, keyEncoding: KeyEncodingStrategy = .preferIntegerOverStringKeys) throws -> Data {
        let encoder = BinaryEncoder(keyEncoding: keyEncoding)
        try value.encode(to: encoder)
        return encoder.data
    }
}


// MARK: Traversing the tree

extension BinaryEncoder: Encoder {
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = DictionaryEncodingNode<Key>(encoder: self)
        storage.append(container)
        return KeyedEncodingContainer(container)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = RepeatedEncodingNode(encoder: self)
        storage.append(container)
        return container
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        let container = SingleValueEncodingNode(encoder: self)
        storage.append(container)
        return container
    }
    
}
