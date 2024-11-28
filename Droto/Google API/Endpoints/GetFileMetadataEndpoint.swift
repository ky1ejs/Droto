//
//  GetFileMetadataEndpoint.swift
//  Droto
//
//  Created by Kyle Satti on 14/07/2022.
//

import Foundation

struct GetFileMetadataEndpoint: Endpoint {
    let fileId: String
    let method = HTTPMethod.get

    var url: URL {
        var comps = URLComponents(string: "https://www.googleapis.com/drive/v3/files/\(fileId)")!
        comps.queryItems = [
            URLQueryItem(name: "fields", value: "name,id,mimeType,thumbnailLink,version,md5Checksum")
        ]
        return comps.url!
    }
    
    typealias SuccessType = FileMetadata
}
