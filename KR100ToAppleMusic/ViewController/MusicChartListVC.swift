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
    func modalFailSearching()
}


class MusicChartListVC: UITableViewController {

    @IBOutlet var createBtn: UIBarButtonItem!
    @IBOutlet var sortBtn: UIBarButtonItem!
    @IBOutlet var navItem: UINavigationItem!
    
    var actIndicatorView: UIActivityIndicatorView?
    var customToolBarView: UIView?
    var progressBar: UIProgressView?
    var progressLabel: UILabel?
    var searchController: UISearchController?
    
    
    
    
    let musicSearchUtil = MusicSearchUtil()
    let tokenUtils = TokenUtils()
    let appdelegate = UIApplication.shared.delegate as! AppDelegate
    
    var sortedList: [MusicInfoVO]?
    var finalList: [MusicInfoVO]?
    var filteredList: [MusicInfoVO]?
    
    var sortStatus: SortStatus = .showAll
    var isSearchComplete = false
    var selectedRow: Int?
    
    var currentUpdateTime: String?
    var latestUpdateTime: String?
    
    
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
        if isSearchComplete == false {
            self.alert(message: "\(self.createBtn.title!)을 시작합니다.") {
                // 탐색 로직 시작
                self.showLoading()
                self.createBtn.isEnabled = false
                self.musicSearchUtil.startSearching(
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
                        self.progressBar?.setProgress((count / Float(self.appdelegate.musicChartList.count)), animated: true)
                        
                        self.tableView.reloadData()
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
            }
        } // END of isSearchComplete == false
        
        // isSearchComplete이 True일 경우 AppleMusic에서 음악 탐색을 시작.
        else {
            let alert = UIAlertController(title: "플레이리스트 생성", message: "생성할 플레이리스트의 제목 및 설명을 작성해주세요.", preferredStyle: .alert)
            alert.addTextField() {tf in
                tf.placeholder = "플레이리스트 제목"
                tf.text = "Melon \(self.currentDate())"
            }
            alert.addTextField() {tf in
                tf.placeholder = "플레이리스트 설명"
                tf.text = "Melon\(self.currentDate()) \(self.currentTime())에 생성됨)"
            }
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
                    self.musicSearchUtil.createPlayList(
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
    }
    
    // MARK: View CallBack Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.delegate = self as? UISearchControllerDelegate
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.searchResultsUpdater = self
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.toolbar.isHidden = true
        navItem.searchController = searchController
        
        
        self.tableView.allowsSelection = false
        self.sortBtn.tintColor = .clear

        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.attributedTitle = NSAttributedString(string: "당겨서 새로고침")
        self.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        
        self.latestUpdateTime = self.currentUpdateTime
        self.navigationItem.title = "\(self.currentUpdateTime!) 집계"
        self.tableView.reloadData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    
    // MARK: ToolBar Loading View Methods
    func showLoading() {
        self.navigationController?.toolbar.isHidden = false
        customToolBarView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: (self.navigationController?.toolbar.frame.height)!))
        
        let objectBetweenInterval = 10
//        progressLabel                = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        progressLabel                = UILabel()
        progressLabel?.text          = "총 \(appdelegate.musicChartList.count)곡 중   0곡 완료 "
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
        progressLabel?.removeFromSuperview()
        progressBar?.removeFromSuperview()
        actIndicatorView?.removeFromSuperview()
        customToolBarView?.removeFromSuperview()
        self.navigationController?.toolbar.isHidden = true
    }
    
    
    // MARK: Action Methods
    @objc func pullToRefresh(_ sender: Any) {
        let htmlParser = HTMLParser()
        htmlParser.getUpdateTime(
            success: { time in
                self.currentUpdateTime = time
                
                guard self.currentUpdateTime != self.latestUpdateTime! else {
                    let alert = UIAlertController(title: nil, message: "갱신할 데이터가 없습니다.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(alert, animated: true) {
                        self.refreshControl?.endRefreshing()
                    }
                    return
                } // END of guard statement
                
                htmlParser.parseResult(
                    success: {
                        self.refreshControl?.endRefreshing()
                        DispatchQueue.main.async {
                            self.okAlert("\(self.appdelegate.musicChartList.count)개의 불러오기를 성공했습니다.") {
                                self.latestUpdateTime = self.currentUpdateTime
                                self.navigationItem.title = "\(self.currentUpdateTime!) 집계"
                                self.isSearchComplete = false
                                self.createBtn.title = "탐색"
                                
                                self.appdelegate.musicChartList = self.appdelegate.tempMusicChartList!
                                self.appdelegate.tempMusicChartList = nil
                                
                                self.musicSearchUtil.index = 0
                                
                                self.tableView.reloadData()
                            } // END of okAlert() closure
                        } // END of DispatchQueue.main.async closure
                    }, // END of parseResult(success:) closure
                    fail: { msg in
                        self.errorAlert(msg)
                        self.errorAlert("음악을 불러오는데 실패했습니다.")
                        self.refreshControl?.endRefreshing()
                    } // END of parseResult(fail:) closure
                ) // END of htmlParser.parseResult()
            }, // END of getUpdateTime(success:) closure
            fail: { msg in
                self.errorAlert(msg)
            } // END of getUpdateTime(fail:) closure
        ) // END of htmlParser.getUpdateTime()
    } // END of pullToRefresh()
    
    
    // MARK: Other Methods
    func sortList(isSucceed: Bool) {
        self.sortedList = [MusicInfoVO]()
        for item in self.appdelegate.musicChartList {
            if isSucceed == true {
                if item.isSucceed == true {
                    self.sortedList?.append(item)
                }
            } else {
                if item.isSucceed == false {
                    self.sortedList?.append(item)
                }
            }
        }
    }
    
    
    func currentDate() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }
    
    func currentTime() -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: Date())
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard self.searchController!.isActive == false else {
            return filteredList!.count
        }
        
        switch sortStatus {
        case .showSuccess:
            sortList(isSucceed: true)
            return self.sortedList!.count
        case .showFail:
            sortList(isSucceed: false)
            return self.sortedList!.count
        default:
            return self.appdelegate.musicChartList.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard var cell = tableView.dequeueReusableCell(withIdentifier: "chart_cell", for: indexPath) as? MusicChartListCell else {
            print("error making cell")
            return UITableViewCell()
        }
        
        guard self.searchController!.isActive == false else {
            cell = makeCell(cell, row: filteredList![indexPath.row])
            return cell
        }
        
        let item = self.appdelegate.musicChartList
        
        switch self.sortStatus {
        case .showSuccess:
            guard indexPath.row >= sortedList!.startIndex && indexPath.row <= sortedList!.endIndex else {
                print("Out of Index")
                return UITableViewCell()
            }
            sortList(isSucceed: true)
            cell = makeCell(cell, row: (self.sortedList?[indexPath.row])!)
            cell.failIndicator.isHidden = true
        case .showFail:
            guard indexPath.row >= sortedList!.startIndex && indexPath.row <= sortedList!.endIndex else {
                print("Out of Index")
                return UITableViewCell()
            }
            sortList(isSucceed: false)
            cell = makeCell(cell, row: (self.sortedList?[indexPath.row])!, textColor: .systemGray)
            cell.failIndicator.isHidden = false
        case .showAll:
            guard indexPath.row >= item.startIndex && indexPath.row <= item.endIndex else {
                print("Out of Index")
                return UITableViewCell()
            }
            let isCellSucceed = item[indexPath.row].isSucceed
            
            if isCellSucceed == true || isCellSucceed == nil {
                cell = makeCell(cell, row: item[indexPath.row])
                cell.failIndicator.isHidden = true
            } else {
                cell = makeCell(cell, row: item[indexPath.row], textColor: .systemGray)
                cell.failIndicator.isHidden = false
            }
        default:
            break
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
        manualSearchAlert(index: originIndex)
    }
    
    
    func makeCell(_ cell: MusicChartListCell, row: MusicInfoVO, textColor: UIColor = .label) -> MusicChartListCell {
        cell.rank.text        = (row.rank as String?)! + "위"
        cell.rank.textColor   = textColor
        cell.music.text       = row.music as String?
        cell.music.textColor  = textColor
        cell.artist.text      = row.artist as String?
        cell.artist.textColor = textColor
        
        switch row.rankChangeStat{
        case .no:
            cell.rankChange.text      = row.rankChangeVal
            cell.rankChange.textColor = .systemGray
        case .up:
            cell.rankChange.text      = "↑\(row.rankChangeVal!)"
            cell.rankChange.textColor = .systemGreen
        case .down:
            cell.rankChange.text      = "↓\(row.rankChangeVal!)"
            cell.rankChange.textColor = .systemRed
        case .new:
            cell.rankChange.text      = row.rankChangeVal
            cell.rankChange.textColor = .systemOrange
        default:
            break
        }
        
        if textColor != .label {
            cell.rankChange.textColor = textColor
        }
        
        return cell
    }
    
    func manualSearchAlert(index: Int) {
        let selectedMusicTitle  = appdelegate.musicChartList[index].music
        let selectedMusicArtist = appdelegate.musicChartList[index].artist
        
        let musicSearchUtil = MusicSearchUtil()
        let modifiedMusicTitle = musicSearchUtil.modifyString(string: selectedMusicTitle)
        
        
        let alert = UIAlertController(title: "수동 검색", message: "\n\(selectedMusicTitle!)\n\(selectedMusicArtist!)", preferredStyle: .alert)
        alert.addTextField() { tf in
            tf.placeholder = "수동 검색할 곡 명을 입력해주세요"
            tf.text = modifiedMusicTitle
            tf.clearButtonMode = .always
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
            manualMusicSearchVC.originIndex = index
            manualMusicSearchVC.delegate    = self
            manualMusicSearchVC.melonAlbumImageURL = self.appdelegate.musicChartList[index].melonAlbumImg

            self.present(manualMusicSearchVC, animated: true) {
                self.selectedRow = index
            }
        })
        self.present(alert, animated: true)
    }
}

extension MusicChartListVC: UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    func filterContent(searchText: String) {
        self.filteredList = self.appdelegate.musicChartList.filter { (musicList: MusicInfoVO) -> Bool in
            return musicList.music!.contains(searchText) || musicList.artist!.contains(searchText)
        }
        self.tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        
        guard searchText?.isEmpty == false else {
            return
        }
        filterContent(searchText: searchText!)
    }
    
}


extension MusicChartListVC: ModalHandler {
    func modalDismissed() {
        self.tableView.reloadData()
        
    }
    
    func modalFailSearching() {
        guard selectedRow != nil else {
            return
        }
        manualSearchAlert(index: selectedRow!)
    }
}
