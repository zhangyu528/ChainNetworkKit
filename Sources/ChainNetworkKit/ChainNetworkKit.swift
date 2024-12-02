// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import FoundationNetworking

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct NetworkResponse {
    public let data: Data?
    public let statusCode: Int
    public let headers: [AnyHashable: Any]

    public func decode<T: Decodable>(to type: T.Type) throws -> T {
        guard let data = data else {
            throw NSError(domain: "ChainNetworkKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data available"])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}


public class NetworkRequestBuilder {
    private var url: URL?
    private var method: HTTPMethod = .get
    private var headers: [String: String] = [:]
    private var parameters: [String: Any] = [:]
    private var jsonRequest: Bool = true

    public init() {}

    // 设置请求 URL
    @discardableResult
    public func setURL(_ url: String) -> Self {
        self.url = URL(string: url)
        return self
    }

    // 设置 HTTP 方法
    @discardableResult
    public func setMethod(_ method: HTTPMethod) -> Self {
        self.method = method
        return self
    }

    // 添加请求头
    @discardableResult
    public func addHeader(key: String, value: String) -> Self {
        self.headers[key] = value
        return self
    }

    // 设置多个请求头
    @discardableResult
    public func setHeaders(_ headers: [String: String]) -> Self {
        self.headers.merge(headers) { _, new in new }
        return self
    }

    // 设置请求参数
    @discardableResult
    public func setParameters(_ parameters: [String: Any]) -> Self {
        self.parameters = parameters
        return self
    }

    // 设置是否为 JSON 请求
    @discardableResult
    public func setJSONRequest(_ jsonRequest: Bool) -> Self {
        self.jsonRequest = jsonRequest
        return self
    }

    // 发送请求
    public func send(completion: @escaping @Sendable (Result<NetworkResponse, Error>) -> Void) {
        guard let url = url else {
            completion(.failure(NSError(domain: "ChainNetworkKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL is missing"])))
            return
        }

        let request = createRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "ChainNetworkKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }

            let networkResponse = NetworkResponse(
                data: data,
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields
            )
            completion(.success(networkResponse))
        }
        task.resume()
    }

    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // 设置请求头
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        // 设置请求参数
        if let parameters = try? serializeParameters() {
            if jsonRequest {
                request.httpBody = parameters
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } else if method != .get {
                request.httpBody = parameters
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
        }
        return request
    }

    private func serializeParameters() throws -> Data? {
        if jsonRequest {
            return try JSONSerialization.data(withJSONObject: parameters, options: [])
        } else {
            let query = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            return query.data(using: .utf8)
        }
    }
}