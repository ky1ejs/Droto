//
//  AuthViewController.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import UIKit

class AuthViewController: UIViewController {
    private let authCoordinator: AuthCoordinator
    
    init(authCoordinator: AuthCoordinator) {
        self.authCoordinator = authCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        
        let signInButton = UIButton()
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        signInButton.sizeToFit()
        signInButton.addTarget(self, action: #selector(auth), for: .touchUpInside)
        signInButton.sizeToFit()
        
        view.addSubview(signInButton)
        signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        self.view = view
    }
    
    @objc private func auth() {
        Task {
            let result = await authCoordinator.authenticate(presentingViewController: self)
            
            if !result {
                assertionFailure()
            }
            
            let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
            let delegate = windowScene.delegate as! SceneDelegate
            
            delegate.authenticated()
        }
    }
}
