// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import FoundationNetworking


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
    case timeout
}
/// Network Configuration 
final class NetConfig: @unchecked Sendable { 
    static let shared = NetConfig() 
    var baseURL: String = "" 
    var defaultHeaders: [String: String] = [:] 
    var timeoutInterval: TimeInterval = 60

    private init() {}
}
/// Network Request Builder with Chainable API
final class NetworkRequestBuilder {
    
    private var baseUrl = NetConfig.shared.baseURL
    private var url: URL?
    private var method: HTTPMethod = .get
    private var headers: [String: String] = NetConfig.shared.defaultHeaders
    private var body: Data?
    private var parameters: [String: Any] = [:]
    private var timeoutInterval = NetConfig.shared.timeoutInterval

    /// Set the URL
    func setURL(_ urlString: String) -> NetworkRequestBuilder {
        self.url = URL(string: baseUrl + urlString)
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

    /// Set the Request Parameters 
    func setParameters(_ parameters: [String: Any]) -> NetworkRequestBuilder { 
        self.parameters = parameters 
        return self 
    }

    /// Perform the request with completion handler
    func execute<T: Decodable>(decodeTo type: T.Type, completion: @escaping @Sendable (Result<T, NetworkError>) -> Void) {
        guard var urlComponents = URLComponents(string: url?.absoluteString ?? "" ) else {
            completion(.failure(.invalidURL))
            return
        }
        //参数编码
        if self.method == .get, !self.parameters.isEmpty { 
            urlComponents.queryItems = self.parameters.map { 
                URLQueryItem(name: $0.key, value: "\($0.value)") 
            } 
        } else if self.method == .post || self.method == .put {
            self.body = try? JSONSerialization.data(withJSONObject: self.parameters)
        }

        guard let finalURL = urlComponents.url else {
             completion(.failure(.invalidURL)) 
             return 
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = self.method.rawValue
        request.allHTTPHeaderFields = self.headers
        request.httpBody = self.body
        request.timeoutInterval = self.timeoutInterval

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            } else if let error = error as NSError?, error.code == NSURLErrorTimedOut {
                completion(.failure(.timeout))
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
