//
//  AuthCoordinator.swift
//  Droto
//
//  Created by Kyle Satti on 05/06/2022.
//

import UIKit

class AuthCoordinator {
    private let authentications: [AuthProvider]
    
    init(authentications: [AuthProvider] = [FirebaseAuth(), GoogleDriveAuth()]) {
        self.authentications = authentications
    }
    
    func appIsAuthorised() -> Bool {
        return !authentications.map({a in a.isAuthenticated()}).contains(false)
    }
    
    func authenticate(presentingViewController: UIViewController) async ->  Bool {
        let unauthenticated = authentications.filter({!$0.isAuthenticated()})
        
        guard !unauthenticated.isEmpty else { return true }
        
        for auth in unauthenticated {
            if await !auth.authenticate(presentingViewController: presentingViewController) {
                return false
            }
        }
        
        return true
    }
}
