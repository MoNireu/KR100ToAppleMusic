//
//  ManualMusicSearchVC.swift
//  Alamofire
//
//  Created by MoNireu on 2020/01/13.
//

import UIKit
import Alamofire

class ManualMusicSearchVC: UIViewController {
    @IBOutlet var melonAlbumImage: UIImageView!
    @IBOutlet var musicLbl: UILabel!
    @IBOutlet var artistLbl: UILabel!
    @IBOutlet var keywordLbl: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var delegate: MusicChartListVC?
    
    var manualSearchMusicInfoList = [ManualSearchMusicInfoVO]()
    var music: String?
    var artist: String?
    var melonAlbumImageURL: String?
    var keyword: String?
    var originIndex: Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate   = self
        self.tableView.dataSource = self
        
        self.view.bringSubviewToFront(activityIndicator)
        self.activityIndicator.startAnimating()

        musicLbl.text   = music
        artistLbl.text  = artist
        keywordLbl.text = "\"\(keyword!)\" 검색결과"
        
        let url = URL(string: "https://" + melonAlbumImageURL!)
        do {
            try! melonAlbumImage.image = UIImage(data: Data(contentsOf: url!))
        }
        
        let musicSearchUtil = MusicSearchUtil()
        musicSearchUtil.startSearch(
            keyWord: keyword,
            fail: { msg in
                self.errorAlert(msg)
            },
            success: { res in
                let result = res as! ManualSearchMusicInfoVO
                self.manualSearchMusicInfoList.append(result)
                print(result.music)
            },
            complete: { msg in
                print(msg)
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
            }
        )
    }
    
}


extension ManualMusicSearchVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(manualSearchMusicInfoList.count)
        return manualSearchMusicInfoList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "manual_music_search_cell") as! ManualMusicSearchCell
        
        cell.music.text = manualSearchMusicInfoList[indexPath.row].music
        cell.artist.text = manualSearchMusicInfoList[indexPath.row].artist
        
        DispatchQueue.main.async {
            cell.appleAlbumImg.image = self.getAlbumImage(indexPath.row)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let music  = manualSearchMusicInfoList[indexPath.row].music
        let artist = manualSearchMusicInfoList[indexPath.row].artist
        
        self.alert(title: "해당 곡을 선택하시겠습니까?", message: "\(music!)\n\(artist!)") {
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.musicChartList[self.originIndex!].musicID = self.manualSearchMusicInfoList[indexPath.row].musicID
            appdelegate.musicChartList[self.originIndex!].isSucceed = true
            self.dismiss(animated: true) {
                self.delegate?.modalDismissed()
            }
        }
    }
    
    
    func getAlbumImage(_ index: Int) -> UIImage? {
        //인자값으로 받은 인덱스를 기반으로 해당하는 배열 데이터를 읽어옴
        let list = self.manualSearchMusicInfoList[index]
        
        //메모제이션: 저장된 이미지가 있으면 그것을 반환하고, 없을 경우 내려받아 저장한 후 반환
        if let savedImage = list.img{
            return savedImage
        } else {
            if let url = list.imgURL {
                let imageURL = URL(string: url)!
                let imageData = try! Data(contentsOf: imageURL)
                list.img = UIImage(data: imageData) //UIImage를 MovieVO 객체에 우선 저장
                return list.img! //저장된 이미지를 반환
            }
            return UIImage()
        }
    }
}
