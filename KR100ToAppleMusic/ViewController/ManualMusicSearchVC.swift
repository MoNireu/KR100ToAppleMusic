//
//  ManualMusicSearchVC.swift
//  Alamofire
//
//  Created by MoNireu on 2020/01/13.
//

import UIKit

class ManualMusicSearchVC: UIViewController {
    @IBOutlet var melonAlbumImage: UIImageView!
    @IBOutlet var musicLbl: UILabel!
    @IBOutlet var artistLbl: UILabel!
    
    
    var melonAlbumImageURL: String?
    var music: String?
    var artist: String?
    
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        musicLbl.text  = music
        artistLbl.text = artist
        
        let url = URL(string: "https://" + melonAlbumImageURL!)
        do {
            try! melonAlbumImage.image = UIImage(data: Data(contentsOf: url!))
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
