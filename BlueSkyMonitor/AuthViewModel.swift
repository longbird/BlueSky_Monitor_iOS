import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var mgrId: String = ""
    @Published var mgrPwd: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var rememberCredentials = true

    private let api: AuthAPI
    private let tokenStore: TokenStore

    init(api: AuthAPI = LiveAuthAPI(), tokenStore: TokenStore = .shared) {
        self.api = api
        self.tokenStore = tokenStore

        loadSavedCredentials()
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
            persistCredentialsIfNeeded()
            NSLog("[AuthVM] login success")
        } catch {
            NSLog("[AuthVM] login error=%@", String(describing: error))
            errorMessage = error.localizedDescription
        }
    }

    private func loadSavedCredentials() {
        do {
            let savedId = try KeychainStore.load(account: "mgrId")
            let savedPwd = try KeychainStore.load(account: "mgrPwd")
            if let savedId, let savedPwd {
                mgrId = savedId
                mgrPwd = savedPwd
                rememberCredentials = true
            }
        } catch {
            NSLog("[AuthVM] keychain load error=%@", String(describing: error))
        }
    }

    private func persistCredentialsIfNeeded() {
        do {
            if rememberCredentials {
                try KeychainStore.save(mgrId, account: "mgrId")
                try KeychainStore.save(mgrPwd, account: "mgrPwd")
            } else {
                try KeychainStore.delete(account: "mgrId")
                try KeychainStore.delete(account: "mgrPwd")
            }
        } catch {
            NSLog("[AuthVM] keychain save error=%@", String(describing: error))
        }
    }
}
