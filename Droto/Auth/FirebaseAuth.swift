//
//  FirebaseAuth.swift
//  Droto
//
//  Created by Kyle Satti on 05/06/2022.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct FirebaseAuth: AuthProvider {
    func isAuthenticated() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    func authenticate(presentingViewController: UIViewController) async -> Bool {
        let clientID = FirebaseApp.app()!.options.clientID!
        let config = GIDConfiguration(clientID: clientID)
        
        return await withCheckedContinuation({ continuation in
            GIDSignIn.sharedInstance.signIn(with: config, presenting: presentingViewController) { user, error in
                guard let authentication = user?.authentication, let idToken = authentication.idToken else {
                    continuation.resume(returning: false)
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: authentication.accessToken)
                
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    continuation.resume(returning: true)
                }
            }
        })
    }
}
