//
//  SyncedFolder.swift
//  Droto
//
//  Created by Kyle Satti on 12/07/2022.
//

import Foundation

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
