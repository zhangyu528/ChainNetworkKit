import Foundation

/// 参数编码策略
enum ParameterEncoding {
    case queryString // 查询 URL 编码
    case formURLEncoded // x-www-form-urlencoded 编码
    case json
    /// 对参数进行编码
    func encode(parameters: [String: Any]) -> Data? {
        switch self {
        case .queryString:
            // 对于查询字符串编码，只需拼接键值对
            let queryString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            return queryString.data(using: .utf8)
        case .formURLEncoded:
            // 对于 x-www-form-urlencoded，确保字符被 URL 编码
            let formString = parameters.map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(encodedKey)=\(encodedValue)"
            }.joined(separator: "&")
            return formString.data(using: .utf8)
        case .json:
            return try? JSONSerialization.data(withJSONObject: parameters)
        }
    }
    /// 返回适合的 Content-Type
    func contentType() -> String {
        switch self {
        case .queryString:
            return "application/x-www-form-urlencoded"
        case .formURLEncoded:
            return "application/x-www-form-urlencoded"
        case .json:
            return "application/json"
        }
    }
}