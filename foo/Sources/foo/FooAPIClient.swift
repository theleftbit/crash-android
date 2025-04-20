import Foundation

public class FooAPIClient: @unchecked Sendable {
    
    let environment: Environment
    let apiClient: APIClient
    var authToken: String?
    var userID: String?
    var apiKey: String?
    
    var installationGuid: String!
    
    public static func create() -> FooAPIClient {
        FooAPIClient(environment: FooAPI.FooEnvironment.production)
    }
    
    private init(environment: Environment, networkFetcher: APIClientNetworkFetcher? = nil) {
        self.environment = environment
        apiClient = .init(environment: environment, networkFetcher: networkFetcher)
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
        let request = APIClient.Request<VoidResponse>(endpoint: LoginAPI.Patient.loginWithSMS(phone: phone, prefix: prefix, installationGuid: installationGuid, countryCode: countryCode))
        let _ = try await apiClient.perform(request)
    }
        
    public func logOut() async throws {
        let request = APIClient.Request<VoidResponse>(endpoint: LoginAPI.Patient.logout)
        let _ = try await apiClient.perform(request)
    }
        
    public func checkConfirmationSMSCode(with phone: String, prefix: String, confirmationCode: String, countryCode: String) async throws -> LoginResponse {
        let request = APIClient.Request<LoginResponse>(endpoint: LoginAPI.Patient.checkSMSCode(phone: phone, prefix: prefix, verificationCode: confirmationCode, installationGuid: installationGuid, countryCode: countryCode))
        return try await apiClient.perform(request)
    }
}


enum LoginAPI {
    enum Patient: Endpoint {
        case loginWithSMS(phone: String, prefix: String, installationGuid: String, countryCode: String)
        case loginWithSocial(provider: String, token: String, installationGuid: String, countryCode: String, parameters: [String: any Sendable])
        case checkSMSCode(phone: String, prefix: String, verificationCode: String, installationGuid: String, countryCode: String)
        case logout
        case deleteAccount
        case availableCountries
        
        var path: String {
            switch self {
            case .loginWithSMS:
                return "api/v1/login-sms"
            case .loginWithSocial:
                return "api/auth/login/social"
            case .checkSMSCode:
                return "api/v1/check"
            case .logout:
                return "api/v1/logout"
            case .deleteAccount:
                return "api/v2/profile"
            case .availableCountries:
                return "api/v2/available-countries"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .loginWithSMS, .checkSMSCode, .logout, .loginWithSocial:
                return .POST
            case .deleteAccount:
                return .DELETE
            case .availableCountries:
                return .GET
            }
        }
        
        var parameters: [String : Any]? {
            switch self {
            case .loginWithSMS(let phone, let prefix, let installationGuid, let countryCode):
                return [
                    "phone": phone,
                    "phone_prefix": prefix,
                    "installation_guid": installationGuid,
                    "country_code": countryCode
                ]
            case .loginWithSocial(let provider, let token, let installationGuid, let countryCode ,var parameters):
                parameters["access_token"] = token
                parameters["provider"] = provider
                parameters["installation_guid"] = installationGuid
                parameters["country_code"] = countryCode
                return parameters
            case .checkSMSCode(let phone, let prefix, let verificationCode, let installationGuid, let countryCode):
                return [
                    "phone": phone,
                    "phone_prefix": prefix,
                    "verification_code": verificationCode,
                    "installation_guid": installationGuid,
                    "country_code": countryCode
                ]
            case .logout, .deleteAccount, .availableCountries:
                return nil
            }
        }
        
        var parameterEncoding: HTTPParameterEncoding {
            switch self {
            case .loginWithSMS, .checkSMSCode, .loginWithSocial, .availableCountries:
                return .json
            case .logout, .deleteAccount:
                return .url
            }
        }
        
        var timeoutInterval: TimeInterval? {
            15
        }
    }
    
    enum Professional: Endpoint {
        
        case loginWithSMS(phone: String, prefix: String, installationGuid: String)
        case checkCode(phone: String, prefix: String, installationGuid: String, verificationCode: String)
        case logout
        case deleteAccount
        
        var path: String {
            switch self {
            case .loginWithSMS:
                return "pro/v1/login-sms"
            case .checkCode:
                return "pro/v1/check"
            case .logout:
                return "pro/v1/logout"
            case .deleteAccount:
                return "pro/v1/profile"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .loginWithSMS, .checkCode, .logout:
                return .POST
            case .deleteAccount:
                return .DELETE
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
            case .checkCode(let phone, let prefix, let installationGuid, let verificationCode):
                return [
                    "verification_code": verificationCode,
                    "phone": phone,
                    "phone_prefix": prefix,
                    "installation_guid": installationGuid
                ]
            case .logout, .deleteAccount:
                return [:]
            }
        }
        
        var parameterEncoding: HTTPParameterEncoding {
            switch self {
            case .loginWithSMS, .checkCode, .logout, .deleteAccount:
                return .json
            }
        }
        
        var timeoutInterval: TimeInterval? {
            15
        }
    }
}

public struct LoginResponse: Decodable, Sendable {
    let accessToken: String
    let customer: Customer

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case customer
    }
    
    public struct Customer: Decodable, Sendable {
        let id: Int
        let customerToken: String
        let countryCode: String?
        
        
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
        
        public var baseURL: URL {
            switch self {
            case .production:
                return URL(string: "https://api.mediquo.com/")!
            case .development:
                return URL(string: "https://develop.mediquo.com/")!
            }
        }
    }
}
