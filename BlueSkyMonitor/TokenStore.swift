import Foundation
import SwiftUI

final class TokenStore: ObservableObject {
    static let shared = TokenStore()

    @AppStorage("accessToken") private var accessTokenStorage: String = ""
    @AppStorage("refreshToken") private var refreshTokenStorage: String = ""

    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?

    private init() {
        self.accessToken = accessTokenStorage.isEmpty ? nil : accessTokenStorage
        self.refreshToken = refreshTokenStorage.isEmpty ? nil : refreshTokenStorage
    }

    func update(accessToken: String, refreshToken: String) {
        accessTokenStorage = accessToken
        refreshTokenStorage = refreshToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clear() {
        accessTokenStorage = ""
        refreshTokenStorage = ""
        accessToken = nil
        refreshToken = nil
    }
}
