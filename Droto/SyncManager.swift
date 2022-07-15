//
//  SyncManager.swift
//  Droto
//
//  Created by Kyle Satti on 05/06/2022.
//

import Foundation
import Photos
import Supabase

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
        let driveFiles = await driveClient.getContentsOfFolder(folder: .file(googleFolderDriveId))
        
        let syncedFolder: SupabaseSyncedFolder = try await supabaseClient.database
            .from("synced_folders")
            .upsert(
                values: NewSyncedFolder(googleDriveId: googleFolderDriveId),
                returning: .representation)
            .execute()
            .decoded()
        
        let syncedFiles: [SyncedFile] = try await supabaseClient.database
            .from("synced_files")
            .select()
            .match(query: ["syned_folder_id" : "= '\(syncedFolder.id)"])
            .execute()
            .decoded()
            
        var syncedFilesByDriveId = [String : SyncedFile]()
        syncedFiles.forEach { file in syncedFilesByDriveId[file.googleDriveId] = file }
        
        var filesToUpdate = [SyncedFile]()
        var filesNoop = [SyncedFile]()
        var filesToCreate = [FileMetadata]()
        
        switch driveFiles {
        case .success(let data):
            data.files.forEach({driveFile in
                if let syncedFile = syncedFilesByDriveId[driveFile.id] {
                    if syncedFile.googleDriveMd5Checksum != driveFile.md5Checksum {
                        filesToUpdate.append(syncedFile)
                    } else {
                        filesNoop.append(syncedFile)
                    }
                } else {
                    filesToCreate.append(driveFile)
                }
            })
            let addPhotos = try await driveClient.downloadFiles(files: filesToCreate.map { $0.id })
            try await photoManager.add(photos: addPhotos)
            // TODO: need to get the IDs returned so that we can add them the database 👆
            
            let filesToDelete = syncedFiles.filter { !filesNoop.contains($0) && !filesToUpdate.contains($0) }
            try await photoManager.delete(photosIds: filesToDelete.map { $0.photosId })
            
            var updates = [(PHAsset, DownloadedFile)]()
            for syncedPhoto in filesToUpdate {
                let asset = PHAsset.fetchAssets(withLocalIdentifiers: [syncedPhoto.photosId], options: nil).firstObject!
                let file: DownloadedFile = try await driveClient.downloadFile(fileId: syncedPhoto.googleDriveId)
                updates.append((asset, file))
            }
            return true
        case .failure:
            return false
        }
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
