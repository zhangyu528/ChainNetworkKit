import Testing

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    print("Tests")
}

import XCTest
@testable import ChainNetworkKit

/// Mock Response
struct User: Codable {
    let id: Int?
    let name: String
    let email: String
}

final class NetworkRequestBuilderTests: XCTestCase {

    func testValidGetRequest() {
        let expectation: XCTestExpectation = self.expectation(description: "Valid GET request should succeed")

        NetworkRequestBuilder()
            .setApi("/users/1")
            .setMethod(.get)
            .execute(decodeTo: User.self) { result in
                switch result {
                case .success(let user):
                    XCTAssertEqual(user.name, "Leanne Graham")
                case .failure(let error):
                    XCTFail("Request failed with error: \(error)")
                }
                
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5.0)
    }

    // func testInvalidURL() {
    //     let expectation = self.expectation(description: "Invalid URL should fail")

    //     NetworkRequestBuilder()
    //         .setURL("invalid-url")
    //         .setMethod(.get)
    //         .execute(decodeTo: User.self) { result in
    //             switch result {
    //             case .failure(let error):
    //                 if case .invalidURL = error {
    //                     expectation.fulfill()
    //                 } else {
    //                     XCTFail("Unexpected error: \(error)")
    //                 }
    //             default:
    //                 XCTFail("Request should fail")
    //             }
    //         }

    //     waitForExpectations(timeout: 5.0)
    // }

    // func testDecodingFailure() {
    //     let expectation = self.expectation(description: "Decoding failure should occur")

    //     NetworkRequestBuilder()
    //         .setURL("https://jsonplaceholder.typicode.com/posts/1")
    //         .setMethod(.get)
    //         .execute(decodeTo: User.self) { result in
    //             switch result {
    //             case .failure(let error):
    //                 if case .decodingFailed = error {
    //                     expectation.fulfill()
    //                 } else {
    //                     XCTFail("Unexpected error: \(error)")
    //                 }
    //             default:
    //                 XCTFail("Decoding should fail")
    //             }
    //         }

    //     waitForExpectations(timeout: 5.0)
    // }
}