//
//  Keychain.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation
import KeychainAccess

struct KeychainManager {
    private static let service = "dev.kylejm.Droto"
    private static let credentialsKeychainKey = "google_oauth_credentials"

    func setGoogleAuthCredentials(credentials: GoogleOauth.Credentials) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let json = try! encoder.encode(credentials)
        try! Keychain(service: type(of: self).service).set(json, key: type(of: self).credentialsKeychainKey)
    }

    func getGoogleAuthCredentials() -> GoogleOauth.Credentials? {
        guard let json = try! Keychain(service: type(of: self).service).getData(type(of: self).credentialsKeychainKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try! decoder.decode(GoogleOauth.Credentials.self, from: json)
    }
}
