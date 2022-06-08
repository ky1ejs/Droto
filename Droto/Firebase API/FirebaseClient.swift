//
//  FirebaseClient.swift
//  Droto
//
//  Created by Kyle Satti on 06/06/2022.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

struct FirebaseClient {
    func fetchSyncFolders() async -> [SyncedFolder] {
        let userId = Auth.auth().currentUser!.uid
        let ref = Database.database().reference()
        
        do {
            let snapshot = try await ref.child("user_data").child("\(userId)/synced_folders/").getData() as! [String : SyncedFolder.FilesFirebaseType]
            return snapshot.map(SyncedFolder.from)
        } catch {
            return []
        }
    }
    
    
}

struct SyncedFolder {
    let googleDriveId: String
    let files: [SyncedFile]
    
    typealias FilesFirebaseType = [String : [String : String]]
    
    static func from(googleDriveId: String, files: FilesFirebaseType) -> SyncedFolder {
        return SyncedFolder(
            googleDriveId: googleDriveId,
            files: files.map(SyncedFile.from))
    }
}


struct SyncedFile {
    let id: String
    let photosId: String
    let photosCloudId: String
    let googleDriveId: String
    let googleDriveMd5Checksum: String
    
    static func from(id: String, snapshot: [String : String]) -> SyncedFile {
        return SyncedFile(
            id: id,
            photosId: snapshot["photos_app_id"]!,
            photosCloudId: snapshot["photos_app_cloud_id"]!,
            googleDriveId: snapshot["google_drive_id"]!,
            googleDriveMd5Checksum: snapshot["google_drive_md5_checksum"]!
        )
    }
}
