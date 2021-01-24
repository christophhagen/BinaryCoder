//
//  File.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

final class SingleValueEncodingNode: SingleValueEncodingContainer, EncodingStorage {
    
    var encoder: BinaryEncoder
    
    var storage: [EncodingStorage] = []
    
    var codingPath: [CodingKey] { [] }
    
    init(encoder: BinaryEncoder) {
        self.encoder = encoder
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        let data = try encodeOnlyValue(value)
        storage.append(data)
    }
}
