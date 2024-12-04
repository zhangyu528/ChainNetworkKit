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
}

/// Network Configuration 
final class NetConfig: @unchecked Sendable { 
    static let shared = NetConfig() 
    
    var environmentURLs: [Environment: String] = [:]
    var env: Environment = .development {
        didSet {
            self.baseURL = environmentURLs[env] ?? ""
            self.defaultHeaders = env.defaultHeaders
            self.timeoutInterval = env.timeoutInterval
        }
    }
    var baseURL: String = ""
    var defaultHeaders: [String: String] = [:]
    var timeoutInterval: TimeInterval = 30

    var bearerTokenProvider: (() -> String?)?
    var serverTrustPolicies: [String: ServerTrustPolicy] = [:]
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
