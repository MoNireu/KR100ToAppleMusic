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
    let devToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjQ3NVlHSDc4ODcifQ.eyJpc3MiOiJUQldRVFk5UFZVIiwiaWF0IjoxNTc4NTUwMTUzLCJleHAiOjE1Nzg1OTMzNTN9.rpwbuSswlpKOdmsYhkbN7CKGk4DpgOXteZWi0pulBKKLF3-gfl2W7B8HQOgD7tGda9eeK7p8e3VpRIgWwuS9RQ"
    
    func requestCloudServiceAuthorization(fail: ((String)->Void)? = nil, success :(()->Void)? = nil) {
        
        // 인증 상태 체크
        guard SKCloudServiceController.authorizationStatus() == .notDetermined else {
            print("Success: Already Authorized")
            success?()
            return
        }
        
        // 미인증의 경우 실행되는 인증 요청 코드
        SKCloudServiceController.requestAuthorization { authorizationStatus in
            switch authorizationStatus {
            case .authorized:
                self.requestUserToken(forDeveloperToken: self.devToken) { userToken, err in
                    if userToken == nil {
                        print("Error: Failed requesting User Token. Details - \(err!)")
                        let msg = "인증 과정 중 오류가 발생하였습니다."
                        fail?(msg)
                    } else {
                        let tokenUtils = TokenUtils()
                        // User Token 저장
                        tokenUtils.save("monireu.KR100ToAppleMusic", account: "userToken", value: userToken!)
                        print("Success : Requesting User Token. Details")
                        success?()
                    }
                }
            default:
                break
            }
        }
    }
    
    
    func requestCountryCode(fail :((String)->Void)? = nil, success: (()->Void)? = nil) {
        self.requestStorefrontCountryCode() { countryCode, err in
            if countryCode == nil {
                print("Error: Failed requesting CountryCode. Details - \(err!)")
                let msg = "국가코드를 불러오는 중 오류가 발생했습니다."
                fail?(msg)
            } else {
                print("Success : Requesting CountryCode. Details")
                let tokenUtils = TokenUtils()
                tokenUtils.save("monireu.KR100ToAppleMusic", account: "countryCode", value: countryCode!)
                success?()
            }
        }
    }
    
    // TODO: - Connect Request param with MusicInfoVO
    func searchMusic(musicChart: [MusicInfoVO]) {
        let tokenUtils = TokenUtils()
        
        guard let countryCode = tokenUtils.load("monireu.KR100ToAppleMusic",account: "countryCode") else {
            print("ERROR: Failed loading storeFront")
            return
        }
        let url = "https://api.music.apple.com/v1/catalog/\(countryCode)/search"
        
        guard let userToken = tokenUtils.load("monireu.KR100ToAppleMusic",account: "userToken") else {
            print("ERROR: Failed loading userToken")
            return
        }
        let header: HTTPHeaders = [
            "Music-User-Token" : "\(userToken)",
            "Authorization": "Bearer \(devToken)"
        ]
        
        /*
         이후에 오는 반복 구문안에 들어가야할 코드들
         - 
         */
        for i in 0 ..< musicChart.count - 98 {
            
            let modifiedArtistString = musicChart[i].artist?.replacingOccurrences(of: " ", with: "+")
            let modifiedMusicString = musicChart[i].music?.replacingOccurrences(of: " ", with: "+")
            
            let param : Parameters = [
                "term" : "\(modifiedArtistString!)+\(modifiedMusicString!)",
                "limit" : 1,
                "types" : "songs"
            ]
            
            let call = AF.request(url, method: .get, parameters: param, encoding: URLEncoding.default, headers: header)
            
            
            let jsonObject = call.responseData() { res in
                print("Failed: \(res.result)")
            }
        }
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
