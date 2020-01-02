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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.parsedHTML = model.parseResult()
        model.parse(html: self.parsedHTML,
                                  success: {
                                    self.alert("불러오기를 성공했습니다.")},
                                  fail: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return model.musicChartList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as? MusicChartListCell else {
                return UITableViewCell()
            }
            

        cell.rank.text   = (self.model.musicChartList[indexPath.row].rank)! + "위"
        cell.music.text  = self.model.musicChartList[indexPath.row].music
        cell.artist.text = self.model.musicChartList[indexPath.row].artist
            
        return cell
        }
}
