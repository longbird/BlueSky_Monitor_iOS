import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var mgrId: String = ""
    @Published var mgrPwd: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: AuthAPI
    private let tokenStore: TokenStore

    init(api: AuthAPI = LiveAuthAPI(), tokenStore: TokenStore = .shared) {
        self.api = api
        self.tokenStore = tokenStore
    }

    func login() async {
        guard !mgrId.isEmpty, !mgrPwd.isEmpty else {
            errorMessage = "아이디와 비밀번호를 입력하세요."
            return
        }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        NSLog("[AuthVM] login start id=%@", mgrId)
        do {
            let data = try await api.login(mgrId: mgrId, mgrPwd: mgrPwd)
            tokenStore.update(accessToken: data.accessToken, refreshToken: data.refreshToken)
            NSLog("[AuthVM] login success")
        } catch {
            NSLog("[AuthVM] login error=%@", String(describing: error))
            errorMessage = error.localizedDescription
        }
    }
}
