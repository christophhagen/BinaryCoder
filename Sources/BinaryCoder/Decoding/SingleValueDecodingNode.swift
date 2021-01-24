//
//  SingleValueDecodingNode.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation


final class SingleValueDecodingNode: SingleValueDecodingContainer {
    
    var decoder: BinaryDecoder
    
    var codingPath: [CodingKey] { [] }
    
    init(decoder: BinaryDecoder) {
        self.decoder = decoder
    }
    
    func decodeNil() -> Bool {
        false
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try decoder.decode(type)
    }
}
