//
//  PhotoManager.swift
//  Droto
//
//  Created by Kyle Satti on 13/07/2022.
//

import Foundation
import Photos

class PhotoManager {
    typealias PhotoKitLocalId = String
    
    func add(photos: [DownloadedFile]) async throws -> [PHCloudIdentifier : DownloadedFile] {
        try await authIfNeeded()
        
        var localIdsAndFiles = [PhotoKitLocalId : DownloadedFile]()
        try await PHPhotoLibrary.shared().performChanges {
            for photo in photos {
                let newPhoto = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: photo.path)
                let photoKitId = newPhoto!.placeholderForCreatedAsset!.localIdentifier
                localIdsAndFiles[photoKitId] = photo
            }
        }
        
        let cloudIds = PHPhotoLibrary.shared().cloudIdentifierMappings(forLocalIdentifiers: Array(localIdsAndFiles.keys))
        var cloudIdsAndFiles = [PHCloudIdentifier : DownloadedFile]()
        for entry in cloudIds {
            switch entry.value {
            case .success(let cloudId):
                cloudIdsAndFiles[cloudId] = localIdsAndFiles[entry.key]
            case .failure(let error):
                throw error
            }
        }
        
        return cloudIdsAndFiles
    }
    
    func update(assetsAndNewPhotos: [(PHAsset, DownloadedFile)]) async throws {
        try await authIfNeeded()
        
        try await PHPhotoLibrary.shared().performChanges({
            for update in assetsAndNewPhotos {
                update.0.requestContentEditingInput(with: nil) { input, _ in
                    
                    let contentEditingOutput = PHContentEditingOutput(contentEditingInput: input!)
                    try! FileManager.default.moveItem(at: update.1.path, to: contentEditingOutput.renderedContentURL)
                    let request = PHAssetChangeRequest(for: update.0)
                    request.contentEditingOutput = contentEditingOutput
                }
            }
        })
    }
    
    func delete(photosIds: [PhotoKitLocalId]) async throws {
        try await authIfNeeded()
        
        let assetsToDelete = PHAsset.fetchAssets(withLocalIdentifiers: photosIds, options: nil)
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete)
        }
    }
    
    private func authIfNeeded() async throws {
        var authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if authStatus == .notDetermined {
            authStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        
        guard authStatus == .authorized else {
            throw PhotoManagerError.unauthroized
        }
    }
}

enum PhotoManagerError: Error {
    case unauthroized
    case missingProxyObject
}
