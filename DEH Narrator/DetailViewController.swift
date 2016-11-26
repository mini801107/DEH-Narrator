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

class DetailViewController: UIViewController, AVAudioPlayerDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var descriptionTextField: UITextView!
    @IBOutlet weak var mediaButton: UIButton!
    
    var POIinfo: JSON = nil
    var audioPlayer: AVAudioPlayer?
    var mediaType: String?
    var fileURL: NSURL?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //display POI information
        titleLabel.text = POIinfo["POI_title"].stringValue
        authorLabel.text = POIinfo["rights"].stringValue
        typeLabel.text = POIinfo["format"].stringValue
        addressLabel.text = POIinfo["POI_address"].stringValue
        descriptionTextField.text = POIinfo["POI_description"].stringValue
        
        //setup mediaButton's image corresponding to media type
        mediaType = POIinfo["media_set"][0]["media_format"].stringValue
        if mediaType == "1" {
            mediaButton.setImage(UIImage(named: "camera"), forState: UIControlState.Normal)
        }
        else if mediaType == "2" {
            mediaButton.setImage(UIImage(named: "headphones"), forState: UIControlState.Normal)
            
            //setup AVAudioPlayer
            let mediaSet = POIinfo["media_set"].arrayValue
            let url = mediaSet[0]["media_url"].stringValue
            let fileURL = NSURL(string: url)
            let soundData = NSData(contentsOfURL: fileURL!)
            
            do {
                audioPlayer = try AVAudioPlayer(data: soundData!)
                audioPlayer!.prepareToPlay()
                audioPlayer!.volume = 1.0
                audioPlayer!.delegate = self
            } catch let error as NSError {
                print("\nError : \n"+error.localizedDescription)
            }

        }
        else if mediaType == "4" {
            mediaButton.setImage(UIImage(named: "video_camera"), forState: UIControlState.Normal)
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
                destinationVC.fileURL = fileURL
            }
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
            performSegueWithIdentifier("DetailToImage", sender: picCount)
        }
        else if mediaType == "2" {  //type 2 : audio(.acc)
            if audioPlayer != nil {
                if audioPlayer!.playing == false {
                    audioPlayer!.play()
                    mediaButton.setImage(UIImage(named: "pause"), forState: UIControlState.Normal)
                }
                else {
                    audioPlayer!.pause()
                    mediaButton.setImage(UIImage(named: "play"), forState: UIControlState.Normal)
                }
            }
        }
        else if mediaType == "4" {  //type 4 : video(.mp4)
            let mediaSet = POIinfo["media_set"].arrayValue
            let url = mediaSet[0]["media_url"].stringValue
            fileURL = NSURL(string: url)
            performSegueWithIdentifier("DetailToVideo", sender: self)
        }
        
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        mediaButton.setImage(UIImage(named: "headphones"), forState: UIControlState.Normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

   

}
