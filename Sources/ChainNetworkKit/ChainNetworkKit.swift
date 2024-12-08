// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

#if os(Linux) 
import FoundationNetworking 
#endif

#if canImport(Security)
import Security
#endif

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
    case serverTrustFailed
}


/// Network Request Builder with Chainable API

final class NetworkRequestBuilder: @unchecked Sendable {
    
    private var host = NetConfig.shared.host
    private var api: URL?
    private var method: HTTPMethod = .post
    private var headers: [String: String] = NetConfig.shared.defaultHeaders
    private var body: Data?
    private var parameters: [String: Any] = [:]
    private var timeoutInterval = NetConfig.shared.timeoutInterval
    private var encoding: ParameterEncoding = .json

    /// Set the URL
    func setApi(_ pathString: String) -> NetworkRequestBuilder {
        self.api = URL(string: host + pathString)
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

    /// 设置参数编码方式
    func setParameterEncoding(_ encoding: ParameterEncoding) -> NetworkRequestBuilder {
        self.encoding = encoding
        return self
    }


    /// Perform the request with completion handler
    func execute<T: Decodable>(decodeTo type: T.Type, 
                               completion: @escaping @Sendable (Result<T, NetworkError>) -> Void) {
        guard let request = self.buildRequest() else {
            completion(.failure(.invalidURL))
            return
        }

        // Log the request
        NetLogger.shared.logRequest(request)

        let session = URLSession(configuration: .default,
                                 delegate: NetworkRequestServerTrust(), 
                                 delegateQueue: nil) 
        let task = session.dataTask(with: request) { [weak self] data, response, error  in 
            // Log the response
            NetLogger.shared.logResponse(response, data: data, error: error)
            
            self?.handleResponse(data: data, 
                                response: response, 
                                error: error, 
                                decodeTo: type, 
                                completion: completion) 
        }
        task.resume()
    }

    /// BUild the URLRequest
    private func buildRequest() -> URLRequest? {
        guard var urlComponents = URLComponents(string: self.host + (self.api?.absoluteString ?? "" )) else {
            return nil
        }

        if self.method == .get, self.encoding == .queryString {
            let queryData = self.encoding.encode(parameters: self.parameters)
            urlComponents.query = String(data: queryData, encoding: .utf8)
        } else if self.encoding == .formURLEncoded {
            self.body = self.encoding.encode(parameters: self.parameters)
        } else if self.method == .post || self.method == .put {
            self.body = try? JSONSerialization.data(withJSONObject: self.parameters)
        }

        guard let finalURL = urlComponents.url else {
             return nil
        }

        var request = URLRequest(url: finalURL) 
        request.httpMethod = method.rawValue 
        request.allHTTPHeaderFields = headers 
        request.httpBody = body 
        request.timeoutInterval = timeoutInterval 
        request.setValue(self.encoding.contentType(), forHTTPHeaderField: "Content-Type")

        if let bearerToken = NetConfig.shared.bearerTokenProvider?() { 
            request.addValue(bearerToken, forHTTPHeaderField: "Authorization") 
        } 
        return request   
    }
    /// Handle the response
    private func handleResponse<T: Decodable>(data: Data?, 
                                              response: URLResponse?, 
                                              error: Error?, 
                                              decodeTo type: T.Type, 
                                              completion: @escaping @Sendable (Result<T, NetworkError>) -> Void) {

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
}
