import Foundation

struct LoginRequest: Codable {
    let mgrId: String
    let mgrPwd: String
}

struct RefreshRequest: Codable {
    let refreshToken: String
}

struct LoginResponseData: Codable {
    let loginInfo: LoginInfo
    let permissions: [String]
    let accessToken: String
    let refreshToken: String
}

struct LoginInfo: Codable {
    let mgrId: String
    let mgrNm: String
    let callCenterCd: String
    let callCenterNm: String
    let userType: String
    let loginUserType: String
}
