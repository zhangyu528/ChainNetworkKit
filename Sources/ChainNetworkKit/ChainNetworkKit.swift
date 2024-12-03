// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import FoundationNetworking

import Foundation

/// HTTP Methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Network Request Error
enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case decodingFailed
}

/// Network Request Builder with Chainable API
final class NetworkRequestBuilder {
    private var url: URL?
    private var method: HTTPMethod = .get
    private var headers: [String: String] = [:]
    private var body: Data?

    /// Set the URL
    func setURL(_ urlString: String) -> NetworkRequestBuilder {
        self.url = URL(string: urlString)
        return self
    }

    /// Set the HTTP Method
    func setMethod(_ method: HTTPMethod) -> NetworkRequestBuilder {
        self.method = method
        return self
    }

    /// Add a Header
    func addHeader(key: String, value: String) -> NetworkRequestBuilder {
        self.headers[key] = value
        return self
    }

    /// Set the Request Body
    func setBody<T: Encodable>(_ body: T) -> NetworkRequestBuilder {
        self.body = try? JSONEncoder().encode(body)
        return self
    }

    /// Perform the request with completion handler
    func execute<T: Decodable>(decodeTo type: T.Type, completion: @escaping @Sendable (Result<T, NetworkError>) -> Void) {
        guard let url = url else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.decodingFailed))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(.decodingFailed))
            }
        }
        task.resume()
    }
}
