//
//  MusicChartList.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/02.
//  Copyright © 2020 monireu. All rights reserved.
//

import UIKit

enum SortStatus: Int {
    case showAll = 0
    case showSuccess = 1
    case showFail = 2
}


class MusicChartListVC: UITableViewController {
    
    let model = MusicChartListModel()
    let jwtModel = JWTModel()
    let tokenUtils = TokenUtils()
    var sortStatus: SortStatus? = .showAll
    var sortedList: [MusicInfoVO]?
    
    @IBOutlet var createBtn: UIBarButtonItem!
    @IBOutlet var sortBtn: UIBarButtonItem!
    
    @IBAction func sortAction(_ sender: Any) {
        let alert = UIAlertController(title: "test", message: "test", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "모두 보기", style: .default) { _ in
            self.sortStatus = .showAll
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "성공한 항목", style: .default) { _ in
            self.sortedList = [MusicInfoVO]()
            for list in self.model.musicChartList {
                if list.isSucceed == true {
                    self.sortedList?.append(list)
                }
            }
            self.sortStatus = .showSuccess
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "실패한 항목", style: .default) { _ in
            self.sortedList = [MusicInfoVO]()
            for list in self.model.musicChartList {
                if list.isSucceed == false {
                    self.sortedList?.append(list)
                }
            }
            self.sortStatus = .showFail
            self.tableView.reloadData()
        })
        
        self.present(alert, animated: true)
    }
    
    @IBAction func createAction(_ sender: Any) {
        self.createBtn.isEnabled = false
        // 인증 시도
        jwtModel.requestCloudServiceAuthorization(
            fail: { msg in
                self.alert(msg)
        },
            success: {
                self.jwtModel.requestCountryCode(
                    fail: { msg in
                        self.alert(msg)
                },
                    success: {
                        self.jwtModel.searchMusic(musicChart: self.model.musicChartList)
                        DispatchQueue.main.async {
                            self.sortBtn.isEnabled = true
                            self.sortBtn.tintColor = .systemBlue
                        }
                }
                )
        }
        )
        self.createBtn.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sortBtn.tintColor = .clear
        model.parseResult(
            success: {
                self.alert("총 \(self.model.musicChartList.count)개의 불러오기를 성공했습니다.")
                self.tableView.reloadData()
        },
            fail: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sortStatus {
        case .showSuccess:
            return self.sortedList!.count
        case .showFail:
            return self.sortedList!.count
        default:
         return model.musicChartList.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard var cell = tableView.dequeueReusableCell(withIdentifier: "chart_cell", for: indexPath) as? MusicChartListCell else {
            print("error making cell")
            return UITableViewCell()
        }
        
//        guard isCellSucceed != nil else { // Apple Music 검색 이전일 경우 모두 출력
//            cell = makeCell(cell, indexPath: indexPath)
//            return cell
//        }
        
        switch self.sortStatus {
        case .showSuccess:
            cell = makeCell(cell, list: self.sortedList!, indexPath: indexPath)
        case .showFail:
            cell = makeCell(cell, list: self.sortedList!, indexPath: indexPath, textColor: .red)
        default:
            let isCellSucceed = self.model.musicChartList[indexPath.row].isSucceed
            
            if isCellSucceed == true || isCellSucceed == nil {
                cell = makeCell(cell, list: self.model.musicChartList, indexPath: indexPath)
            } else {
                cell = makeCell(cell, list: self.model.musicChartList, indexPath: indexPath, textColor: .red)
            }
        }
        return cell
    }
    
    func makeCell(_ cell: MusicChartListCell, list: [MusicInfoVO], indexPath: IndexPath, textColor: UIColor = .label) -> MusicChartListCell {
        cell.rank.text   = ((list[indexPath.row].rank)! as String) + "위"
        cell.rank.sizeToFit()
        cell.rank.textColor = textColor
        cell.music.text  = list[indexPath.row].music as String?
        cell.music.textColor = textColor
        cell.artist.text = list[indexPath.row].artist as String?
        cell.artist.textColor = textColor
        
        return cell
    }
}
