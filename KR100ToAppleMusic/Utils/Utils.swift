//
//  Utils.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/02.
//  Copyright © 2020 monireu. All rights reserved.
//

import Foundation
import UIKit
import StoreKit
import Alamofire

//extension UITableViewController {
//    func okAlert(_ message: String, completion: (()->Void)? = nil) {
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "확인", style: .default){ (_) in
//            completion?()
//        })
//        self.present(alert, animated: true)
//    }
//    
//    func errorAlert(_ message: String, completion: (()->Void)? = nil) {
//        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "확인", style: .default){ (_) in
//            completion?()
//        })
//        self.present(alert, animated: true)
//    }
//    
//    func alert(_ message: String, completion: (()->Void)? = nil) {
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "확인", style: .default){ (_) in
//            completion?()
//        })
//        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
//        self.present(alert, animated: true)
//    }
//}

extension UIViewController {
    func okAlert(_ message: String, completion: (()->Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default){ (_) in
            completion?()
        })
        self.present(alert, animated: true)
    }
    
    func errorAlert(_ message: String, completion: (()->Void)? = nil) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default){ (_) in
            completion?()
        })
        self.present(alert, animated: true)
    }
    
    func alert(title:String? = nil, message: String? = nil, completion: (()->Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default){ (_) in
            completion?()
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        self.present(alert, animated: true)
    }
}




class TokenUtils {
    func save(_ service: String,  account: String, value: String) {
        let keyChainQuery: NSDictionary = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : service,
            kSecAttrAccount : account,
            kSecValueData : value.data(using: .utf8)
        ]
        
        SecItemDelete(keyChainQuery)
        
        let status: OSStatus = SecItemAdd(keyChainQuery, nil)
        assert(status == noErr, "토큰 값 저장에 실패했습니다.")
        NSLog("status = \(status)")
    }
    
    func load(_ service: String, account: String) -> String? {
        let keyChainQuery: NSDictionary = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : service,
            kSecAttrAccount : account,
            kSecReturnData : kCFBooleanTrue,
            kSecMatchLimit : kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(keyChainQuery, &dataTypeRef)
        
        if (status == errSecSuccess) {
            let retrievedData = dataTypeRef as! Data
            let value = String(data: retrievedData, encoding: .utf8)
            return value
        } else {
            print("Nothing was retrieved from the keychain. Status code \(status)")
            return nil
        }
    }
}
