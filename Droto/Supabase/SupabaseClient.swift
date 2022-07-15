//
//  SupabaseClient.swift
//  Droto
//
//  Created by Kyle Satti on 14/07/2022.
//

import Foundation
import Supabase

extension SupabaseClient {
    convenience init() {
        let plistPath = Bundle.main.path(forResource: "supabase", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: plistPath)!
        let host = URL(string: dict["host"] as! String)!
        let clientId = dict["client_id"] as! String
        self.init(supabaseURL: host, supabaseKey: clientId)
    }
    
    func getSyncedFolder(with googleFolderDriveId: String) async throws -> SupabaseSyncedFolder {
    return try await database
        .from("synced_folders")
        .upsert(
            values: NewSyncedFolder(googleDriveId: googleFolderDriveId),
            returning: .representation)
        .execute()
        .decoded()
    }
    
    func getSyncedFiles(in syncedFolder: SupabaseSyncedFolder) async throws -> [SyncedFile] {
        return try await database
            .from("synced_files")
            .select()
            .match(query: ["syned_folder_id" : "= '\(syncedFolder.id)"])
            .execute()
            .decoded()
    }
    
    func create(_ syncedFile: NewSyncedFile) async throws {
        try await database
            .from("synced_files")
            .insert(values: syncedFile)
            .execute()
    }
}
