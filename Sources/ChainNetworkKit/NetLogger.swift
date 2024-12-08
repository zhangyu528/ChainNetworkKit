import Foundation
#if os(Linux) 
import FoundationNetworking 
#endif

/// A centralized logger for network requests and responses
final class NetLogger {
    /// Shared singleton instance
    nonisolated(unsafe) static let shared = NetLogger()

    /// Flag to control logging
    var isLoggingEnabled: Bool = false

    private init() {}

    /// Logs HTTP request details
    func logRequest(_ request: URLRequest) {
        guard isLoggingEnabled else { return }
        print("\n===== HTTP Request =====")
        print("URL: \(request.url?.absoluteString ?? "N/A")")
        print("Method: \(request.httpMethod ?? "N/A")")
        if let headers = request.allHTTPHeaderFields {
            print("Headers: \(headers)")
        }
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        } else {
            print("Body: Empty")
        }
        print("========================\n")
    }

    /// Logs HTTP response details
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        guard isLoggingEnabled else { return }
        print("\n===== HTTP Response =====")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        } else {
            print("Response: \(response.debugDescription)")
        }
        if let data = data,
           let responseString = String(data: data, encoding: .utf8) {
            print("Data: \(responseString)")
        } else {
            print("Data: Empty")
        }
        if let error = error {
            print("Error: \(error.localizedDescription)")
        }
        print("========================\n")
    }
}
