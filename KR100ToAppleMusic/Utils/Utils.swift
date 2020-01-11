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


class MusicSearchUtil: SKCloudServiceController {
    let devToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjQ3NVlHSDc4ODcifQ.eyJpc3MiOiJUQldRVFk5UFZVIiwiaWF0IjoxNTc4NjUzODIyLCJleHAiOjE1Nzg2OTcwMjJ9.UNYBYWF3YiO4vmtjUUKlUgbErKpUyNhvc6pG3sv5m69_jjdOfFSApFrtOFLILkeNzqC0OLM3Sku9brEBEDW95w"
    
    var index = 0
    var failCount = 0
    
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
        
        print(header)
       
        self.searchEachMusic(musicChart: musicChart, url: url, header: header)
    }
    
    
    func searchEachMusic(musicChart: [MusicInfoVO], url: String, header: HTTPHeaders) {
//        let modifiedArtistString = (musicChart[index].artist?.replacingOccurrences(of: " ", with: "+"))!
//        let modifiedMusicString = (musicChart[index].music?.replacingOccurrences(of: " ", with: "+"))!
        
        let modifiedArtistString = modifyString(string: musicChart[index].artist)
        let modifiedMusicString = modifyString(string: musicChart[index].music)
        
        let musicInfoString: String = modifiedMusicString + " " + modifiedArtistString
        let param : [String : String] = [
            "term" : musicInfoString,
            "limit" : "1",
            "types" : "songs,artists"
        ]
        print(param)
        
        let call = AF.request(url, method: .get, parameters: param, encoding: URLEncoding.default, headers: header)
//        print(call)
        call.responseJSON() { res in
            guard let jsonObject = res.value as? NSDictionary else {
                print("Error : searchMusic() requestJSON()")
                self.failCount = 0
                return
            }
            
            let results = jsonObject["results"] as? NSDictionary
            let songs = results?["songs"] as? NSDictionary
            let data = songs?["data"] as? NSArray
            let dataObject = data?.firstObject as? NSDictionary

//            let songId = dataObject?["id"] as? String
            
            // 검색 실패
            guard let songId = dataObject?["id"] as? String else {
                print("\(self.index+1)위 : 검색결과없음")
                musicChart[self.index].isSucceed = false
                self.index += 1
                self.failCount += 1
                
                guard self.index < musicChart.count else {
                    print("실패 : \(self.failCount)개")
                    self.failCount = 0
                    return
                }
                
                self.searchEachMusic(musicChart: musicChart, url: url, header: header)
                return
            }
//            print(jsonObject)
            // 검색 성공
            print("\(self.index+1)위 : \(songId)")
            musicChart[self.index].isSucceed = true
            self.index += 1
            
            guard self.index < musicChart.count else {
                print("실패 : \(self.failCount)개")
                self.failCount = 0
                return
            }
            
            self.searchEachMusic(musicChart: musicChart, url: url, header: header)
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
