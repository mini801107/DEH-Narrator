//
//  DetailViewController.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/26.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON
import Alamofire
import AVKit
import AVFoundation
import CocoaAsyncSocket

class DetailViewController: UIViewController, AVAudioPlayerDelegate, PacketHandleDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var descriptionTextField: UITextView!
    @IBOutlet weak var mediaButton: UIButton!
    
    var POIinfo: JSON = nil
    var mediaType: String?
    var fileURL: NSURL?
    var soundData = NSData()
    
    var audioPlayer: AVAudioPlayer? = nil
    var audioBuffer: NSMutableData?
    var audioFileLength: Int = 0
    var audioPacketCount: Int = -1
    let threshold = 500000
    var hasStreamAudioFile: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Var.userMode == "Member" {
            mediaButton.enabled = false
            Var.narratorServiceBrowser.delegate = self
            Var.narratorServiceBrowser.poiDelegate = nil
            showPOIinfo()
        }
        else {
            showPOIinfo()
        }
    }
    
    func showPOIinfo() {
        //display POI information
        titleLabel.text = POIinfo["POI_title"].stringValue
        authorLabel.text = POIinfo["rights"].stringValue
        typeLabel.text = POIinfo["format"].stringValue
        addressLabel.text = POIinfo["POI_address"].stringValue
        descriptionTextField.text = POIinfo["POI_description"].stringValue
        
        //setup mediaButton's image corresponding to media type
        mediaType = POIinfo["media_set"][0]["media_format"].stringValue
        if mediaType == "1" {
            mediaButton.setImage(UIImage(named: "detail_button_image"), forState: UIControlState.Normal)
        }
        else if mediaType == "2" {
            mediaButton.setImage(UIImage(named: "detail_button_audio"), forState: UIControlState.Normal)
            
            if Var.userMode != "Member" {
                //setup AVAudioPlayer
                let mediaSet = POIinfo["media_set"].arrayValue
                let url = mediaSet[0]["media_url"].stringValue
                let fileURL = NSURL(string: url)
                soundData = NSData(contentsOfURL: fileURL!)!
            
                do {
                    audioPlayer = try AVAudioPlayer(data: soundData)
                    audioPlayer!.prepareToPlay()
                    audioPlayer!.volume = 1.0
                    audioPlayer!.delegate = self
                } catch let error as NSError {
                    print("\nError : \n"+error.localizedDescription)
                }
            }
            if Var.userMode == "Narrator" {
                hasStreamAudioFile = false
            }
        }
        else if mediaType == "4" {
            mediaButton.setImage(UIImage(named: "detail_button_video"), forState: UIControlState.Normal)
        }
        else {
            mediaButton.hidden = true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DetailToImage" {
            if let destinationVC = segue.destinationViewController as? ImageViewController {
                destinationVC.picCount = (sender?.integerValue)!
                destinationVC.mediaSet = POIinfo["media_set"].arrayValue
            }
        }
        
        if segue.identifier == "DetailToVideo" {
            if let destinationVC = segue.destinationViewController as? VideoPlayerViewController {
                if Var.userMode != "Member" {
                    destinationVC.fileURL = fileURL
                }
            }
        }
        
        if segue.identifier == "DetailToTableUnwind" {
            //if let destinationVC = segue.destinationViewController as? SearchTableViewController {
                
            //}
        }
    }

    @IBAction func mediaButtonTapped(sender: AnyObject) {
        if mediaType == "1" {  //type 1 : image(.jpg)
            let mediaSet = POIinfo["media_set"].arrayValue
            var picCount = 0
            for x in mediaSet {
                if x["media_format"].stringValue == "1" {
                    picCount += 1
                }
            }
            
            /* Narrator : send number of images to clients */
            if Var.userMode == "Narrator" {
                let infoPacket = Packet(objectType: ObjectType.imageInfoPacket, object: picCount)
                Var.narratorService.sendPacket(infoPacket)
            }

            performSegueWithIdentifier("DetailToImage", sender: picCount)
        }
        else if mediaType == "2" {  //type 2 : audio(.acc)
            if audioPlayer != nil {
                if audioPlayer!.playing == false {
                    /* Narrator : stream audio file to clients */
                    if Var.userMode == "Narrator" && hasStreamAudioFile == false {
                        Var.narratorService.streamData(soundData, type: "audio")
                        hasStreamAudioFile = true
                        print("stream audio packet")
                    }
                    
                    audioPlayer!.play()
                    mediaButton.setImage(UIImage(named: "detail_button_pause"), forState: UIControlState.Normal)
                }
                else {
                    audioPlayer!.pause()
                    mediaButton.setImage(UIImage(named: "detail_button_play"), forState: UIControlState.Normal)
                }
            }
        }
        else if mediaType == "4" {  //type 4 : video(.mp4)
            /* Narrator : send notice to clients to prepare sugue to video view */
            if Var.userMode == "Narrator" {
                let textPacket = Packet(objectType: ObjectType.textPacket, object: "video")
                Var.narratorService.sendPacket(textPacket)
            }
            
            let mediaSet = POIinfo["media_set"].arrayValue
            let url = mediaSet[0]["media_url"].stringValue
            fileURL = NSURL(string: url)
            performSegueWithIdentifier("DetailToVideo", sender: self)
        }
        
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        mediaButton.setImage(UIImage(named: "detail_button_audio"), forState: UIControlState.Normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /******************************** Implement PacketHandleDelegate ********************************/
    func textPacket(text: String) {
        if audioPlayer != nil {
            if audioPlayer!.playing == true {
                audioPlayer?.stop()
            }
        }
        performSegueWithIdentifier("DetailToVideo", sender: self)
    }
    
    func imageInfoPacket(count: Int) {
        if audioPlayer != nil {
            if audioPlayer!.playing == true {
                audioPlayer?.stop()
            }
        }
        performSegueWithIdentifier("DetailToImage", sender: count)
    }
    
    func audioPacket(audio: NSData) {
        audioPacketCount += 1
        if audioFileLength <= threshold {
            if audioPacketCount == 1 {
                audioBuffer = NSMutableData(data: audio)
            }
            else if audioPacketCount == (audioFileLength/4096 + 1) {
                audioBuffer!.appendData(audio)
                do {
                    audioPlayer = try AVAudioPlayer(data: audioBuffer!)
                    audioPlayer!.prepareToPlay()
                    audioPlayer!.volume = 1.0
                    audioPlayer!.delegate = self
                    print("Initial audio player")
                    audioPlayer!.play()
                    mediaButton.setImage(UIImage(named: "detail_button_pause"), forState: UIControlState.Normal)
                    mediaButton.enabled = true
                } catch {
                    print("Error initialing audio player")
                }
            }
            else {
                audioBuffer!.appendData(audio)
            }
            
        }
        else {
            if audioPacketCount == 1 {
                audioBuffer = NSMutableData(data: audio)
            }
            else if audioPacketCount*4096 >=  audioFileLength/5 {
                audioBuffer!.appendData(audio)
                if audioPlayer == nil {
                    do {
                        audioPlayer = try AVAudioPlayer(data: audioBuffer!)
                        audioPlayer!.prepareToPlay()
                        audioPlayer!.volume = 1.0
                        audioPlayer!.delegate = self
                        print("Initial audio player")
                        audioPlayer!.play()
                        mediaButton.setImage(UIImage(named: "detail_button_pause"), forState: UIControlState.Normal)
                        mediaButton.enabled = true
                    } catch {
                        print("Error initialing audio player")
                    }
                }
            }
            else {
                audioBuffer!.appendData(audio)
            }
        }
    }
    
    func audioInfoPacket(length: Int) {
        audioFileLength = length
        audioPacketCount = 0
    }
    
    func POIInfoPacket(POIdata: NSData) {
        if audioPlayer != nil {
            if audioPlayer!.playing == true {
                audioPlayer?.stop()
            }
        }
        let json = JSON(data: POIdata)
        POIinfo = json
        showPOIinfo()
    }
    
    /************************************************************************************************/
    
    @IBAction func unwindToDetail(segue: UIStoryboardSegue) {
        
    }
    
}
