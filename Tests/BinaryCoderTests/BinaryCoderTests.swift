import XCTest
import BinaryCoder

final class BinaryCoderTests: XCTestCase {
    
    static var allTests = [
        ("testPrimitiveEncoding", testPrimitiveEncoding),
        ("testPrimitiveDecoding", testPrimitiveDecoding),
        ("testString", testString),
        ("testArray", testArray),
        ("testArrayAndString", testArrayAndString),
        ("testMissingIntegerCodingKeys", testMissingIntegerCodingKeys),
        ("testSwitchedOrder", testSwitchedOrder),
        ("testMultipleEncodings", testMultipleEncodings),
        ("testLargeKeyId", testLargeKeyId),
        ("testNil", testNil),
        ("testData", testData),
        ("testComplex", testComplex),
        ("testAutomaticKeys", testAutomaticKeys),
        ("testEncodeNilWithoutKeys", testEncodeNilWithoutKeys),
    ]
    
    func testPrimitiveEncoding() throws {
        let s = Primitives(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: false, i: true)
        let data = try BinaryEncoder.encode(s)
        XCTAssertEqual(Array(data), [
            0, 1, // Int8 is encoded as a single byte (no varint magic)
            2, 2, // UInt16(2) is encoded as single byte, without sign
            4, 6, // Int32(3) is encoded as 2 * abs(3) + 0
            6, 4, // UInt64(4) is encoded as single byte
            8, 10, // Int(5) is encoded as 2 * abs(5) + 0
            
            10, 0x40, 0xC0, 0x00, 0x00,
            12, 0x40, 0x1C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            
            14, 0x00, // Bool(false) is encoded as single byte
            16, 0x01 // Bool(true) is encoded as single byte
        ])
    }
    
    func testPrimitiveDecoding() throws {
        let data: [UInt8] = [
            0, 1, // Int8 is encoded as a single byte (no varint magic)
            2, 2, // UInt16(2) is encoded as single byte, without sign
            4, 6, // Int32(3) is encoded as 2 * abs(3) + 0
            6, 4, // UInt64(4) is encoded as single byte
            8, 10, // Int(5) is encoded as 2 * abs(5) + 0
            
            10, 0x40, 0xC0, 0x00, 0x00,
            12, 0x40, 0x1C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            
            14, 0x00, // Bool(false) is encoded as single byte
            16, 0x01 // Bool(true) is encoded as single byte
        ]
        let s = try BinaryDecoder.decode(Primitives.self, from: Data(data))
        XCTAssertEqual(s.a, 1)
        XCTAssertEqual(s.b, 2)
        XCTAssertEqual(s.c, 3)
        XCTAssertEqual(s.d, 4)
        XCTAssertEqual(s.e, 5)
        XCTAssertEqual(s.f, 6)
        XCTAssertEqual(s.g, 7)
        XCTAssertEqual(s.h, false)
        XCTAssertEqual(s.i, true)
    }
    
    func testString() {
        struct WithString: Codable {
            var a: String
            var b: String
            var c: Int
            
            enum CodingKeys: Int, CodingKey {
                case a
                case b
                case c
            }
        }
        AssertRoundtrip(WithString(a: "hello", b: "world", c: 42))
    }
    
    func testArray() {
        struct Test: Codable {
            var numbers: [Int32]
            
            enum CodingKeys: Int, CodingKey {
                case numbers
            }
        }
        
        let s = Test(numbers: [1,2,3,4])
        AssertRoundtrip(s)
    }
    
    func testArrayAndString() {
        struct Test: Codable {
            var numbers: [Int32]
            var name: String
            
            enum CodingKeys: Int, CodingKey {
                case numbers
                case name
            }
        }
        
        let s = Test(numbers: [1,2,3,4], name: "Arbitrary")
        AssertRoundtrip(s)
    }
    
