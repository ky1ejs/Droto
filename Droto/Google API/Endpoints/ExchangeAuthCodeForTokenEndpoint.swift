//
//  ExchangeAuthCodeForTokenEndpoint.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

struct ExchangeAuthCodeForTokenEndpoint: Endpoint {
    let code: String
    let clientId: String
    
    var url: URL {
        var comps = URLComponents(string: "https://oauth2.googleapis.com/token")!

        comps.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: "dev.kylejs.Droto:/google-oauth-callback"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        return comps.url!
    }
    
    let method = HTTPMethod.post
    typealias SuccessData = GoogleOauth.Credentials
}
