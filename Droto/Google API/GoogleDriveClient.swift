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
                let file = File(
                    id: about.rootFolderId,
                    name: "Drive",
                    mimeType: .folder,
                    thumbnailLink: nil,
                    version: "0",
                    md5Checksum: "0"
                )
                return await getContentsOfFolder(folder: .file(file))
            case let .failure(error):
                return .failure(error)
            }

        case .file(let file):
            return await httpClient.call(endpoint: ListFoldersAndImagesEndpoint(folderId: file.id))
        }
    }
    
    func downloadFile(fileId: String) async -> DownloadFileEndpoint.ReturnType {
        return await httpClient.call(endpoint: DownloadFileEndpoint(fileId: fileId))
    }
}

