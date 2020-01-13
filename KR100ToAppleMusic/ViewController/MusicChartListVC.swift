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
    
    @IBOutlet var createBtn: UIBarButtonItem!
    @IBOutlet var sortBtn: UIBarButtonItem!
    
    var actIndicatorView: UIActivityIndicatorView?
    var customToolBarView: UIView?
    var progressBar: UIProgressView?
    var progressLabel: UILabel?
    
    
    let htmlParser = HTMLParser()
    let musicSearch = MusicSearchUtil()
    let tokenUtils = TokenUtils()
    var sortStatus: SortStatus? = .showAll
    var sortedList: [MusicInfoVO]?
    
    
    @IBAction func sortAction(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
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
        
        // 로딩창 생성
        showLoading()
        
        // 인증 시도
        musicSearch.startSearching(
            fail: { msg in
                self.actIndicatorView?.stopAnimating()
                self.alert(msg)
                self.createBtn.isEnabled = true
            },
            success: { count in
                self.progressLabel?.text     = "총 \(HTMLParser.musicChartList.count)곡 중 \(Int(count))곡 완료 "
                self.progressLabel?.sizeToFit()
                self.progressLabel?.center.x = (self.customToolBarView?.center.x)!
                
                self.progressBar?.setProgress((count / Float(HTMLParser.musicChartList.count)), animated: true)
            },
            complete: { msg in
            self.actIndicatorView?.stopAnimating()
            
            let alert = UIAlertController(title: "음악 탐색 완료", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default){ _ in
                self.createBtn.isEnabled = true
                self.sortBtn.isEnabled = true
                self.sortBtn.tintColor = .systemBlue
                self.navigationController?.toolbar.isHidden = true
                self.tableView.reloadData()
            })
            self.present(alert, animated: true)
            }
        )
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sortBtn.tintColor = .clear
        
        self.navigationController?.toolbar.isHidden = true
        
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
    
    
    func showLoading() {
        self.navigationController?.toolbar.isHidden = false
        customToolBarView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: (self.navigationController?.toolbar.frame.height)!))
        
        let objectBetweenInterval = 15
        progressLabel                = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        progressLabel?.center.y      = self.customToolBarView!.center.y - CGFloat(objectBetweenInterval)
        progressLabel?.textAlignment = .center
        progressLabel?.textColor     = .label
        progressLabel?.font          = .systemFont(ofSize: 12)
        customToolBarView?.addSubview(progressLabel!)
        
        progressBar                    = UIProgressView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.6, height: preferredContentSize.height))
        progressBar!.center.x          = self.customToolBarView!.center.x
        progressBar!.center.y          = self.customToolBarView!.center.y + CGFloat(objectBetweenInterval)
        progressBar!.progressViewStyle = .default
        customToolBarView?.addSubview(progressBar!)
        
        actIndicatorView                   = UIActivityIndicatorView(frame: CGRect(x: 30, y: 0, width: 20, height: 20))
        actIndicatorView?.center.y         = (customToolBarView?.center.y)!
        actIndicatorView?.color            = .lightGray
        actIndicatorView?.hidesWhenStopped = true
        actIndicatorView?.startAnimating()
        self.customToolBarView?.addSubview(actIndicatorView!)
        
        self.navigationController?.toolbar.addSubview(customToolBarView!)
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
