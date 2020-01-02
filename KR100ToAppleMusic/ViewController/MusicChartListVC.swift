//
//  MusicChartList.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/02.
//  Copyright © 2020 monireu. All rights reserved.
//

import UIKit

class MusicChartListVC: UITableViewController {

    var parsedHTML: String?
    var model = MusicChartListModel()
    var jwtModel = JWTModel()
    
    var userToken: String?
    var storeFront: String?
    
    @IBOutlet var createBtn: UIBarButtonItem!
    
    @IBAction func createAction(_ sender: Any) {
        jwtModel.requestCloudServiceAuthorization() { res in
            self.userToken = res
        }
        jwtModel.requestStoreFront() { res in
            self.storeFront = res
        }
        jwtModel.searchMusic(storeFront: self.storeFront, musicChart: model.musicChartList)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        model.parseResult(success: {
            self.alert("총 \(self.model.musicChartList.count)개의 불러오기를 성공했습니다.")
            self.tableView.reloadData()
        }, fail: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return model.musicChartList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "chart_cell", for: indexPath) as? MusicChartListCell else {
                print("error")
                return UITableViewCell()
                
            }
            

        cell.rank.text   = ((self.model.musicChartList[indexPath.row].rank)! as String) + "위"
        cell.rank.sizeToFit()
        cell.music.text  = self.model.musicChartList[indexPath.row].music as String?
        cell.artist.text = self.model.musicChartList[indexPath.row].artist as String?
            
        return cell
        }
}
