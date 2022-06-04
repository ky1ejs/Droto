//
//  UITableView+Utils.swift
//  Droto
//
//  Created by Kyle Satti on 04/06/2022.
//

import Foundation
import UIKit

extension UITableView {
    func register<C: UITableViewCell>(type: C.Type) {
        register(type, forCellReuseIdentifier: type.identifier)
    }
    
    func dequeue<C: UITableViewCell>(type: C.Type) -> C {
        return dequeueReusableCell(withIdentifier: type.identifier) as! C
    }
}

extension UITableViewCell {
    static var identifier: String { return String(describing: self) }
}
