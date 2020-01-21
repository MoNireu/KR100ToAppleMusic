//
//  MusicInfoVO.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/02.
//  Copyright © 2020 monireu. All rights reserved.
//

import Foundation

enum RankChangeStat {
    case up
    case down
    case no
    case new
}

class MusicInfoVO {
    var rank: String?
    var music: String?
    var artist: String?
    var rankChangeStat: RankChangeStat?
    var rankChangeVal: String?
    var melonAlbumImg: String?
    var isSucceed: Bool?
    var musicID: String?
}
