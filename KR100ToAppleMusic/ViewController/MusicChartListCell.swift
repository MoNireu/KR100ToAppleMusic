//
//  MusicChartListCell.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/02.
//  Copyright © 2020 monireu. All rights reserved.
//

import UIKit

class MusicChartListCell: UITableViewCell {

    @IBOutlet var rank: UILabel!
    @IBOutlet var music: UILabel!
    @IBOutlet var artist: UILabel!
    @IBOutlet var rankChange: UILabel!
    @IBOutlet var failIndicator: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
