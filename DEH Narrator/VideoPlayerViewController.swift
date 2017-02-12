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
import SwiftyJSON
import CocoaAsyncSocket

class VideoPlayerViewController: AVPlayerViewController, VideoPacketHandleDelegate, POIInfoPacketHandleDelegate {

    var fileURL: NSURL?
    var videoPlayer: AVPlayer? = nil
    var redundantPacket: Bool = false
    
    let threshold = 500000
    var videoBuffer: NSMutableData?
    var videoFileLength: Int = 0
    var videoPacketCount: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Var.userMode == "Member" {
            redundantPacket = false
            Var.narratorServiceBrowser.videoDelegate = self
            Var.narratorServiceBrowser.poiDelegate = self
        }
        else {
            view.backgroundColor = .blackColor()
            videoPlayer = AVPlayer(URL: fileURL!)
            self.player = videoPlayer
            self.showsPlaybackControls = true
            self.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
            videoPlayer!.play()
        }
        
        if Var.userMode == "Narrator" {
            //stream video file to clients
            let videoData = NSData(contentsOfURL: fileURL!)
            Var.narratorService.streamData(videoData!, type: "video")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func videoPacket(video: NSData) {
        if redundantPacket == true {
            print("drop packet")
            return
        }
        
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
        if redundantPacket == false {
            if videoFileLength != 0 && videoPlayer != nil {
                videoPlayer?.pause()
                videoPlayer = nil
            }
            
            videoFileLength = length
            videoPacketCount = 0
            print("video length = \(videoFileLength)")
        }
    }
    
    func videoPlayerDidFinishPlaying(note: NSNotification) {
        videoFileLength = 0
    }
    
    // When receive same image info, ignore
    func textPacket(text: String) {
        redundantPacket = true
        print("redundant packet")
    }
    
    // When receive POI info, unwind to Detail View and present new POI info
    func POIInfoPacket(POIdata: NSData) {
        redundantPacket = false
        let str = POIdata.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        performSegueWithIdentifier("VideoToDetailUnwind", sender: str)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "VideoToDetailUnwind" {
            if let destinationVC = segue.destinationViewController as? DetailViewController {
                let str = String(sender!)
                let POIdata = NSData(base64EncodedString: str, options: NSDataBase64DecodingOptions(rawValue: 0))
                let json = JSON(data: POIdata!)
                destinationVC.POIinfo = json
                destinationVC.showPOIinfo()
            }
        }
    }
    
}
