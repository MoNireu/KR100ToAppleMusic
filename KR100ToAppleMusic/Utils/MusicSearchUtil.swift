//
//  MusicSearchUtil.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/13.
//  Copyright © 2020 monireu. All rights reserved.
//

import Foundation
import UIKit
import StoreKit
import Alamofire


class MusicSearchUtil: SKCloudServiceController {
    let appdelegate = UIApplication.shared.delegate as! AppDelegate
    
    let devToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjQ3NVlHSDc4ODcifQ.eyJpc3MiOiJUQldRVFk5UFZVIiwiaWF0IjoxNTc4OTA5MTg5LCJleHAiOjE1Nzg5NTIzODl9.MtOcrMJeQCig25vp3EVEIRNaxbzkh23J4hD0J31yL5e8H1S1YPO0xgYEGWYhT1HtEPB8pwPFkOStRLTrnCMpdA"
    
    var index = 0
    var failCount = 0
    
    func startSearching(fail: ((String)->Void)? = nil, success :((AnyObject)->Void)? = nil, complete: ((String)->Void)? = nil) {
        
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
    
    
    func requestCountryCode(fail :((String)->Void)? = nil, success :((AnyObject)->Void)? = nil, complete: ((String)->Void)? = nil) {
        
        self.requestStorefrontCountryCode() { countryCode, err in
            if countryCode == nil {
                print("Error: Requesting CountryCode. Details - \(err!)") // TEST - Status Code
                let msg = "국가코드를 불러오는 중 오류가 발생했습니다."
                fail?(msg)
            } else {
                print("Success : Requesting CountryCode.") // TEST - Status Code
                let tokenUtils = TokenUtils()
                tokenUtils.save("monireu.KR100ToAppleMusic", account: "countryCode", value: countryCode!)
                self.startSearch(fail: fail, success: success, complete: complete)
            }
        }
    }
    
    
    // TODO: - Connect Request param with MusicInfoVO
    func startSearch(keyWord: String? = nil, fail :((String)->Void)? = nil, success :((AnyObject)->Void)? = nil, complete: ((String)->Void)? = nil) {
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
       
        if keyWord == nil {
            self.searchEachMusic(url: url, header: header, fail: fail, success: success, complete: complete)
        } else {
            self.searchOneMusic(url: url, header: header, keyWord: keyWord!, fail: fail, success: success, complete: complete)
        }
    }
    
    
    func searchEachMusic(url: String, header: HTTPHeaders, fail :((String)->Void)? = nil, success :((AnyObject)->Void)? = nil, complete: ((String)->Void)? = nil) {
        // 이미 탐색 성공한 항목일 경우에는 재탐색에서 제외.
        guard self.appdelegate.musicChartList[index].isSucceed != true else {
            index += 1
            return
        }
        
        let modifiedArtistString = modifyString(string: appdelegate.musicChartList[index].artist)
        let modifiedMusicString  = modifyString(string: appdelegate.musicChartList[index].music)
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
                self.appdelegate.musicChartList[self.index].isSucceed = true
                self.appdelegate.musicChartList[self.index].musicID = songId
                self.index += 1
                success?(Float(self.index) as AnyObject)
            // 검색 실패
            } else {
                print("\(self.index+1)위 : 검색결과없음")
                self.appdelegate.musicChartList[self.index].isSucceed = false
                self.index += 1
                self.failCount += 1
                success?(Float(self.index) as AnyObject)
            }
            
            // 탐색 종료
            guard self.index < self.appdelegate.musicChartList.count else {
                let msg = "총 \(self.appdelegate.musicChartList.count)곡의 탐색이 완료되었습니다.\n성공 : \(self.appdelegate.musicChartList.count - self.failCount)\n실패 : \(self.failCount)"
                complete?(msg)
                print("탐색 종료\n실패 : \(self.failCount)개")
                self.failCount = 0
                return
            }
            self.searchEachMusic(url: url, header: header, fail: fail, success: success, complete: complete)
            return
        }
    }
    
    
    func searchOneMusic(url: String, header: HTTPHeaders, keyWord: String, fail :((String)->Void)? = nil, success :((AnyObject)->Void)? = nil, complete: ((String)->Void)? = nil) {
        
        let param : [String : String] = [
            "term" : keyWord,
            "limit" : "7",
            "types" : "songs"
        ]
        
        let call = AF.request(url, method: .get, parameters: param, encoding: URLEncoding.default, headers: header)
        call.responseJSON(){ res in
            guard let jsonObject = res.value as? NSDictionary else {
                let msg = "잘못된 응답형식입니다."
                fail?(msg)
                print("Error : searchMusic() requestJSON()")
                return
            }
            
            
            let results = jsonObject["results"] as? NSDictionary
            let songs = results?["songs"] as? NSDictionary
            let data = songs?["data"] as? NSArray
            
            for list in data! {
                let dataObject = list as? NSDictionary
                let attributes = dataObject?["attributes"] as? NSDictionary
                
                let musicID    = dataObject?["id"] as! String
                let artistName = attributes?["artistName"] as! String
                let music      = attributes?["name"] as! String
                
                let artwork = attributes?["artwork"] as! NSDictionary
                let url = artwork["url"] as! String
                
                let startIndex = url.startIndex
                let endIndex = url.index(url.endIndex, offsetBy: -14)
                let imgURL = String(url[startIndex..<endIndex])
                
                let manualSearchMusicInfo = ManualSearchMusicInfoVO()
                
                manualSearchMusicInfo.musicID = musicID
                manualSearchMusicInfo.artist  = artistName
                manualSearchMusicInfo.music   = music
                manualSearchMusicInfo.imgURL  = imgURL
                
                let img = URL(string: imgURL + "50x50bb.jpeg")
                manualSearchMusicInfo.img = try! UIImage(data: Data(contentsOf: img!))
                
                success?(manualSearchMusicInfo)
            }
            let msg = "완료"
            complete?(msg)
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
