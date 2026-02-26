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
            .filter { !$0.hasPrefix("-----") && !$0.isEmpty }
        let base64 = lines.joined()
        guard let data = Data(base64Encoded: base64) else {
            throw PBXJWTError.invalidPEM
        }
        return stripPKCS8HeaderIfNeeded(data)
    }

    /// PKCS#8 DER 데이터에서 PKCS#1 RSA 키 부분만 추출
    private static func stripPKCS8HeaderIfNeeded(_ data: Data) -> Data {
        // PKCS#8 header for RSA: 30 82 xx xx 02 01 00 30 0D 06 09 2A 86 48 86 F7 0D 01 01 01 05 00 04 82 xx xx 30 82
        // We look for the inner OCTET STRING that contains the PKCS#1 key
        let bytes = [UInt8](data)
        // Minimum PKCS#8 wrapper is ~26 bytes header
        guard bytes.count > 26, bytes[0] == 0x30 else { return data }
        // Find the OCTET STRING (tag 0x04) that wraps the PKCS#1 key
        var index = 0
        // Skip outer SEQUENCE tag + length
        guard bytes[index] == 0x30 else { return data }
        index += 1
        index = skipASN1Length(bytes, index)
        // Skip version INTEGER
        guard index < bytes.count, bytes[index] == 0x02 else { return data }
        index += 1
        index = skipASN1Length(bytes, index)
        index += 1 // version value (0x00)
        // Skip AlgorithmIdentifier SEQUENCE
        guard index < bytes.count, bytes[index] == 0x30 else { return data }
        index += 1
        let algLen = asn1Length(bytes, index)
        index = skipASN1Length(bytes, index)
        index += algLen
        // Now we should be at OCTET STRING containing PKCS#1 key
        guard index < bytes.count, bytes[index] == 0x04 else { return data }
        index += 1
        index = skipASN1Length(bytes, index)
        return Data(bytes[index...])
    }

    private static func skipASN1Length(_ bytes: [UInt8], _ index: Int) -> Int {
        guard index < bytes.count else { return index }
        if bytes[index] & 0x80 == 0 {
            return index + 1
        }
        let numBytes = Int(bytes[index] & 0x7F)
        return index + 1 + numBytes
    }

    private static func asn1Length(_ bytes: [UInt8], _ index: Int) -> Int {
        guard index < bytes.count else { return 0 }
        if bytes[index] & 0x80 == 0 {
            return Int(bytes[index])
        }
        let numBytes = Int(bytes[index] & 0x7F)
        var length = 0
        for i in 1...numBytes {
            guard index + i < bytes.count else { return 0 }
            length = (length << 8) | Int(bytes[index + i])
        }
        return length
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
