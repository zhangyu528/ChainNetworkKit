import Foundation

enum Environment {
    case development
    case testing
    case production

    var defaultHeaders: [String: String] {
        switch self {
        case .development, .testing:
            return ["Content-Type": "application/json"]
        case .production:
            return ["Content-Type": "application/json", "Authorization": "Bearer <token>"]
        }
    }

    var timeoutInterval: TimeInterval {
        switch self {
        case .development, .testing:
            return 60.0
        case .production:
            return 30.0
        }
    }

    var isLoggingEnabled: Bool {
        switch self {
        case .development, .testing:
            return true
        case .production:
            return false
        }

    }
}

/// Network Configuration 
final class NetConfig: @unchecked Sendable { 
    static let shared = NetConfig() 
    
    var environmentHosts: [Environment: String] = [:]
    var env: Environment = .development {
        didSet {
            // Automatically update logger configuration based on environment
            NetLogger.shared.isLoggingEnabled = env.isLoggingEnabled
        }
    }
    
    var host: String {
        return environmentHosts[env] ?? ""
    }
    var defaultHeaders: [String: String] {
        return env.defaultHeaders
    }
    var timeoutInterval: TimeInterval {
        return env.timeoutInterval
    }

    var bearerTokenProvider: (() -> String?)?
    private var serverTrustPolicies: [String: ServerTrustPolicy] = [:]
    private var certificates: [Data] = []

    private init() {}

    /// Set Bearer Token Provider
    func setBearerTokenProvider(_ provider: @escaping() -> String) {
        self.bearerTokenProvider = provider
    }
    /// Load Certificates from Paths 
    func loadCertificates(from paths: [String]) { 
        self.certificates = paths.compactMap { path in 
            return NSData(contentsOfFile: path) as Data?
        } 
    }
}
