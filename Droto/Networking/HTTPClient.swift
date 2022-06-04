//
//  HTTPClient.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

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

    private func internalCall<E: Endpoint>(endpoint: E) async -> CallResult<E.ReturnType> {
        var data: Data?
        var response: URLResponse?
        
        do {
            let (returnedData, returnedResponse) = try await type(of: self).session.data(for: buildRequest(endpoint: endpoint))
            data = returnedData
            response = returnedResponse
        } catch {
            return CallResult(result: .failure(.unknownError), data: nil, response: nil)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return CallResult(result: .failure(.unknownError), data: data, response: nil)
        }

        guard httpResponse.status?.type == .success else {
            if let status = httpResponse.status {
                return CallResult(result: .failure(.invalidResponseCode(status)), data: data, response: httpResponse)
            }
            return CallResult(result: .failure(.unknownError), data: data, response: httpResponse)
        }
        
        guard let unwrappedData = data else {
            return CallResult(result: .failure(.unknownError), data: data, response: httpResponse)
        }

        do {
            let model = try E.SuccessData.parse(data: unwrappedData)
            return CallResult(result: .success(model), data: data, response: httpResponse)
        } catch let error as DecodingError {
            print(error)
            return CallResult(result: .failure(.parsingError), data: data, response: httpResponse)
        } catch {
            return CallResult(result: .failure(.unknownError), data: data, response: httpResponse)
        }
    }
    
    private func buildRequest<E: Endpoint>(endpoint: E) -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpMethod = endpoint.method.rawValue
        return request
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
