//
//  MusicChartList.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/02.
//  Copyright © 2020 monireu. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftSoup

class HTMLParser {
    
    func getUpdateTime(success: ((String)->Void)? = nil, fail: ((String)->Void)? = nil) {
        let url = "https://www.melon.com/chart/index.htm"
        
        let req = AF.request(url)
        
        req.responseString() { res in
            let html = res.value
//            print(html!)
            do {
                let doc: Document = try SwiftSoup.parseBodyFragment(html!)
                
                let updateTime = try doc.getElementsByClass("hour").first()?.text()
                success?(updateTime!)
            } catch let error as NSError{
                print(error)
                let msg = "데이터를 갱신하지 못했습니다."
                fail?(msg)
            }
        }
    }
    
    func parseResult(success: (()->Void)? = nil, fail: ((String)->Void)? = nil){
        
        // 파싱시작
        let url = "https://m.app.melon.com/cds/main/mobile4web/main_chartPaging.htm"
        let userAgentString = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
        
        let header : HTTPHeaders = ["User-Agent" : "\(userAgentString)"]
        let param = [
            "startIndex" : 1,
            "pageSize" : 50,
            "rowsCnt" : 100
        ]
        
        let req = AF.request(url, parameters: param, headers: header)
        
        req.responseString() { res in
            let html = res.value
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            
            do {
                let doc: Document = try SwiftSoup.parseBodyFragment(html!)
                
                let artist       = try doc.getElementsByClass("name ellipsis")
                let title        = try doc.getElementsByClass("title ellipsis")
                let contentChart = try doc.select("div.content.chart")
                let rankChange   = try contentChart.select("span")
                let img          = try doc.getElementsByClass("img")
                

                for i in 0 ..< artist.count {
                    
                    let musicInfoObject = MusicInfoVO()
                    
                    // 곡 정보 가져오기
                    musicInfoObject.rank = String(i+1)
                    musicInfoObject.music = try title.get(i).text()
                    musicInfoObject.artist = try artist.get(i).text()
                    
                    // 순위 변동 가져오기
                    let rankStat = try rankChange.get(i).className()
                    let rankChangeVal = try rankChange.get(i).text()
                    
                    if rankStat == "sprite rank none" {
                        musicInfoObject.rankChangeStat = .no
                        musicInfoObject.rankChangeVal  = "-"
                    } else if rankStat == "sprite rank up" {
                        musicInfoObject.rankChangeStat = .up
                        musicInfoObject.rankChangeVal  = rankChangeVal
                    } else if rankStat == "sprite rank down" {
                        musicInfoObject.rankChangeStat = .down
                        musicInfoObject.rankChangeVal  = rankChangeVal
                    } else {
                        musicInfoObject.rankChangeStat = .new
                        musicInfoObject.rankChangeVal  = "NEW"
                    }
                    
                    
                    // 앨범 이미지 가져오기
                    let imgURL = try img.get(i).attr("style")
                    let startIndex = imgURL.index(imgURL.firstIndex(of: "'")!, offsetBy: 3)
                    let endIndex = imgURL.lastIndex(of:"'")
                    
                    musicInfoObject.melonAlbumImg = String(imgURL[(startIndex)..<(endIndex)!])

                    print(musicInfoObject.melonAlbumImg!)
                    appdelegate.musicChartList.append(musicInfoObject)
                }
                
                for vo in appdelegate.musicChartList {
                    print("\(vo.rank!) / \(vo.artist!) / \(vo.music!)")
                }
            } catch Exception.Error(let type, let message) {
                fail?(message)
                print("Error Occured while Parsing URL \n Details [ \nErrorType : \(type) /nErrorMessage : \(message)")
            } catch {
                print("에러가 발생했습니다.")
            }
            success?()
        }
    }
}
