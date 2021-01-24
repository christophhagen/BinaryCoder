//
//  RepeatedDecodingNode.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

final class RepeatedDecodingNode: UnkeyedDecodingContainer {
    
    var decoder: BinaryDecoder
    
    var codingPath: [CodingKey] { [] }
    
    var count: Int? = nil
    
    var isAtEnd: Bool {
        // When no length is set, then we haven't even started
        bytesConsumed == length ?? -1
    }
    
    var currentIndex: Int = 0
    
    /// The number of bytes already read
    private var bytesConsumed: Int = 0
    
    /// The length of the binary data belonging to the container
    private var length: Int?
    
    init(decoder: BinaryDecoder) {
        self.decoder = decoder
    }
    
    func decodeNil() throws -> Bool {
        false
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if length == nil {
            // Decode the length of the container first
            let size = try decoder.decode(UInt64.self)
            length = Int(size)
        }
        guard !isAtEnd else {
            throw BinaryDecodingError.unexpectedEndOfData
        }
        let cursorBefore = decoder.cursor
        let result = try decoder.decode(type)
        bytesConsumed += decoder.cursor - cursorBefore
        currentIndex += 1
        return result
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        KeyedDecodingContainer(DictionaryDecodingNode<NestedKey>(decoder: decoder))
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        RepeatedDecodingNode(decoder: decoder)
    }
    
    func superDecoder() throws -> Decoder {
        decoder
    }
    
    
}
