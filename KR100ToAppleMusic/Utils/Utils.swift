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
    
    func requestCloudServiceAuthorization(complete :((String)->Void)? = nil) {
        
//        var storeFront: String?
//        var userToken: String?
        
        // 인증 상태 체크
        guard SKCloudServiceController.authorizationStatus() == .notDetermined else {
            print("Success: Authorized")
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
                        complete?(res!)
                    }
                }
            default:
                break
            }
        }
    }
    
    
    func requestStoreFront(complete :((String)->Void)? = nil) {
        guard SKCloudServiceController.authorizationStatus() == .authorized else {
            return
        }
        self.requestStorefrontCountryCode() { res, err in
            if res == nil {
                print("Error: Failed requesting StoreFront. Details - \(err!)")
            } else {
                print("Success : Requesting StoreFront. Details - \(res!)")
                complete?(res!)
            }
        }
    }
    
    // TODO: - Connect Request param with MusicInfoVO
    func searchMusic(storeFront: String?, musicChart: [MusicInfoVO]) {
        guard let storeFront = storeFront else {
            print("StoreFront 값을 전달받지 못했습니다.")
            return
        }
        let url = "https://api.music.apple.com/v1/catalog/\(storeFront)/search"
        
        for i in 0 ..< musicChart.count - 99 {
            
            let modifiedArtistString = musicChart[i].artist?.replacingOccurrences(of: " ", with: "+")
            let modifiedMusicString = musicChart[i].music?.replacingOccurrences(of: " ", with: "+")
            
            let param : Parameters = [
                "term" : "\(modifiedArtistString!)+\(modifiedMusicString!)",
                "limit" : 1,
                "types" : "songs"
            ]
            
            let call = AF.request(url, parameters: param)
            let jsonObject = call.responseJSON() { res in
                print("\(res)")
            }
        }
    }
}
