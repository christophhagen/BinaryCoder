# BinaryCoder

An encoder to convert Swift `Codable` types to a binary representation, using variable-length encoding for efficient packing.

## Motivation

Swift provides very convenient encoding and decoding for all types which conform to the `Codable` protocol. However, by default only two actual encoders are provided by default: `JSONEncoder` and `PropertyListEncoder`. Both aren't particularly space-efficient or suitable for binary data.

The goal of this library is to provide convenient and efficient encoding into a binary format for data storage or transmission.

#### Limitations

There are some notable limitations to the current encoding concept:
- [Dictionaries](#dictionaries) can't be decoded.
- For [Arrays of Optionals](#optionals), only non-nil values are decoded
- No support for advanced features of `Codable` types (coding path, defaults, etc.)

#### Road map

In future versions, the option to include a `length` field for each basic element will be added, which increases the file size, but also allows the decoding of dictionaries, out-of-order fields, and merging of multiple messages.

Another option to add will be the automatic hashing of string keys to smaller integers, in order to decrease the message size when no explicit integer keys are provided.

## Usage

The usage of encoders and decoders in Swift is very easy: Simply conform your types to the `Codable` protocol (or `Encodable` and `Decodable` individually), and use any `Encoder` oder `Decoder` type.



#### Codable

````swift
struct MyCodable: Codable {
    var name: String
    var numbers: [Int]
}
````

#### Encoding

To convert a value to data, simply call the convenience method on `BinaryEncoder`
````swift
let value = MyCodable(
    name: "Eve",
    numbers: [4,8,15,16,23,42]

let data = try BinaryEncoder.encode(value)
````

It's also possible to encode multiple values one after another:
````swift
let encoder = BinaryEncoder()
try value1.encode(to: encoder)
// Equivalent way of encoding
try encoder.encode(value2)
let data = encoder.encodedData
````

#### Decoding

Decoding can also be done using a convenience method, this time on `BinaryDecoder`
````swift
let value = try BinaryDecoder.decode(MyCodable.self, from: data)
````

To decode multiple values:
````swift
let decoder = BinaryDecoder()
let value1 = try decoder.decode(MyCodable.self)
// Equivalent way of decoding
let value2: MyCodable = try decoder.decode()
````

#### Integer keys

By default, each property of a `Codable` type is identified in the binary data by its string value.

For more efficient packing, `Codable` types should provide integer representations for each `CodingKey`, which can be achieved by providing an `enum` on the type with the raw type `Int` and conforming to `CodingKey`:

````swift
extension MyCodable {
    enum CodingsKeys: Int, CodingKey {
        case name // Implicit key ids starting at 0
        case numbers = 2 // Explicit key id
    }
}
````

#### Dictionaries

With the current approach, it's not possible to decode dictionaries. Apple's implementation expects the decoder to provide all dictionary keys when the dictionary is first decoded, but the binary decoder can't provide that information at this time in the decoding process. Since keys and values can vary in length, there's no way to decode all keys before the corresponding values are decoded, since the decoder can't know their starting positions in the code.

````swift
struct MyCodable: Codable {
    var dict: [Int : String]
}
let s = MyCodable(dict: [123 : "Some"])
let data = try BinaryEncoder.encode(s)
let decoded = try BinaryDecoder.decode(MyCodable.self, from: data)
print(decoded.dict) // Prints []
````

Future versions of this encoder may include a `length` field for all basic information, which increases storage size, but allows all keys to be decoded beforehand.

#### Optionals

Optional properties work fine with the default setting, which means optional properties are decoded correctly. One notable exception are arrays of optionals, where only non-nil values are decoded.
````swift
struct MyCodable: Codable {
    var numbers: [Int?]
}
let s = MyCodable(numbers: [1, nil, 2, nil])
let data = try BinaryEncoder.encode(s)
let decoded = try BinaryDecoder.decode(MyCodable.self, from: data)
print(decoded.numbers) // Prints [1,2]
````

#### Key encoding options

**preferIntegerOverStringKeys**
The default key encoding strategy is to use integer keys if they are available, and default to the string keys if necessary.

**failForMissingIntegerKeys**
It's also possible to force errors if no integer keys are available.

**alwaysEncodeKeysAsStrings**
Always encodes keys as strings, even in the presence of integer values.

**excludeKeys**
For even more efficient packing, keys can be omitted completely from the packet. This can result in slightly smaller packets due to the missing key bytes, but the big caveat is the fact that **optional values can't be decoded when using the `excludeKeys` option**. As a consequence, all optional properties must be set when encoding. Otherwise decoding will fail with various errors.

If you want to omit keys, specify the corresponding option:
````swift
let encoder = BinaryEncoder(keyEncoding: .excludeKeys)
// or
let data = try BinaryEncoder.encode(value, keyEncoding: .excludeKeys)
````

#### Memory Alignment

When transmitting binary data between machines, the problem of different interpretations of the binary data often occurs due to different memory alignment of the operating systems. `BinaryCoder` uses a platform-independent byte representation provided by apple for floating-point values, and the variable-length integer encoding is also endian-agnostic. All in all, `BinaryCoder` data from different platforms should be compatible with each other.

## Other binary coders

This library was written after stumbling upon [BinaryCoder](https://github.com/mikeash/BinaryCoder) by [Mike Ash](https://github.com/mikeash). It doesn't use keys and also has trouble with optional values. Also doesn't use variable-length integer encoding.

There's also [sticky-encoding](https://github.com/stickytools/sticky-encoding), which uses are more complex layout, and provides additional features, including out-of-order decoding, and many of the advanced `Codable` features. Unfortunately, development seems to be stale (Version 1.0.0 hasn't arrived yet, although it was announced as "coming soon" in March 2019). Ultimately, I wanted something a bit more space-efficient, and I didn't need the advanced features.

## License

THE BEER-WARE LICENSE (Revision 42):

CH (info@christophhagen.de) wrote this file. As long as you retain this notice you can do whatever you want with this stuff. If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.

CH
