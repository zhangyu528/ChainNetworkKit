import Foundation
#if canImport(Security)
import Security
#endif

#if os(Linux) 
import FoundationNetworking 
#endif

/// Server Trust Policy
enum ServerTrustPolicy {
    case performDefaultEvaluation(validateHost: Bool)
    case pinCertificates(certificates: [Data], validateCertificateChain: Bool, validateHost: Bool)
    case disableEvaluation
}

// Linux 平台独立实现 URLSessionDelegate
#if os(Linux)
final class NetworkRequestServerTrust: NSObject, URLSessionDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // 在 Linux 上处理认证挑战的代码
        // 这里可以实现简单的跳过 SSL 验证的逻辑（仅在测试环境中使用！）
        completionHandler(.useCredential, nil)
    }
}
#else
// macOS 或 iOS 平台的 URLSessionDelegate 实现
final class NetworkRequestServerTrust: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // 在 macOS 或 iOS 上处理认证挑战的代码（可能需要 Security 框架）
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
#endif

