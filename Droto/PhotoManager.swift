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
    
    func add(photos: [DownloadedFile]) async throws {
        try await authIfNeeded()
        
        try await PHPhotoLibrary.shared().performChanges {
            let creation = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            for photo in photos {
                creation.addResource(with: .photo, fileURL: photo.path, options: options)
            }
        }
    }
    
    func update(assetsAndNewPhotos: [(PHAsset, DownloadedFile)]) async throws {
        try await authIfNeeded()
        
        for update in assetsAndNewPhotos {
            update.0.requestContentEditingInput(with: nil) { input, _ in
                PHPhotoLibrary.shared().performChanges({
                    let contentEditingOutput = PHContentEditingOutput(contentEditingInput: input!)
                    try! FileManager.default.moveItem(at: update.1.path, to: contentEditingOutput.renderedContentURL)
                    let request = PHAssetChangeRequest(for: update.0)
                    request.contentEditingOutput = contentEditingOutput
                    
                })
            }
        }
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
}
