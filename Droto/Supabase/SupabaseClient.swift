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
}
