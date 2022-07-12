//
//  SyncedFile.swift
//  Droto
//
//  Created by Kyle Satti on 12/07/2022.
//

import Foundation

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
