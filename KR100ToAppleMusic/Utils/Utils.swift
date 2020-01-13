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
    
    func errorAlert(_ message: String, completion: (()->Void)? = nil) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default){ (_) in
            completion?()
        })
        self.present(alert, animated: true)
    }
}


class MusicSearchUtil: SKCloudServiceController {
    let devToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjQ3NVlHSDc4ODcifQ.eyJpc3MiOiJUQldRVFk5UFZVIiwiaWF0IjoxNTc4NzM0NDE4LCJleHAiOjE1Nzg3Nzc2MTh9.ft3eH0nGNb9AIzu3GDkpob57ufaXLU1gyUxM4Sh68uSeH0uaN777qDz4Celx3QETRdsbfR6emEU15Gu4s6CG7w"
    
    var index = 0
    var failCount = 0
    
    func startSearching(fail: ((String)->Void)? = nil, success :((Float)->Void)? = nil, complete: ((String)->Void)? = nil) {
        
        // 인증 상태 체크
        guard SKCloudServiceController.authorizationStatus() == .notDetermined else {
            print("Success: Already Authorized")
            self.requestCountryCode(fail: fail, success: success, complete: complete)
            return
        }
        
        // 미인증의 경우 실행되는 인증 요청 코드
        SKCloudServiceController.requestAuthorization { authorizationStatus in
            switch authorizationStatus {
            case .authorized:
                self.requestUserToken(forDeveloperToken: self.devToken) { userToken, err in
                    if userToken == nil {
                        print("Error: Requesting User Token. Details - \(err!)") // TEST - Status Code
                        let msg = "인증 과정에서 오류가 발생하였습니다."
                        fail?(msg)
                    } else {
                        let tokenUtils = TokenUtils()
                        // User Token 저장
                        tokenUtils.save("monireu.KR100ToAppleMusic", account: "userToken", value: userToken!)
                        print("Success : Requesting User Token.") // TEST - Status Code
                        self.requestCountryCode(fail: fail, success: success, complete: complete)
                    }
                } // END of self.requestUserToken() Closure
            default:
                break
            } // END of switch statement
        }
    }
    
    
    func requestCountryCode(fail :((String)->Void)? = nil, success :((Float)->Void)? = nil, complete: ((String)->Void)? = nil) {
        
        self.requestStorefrontCountryCode() { countryCode, err in
            if countryCode == nil {
                print("Error: Requesting CountryCode. Details - \(err!)") // TEST - Status Code
                let msg = "국가코드를 불러오는 중 오류가 발생했습니다."
                fail?(msg)
            } else {
                print("Success : Requesting CountryCode.") // TEST - Status Code
                let tokenUtils = TokenUtils()
                tokenUtils.save("monireu.KR100ToAppleMusic", account: "countryCode", value: countryCode!)
                self.searchMusic(fail: fail, success: success, complete: complete)
            }
        }
    }
    
    
    // TODO: - Connect Request param with MusicInfoVO
    func searchMusic(fail :((String)->Void)? = nil, success :((Float)->Void)? = nil, complete: ((String)->Void)? = nil) {
        let tokenUtils = TokenUtils()
        
        
        guard let countryCode = tokenUtils.load("monireu.KR100ToAppleMusic",account: "countryCode") else {
            let msg = "국가 코드를 불러오는중 오류가 발생하였습니다."
            fail?(msg)
            print("ERROR: Failed loading storeFront")
            return
        }
        let url = "https://api.music.apple.com/v1/catalog/\(countryCode)/search"
        
        guard let userToken = tokenUtils.load("monireu.KR100ToAppleMusic",account: "userToken") else {
            let msg = "유저 인증에 실패하였습니다."
            fail?(msg)
            print("ERROR: Failed loading userToken")
            return
        }
        let header: HTTPHeaders = [
            "Music-User-Token" : "\(userToken)",
            "Authorization": "Bearer \(devToken)"
        ]
        
        print(header)
       
        self.searchEachMusic(url: url, header: header, fail: fail, success: success, complete: complete)
    }
    
    
    func searchEachMusic(url: String, header: HTTPHeaders, fail :((String)->Void)? = nil, success :((Float)->Void)? = nil, complete: ((String)->Void)? = nil) {
        
        let modifiedArtistString = modifyString(string: HTMLParser.musicChartList[index].artist)
        let modifiedMusicString  = modifyString(string: HTMLParser.musicChartList[index].music)
        let musicInfoString: String = modifiedMusicString + " " + modifiedArtistString
        
        let param : [String : String] = [
            "term" : musicInfoString,
            "limit" : "1",
            "types" : "songs,artists"
        ]
        print(param)
        
        let call = AF.request(url, method: .get, parameters: param, encoding: URLEncoding.default, headers: header)

        call.responseJSON() { res in
            guard let jsonObject = res.value as? NSDictionary else {
                let msg = "잘못된 응답형식입니다."
                fail?(msg)
                print("Error : searchMusic() requestJSON()")
                self.failCount = 0
                return
            }
            
            let results = jsonObject["results"] as? NSDictionary
            let songs = results?["songs"] as? NSDictionary
            let data = songs?["data"] as? NSArray
            let dataObject = data?.firstObject as? NSDictionary
            
            // 검색 성공
            if let songId = dataObject?["id"] as? String {
                print("\(self.index+1)위 : \(songId)")
                HTMLParser.musicChartList[self.index].isSucceed = true
                self.index += 1
                success?(Float(self.index))
                // 검색 실패
            } else {
                print("\(self.index+1)위 : 검색결과없음")
                HTMLParser.musicChartList[self.index].isSucceed = false
                self.index += 1
                self.failCount += 1
                success?(Float(self.index))
            }
            
            // 탐색 종료
            guard self.index < HTMLParser.musicChartList.count else {
                let msg = "총 \(HTMLParser.musicChartList.count)곡의 탐색이 완료되었습니다.\n성공 : \(HTMLParser.musicChartList.count - self.failCount)\n실패 : \(self.failCount)"
                complete?(msg)
                print("탐색 종료\n실패 : \(self.failCount)개")
                self.failCount = 0
                return
            }
            self.searchEachMusic(url: url, header: header, fail: fail, success: success, complete: complete)
            return
        }
    }
    
    func modifyString(string: String?) -> String {
        let string = (string?.replacingOccurrences(of: " ", with: " "))!

        let index = string.lastIndex(of: "(") ?? string.endIndex
        if index != string.endIndex { // "("가 존재할 경우
            if string.startIndex != index && string[string.index(before: index)] == " " {
                return String(string[..<string.index(before: index)])
            }
        }
        
        return String(string[..<string.endIndex])
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
