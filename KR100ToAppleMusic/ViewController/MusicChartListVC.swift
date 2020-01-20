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

protocol ModalHandler {
    func modalDismissed()
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
    var finalList: [MusicInfoVO]?
    
    var sortStatus: SortStatus? = .showAll
    var isSearchComplete = false
    var latestTime: String?
    let currentDate : String = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }()
    let currentTime: String = {
        let df = DateFormatter()
        df.dateFormat = "HH:00"
        return df.string(from: Date())
    }()
    
    @IBAction func sortAction(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "모두 보기", style: .default) { _ in
            self.sortStatus = .showAll
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "성공한 항목", style: .default) { _ in
            self.sortStatus = .showSuccess
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "실패한 항목", style: .destructive) { _ in
            self.sortStatus = .showFail
            self.tableView.reloadData()
        })
        
        self.present(alert, animated: true)
    }
    
    
    @IBAction func createAction(_ sender: Any) {
        
        // 탐색이 완료된 이후 일 경우 AppleMusic 플레이리스트 생성 작업을 실행한다.
        if isSearchComplete == true {
            let alert = UIAlertController(title: "플레이리스트 생성", message: "생성할 플레이리스트의 제목 및 설명을 작성해주세요.", preferredStyle: .alert)
            alert.addTextField() {tf in tf.placeholder = "플레이리스트 제목"}
            alert.addTextField() {tf in tf.placeholder = "플레이리스트 설명"}
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                let playListName = alert.textFields?.first?.text
                let playListDesc = alert.textFields?.last?.text
                
                if (playListName == nil || playListName!.isEmpty == true) && (playListDesc == nil || playListDesc!.isEmpty == true){
                    self.errorAlert("플레이리스트 제목과 설명을 입력해주세요.") {self.present(alert, animated: true)}
                }else if playListName == nil || playListName!.isEmpty == true {
                    self.errorAlert("플레이리스트 제목을 입력해주세요.") {self.present(alert, animated: true)}
                } else if playListDesc == nil || playListDesc!.isEmpty == true {
                    self.errorAlert("플레이리스트 설명을 입력해주세요.") {self.present(alert, animated: true)}
                } else {
                    self.sortList(isSucceed: true)
                    print("##############\(self.sortedList!)")
                    self.musicSearch.createPlayList(
                        list: self.sortedList!,
                        name: playListName!,
                        desc: playListDesc!,
                        fail: {msg in
                            self.errorAlert(msg) {
                            self.createBtn.isEnabled = true
                            }
                        }, // END of fail:
                        success: {msg in
                            self.okAlert(msg) {
                            self.createBtn.isEnabled = true
                            }
                        } // END of success:
                    ) // END of self.musicSearch.createPlayList CLOSURE
                } // END of if-else Statement
            }) // END of alert.addAction("확인")
            self.present(alert, animated: true)
        }
        
        else {
            self.alert(message: "\(self.createBtn.title!)을 시작합니다.") {
                // 탐색 로직 시작
                self.createBtn.isEnabled = false
                self.musicSearch.startSearching(
                    fail: { msg in
                        self.actIndicatorView?.stopAnimating()
                        self.errorAlert(msg) {
                            self.hideLoading()
                            self.createBtn.title = "재탐색"
                            self.createBtn.isEnabled = true
                        }
                    },
                    success: { cnt in
                        let count = cnt as! Float
                        self.progressLabel?.text     = "총 \(self.appdelegate.musicChartList.count)곡 중 \(Int(count))곡 완료 "
                        self.progressLabel?.sizeToFit()
                        self.progressLabel?.center.x = (self.customToolBarView?.center.x)!
                        
                        self.progressBar?.setProgress((count / Float(self.appdelegate.musicChartList.count)), animated: true)
                    },
                    complete: { msg in
                        self.actIndicatorView?.stopAnimating()
                        
                        self.okAlert("\(msg)") {
                            self.hideLoading()
                            self.createBtn.title     = "트랙 생성"
                            self.createBtn.isEnabled = true
                            self.sortBtn.isEnabled   = true
                            self.sortBtn.tintColor   = .systemBlue
                            self.isSearchComplete    = true
                            self.tableView.allowsSelection = true
                            self.tableView.reloadData()
                        }
                    }
                )
                self.showLoading()
            }
        }
    }
    
    // MARK: View CallBack Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelection = false
        self.sortBtn.tintColor = .clear
        self.navigationController?.toolbar.isHidden = true
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.attributedTitle = NSAttributedString(string: "당겨서 새로고침")
        self.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        
        htmlParser.parseResult(
            success: {
                self.okAlert("총 \(appdelegate.musicChartList.count)개의 불러오기를 성공했습니다.")
                self.latestTime = self.currentTime
                self.navigationItem.title = "\(self.currentTime) 집계"
                self.tableView.reloadData()
            },
            fail: { msg in
                self.errorAlert(msg)
                self.errorAlert("음악을 불러오는데 실패했습니다.")
            }
        )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    
    // MARK: ToolBar Loading View Methods
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
        customToolBarView = nil
    }
    
    @objc func pullToRefresh(_ sender: Any) {
        guard self.currentTime != latestTime! else {
            self.refreshControl?.endRefreshing()
            return
        }
        
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.musicChartList = []
        
        htmlParser.parseResult(
            success: {
                self.okAlert("\(appdelegate.musicChartList.count)개의 불러오기를 성공했습니다.")
                self.navigationItem.title = "\(self.currentTime) 집계"
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            },
            fail: { msg in
                self.errorAlert(msg)
                self.errorAlert("음악을 불러오는데 실패했습니다.")
                self.refreshControl?.endRefreshing()
            }
        )
    }
    
    
    // MARK: Other Methods
    func sortList(isSucceed: Bool) {
        self.sortedList = [MusicInfoVO]()
        for list in self.appdelegate.musicChartList {
            if isSucceed == true {
                if list.isSucceed == true {
                    self.sortedList?.append(list)
                }
            } else {
                if list.isSucceed == false {
                    self.sortedList?.append(list)
                }
            }
        }
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sortStatus {
        case .showSuccess:
            sortList(isSucceed: true)
            return self.sortedList!.count
        case .showFail:
            sortList(isSucceed: false)
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
            sortList(isSucceed: true)
            cell = makeCell(cell, list: self.sortedList!, indexPath: indexPath)
        case .showFail:
            sortList(isSucceed: false)
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
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var originIndex = 0
        
        switch self.sortStatus {
        case .showAll:
            originIndex = indexPath.row
        default:
            originIndex = Int((self.sortedList?[indexPath.row].rank)!)! - 1
        }
        
        let selectedMusicTitle  = appdelegate.musicChartList[originIndex].music
        let selectedMusicArtist = appdelegate.musicChartList[originIndex].artist
        
        let alert = UIAlertController(title: "수동 검색", message: "\n\(selectedMusicTitle!)\n\(selectedMusicArtist!)", preferredStyle: .alert)
        alert.addTextField() { tf in
            tf.placeholder = "수동 검색할 곡 명을 입력해주세요"
            tf.textAlignment = .natural
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            guard alert.textFields?.first?.text != nil && alert.textFields?.first?.text?.isEmpty == false  else{
                self.errorAlert("검색어를 입력해주세요.")
                return
            }
            
            let manualMusicSearchVC = self.storyboard?.instantiateViewController(identifier: "manual_music_search") as! ManualMusicSearchVC
            
            manualMusicSearchVC.music       = selectedMusicTitle
            manualMusicSearchVC.artist      = selectedMusicArtist
            manualMusicSearchVC.keyword     = alert.textFields?.first!.text
            manualMusicSearchVC.originIndex = originIndex
            manualMusicSearchVC.delegate    = self
            manualMusicSearchVC.melonAlbumImageURL = self.appdelegate.musicChartList[originIndex].melonAlbumImg

            self.present(manualMusicSearchVC, animated: true)
        })
        self.present(alert, animated: true)
    }
    
    
    func makeCell(_ cell: MusicChartListCell, list: [MusicInfoVO], indexPath: IndexPath, textColor: UIColor = .label) -> MusicChartListCell {
        cell.rank.text        = ((list[indexPath.row].rank)! as String) + "위"
        cell.rank.sizeToFit()
        cell.rank.textColor   = textColor
        cell.music.text       = list[indexPath.row].music as String?
        cell.music.textColor  = textColor
        cell.artist.text      = list[indexPath.row].artist as String?
        cell.artist.textColor = textColor
        
        return cell
    }
}


extension MusicChartListVC: ModalHandler {
    func modalDismissed() {
        self.tableView.reloadData()
    }
}
