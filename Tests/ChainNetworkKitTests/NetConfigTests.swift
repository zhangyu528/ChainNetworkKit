import XCTest
@testable import ChainNetworkKit

final class NetConfigTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // 在每个测试之前调用
        NetConfig.shared.environmentURLs = [
            .development: "https://dev.example.com",
            .testing: "https://test.example.com",
            .production: "https://prod.example.com"
        ]
    }

    override func tearDown() {
        // 在每个测试之后调用
        super.tearDown()
    }

    func testBaseURL() {
        NetConfig.shared.env = .development
        XCTAssertEqual(NetConfig.shared.baseURL, "https://dev.example.com")

        NetConfig.shared.env = .testing
        XCTAssertEqual(NetConfig.shared.baseURL, "https://test.example.com")

        NetConfig.shared.env = .production
        XCTAssertEqual(NetConfig.shared.baseURL, "https://prod.example.com")
    }

    func testDefaultHeaders() {
        NetConfig.shared.env = .development
        XCTAssertEqual(NetConfig.shared.defaultHeaders, ["Content-Type": "application/json"])

        NetConfig.shared.env = .testing
        XCTAssertEqual(NetConfig.shared.defaultHeaders, ["Content-Type": "application/json"])

        NetConfig.shared.env = .production
        XCTAssertEqual(NetConfig.shared.defaultHeaders, ["Content-Type": "application/json", "Authorization": "Bearer <token>"])
    }

    func testTimeoutInterval() {
        NetConfig.shared.env = .development
        XCTAssertEqual(NetConfig.shared.timeoutInterval, 60.0)

        NetConfig.shared.env = .testing
        XCTAssertEqual(NetConfig.shared.timeoutInterval, 60.0)

        NetConfig.shared.env = .production
        XCTAssertEqual(NetConfig.shared.timeoutInterval, 30.0)
    }

    // func testBearerTokenProvider() {
    //     let tokenProvider: () -> String? = { return "testToken" }
    //     NetConfig.shared.setBearerTokenProvider(tokenProvider)
    //     XCTAssertEqual(NetConfig.shared.bearerTokenProvider?(), "testToken")
    // }

    // func testLoadCertificates() {
    //     let paths = ["path/to/cert1", "path/to/cert2"]
    //     NetConfig.shared.loadCertificates(from: paths)
    //     XCTAssertEqual(NetConfig.shared.certificates.count, 2)
    // }
}
