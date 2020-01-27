//
//  FakeLaunchScreen.swift
//  KR100ToAppleMusic
//
//  Created by MoNireu on 2020/01/27.
//  Copyright © 2020 monireu. All rights reserved.
//

import UIKit

class FakeLaunchScreen: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.isToolbarHidden = true
    }
    
    let htmlParser = HTMLParser()
    var currentUpdateTime: String?
    
    override func viewDidAppear(_ animated: Bool) {
        htmlParser.getUpdateTime(
            success: { time in
                self.htmlParser.parseResult(
                    success: {
                        self.currentUpdateTime = time
                        self.navigationController?.isNavigationBarHidden = false
                        self.performSegue(withIdentifier: "toMusicChartListVC", sender: self)
                    },
                    fail: { msg in
                        self.errorAlert(msg)
                    }
                )
            },
            fail: { msg in
                self.errorAlert(msg)
            }
        )
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMusicChartListVC" {
            let vc = segue.destination as? MusicChartListVC
            vc?.currentUpdateTime = self.currentUpdateTime
        }
    }

}
