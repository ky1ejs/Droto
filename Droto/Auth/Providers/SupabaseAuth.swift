//
//  SupabaseAuth.swift
//  Droto
//
//  Created by Kyle Satti on 05/06/2022.
//

import UIKit
import AuthenticationServices
import Supabase

class SupabaseAuth: NSObject, AuthProvider {
    private static let CLIENT: SupabaseClient = {
        let plistPath = Bundle.main.path(forResource: "supabase", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: plistPath)!
        let host = dict["host"] as! String
        let clientId = dict["client_id"] as! String
        return SupabaseClient(supabaseURL: URL(string: host)!, supabaseKey: clientId)
    }()
    
    private var client: SupabaseClient { type(of: self).CLIENT }
    private var currentViewController: UIViewController?
    
    func isAuthenticated() -> Bool {
        return client.auth.session != nil
    }
    
    func authenticate(presentingViewController: UIViewController) async -> Bool {
        currentViewController = presentingViewController
        
        return await withCheckedContinuation({ [unowned self] continuation in
    
            let url = try! client.auth.signIn(provider: .google, redirectURL: URL(string: "droto://supabase-oauth-callback")!)
                        
            DispatchQueue.main.async { [unowned self] in
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "droto") { [unowned self] callbackUrl, error in
                    guard let callbackUrl = callbackUrl else {
                        continuation.resume(returning: false)
                        return
                    }
                    Task {
                        let _ = try! await client.auth.session(from: callbackUrl.absoluteURL)
                        continuation.resume(returning: true)
                    }
                }
                session.presentationContextProvider = self
                session.start()
            }
        })
    }
}

extension SupabaseAuth: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return currentViewController!.view.window!
    }
}

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
    }
}
}
