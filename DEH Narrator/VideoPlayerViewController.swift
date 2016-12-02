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
import CocoaAsyncSocket

class VideoPlayerViewController: AVPlayerViewController, VideoPacketHandleDelegate {

    var mode: String = ""
    var fileURL: NSURL?
    var videoPlayer: AVPlayer? = nil
    var narratorService: NarratorService!
    var narratorServiceBrowser: NarratorServiceBrowser!
    
    let threshold = 500000
    var videoBuffer: NSMutableData?
    var videoFileLength: Int = 0
    var videoPacketCount: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if mode == "Narrator" {
            //stream video file to clients
            let videoData = NSData(contentsOfURL: fileURL!)
            narratorService.streamData(videoData!, type: "video")
            
            view.backgroundColor = .blackColor()
            videoPlayer = AVPlayer(URL: fileURL!)
            self.player = videoPlayer
            self.showsPlaybackControls = true
            self.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
            videoPlayer!.play()
        }
        else if mode == "Member" {
            narratorServiceBrowser.videoDeledate = self
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func videoPacket(video: NSData) {
        videoPacketCount += 1
        if videoFileLength <= threshold {
            if videoPacketCount == 1 {
                videoBuffer = NSMutableData(data: video)
            }
            else if videoPacketCount == (videoFileLength/4096 + 1) {
                videoBuffer!.appendData(video)
                let directory = NSSearchPathForDirectoriesInDomains(.AllLibrariesDirectory, .UserDomainMask , true)[0] as String
                let path = NSURL(fileURLWithPath: "\(directory)/video.mp4")
                fileURL = path
                
                videoBuffer!.writeToURL(path, atomically: true)
                videoPlayer = AVPlayer(URL: path)
                self.player = videoPlayer
                self.showsPlaybackControls = true
                self.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
                videoPlayer!.play()
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoPlayerViewController.videoPlayerDidFinishPlaying(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: self.videoPlayer?.currentItem)
                
            }
            else {
                videoBuffer!.appendData(video)
            }
            
        }
        else {
            if videoPacketCount == 1 {
                videoBuffer = NSMutableData(data: video)
            }
            else if videoPacketCount*4096 >=  videoFileLength/5 {
                videoBuffer!.appendData(video)
                if videoPlayer == nil {
                    let directory = NSSearchPathForDirectoriesInDomains(.AllLibrariesDirectory, .UserDomainMask , true)[0] as String
                    let path = NSURL(fileURLWithPath: "\(directory)/video.mp4")
                    fileURL = path
                    
                    videoBuffer!.writeToURL(path, atomically: true)
                    videoPlayer = AVPlayer(URL: path)
                    self.player = videoPlayer
                    self.showsPlaybackControls = true
                    self.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
                    videoPlayer!.play()
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoPlayerViewController.videoPlayerDidFinishPlaying(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: self.videoPlayer?.currentItem)
                }
                else if videoPacketCount*4096 >= videoFileLength {
                    videoBuffer!.writeToURL(fileURL!, atomically: true)
                    
                    let currentTime = videoPlayer?.currentTime()
                    videoPlayer?.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL:fileURL!))
                    videoPlayer?.seekToTime(currentTime!)
                }
                else {
                    let currentTime = videoPlayer?.currentTime()
                    let duration = videoPlayer?.currentItem?.duration
                    let current_seconds: Double = Float64(currentTime!.value) / Float64(currentTime!.timescale)
                    let total_seconds: Double = Float64(duration!.value) / Float64(duration!.timescale)
                    let playing_percentage = current_seconds / total_seconds
                    
                    if playing_percentage >= 0.2 {
                        videoBuffer!.writeToURL(fileURL!, atomically: true)
                        let curTime = videoPlayer?.currentTime()
                        videoPlayer?.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL:fileURL!))
                        videoPlayer?.seekToTime(curTime!)
                    }
                }
            }
            else {
                videoBuffer!.appendData(video)
            }
        }
    }
    
    func videoInfoPacket(length: Int) {
        if videoFileLength != 0 && videoPlayer != nil {
            videoPlayer?.pause()
            videoPlayer = nil
        }
        videoFileLength = length
        videoPacketCount = 0
        print("video length = \(videoFileLength)")
    }
    
    func videoPlayerDidFinishPlaying(note: NSNotification) {
        videoFileLength = 0
    }

}
