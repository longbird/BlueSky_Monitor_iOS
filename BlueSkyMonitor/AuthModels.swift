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
    let permissions: [Permission]
    let accessToken: String
    let refreshToken: String
}

struct Permission: Codable {
    let menuId: String?
    let menuNm: String?
    let menuDepth: String?
    let parentNm: String?
    let parentCd: String?
    let showSearchYn: String?
    let showSaveYn: String?
    let showExcelYn: String?
    let authSearchYn: String?
    let authSaveYn: String?
    let authExcelYn: String?
    let sort: String?
    let guide: String?
    let comboData: String?
    let comboKey: String?

    enum CodingKeys: String, CodingKey {
        case menuId = "menu_id"
        case menuNm = "menu_nm"
        case menuDepth = "menu_depth"
        case parentNm = "parent_nm"
        case parentCd = "parent_cd"
        case showSearchYn = "show_search_yn"
        case showSaveYn = "show_save_yn"
        case showExcelYn = "show_excel_yn"
        case authSearchYn = "auth_search_yn"
        case authSaveYn = "auth_save_yn"
        case authExcelYn = "auth_excel_yn"
        case sort
        case guide
        case comboData = "combo_data"
        case comboKey = "combo_key"
    }
}

struct LoginInfo: Codable {
    let mgrId: String
    let mgrNm: String
    let callCenterCd: String
    let callCenterNm: String
    let userType: String
    let loginUserType: String
}
