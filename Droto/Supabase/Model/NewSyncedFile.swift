//
//  NewSyncedFile.swift
//  Droto
//
//  Created by Kyle Satti on 15/07/2022.
//

import Foundation

struct NewSyncedFile: Encodable, Equatable {
    let syncedFolderId: String
    let photosId: String
    let photosCloudId: String
    let googleDriveId: String
    let googleDriveMd5Checksum: String
}
