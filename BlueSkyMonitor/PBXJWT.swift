import Foundation
import Security

enum PBXJWTError: Error {
    case invalidPEM
    case invalidKey
    case signFailed
}

struct PBXJWT {
    static func token(callCenterCd: String, manager: Bool, privateKeyPEM: String, now: Date = Date()) throws -> String {
        let header: [String: Any] = [
            "typ": "JWT",
            "alg": "RS256"
        ]

        let iat = Int(now.timeIntervalSince1970) - 60
        let exp = iat + 3600
        let claims: [String: Any] = [
            "iss": "bluesky.file.service.v1",
            "aud": callCenterCd,
            "manager": manager ? "true" : "false",
            "iat": iat,
            "exp": exp
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
        let claimsData = try JSONSerialization.data(withJSONObject: claims, options: [])
        let headerPart = headerData.base64URLEncodedString()
        let claimsPart = claimsData.base64URLEncodedString()
        let signingInput = "\(headerPart).\(claimsPart)"

        let signature = try sign(message: signingInput, privateKeyPEM: privateKeyPEM)
        let signaturePart = signature.base64URLEncodedString()
        return "\(signingInput).\(signaturePart)"
    }

    private static func sign(message: String, privateKeyPEM: String) throws -> Data {
        let keyData = try decodePEM(privateKeyPEM)
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            throw PBXJWTError.invalidKey
        }

        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            Data(message.utf8) as CFData,
            &error
        ) else {
            throw PBXJWTError.signFailed
        }

        return signature as Data
    }

    private static func decodePEM(_ pem: String) throws -> Data {
        let lines = pem
            .components(separatedBy: .newlines)
            .filter { !$0.contains("BEGIN PRIVATE KEY") && !$0.contains("END PRIVATE KEY") && !$0.isEmpty }
        let base64 = lines.joined()
        guard let data = Data(base64Encoded: base64) else {
            throw PBXJWTError.invalidPEM
        }
        return data
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        let base64 = self.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
