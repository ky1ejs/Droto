//
//  Endpoint.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

protocol Endpoint {
    var url: URL { get }
    var method: HTTPMethod { get }
    associatedtype SuccessData: URLResponseDecodable
    typealias ReturnType = Result<SuccessData, HTTPClient.HTTPClientError>
}

protocol URLResponseDecodable {
    static func parse(data: Data) throws -> Self
}

protocol JsonResponseDecodable: URLResponseDecodable, Decodable {}

extension JsonResponseDecodable {
    static func parse(data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(self, from: data)
    }
}
