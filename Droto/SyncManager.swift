//
//  SyncManager.swift
//  Droto
//
//  Created by Kyle Satti on 05/06/2022.
//

import Foundation
import Photos
import Supabase
import Combine

class SyncManager {
    typealias GoogleFileID = String
    typealias PhotosId = String
    
    private var syncedItems = [GoogleFileID : PhotosId]()
    private let driveClient: GoogleDriveClient
    private let supabaseClient: SupabaseClient
    private let photoManager = PhotoManager()
    
    init(driveClient: GoogleDriveClient, supabaseClient: SupabaseClient) {
        self.driveClient = driveClient
        self.supabaseClient = supabaseClient
    }
    
    // TODO: on launch check for diffs and ask user if you can store the changes
    
    func sync(folder googleFolderDriveId: String) async throws -> Bool {
        // Sources
        /* TODO: is it possible to query PHPhotoLibrary based on some metadata field or by photos we created?
         * it appears that PHFetchOptions don't allow you to do that. The reason this would be helpful is that
         * Supabase doesn't handle offline writes (I need to double check this). The other option is to go
         * back to Firebase.
         */
        let driveFiles = await driveClient.getContentsOfFolder(folder: .file(googleFolderDriveId))
        let syncedFolder = try await supabaseClient.getSyncedFolder(with: googleFolderDriveId)
        let syncedFiles = try await supabaseClient.getSyncedFiles(in: syncedFolder)
        
        switch driveFiles {
        case .success(let data):
            // TODO: is there a better way to map from array to dict in Swift
            var syncedFilesByDriveId = [String : SyncedFile]()
            syncedFiles.forEach { file in syncedFilesByDriveId[file.googleDriveId] = file }
            
            let operations = sortGoogleDriveFilesIntoOperations(
                files: data.files,
                syncedFilesByDriveId: syncedFilesByDriveId
            )
            
            try await create(operations.create, in: googleFolderDriveId)
            try await photoManager.delete(photosIds: operations.delete.map { $0.photosId })
            try await update(operations.update)
            return true
        case .failure:
            return false
        }
    }
    
    private struct Operations {
        let update: [SyncedFile]
        let delete: [SyncedFile]
        let create: [FileMetadata]
    }
    
    private func sortGoogleDriveFilesIntoOperations(
        files: [FileMetadata],
        syncedFilesByDriveId: [String : SyncedFile]
    ) -> Operations {
        var update = [SyncedFile]()
        var noop = [SyncedFile]()
        var create = [FileMetadata]()
        
        files.forEach({file in
            if let syncedFile = syncedFilesByDriveId[file.id] {
                if syncedFile.googleDriveMd5Checksum != file.md5Checksum {
                    update.append(syncedFile)
                } else {
                    noop.append(syncedFile)
                }
            } else {
                create.append(file)
            }
        })
        
        let delete = syncedFilesByDriveId.values.filter { !noop.contains($0) && !update.contains($0) }
        return Operations(update: update, delete: delete, create: create)
    }
    
    private func create(_ files: [FileMetadata], in googleFolderDriveId: String) -> AnyPublisher<DownloadStatus<Void>, Error> {
        return driveClient.downloadFiles(files: files.map { $0.id })
            .map { status -> DownloadStatus<[DownloadedFile]>  in
                switch status {
                case .progressMade(let progress):
                    return .progressMade(progress)
                case .complete(let downloads):
                    return .complete(downloads)
                }
            }.flatMap { [unowned self] status -> AnyPublisher<DownloadStatus<Void>, Error> in
                switch status {
                case .progressMade(let progress):
                    let pass = PassthroughSubject<DownloadStatus<Void>, Error>()
                    pass.send(.progressMade(progress))
                    return pass.eraseToAnyPublisher()
                case .complete(let files):
                    return self.photoManager.add(photos: files).flatMap { result -> AnyPublisher<DownloadStatus<Void>, Error> in
                        return Future { [unowned self] in
                            for entry in result {
                                // TODO: would be great if we could insert multiple rows in one call
                                try await supabaseClient.create(NewSyncedFile(
                                    syncedFolderId: googleFolderDriveId,
                                    photosId: "",
                                    photosCloudId: entry.key.stringValue,
                                    googleDriveId: entry.value.file.id,
                                    googleDriveMd5Checksum: entry.value.file.md5Checksum
                                ))
                            }

                            return .complete(())
                        }.eraseToAnyPublisher()
                    }.eraseToAnyPublisher()
                }
            }.eraseToAnyPublisher()
    }
    
    private func update(_ files: [SyncedFile]) async throws {
        var updates = [(PHAsset, DownloadedFile)]()
        for syncedPhoto in files {
            // fetch asset from library
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [syncedPhoto.photosId], options: nil).firstObject!
            // download file
            let file: DownloadedFile = try await driveClient.downloadFile(fileId: syncedPhoto.googleDriveId)
            updates.append((asset, file))
        }
        // update
        try await photoManager.update(assetsAndNewPhotos: updates)
    }
    
    func delete(_ file: FileMetadata) async -> Bool {
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
    
    func state(for file: FileMetadata) -> SyncState {
        return syncedItems[file.id] == nil ? .notDownloaded : .downloaded
    }
}

extension Future where Failure == Error {
    convenience init(operation: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let output = try await operation()
                    promise(.success(output))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}

