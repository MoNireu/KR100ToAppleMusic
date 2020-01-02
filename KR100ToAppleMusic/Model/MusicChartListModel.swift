//
//  MusicChartList.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/02.
//  Copyright © 2020 monireu. All rights reserved.
//

import Foundation
import Alamofire
import SwiftSoup

class MusicChartListModel {
    
    var musicChartList = [MusicInfoVO]()
    
    func parseResult(success: (()->Void)? = nil, fail: (()->Void)? = nil){
        // 파싱시작
        var result: String?
        let url = "https://m.app.melon.com/cds/main/mobile4web/main_chartPaging.htm"
        let userAgentString = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
        let header : HTTPHeaders = ["User-Agent" : "\(userAgentString)"]
        let param = [
            "startIndex" : 1,
            "pageSize" : 50,
            "rowsCnt" : 100
        ]
        
        let req = AF.request(url, parameters: param, headers: header)
        
        let resultHTML = req.responseString() { res in
            let html = res.value
            
            do {
                let doc: Document = try SwiftSoup.parseBodyFragment(html!)
                let artist = try doc.getElementsByClass("name ellipsis")
                let title = try doc.getElementsByClass("title ellipsis")
                for i in 0 ..< artist.count {
                    let musicInfo = MusicInfoVO()
                    musicInfo.rank   = String(i + 1)
                    musicInfo.music  = try title.get(i).text()
                    musicInfo.artist = try artist.get(i).text()
                    
                    self.musicChartList.append(musicInfo)
                }
                
                for vo in self.musicChartList {
                    print("\(vo.rank!) / \(vo.artist!) / \(vo.music!)")
                }
                
            } catch Exception.Error(let type, let message) {
                print("\(type) / \(message)")
            } catch {
                print("에러가 발생했습니다.")
            }
            
            success?()
            
        }
    }
    
//    self.parse(html: html,
//               success: {
//                self.performSegue(withIdentifier: "toMusicChartList", sender: self)
//                self.activityIndicator.stopAnimating()
//    })
    
}
