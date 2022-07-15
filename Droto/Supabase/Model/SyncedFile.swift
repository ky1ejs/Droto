//
//  SyncedFile.swift
//  Droto
//
//  Created by Kyle Satti on 12/07/2022.
//

import Foundation

struct SyncedFile: Codable, Equatable {
    let id: String
    let syncedFolderId: String
    let photosId: String
    let photosCloudId: String
    let googleDriveId: String
    let googleDriveMd5Checksum: String
}
