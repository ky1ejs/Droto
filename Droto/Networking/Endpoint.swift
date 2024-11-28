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
    associatedtype SuccessType: URLResponseDecodable
    typealias ErrorType = HTTPClient.HTTPClientError
    typealias ReturnType = Result<SuccessType, ErrorType>
}

extension Endpoint {
    func buildRequest(headers: [String : String]) -> URLRequest {
        var request = URLRequest(url: url)
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpMethod = method.rawValue
        return request
    }
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
