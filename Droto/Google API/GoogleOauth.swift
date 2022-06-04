//
//  GoogleOauth.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation
import AuthenticationServices

class GoogleOauth {
    private let httpClient: HTTPClient
    private let keychainManager: KeychainManager
    private let clientId: String
    private var credentials: Credentials? {
        didSet {
            guard let credentials = credentials else { return }
            keychainManager.setGoogleAuthCredentials(credentials: credentials)
        }
    }
    typealias AuthResopnseCallback = (Credentials) -> Void

    init(httpClient: HTTPClient = HTTPClient(), keychainManager: KeychainManager = KeychainManager()) {
        let plistPath = Bundle.main.path(forResource: "google-oauth", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: plistPath)!
        clientId = dict["CLIENT_ID"] as! String
        self.keychainManager = keychainManager
        self.httpClient = httpClient
        self.credentials = keychainManager.getGoogleAuthCredentials()
    }

    func createAuthSession(callback: @escaping (Result<Credentials, Error>) -> ()) -> ASWebAuthenticationSession {
        let session = ASWebAuthenticationSession(url: createGoogleOauthUrl(), callbackURLScheme: "dev.kylejs.Droto") { [weak self] callbackURL, _ in
            guard let callbackURL = callbackURL, let `self` = self else {
                assertionFailure()
                return
            }
            let code = self.codeFrom(callbackURL: callbackURL)
            let endpoint = ExchangeAuthCodeForTokenEndpoint(code: code, clientId: self.clientId)
            Task {
                switch await self.httpClient.call(endpoint: endpoint) {
                case .success(let credentials):
                    self.keychainManager.setGoogleAuthCredentials(credentials: credentials)
                    callback(.success(credentials))
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        }
        return session
    }
    
    enum GoogleOauthError: Error {
        case noCredentialsToRefresh
        case httpError(HTTPClient.HTTPClientError)
    }
    
    func refreshAccessToken() async -> Result<Credentials, GoogleOauthError> {
        guard let credentials = credentials else {
            return .failure(.noCredentialsToRefresh)
        }

        let refreshEndpoint = RefreshTokenEndpoint(clientId: clientId, refreshToken: credentials.refreshToken)
        switch await httpClient.call(endpoint: refreshEndpoint) {
        case .success(let refreshResult):
            self.credentials = credentials.updateWith(refreshTokenResponse: refreshResult)
            return .success(credentials)
        case .failure(let error):
            return .failure(.httpError(error))
        }
    }
    
    func headersWith(credentials: Credentials) -> [String : String] {
        return ["Authorization": "Bearer \(credentials.accessToken)"]
    }

    private func createGoogleOauthUrl() -> URL {
        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        comps?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: "dev.kylejs.Droto:/google-oauth-callback"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/drive")
        ]
        return comps!.url!
    }
    
    private func codeFrom(callbackURL: URL) -> String {
        let queryItems = URLComponents(string: callbackURL.absoluteString)!.queryItems
        return queryItems!.filter({ $0.name == "code" }).first!.value!
    }

    struct Credentials: JsonResponseDecodable, Encodable {
        let accessToken: String
        let expiresIn: Int
        let tokenType: String
        let scope: String
        let refreshToken: String
        
        func updateWith(refreshTokenResponse: RefreshTokenEndpoint.RefreshTokenResponse) -> Credentials {
            return Credentials(
                accessToken: refreshTokenResponse.accessToken,
                expiresIn: refreshTokenResponse.expiresIn,
                tokenType: tokenType,
                scope: scope,
                refreshToken: refreshToken)
        }
    }
}
