//
//  RefreshAccessEndpoint.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

struct RefreshTokenEndpoint: Endpoint {
    let clientId: String
    let refreshToken: String
    
    let method = HTTPMethod.post
    var url: URL {
        var comps = URLComponents(string: "https://oauth2.googleapis.com/token")!
        comps.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        return comps.url!
    }
    typealias SuccessData = RefreshTokenResponse
    
    struct RefreshTokenResponse: JsonResponseDecodable {
        let accessToken: String
        let expiresIn: Int
    }
}
