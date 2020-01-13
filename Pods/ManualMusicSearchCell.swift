//
//  ManualMusicSearchCell.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/14.
//  Copyright © 2020 monireu. All rights reserved.
//

import UIKit

class ManualMusicSearchCell: UITableViewCell {

    @IBOutlet var appleAlbumImg: UIImageView!
    @IBOutlet var music: UILabel!
    @IBOutlet var artist: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
