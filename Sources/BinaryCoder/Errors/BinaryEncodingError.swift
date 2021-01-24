//
//  BinaryEncodingError.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

/**
 All errors which can be thrown by a `BinaryEncoder`.
 */
public enum BinaryEncodingError: Error {
    
    /// A String value can't be represented using UTF8 encoding
    case stringNotRepresentableInUTF8(String)
    
    /**
     The coding key doesn't provide an integer value.
     
      Declare all coding keys with a raw value of type `Int` to prevent this error.
     - Note: This error is only thrown when using the `failForMissingIntegerKeys` key encoding strategy.
     */
    case codingKeyRequiresIntegerValue(CodingKey)
    
    /// The coding key string value can't be represented using UTF8 encoding.
    case codingKeyNotRepresentableInUTF8(CodingKey)
    
    /// An optional value was present in the value to encode while the `excludeKeys` key encoding strategy was specified.
    case foundOptionalValueWhileExcludingKeys
}
