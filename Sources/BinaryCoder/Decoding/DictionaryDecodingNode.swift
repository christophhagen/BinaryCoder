//
//  DictionaryDecodingNode.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

final class DictionaryDecodingNode<Key : CodingKey>: KeyedDecodingContainerProtocol {

    var decoder: BinaryDecoder
    
    var allKeys: [Key] { [] }
    
    var codingPath: [CodingKey] { [] }
    
    init(decoder: BinaryDecoder) {
        self.decoder = decoder
    }
    
    func contains(_ key: Key) -> Bool {
        (try? decoder.keyIsPresentForOptionalValue(for: key)) ?? false
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        try !decoder.keyIsPresentForOptionalValue(for: key)
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        try decoder.decode(T.self, forKey: key)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        
        // Decode the key for the container
        try decoder.decode(key)
        let container = DictionaryDecodingNode<NestedKey>(decoder: decoder)
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        RepeatedDecodingNode(decoder: decoder)
    }
    
    func superDecoder() throws -> Decoder {
        decoder
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        decoder
    }
}
