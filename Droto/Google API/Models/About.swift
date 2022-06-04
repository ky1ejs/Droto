//
//  About.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

struct About: JsonResponseDecodable {
    let name: String
    let rootFolderId: String
}