    func testMissingIntegerCodingKeys() throws {
        struct Test: Codable {
            var numbers: [Int32]
            var name: String
        }
        let s = Test(numbers: [1,2,3,4], name: "Arbitrary")
        do {
            _ = try BinaryEncoder.encode(s, keyEncoding: .failForMissingIntegerKeys)
            XCTFail("Should not encode without integer coding keys")
        } catch BinaryEncodingError.codingKeyRequiresIntegerValue(let key) {
            XCTAssertEqual(key.stringValue, "numbers")
        } catch {
            XCTFail("Encoder failed with unexpected error \(error)")
        }
        
        let d = Data(repeating: 0, count: 10)
        do {
            _ = try BinaryDecoder.decode(Test.self, from: d, keyEncoding: .failForMissingIntegerKeys)
            XCTFail("Should not decode without integer coding keys")
        } catch BinaryDecodingError.codingKeyRequiresIntegerValue(let key) {
            XCTAssertEqual(key.stringValue, "numbers")
        } catch {
            XCTFail("Decoder failed with unexpected error \(error)")
        }
    }
    
    func testSwitchedOrder() {
        struct Test1: Codable {
            var numbers: [Int32]
            var name: String
            
            enum CodingKeys: Int, CodingKey {
                case numbers = 1
                case name = 2
            }
        }
        
        struct Test2: Codable {
            var name: String
            
            var numbers: [Int32]
            
            enum CodingKeys: Int, CodingKey {
                case name = 2
                case numbers = 1
            }
        }
        
        let s = Test1(numbers: [1,2,3,4], name: "Arbitrary")
        do {
            let data = try BinaryEncoder.encode(s)
            let _ = try BinaryDecoder.decode(Test2.self, from: data)
            XCTFail("Should not decode with switched order")
        } catch BinaryDecodingError.keyMismatch(let key) {
            XCTAssertNotNil(key as? Test2.CodingKeys)
            XCTAssertTrue(key.stringValue == Test2.CodingKeys.name.stringValue)
        } catch {
            XCTFail("De/Encoder failed with unexpected error \(error)")
        }
    }
    
    func testMultipleEncodings() {
        struct Test: Codable, Equatable {
            var numbers: [Int32]
            var name: String
            
            enum CodingKeys: Int, CodingKey {
                case numbers = 1
                case name = 2
            }
        }
        
        let s1 = Test(numbers: [1,2,3], name: "Adam")
        let s2 = Test(numbers: [3,4,5], name: "Eve")
        do {
            let encoder = BinaryEncoder()
            try s1.encode(to: encoder)
            try s2.encode(to: encoder)
            let data = encoder.encodedData
            
            let decoder = BinaryDecoder(data: data)
            let decoded1 = try Test(from: decoder)
            let decoded2: Test = try decoder.decode()
            XCTAssertEqual(decoded1, s1)
            XCTAssertEqual(decoded2, s2)
        } catch {
            XCTFail("Failed to encode multiple values: \(error)")
        }
    }
    
    func testLargeKeyId() {
        struct Test: Codable {
            var numbers: [Int32]
            var name: String
            
            enum CodingKeys: Int, CodingKey {
                case numbers = 128
                case name = 92837382
            }
        }
        
        let s = Test(numbers: [1,2,3,4], name: "Arbitrary")
        AssertRoundtrip(s)
    }
    
    func testNil() {
        
        struct Test: Codable {
            
            var numbers: Data?
            
            enum CodingKeys: Int, CodingKey {
                case numbers
            }
        }
        let s = Test(numbers: Data(repeating: 42, count: 12))
        AssertRoundtrip(s)
        let s2 = Test(numbers: nil)
        AssertRoundtrip(s2)
        
        struct Test2: Codable {
            
            var a: Int?
            
            var b: String?
            
            enum CodingKeys: Int, CodingKey {
                case a
                case b
            }
        }
        
        let s3 = Test2(a: nil, b: "Some")
        AssertRoundtrip(s3)
        let s4 = Test2(a: 123, b: nil)
        AssertRoundtrip(s4)
    }
    
    func testData() {
        
        struct Test: Codable {
            
            var numbers: Data
            
            enum CodingKeys: Int, CodingKey {
                case numbers
            }
        }
        let s = Test(numbers: Data(repeating: 42, count: 12))
        AssertRoundtrip(s)
    }
    
