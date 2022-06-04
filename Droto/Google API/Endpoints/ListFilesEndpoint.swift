//
//  ListFilesResponse.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

struct ListFoldersAndImagesEndpoint: Endpoint {
    let folderId: String
    let method = HTTPMethod.get

    var url: URL {
        var comps = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        comps.queryItems = [
            URLQueryItem(name: "q", value: "'\(folderId)' in parents and (mimeType = '\(GoogleMimeType.folder.rawValue)' or mimeType = '\(GoogleMimeType.jpeg.rawValue)' or mimeType = '\(GoogleMimeType.jpeg.rawValue)')"),
            URLQueryItem(name: "orderBy", value: "folder,name"),
            URLQueryItem(name: "fields", value: "files/name,files/id,files/mimeType,files/thumbnailLink")
        ]
        return comps.url!
    }
    
    typealias SuccessData = ListFilesResponse
    
    struct ListFilesResponse: JsonResponseDecodable {
        let files: [File]
    }
}
