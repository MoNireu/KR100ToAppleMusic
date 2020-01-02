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

extension UITableViewController {
    func alert(_ message: String, completion: (()->Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default){ (_) in
            completion?()
        })
        self.present(alert, animated: true)
    }
}


class JWTModel: SKCloudServiceController {
    let devToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlUyNjhKNFFQUkQifQ.eyJpc3MiOiJUQldRVFk5UFZVIiwiaWF0IjoxNTc3OTU4NTYyLCJleHAiOjE1NzgwMDE3NjJ9.dEbEtGmTtOrREPKscS-SR0Wj1bEjIZ4HcNmjukcF9yin8A473rUZ1F3Fsf6HdqVWKk2BD4-aR_yW4zfhLH8kUQ"
    var userToken: String?
    var storeFront: String?
    
    func requestCloudServiceAuthorization() {
        
        
        guard SKCloudServiceController.authorizationStatus() == .notDetermined else {
            print("Success: Authorized")
            
            self.requestStorefrontCountryCode() { res, err in
                if res == nil {
                    print("Error: Failed requesting StoreFront. Details - \(err!)")
                } else {
                    print("Success : Requesting StoreFront. Details - \(res!)")
                    self.storeFront = res
                }
            }
            
            return
        }
        
        SKCloudServiceController.requestAuthorization { authorizationStatus in
            switch authorizationStatus {
            case .authorized:
                self.requestUserToken(forDeveloperToken: self.devToken) { res, err in
                    if res == nil {
                        print("Error: Failed requesting User Token. Details - \(err!)")
                    } else {
                        print("Success : Requesting User Token. Details - \(res!)")
                        self.userToken = res
                    }
                }
            default:
                break
            }
        }
    }
    
    // TODO: - Connect Request param with MusicInfoVO
//    func searchMusic(devToken: String, storeFront: String, musicChart: [MusicInfoVO]) {
//        let url = "https://api.music.apple.com/v1/catalog/\(storeFront)/search"
//
//        let param = ["term" : "\(musicChart)"]
//
//        AF.request(<#T##url: URLConvertible##URLConvertible#>, method: <#T##HTTPMethod#>, parameters: <#T##Parameters?#>, encoding: <#T##ParameterEncoding#>, headers: <#T##HTTPHeaders?#>, interceptor: <#T##RequestInterceptor?#>)
//    }
}
