//
//  AboutEndpoint.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

struct AboutEndpoint: Endpoint {
    var url: URL { return URL(string: "https://www.googleapis.com/drive/v2/about")! }
    let method = HTTPMethod.get
    typealias SuccessData = About
}
