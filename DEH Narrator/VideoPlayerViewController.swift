//
//  VideoPlayerViewController.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/26.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideoPlayerViewController: AVPlayerViewController {

    var fileURL: NSURL?
    var videoPlayer = AVPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .blackColor()
        videoPlayer = AVPlayer(URL: fileURL!)
        self.player = videoPlayer
        self.showsPlaybackControls = true
        self.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
        videoPlayer.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
