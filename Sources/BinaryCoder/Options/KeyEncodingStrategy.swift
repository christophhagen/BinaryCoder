//
//  KeyEncodingStrategy.swift
//  BinaryCoder
//
//  Created by CH on 22.01.21.
//

import Foundation

/**
 Specifies how keys should be encoded in the binary data.
 */
public enum KeyEncodingStrategy {
    
    /**
     Don't encode any keys.
     
     This option excludes any identifiers from the binary data which could be used to associate values with keys.
     This decreases the message size, but has two main disadvantages:
     
     - Warning: Any optionals present in the type will be encoded using default values. Optionals can't be encoded, because optionals are marked by excluding keys, which are omitted by default using this option.
     - Note: Reordering of properties results in decoding errors. Since no keys are present in the data, the same order of the properties in the data is assumed as for the source.
     */
    case excludeKeys
    
    /**
     When no integer value is specified for the key, then encode keys as strings.
     
     This is the default mode. 
     
     - Note: Reordering of properties results in decoding errors. Since the keys are derived from the order in the source code, the same order of the properties in the data is assumed as for the source.
     */
    case preferIntegerOverStringKeys
    
    /**
     Always encode the keys as their string values.
     
     - Note: Reordering of properties results in decoding errors. Since the keys are derived from the order in the source code, the same order of the properties in the data is assumed as for the source.
     */
    case alwaysEncodeKeysAsStrings
    
    /**
     Fail with an error if coding keys have no raw integer value.
     
     Each `Codable` type is expected to contain an enum with raw type `Int` conforming to `CodingKey`. All properties will thus have distinct integer keys, which are encoded using variable-length encoding.
     
     Optional values are encoded through the absence of the key. This means that optional properties will be decoded correctly.
     - Note: Properties consisting of sequences of optionals will be decoded to only contain non-optional values. A property of type ` [Int?] = [1, nil, 2, 3, nil]` will be decoded as ` [Int?] = [1,2,3]`
     
     This prevents incompatible types from decoding.
     */
    case failForMissingIntegerKeys
    
    /// Compute the hash for each key and encode it as an integer
    //case hashStringValues
}
