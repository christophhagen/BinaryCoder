//
//  DictionaryEncodingNode.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

final class DictionaryEncodingNode<K : CodingKey>: KeyedEncodingContainerProtocol, EncodingStorage {
    
    var encoder: BinaryEncoder
    
    var codingPath: [CodingKey] { [] }
    
    var storage: [EncodingStorage] = []
    
    
    init(encoder: BinaryEncoder) {
        self.encoder = encoder
    }
    
    // MARK: Type encoding
    
    func encodeNil(forKey key: K) throws {
        try encodeNil()
    }
    
    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        let data = try encodeValueAndKey(value, forKey: key)
        storage.append(data)
    }
    
    // MARK: Traversing
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = DictionaryEncodingNode<NestedKey>(encoder: encoder)
        storage.append(container)
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        let container = RepeatedEncodingNode(encoder: encoder)
        storage.append(container)
        return container
    }
    
    func superEncoder() -> Encoder {
        return encoder
    }
    
    func superEncoder(forKey key: K) -> Encoder {
        return encoder
    }
}
