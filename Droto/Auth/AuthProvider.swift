//
//  AuthProvider.swift
//  Droto
//
//  Created by Kyle Satti on 05/06/2022.
//

import UIKit

protocol AuthProvider {
    func isAuthenticated() -> Bool
    func authenticate(presentingViewController: UIViewController) async -> Bool
}
