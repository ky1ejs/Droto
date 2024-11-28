//
//  GoogleDriveClient.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation
import Combine

struct GoogleDriveClient {
    private let httpClient: HTTPClient
    private let authHeaders: [String : String]

    init(googleCredentials: GoogleOauth.Credentials, googleOauth: GoogleOauth = GoogleOauth()) {
        let authHeaders = googleOauth.headersWith(credentials: googleCredentials)
        httpClient = HTTPClient(
            headers: authHeaders,
            retryConfig: HTTPClient.RetryConfig(
                evaluator: { data, response in
                    return response?.status == .unauthorized
                },
                beforeRetry: { client in
                    switch await googleOauth.refreshAccessToken() {
                    case .success(let credentials):
                        client.headers = googleOauth.headersWith(credentials: credentials)
                    case .failure:
                        return
                    }
                }, retryCount: 1)
        )
        self.authHeaders = authHeaders
    }

    func getAbout() async -> AboutEndpoint.ReturnType {
        return await httpClient.call(endpoint: AboutEndpoint())
    }

    func getContentsOfFolder(folder: Folder) async -> ListFoldersAndImagesEndpoint.ReturnType {
        switch folder {
        case .root:
            switch await getAbout() {
            case let .success(about):
                let file = FileMetadata(
                    id: about.rootFolderId,
                    name: "Drive",
                    mimeType: .folder,
                    thumbnailLink: nil,
                    version: "0",
                    md5Checksum: "0"
                )
                return await getContentsOfFolder(folder: .file(file.id))
            case let .failure(error):
                return .failure(error)
            }

        case .file(let fileId):
            return await httpClient.call(endpoint: ListFoldersAndImagesEndpoint(folderId: fileId))
        }
    }
    
    func downloadFile(fileId: String) async throws -> DownloadedFile {
        let metadataResult = await httpClient.call(endpoint: GetFileMetadataEndpoint(fileId: fileId))
        let contentResult = await httpClient.call(endpoint: DownloadFileEndpoint(fileId: fileId))
        
        switch (metadataResult, contentResult) {
        case let (.success(file), .success(data)):
            return try writeFileToCache(metadata: file, content: data)
        default:
            throw GoogleDriveClientError.unknownError
        }
    }
    
    func downloadFile(file: FileMetadata) async throws -> DownloadedFile {
        switch await httpClient.call(endpoint: DownloadFileEndpoint(fileId: file.id)) {
        case .success(let data):
            return try writeFileToCache(metadata: file, content: data)
        case .failure(let error):
            throw GoogleDriveClientError.endpointError(error)
        }
    }
    
    func downloadFiles(files: [String]) -> AnyPublisher<DownloadStatus<[DownloadedFile]>, Error> {
        let requests = files.map { file -> TwinDownloadTask<GetFileMetadataEndpoint.SuccessType> in
                let metadataPublisher = httpClient.call(endpoint: GetFileMetadataEndpoint(fileId: file))
                let downloadRequest = DownloadFileEndpoint(fileId: file).buildRequest(headers: authHeaders)
                let downloadPublisher = DownloadResultPublisher(request: downloadRequest).eraseToAnyPublisher()
                
                return TwinDownloadTask(
                    request: metadataPublisher,
                    download: downloadPublisher
                )
            }   
            
            return Downloader<GetFileMetadataEndpoint.SuccessType>(requests)
                .map { status -> DownloadStatus<[DownloadedFile]> in
                    switch status {
                    case .progressMade(let progress): return .progressMade(progress)
                    case .complete(let data):
                        return .complete(data.map { DownloadedFile(file: $0.request, path: $0.download)})
                    }
                }.eraseToAnyPublisher()
        }
    
    private func writeFileToCache(metadata: FileMetadata, content: Data) throws -> DownloadedFile {
        let url = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Droto-TempDowloads")
            .appendingPathComponent("\(metadata.id)_\(metadata.md5Checksum)")
        
        let fm = FileManager.default
        if fm.fileExists(atPath: url.absoluteString) {
            try fm.removeItem(at: url.absoluteURL)
        }
        fm.createFile(atPath: url.absoluteString, contents: content)
        
        return DownloadedFile(file: metadata, path: url)
    }
}

enum GoogleDriveClientError: Error {
    case endpointError(Error)
    case unknownError
}

