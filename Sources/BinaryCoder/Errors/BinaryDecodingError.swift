//
//  BinaryDecodingError.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

/// All errors which `BinaryDecoder` itself can throw.
public enum BinaryDecodingError: Error {
    
    /// The decoder hit the end of the data while the values it was decoding expected more.
    case unexpectedEndOfData
    
    /// The variable length encoded value has an invalid format
    case invalidVariableLengthEncoding
    
    /// Attempted to decode a value which can't be represented in the integer type
    case variableLengthEncodedValueOutOfRange
    
    /// Attempted to decode a `String` but the encoded `String` data was not valid
    /// UTF-8.
    case invalidUTF8([UInt8])
    
    case codingKeyRequiresIntegerValue(CodingKey)
    
    /// The decoder found an unexpected key value while decoding the key
    case keyMismatch(CodingKey)
    
    /// The coding key string value can't be represented using UTF8 encoding.
    case codingKeyNotRepresentableInUTF8(CodingKey)
}
