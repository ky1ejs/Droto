//
//  GoogleDriveClient.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation

struct GoogleDriveClient {
    private let httpClient: HTTPClient
    private let googleOauth: GoogleOauth

    init(googleCredentials: GoogleOauth.Credentials, googleOauth: GoogleOauth = GoogleOauth()) {
        httpClient = HTTPClient(
            headers: googleOauth.headersWith(credentials: googleCredentials),
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
        self.googleOauth = googleOauth
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
        let metadataResult = await httpClient.call(endpoint: GetFileMetadata(fileId: fileId))
        let contentResult = await httpClient.call(endpoint: DownloadFileEndpoint(fileId: fileId))
        
        switch (metadataResult, contentResult) {
        case let (.success(file), .success(data)):
            return writeFileToCache(metadata: file, content: data)
        default:
            throw GoogleDriveClientError.unknownError
        }
    }
    
    func downloadFile(file: FileMetadata) async throws -> DownloadedFile {
        switch await httpClient.call(endpoint: DownloadFileEndpoint(fileId: file.id)) {
        case .success(let data):
            return writeFileToCache(metadata: file, content: data)
        case .failure(let error):
            throw GoogleDriveClientError.endpointError(error)
        }
    }
    
    func downloadFiles(files: [String]) async throws -> [DownloadedFile] {
        var downloads = [DownloadedFile]()
        for file in files {
            let download = try await downloadFile(fileId: file)
            downloads.append(download)
        }
        return downloads
    }
    
    private func writeFileToCache(metadata: FileMetadata, content: Data) -> DownloadedFile {
        let url = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Droto-TempDowloads")
            .appendingPathComponent("\(metadata.id)_\(metadata.md5Checksum ?? "")")
        
        FileManager.default.createFile(atPath: url.absoluteString, contents: content)
        
        return DownloadedFile(file: metadata, path: url)
    }
}

enum GoogleDriveClientError: Error {
    case endpointError(Error)
    case unknownError
}

