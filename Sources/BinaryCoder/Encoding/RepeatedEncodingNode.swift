//
//  RepeatedEncodingNode.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

final class RepeatedEncodingNode: UnkeyedEncodingContainer, SingleValueEncodingContainer, EncodingStorage {
    
    var encoder: BinaryEncoder
    
    var codingPath: [CodingKey] { [] }
    
    var count: Int { storage.count }
    
    var storage: [EncodingStorage] = []
    
    var data: Data {
        let data = storage.reduce(Data()) { $0 + $1.data }
        // Prepend byte count to enable proper decoding
        return UInt64(data.count).variableLengthEncoding + data
    }
    
    init(encoder: BinaryEncoder) {
        self.encoder = encoder
    }
    
    // MARK: Type encoding
    
    func encode<T>(_ value: T) throws where T : Encodable {
        let data = try encodeOnlyValue(value)
        storage.append(data)
    }
    
    // MARK: Traversing the tree
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = DictionaryEncodingNode<NestedKey>(encoder: encoder)
        storage.append(container)
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let container = RepeatedEncodingNode(encoder: encoder)
        storage.append(container)
        return container
    }
    
    func superEncoder() -> Encoder {
        return encoder
    }
}
