import XCTest
@testable import ChainNetworkKit

final class ParameterEncodingTests: XCTestCase {

    func testQueryStringEncoding() {
        let parameters: [String: Any] = [
            "key1": "value1",
            "key2": 123,
            "key3": "value with spaces",
            "key4": "value&with=special?characters"
        ]
        let encoding = ParameterEncoding.queryString
        let encodedData = encoding.encode(parameters: parameters)
        let result = String(data: encodedData, encoding: .utf8)

        let expected = "key1=value1&key2=123&key3=value%20with%20spaces&key4=value%26with%3Dspecial%3Fcharacters"
        XCTAssertEqual(result, expected, "Query string encoding failed.")
        XCTAssertEqual(encoding.contentType(), "application/x-www-form-urlencoded")
    }

    func testFormURLEncodedEncoding() {
        let parameters: [String: Any] = [
            "key1": "value1",
            "key2": 123,
            "key3": "value with spaces",
            "key4": "value&with=special?characters"
        ]
        let encoding = ParameterEncoding.formURLEncoded
        let encodedData = encoding.encode(parameters: parameters)
        let result = String(data: encodedData, encoding: .utf8)

        let expected = "key1=value1&key2=123&key3=value+with+spaces&key4=value%26with%3Dspecial%3Fcharacters"

        XCTAssertEqual(result, expected, "Form URL encoding failed.")
        XCTAssertEqual(encoding.contentType(), "application/x-www-form-urlencoded")
    }

    func testJSONEncoding() {
        let parameters: [String: Any] = [
            "key1": "value1",
            "key2": 123,
            "key3": "value with spaces",
            "key4": "value&with=special?characters"
        ]
        let encoding = ParameterEncoding.json
        let encodedData = encoding.encode(parameters: parameters)
        // 将编码后的数据转换为字典
        guard let result = try? JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any] else {
            XCTFail("Failed to decode JSON data.")
            return
        }
        // 预期的字典
        let expected: [String: Any] = [
            "key1": "value1",
            "key2": 123,
            "key3": "value with spaces",
            "key4": "value&with=special?characters"
        ]
        XCTAssertNotNil(encodedData, "JSON encoding returned nil.")
        // 手动对比字典
        for (key, value) in expected {
            if let decodedValue = result[key] {
                XCTAssertEqual("\(decodedValue)", "\(value)", "Value for key \(key) does not match.")
            } else {
                XCTFail("Key \(key) not found in the decoded result.")
            }
        }        
    XCTAssertEqual(encoding.contentType(), "application/json")
    }

    func testEmptyParameters() {
        let parameters: [String: Any] = [:]

        let encodings: [ParameterEncoding] = [.queryString, .formURLEncoded, .json]
        for encoding in encodings {
            let encodedData = encoding.encode(parameters: parameters)
            XCTAssertNotNil(encodedData, "\(encoding) encoding failed for empty parameters.")
            if encoding == .json {
                XCTAssertEqual(String(data: encodedData, encoding: .utf8), "{}", "JSON encoding should result in '{}' for empty parameters.")
            } else {
                XCTAssertTrue(encodedData.isEmpty, "\(encoding) should result in an empty payload for empty parameters.")
            }
        }
    }

    func testInvalidJSONParameters() {
        let invalidParameters: [String: Any] = [
            "key1": "value1",
            "key2": Data() // `Data` is not valid JSON
        ]
        let encoding = ParameterEncoding.json
        let encodedData = encoding.encode(parameters: invalidParameters)
        XCTAssertNil(encodedData, "JSON encoding should fail for invalid parameters.")
    }
}
