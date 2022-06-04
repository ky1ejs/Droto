//
//  DownloadFileEndpoint.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation
import UIKit

struct DownloadFileEndpoint: Endpoint {
    let fileId: String
    
    var url: URL {
        var comps = URLComponents(string: "https://www.googleapis.com/drive/v3/files/\(fileId)")!
        comps.queryItems = [URLQueryItem(name: "alt", value: "media")]
        return comps.url!
    }
    let method = HTTPMethod.get
    typealias SuccessData = Data
}

enum ParsingError: Error {
    case couldNotParse
}

extension UIImage: URLResponseDecodable {
    static func parse(data: Data) throws -> Self {
        guard let image = UIImage(data: data) else {
            throw ParsingError.couldNotParse
        }
        return image as! Self
    }
}

extension Data: URLResponseDecodable {
    static func parse(data: Data) throws -> Data {
        return data
    }
}
