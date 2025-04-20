import Foundation

public class FooAPIClient: @unchecked Sendable {
    
    let environment: Environment
    let apiClient: APIClient
    public var authToken: String?
    public var apiKey: String?

    var installationGuid: String!
    
    public static func create() -> FooAPIClient {
        FooAPIClient(environment: FooAPI.FooEnvironment.production)
    }
    
    private init(environment: Environment, networkFetcher: APIClientNetworkFetcher? = nil) {
        self.environment = environment
        apiClient = .init(environment: environment, networkFetcher: networkFetcher)
        apiClient.loggingConfiguration = .init(requestBehaviour: .all, responseBehaviour: .all)
        if installationGuid == nil {
            installationGuid = UUID().uuidString
        }
        apiClient.customizeRequest = { [weak self] urlRequest in
            var mutableRequest = urlRequest
            if let token = self?.authToken {
                mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            if let apiKey = self?.apiKey {
                mutableRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            }
            return mutableRequest
        }
    }
        
    public func loginWithSMS(with phone: String, prefix: String, countryCode: String) async throws {
        let request = APIClient.Request<VoidResponse>(endpoint: LoginAPI.LoginEndpoint.loginWithSMS(phone: phone, prefix: prefix, installationGuid: installationGuid))
        let _ = try await apiClient.perform(request)
    }
        
    public func logOut() async throws {
        let request = APIClient.Request<VoidResponse>(endpoint: LoginAPI.LoginEndpoint.logout)
        let _ = try await apiClient.perform(request)
    }
        
    public func checkConfirmationSMSCode(with phone: String, prefix: String, confirmationCode: String, countryCode: String) async throws -> LoginResponse {
        struct Wrapper: Codable {
            let json: LoginResponse
        }
        let request = APIClient.Request<Wrapper>(endpoint: LoginAPI.LoginEndpoint.checkCode(phone: phone, prefix: prefix, installationGuid: installationGuid, verificationCode: confirmationCode))
        return try await apiClient.perform(request).json
    }
}

enum LoginAPI {
    enum LoginEndpoint: Endpoint {
        
        case loginWithSMS(phone: String, prefix: String, installationGuid: String)
        case checkCode(phone: String, prefix: String, installationGuid: String, verificationCode: String)
        case logout
        
        var path: String {
            switch self {
            case .loginWithSMS:
                return "post"
            case .checkCode:
                return "post"
            case .logout:
                return "post"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .loginWithSMS, .checkCode, .logout:
                return .POST
            }
        }
        
        var parameters: [String : Any]? {
            switch self {
            case .loginWithSMS(let phone, let prefix, let installationGuid):
                return [
                    "phone": phone,
                    "phone_prefix": prefix,
                    "installation_guid": installationGuid
                ]
            case .checkCode:
                let response = LoginResponse(
                    accessToken: "123456789",
                    customer: LoginResponse.Customer(id: 123, customerToken: "scfdvghbas", countryCode: "us")
                )
                let data = try! JSONEncoder().encode(response)
                return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            case .logout:
                return [:]
            }
        }
        
        var parameterEncoding: HTTPParameterEncoding {
            switch self {
            case .loginWithSMS, .checkCode, .logout:
                return .json
            }
        }
        
        var timeoutInterval: TimeInterval? {
            15
        }
    }
}

public struct LoginResponse: Codable, Sendable {
    let accessToken: String
    public let customer: Customer

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case customer
    }
    
    public struct Customer: Codable, Sendable {
        let id: Int
        public let customerToken: String
        public let countryCode: String?
        
        
        enum CodingKeys: String, CodingKey {
            case id
            case customerToken = "customer_token"
            case countryCode = "country_code"
        }
    }
}

private enum FooAPI {
    
    enum FooEnvironment: Environment {
        case production
        case development
        
        var baseURL: URL {
            switch self {
            case .production:
                return URL(string: "https://httpbin.org/")!
            case .development:
                return URL(string: "https://dev.httpbin.org/")!
            }
        }
    }
}
