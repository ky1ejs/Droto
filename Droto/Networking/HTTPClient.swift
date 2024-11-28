//
//  HTTPClient.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation
import Combine

class HTTPClient {
    private static let session = URLSession.shared
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    var headers: [String: String]
    private let retryConfig: RetryConfig?

    init(headers: [String: String] = [:], retryConfig: RetryConfig? = nil) {
        self.headers = headers
        self.retryConfig = retryConfig
    }
    
    func call<E: Endpoint>(endpoint: E) async -> E.ReturnType {
        var response = await internalCall(endpoint: endpoint)
        
        if case .failure = response.result, let retryConfig = retryConfig, retryConfig.evaluator(response.data, response.response) {
            var retryCount = 0
            while case .failure = response.result, retryCount < retryConfig.retryCount {
                await retryConfig.beforeRetry(self)
                response = await internalCall(endpoint: endpoint)
                retryCount += 1
            }
        }
        
        #if DEBUG
        if case .failure = response.result {
            print(String(data: response.data ?? Data(), encoding: .utf8) as Any)
            print(response.response as Any)
        }
        #endif
        
        return response.result
    }
    
    func call<E: Endpoint>(endpoint: E) -> AnyPublisher<E.SuccessType, Error> {
        return type(of: self).session
            .dataTaskPublisher(for: buildRequest(endpoint: endpoint))
            .tryMap(handleResponse(endpoint))
            .tryMap { result throws -> E.SuccessType in
                switch result.result {
                case .success(let data): return data
                case .failure(let error): throw error
                }
            }.eraseToAnyPublisher()
    }

    private func internalCall<E: Endpoint>(endpoint: E) async -> CallResult<E.ReturnType> {
        do {
            let (data, response) = try await type(of: self).session.data(for: buildRequest(endpoint: endpoint))
            return try handleResponse(data, response, endpoint)
        } catch {
            return CallResult(result: .failure(.unknownError), data: nil, response: nil)
        }
    }
    
    private func handleResponse<E: Endpoint>(_ endpoint: E) -> (Data, URLResponse) throws -> CallResult<E.ReturnType> {
        return { [unowned self] data, response in
            try self.handleResponse(data, response, endpoint)
        }
    }
    
    private func handleResponse<E: Endpoint>(_ data: Data, _ response: URLResponse, _: E) throws -> CallResult<E.ReturnType> {
        guard let httpResponse = response as? HTTPURLResponse else {
            return CallResult(result: .failure(.unknownError), data: data, response: nil)
        }

        guard httpResponse.status?.type == .success else {
            if let status = httpResponse.status {
                return CallResult(result: .failure(.invalidResponseCode(status)), data: data, response: httpResponse)
            }
            return CallResult(result: .failure(.unknownError), data: data, response: httpResponse)
        }

        do {
            let model = try E.SuccessType.parse(data: data)
            return CallResult(result: .success(model), data: data, response: httpResponse)
        } catch let error as DecodingError {
            print(error)
            return CallResult(result: .failure(.parsingError), data: data, response: httpResponse)
        } catch {
            return CallResult(result: .failure(.unknownError), data: data, response: httpResponse)
        }
    }
    
    private func buildRequest<E: Endpoint>(endpoint: E) -> URLRequest {
        endpoint.buildRequest(headers: headers)
    }
    
    struct RetryConfig {
        let evaluator: (Data?, HTTPURLResponse?) -> Bool
        let beforeRetry: (HTTPClient) async -> ()
        let retryCount: Int
    }
    
    private struct CallResult<ResultType> {
        let result: ResultType
        let data: Data?
        let response: HTTPURLResponse?
    }

    enum HTTPClientError: Error {
        case unknownError
        case parsingError
        case invalidResponseCode(HTTPStatusCode)
    }
}
