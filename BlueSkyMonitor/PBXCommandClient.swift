import Foundation

enum PBXCommandError: Error {
    case missingKey
    case invalidURL
    case requestFailed
}

struct PBXCommandClient {
    private static let headerName = "X-BSAUTH-TOKEN"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: PBXSessionDelegate(), delegateQueue: nil)
    }()

    static func sendCommand(ip: String, port: Int = 443, callCenterCd: String, command: String) async throws -> Bool {
        let token = try jwt(callCenterCd: callCenterCd)
        var components = URLComponents()
        components.scheme = "https"
        components.host = ip
        components.port = 443
        components.path = "/fs_cmd.php"
        components.queryItems = [
            URLQueryItem(name: "auth", value: "ON"),
            URLQueryItem(name: "do", value: command)
        ]
        guard let url = components.url else {
            throw PBXCommandError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: headerName)

        let (_, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        return statusCode == 200
    }

    static func fetchVersion(ip: String, port: Int = 443, callCenterCd: String) async throws -> Int {
        let token = try jwt(callCenterCd: callCenterCd)
        var components = URLComponents()
        components.scheme = "https"
        components.host = ip
        components.port = 443
        components.path = "/fs_version.php"
        guard let url = components.url else {
            throw PBXCommandError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: headerName)

        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else { throw PBXCommandError.requestFailed }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["version"] as? Int ?? 0
    }

    private static func jwt(callCenterCd: String) throws -> String {
        guard let keyURL = Bundle.main.url(forResource: "pbx_private_key", withExtension: "pem"),
              let keyData = try? Data(contentsOf: keyURL),
              let pem = String(data: keyData, encoding: .utf8) else {
            throw PBXCommandError.missingKey
        }
        return try PBXJWT.token(callCenterCd: callCenterCd, manager: true, privateKeyPEM: pem)
    }
}

/// 자체 서명 인증서를 허용하는 URLSession delegate
private final class PBXSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return (.performDefaultHandling, nil)
        }
        return (.useCredential, URLCredential(trust: serverTrust))
    }
}
