//
//  File.swift
//  
//
//  Created by CH on 23.01.21.
//

import Foundation

extension CodingKey {
    
    /**
     Get the data representation for a key.
     - Parameter keyEncoding: The key encoding strategy
     - Returns: The data of the encoded key, or nil, if the `excludeKeys` key encoding strategy is used.
     - Throws: `BinaryEncodingError.stringNotRepresentableInUTF8` if the string value can't be converted to UTF8. `BinaryEncodingError.codingKeyRequiresIntegerValue` if the `failForMissingIntegerKeys` encoding stategy is used without the key providing an integer representation.
     */
    func encode(using keyEncoding: KeyEncodingStrategy) throws -> Data? {
        switch keyEncoding {
        case .excludeKeys:
            return nil
        case .failForMissingIntegerKeys:
            guard let int = intValue else {
                throw BinaryEncodingError.codingKeyRequiresIntegerValue(self)
            }
            return int.variableLengthEncoding
        case .alwaysEncodeKeysAsStrings:
            return try encodeAsString()
        case .preferIntegerOverStringKeys:
            return try intValue?.variableLengthEncoding ?? encodeAsString()
        }
    }
    
    /**
     Attempt to encode the key as a string.
     - Throws: `BinaryEncodingError.stringNotRepresentableInUTF8` if the string value can't be converted to UTF8.
     - Note: The length of the string is prepended to the data encoded as a variable-length unsigned integer.
     - Returns: The string encoded as binary data.
     */
    private func encodeAsString() throws -> Data {
        do {
            return try stringValue.encoded()
        } catch {
            throw BinaryEncodingError.codingKeyNotRepresentableInUTF8(self)
        }
    }
}
