//
//  GoogleDriveAuth.swift
//  Droto
//
//  Created by Kyle Satti on 05/06/2022.
//

import UIKit
import AuthenticationServices

class GoogleDriveAuth: NSObject, AuthProvider {
    private let googleOauth: GoogleOauth
    private let keychainManager: KeychainManager
    private var currentViewController: UIViewController?
    
    init(googleOauth: GoogleOauth = GoogleOauth(), keychainManager: KeychainManager = KeychainManager()) {
        self.googleOauth = googleOauth
        self.keychainManager = keychainManager
    }
    
    func isAuthenticated() -> Bool {
        return keychainManager.getGoogleAuthCredentials() != nil
    }
    
    func authenticate(presentingViewController: UIViewController) async -> Bool {
        currentViewController = presentingViewController
        
        return await withCheckedContinuation({ continuation in
            DispatchQueue.main.async { [unowned self] in
                
                let session = self.googleOauth.createAuthSession { response in
                switch response {
                case .success:
                    continuation.resume(returning: true)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
            session.presentationContextProvider = self
            session.start()
            }
        })
    }
}

extension GoogleDriveAuth: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return currentViewController!.view.window!
    }
}
