//
//  FileMetadata.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

struct FileMetadata: JsonResponseDecodable, Equatable {
    let id: String
    let name: String
    let mimeType: GoogleMimeType
    let thumbnailLink: URL?
    let version: String
    let md5Checksum: String
}
