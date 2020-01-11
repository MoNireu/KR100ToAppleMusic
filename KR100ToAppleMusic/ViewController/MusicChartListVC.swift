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
    
    let htmlParser = HTMLParser()
    let musicSearch = MusicSearchUtil()
    let tokenUtils = TokenUtils()
    var sortStatus: SortStatus? = .showAll
    var sortedList: [MusicInfoVO]?
    
    
    @IBOutlet var createBtn: UIBarButtonItem!
    @IBOutlet var sortBtn: UIBarButtonItem!
    var actIndicatorView: UIActivityIndicatorView?
    
    @IBAction func sortAction(_ sender: Any) {
        let alert = UIAlertController(title: "test", message: "test", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "모두 보기", style: .default) { _ in
            self.sortStatus = .showAll
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "성공한 항목", style: .default) { _ in
            self.sortedList = [MusicInfoVO]()
            for list in HTMLParser.musicChartList {
                if list.isSucceed == true {
                    self.sortedList?.append(list)
                }
            }
            self.sortStatus = .showSuccess
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "실패한 항목", style: .destructive) { _ in
            self.sortedList = [MusicInfoVO]()
            for list in HTMLParser.musicChartList {
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
        
        self.view.bringSubviewToFront(actIndicatorView!)
        self.actIndicatorView?.startAnimating()
        // 인증 시도
        musicSearch.startSearching(
            fail: { msg in
                self.actIndicatorView?.stopAnimating()
                self.alert(msg)
                self.createBtn.isEnabled = true
        }, success: { msg in
            self.actIndicatorView?.stopAnimating()
            
            let alert = UIAlertController(title: "음악 탐색 완료", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default){ _ in
                self.createBtn.isEnabled = true
                self.sortBtn.isEnabled = true
                self.sortBtn.tintColor = .systemBlue
                
                self.tableView.reloadData()
            })
            self.present(alert, animated: true)
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sortBtn.tintColor = .clear
        
        actIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        actIndicatorView?.center = self.view.center
        actIndicatorView?.color = .lightGray
        actIndicatorView?.hidesWhenStopped = true
        self.view.addSubview(actIndicatorView!)
        
        htmlParser.parseResult(
            success: {
                self.alert("총 \(HTMLParser.musicChartList.count)개의 불러오기를 성공했습니다.")
                self.tableView.reloadData()
            },
            fail: { msg in
                self.alert(msg)
            }
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
         return HTMLParser.musicChartList.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard var cell = tableView.dequeueReusableCell(withIdentifier: "chart_cell", for: indexPath) as? MusicChartListCell else {
            print("error making cell")
            return UITableViewCell()
        }
        
        switch self.sortStatus {
        case .showSuccess:
            cell = makeCell(cell, list: self.sortedList!, indexPath: indexPath)
        case .showFail:
            cell = makeCell(cell, list: self.sortedList!, indexPath: indexPath, textColor: .red)
        default:
            let isCellSucceed = HTMLParser.musicChartList[indexPath.row].isSucceed
            
            if isCellSucceed == true || isCellSucceed == nil {
                cell = makeCell(cell, list: HTMLParser.musicChartList, indexPath: indexPath)
            } else {
                cell = makeCell(cell, list: HTMLParser.musicChartList, indexPath: indexPath, textColor: .red)
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
