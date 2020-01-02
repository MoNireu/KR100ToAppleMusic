//
//  Utils.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/02.
//  Copyright © 2020 monireu. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewController {
    func alert(_ message: String, completion: (()->Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default){ (_) in
            completion?()
        })
        self.present(alert, animated: true)
    }
}