    func testComplex() {
        struct Company: Codable {
            var name: String
            var employees: [Employee]
            
            enum CodingKeys: Int, CodingKey {
                case name
                case employees
            }
        }
        
        struct Employee: Codable {
            var name: String
            var jobTitle: String
            var age: Int
            
            enum CodingKeys: Int, CodingKey {
                case name
                case jobTitle
                case age
            }
        }
        
        let company = Company(name: "Joe's Discount Airbags", employees: [
            Employee(name: "Joe Johnson", jobTitle: "CEO", age: 27),
            Employee(name: "Stan Lee", jobTitle: "Janitor", age: 87),
            Employee(name: "Dracula", jobTitle: "Dracula", age: 41),
            Employee(name: "Steve Jobs", jobTitle: "Visionary", age: 56),
        ])
        AssertRoundtrip(company)
    }
 
    func testAutomaticKeys() {
        struct Test: Codable {
            let a: Int
            let b: UInt16
            let c: String
            let d: [Int32]
            let e: Inner
            
            struct Inner: Codable {
                let g: UInt64
                let f: Int?
                let h: Int32
            }
        }
        
        let s = Test(a: -123, b: 1234, c: "Coder", d: [-1920393,1928,11199228], e: Test.Inner(g: UInt64.max, f: 9, h: -120200))
        do {
            let data = try BinaryEncoder.encode(s)
            let r = try BinaryDecoder.decode(Test.self, from: data)
            XCTAssertEqual(s.a, r.a)
            XCTAssertEqual(s.b, r.b)
            XCTAssertEqual(s.c, r.c)
            XCTAssertEqual(s.d, r.d)
            XCTAssertEqual(s.e.f, r.e.f)
            XCTAssertEqual(s.e.g, r.e.g)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testEncodeNilWithoutKeys() {
        struct MyCodable: Codable {
            var some: Int?
            var more: UInt16?
            var other: String?
            var thing: More?
            
            struct More: Codable {
                var a: Int?
            }
        }
        do {
            let s = MyCodable(some: nil, more: 123, other: nil, thing: .init(a: nil))
            let data = try BinaryEncoder.encode(s, keyEncoding: .excludeKeys)
            let decoded = try BinaryDecoder.decode(MyCodable.self, from: data, keyEncoding: .excludeKeys)
            // The second value is treated as the first during decoding,
            // resulting in invalid decoding
            XCTAssertNotEqual(s.some, decoded.some)
            
            // Trailing nil values are correctly decoded
            let s2 = MyCodable(some: 283, more: 123, other: nil, thing: .init(a: nil))
            let data2 = try BinaryEncoder.encode(s2, keyEncoding: .excludeKeys)
            print(Array(data2))
            let decoded2 = try BinaryDecoder.decode(MyCodable.self, from: data2, keyEncoding: .excludeKeys)
            XCTAssertEqual(s2.some, decoded2.some)
            XCTAssertEqual(s2.more, decoded2.more)
            XCTAssertEqual(s2.other, decoded2.other)
            XCTAssertNil(decoded2.thing)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testDict() {
        struct MyCodable: Codable {
            var dict: [Int : String]
            enum CodingKeys: Int, CodingKey {
                case dict
            }
        }
        let s = MyCodable(dict: [123 : "Some", -1920293 : "More"])
        do {
            let data = try BinaryEncoder.encode(s)
            let decoded = try BinaryDecoder.decode(MyCodable.self, from: data)
            // Dictionaries can't be encoded
            XCTAssertEqual(decoded.dict, [:])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

private func AssertEqual<T>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(String(describing: lhs), String(describing: rhs), file: file, line: line)
}

private func AssertRoundtrip<T: Codable>(_ original: T, file: StaticString = #file, line: UInt = #line) {
    do {
        let data = try BinaryEncoder.encode(original)
        let roundtripped = try BinaryDecoder.decode(T.self, from: data)
        AssertEqual(original, roundtripped, file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}

struct Primitives: Codable {
    var a: Int8
    var b: UInt16
    var c: Int32
    var d: UInt64
    var e: Int
    var f: Float
    var g: Double
    var h: Bool
    var i: Bool
    
    enum CodingKeys: Int, CodingKey {
        case a
        case b
        case c
        case d
        case e
        case f
        case g
        case h
        case i
    }
}
