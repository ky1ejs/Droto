//
//  SyncManager.swift
//  Droto
//
//  Created by Kyle Satti on 05/06/2022.
//

import Foundation
import Photos

class SyncManager {
    typealias GoogleFileID = String
    typealias PhotosId = String
    
    private var syncedItems = [GoogleFileID : PhotosId]()
    private let driveClient: GoogleDriveClient
    
    init(driveClient: GoogleDriveClient) {
        self.driveClient = driveClient
    }
    
    func sync(file: File) async -> Bool {
        switch await driveClient.downloadFile(fileId: file.id) {
        case .success(let data):
            let result = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            
            guard result == .authorized else { return false }
            
            let photoLib = PHPhotoLibrary.shared()
            
            var id: String?
            
            do {
                try await photoLib.performChanges {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: data, options: nil)
                    id = creationRequest.placeholderForCreatedAsset!.localIdentifier
                }
                
                guard let unwrappedId = id else { return false }
                
//                let cloudIds = photoLib.cloudIdentifierMappings(forLocalIdentifiers: [unwrappedId])
//
//                switch cloudIds[unwrappedId] {
//                case .success(let cloudIdentifier):
//                    print(cloudIdentifier)
//                case .failure(let error):
//                    print(error)
//                case .none:
//                    print("none")
//                }
                
                syncedItems[file.id] = unwrappedId
                
                return true
            } catch {
                return false
            }
        case .failure:
            return false
        }
    }
    
    func delete(_ file: File) async -> Bool {
        guard let assetId = syncedItems[file.id] else { return false }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
         
        do {
            try await PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets)
            })
            syncedItems[file.id] = nil
            return true
        } catch  {
            return false
        }
    }
    
    func state(for file: File) -> SyncState {
        return syncedItems[file.id] == nil ? .notDownloaded : .downloaded
    }
}
