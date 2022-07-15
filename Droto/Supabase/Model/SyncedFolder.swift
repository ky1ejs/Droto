//
//  SyncedFolder.swift
//  Droto
//
//  Created by Kyle Satti on 12/07/2022.
//

import Foundation

struct SyncedFolder: Equatable {
    let googleDriveId: String
    let files: [SyncedFile]
    
    typealias FilesFirebaseType = [String : [String : String]]
}
