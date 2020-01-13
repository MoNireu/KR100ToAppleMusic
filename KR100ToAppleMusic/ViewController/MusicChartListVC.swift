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
    let appdelegate = UIApplication.shared.delegate as! AppDelegate
    
    var sortedList: [MusicInfoVO]?
    var sortStatus: SortStatus? = .showAll
    var isSearchComplete = false
    
    
    @IBAction func sortAction(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "모두 보기", style: .default) { _ in
            self.sortStatus = .showAll
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "성공한 항목", style: .default) { _ in
            self.sortedList = [MusicInfoVO]()
            for list in self.appdelegate.musicChartList {
                if list.isSucceed == true {
                    self.sortedList?.append(list)
                }
            }
            self.sortStatus = .showSuccess
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "실패한 항목", style: .destructive) { _ in
            self.sortedList = [MusicInfoVO]()
            for list in self.appdelegate.musicChartList {
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
        
        // 탐색이 완료된 이후 일 경우 AppleMusic 플레이리스트 생성 작업을 실행한다.
        if isSearchComplete == true {
            return
        }
        // 로딩창 생성
        self.showLoading()
        
        // 탐색 로직 시작
        musicSearch.startSearching(
            fail: { msg in
                self.actIndicatorView?.stopAnimating()
                self.errorAlert(msg) {
                    self.hideLoading()
                    self.createBtn.title = "재탐색"
                    self.createBtn.isEnabled = true
                }
            },
            success: { count in
                self.progressLabel?.text     = "총 \(self.appdelegate.musicChartList.count)곡 중 \(Int(count))곡 완료 "
                self.progressLabel?.sizeToFit()
                self.progressLabel?.center.x = (self.customToolBarView?.center.x)!
                
                self.progressBar?.setProgress((count / Float(self.appdelegate.musicChartList.count)), animated: true)
            },
            complete: { msg in
            self.actIndicatorView?.stopAnimating()
            
            let alert = UIAlertController(title: "음악 탐색 완료", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default){ _ in
                self.hideLoading()
                self.createBtn.title = "트랙 생성"
                self.createBtn.isEnabled = true
                self.sortBtn.isEnabled = true
                self.sortBtn.tintColor = .systemBlue
                self.isSearchComplete = true
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
        
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        
        htmlParser.parseResult(
            success: {
                self.alert("총 \(appdelegate.musicChartList.count)개의 불러오기를 성공했습니다.")
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH"
                let currentHour = dateFormatter.string(from: Date())
                self.navigationItem.title = "\(currentHour) : 00 집계"
                
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
        
        let objectBetweenInterval = 10
        progressLabel                = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        progressLabel?.text          = "총 \(appdelegate.musicChartList.count)곡 중 0곡 완료 "
        progressLabel?.sizeToFit()
        progressLabel?.center.x      = (self.customToolBarView?.center.x)!
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
    
    
    func hideLoading() {
        self.navigationController?.toolbar.isHidden = true
        progressLabel = nil
        progressBar = nil
        actIndicatorView = nil
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sortStatus {
        case .showSuccess:
            return self.sortedList!.count
        case .showFail:
            return self.sortedList!.count
        default:
         return appdelegate.musicChartList.count
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
            let isCellSucceed = appdelegate.musicChartList[indexPath.row].isSucceed
            
            if isCellSucceed == true || isCellSucceed == nil {
                cell = makeCell(cell, list: appdelegate.musicChartList, indexPath: indexPath)
            } else {
                cell = makeCell(cell, list: appdelegate.musicChartList, indexPath: indexPath, textColor: .red)
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
