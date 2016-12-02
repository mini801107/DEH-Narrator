//
//  ImageViewController.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/26.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON
import AlamofireImage
import Alamofire
import CocoaAsyncSocket

class ImageViewController: UIViewController, ImagePacketHandleDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    
    var mode: String = ""
    var mediaSet = [JSON]()
    var picCount: Int = 0
    var viewSize = CGRect()
    
    var socket: GCDAsyncSocket?
    var client_sockets = [GCDAsyncSocket]()
    var narratorService: NarratorService!
    var narratorServiceBrowser: NarratorServiceBrowser!
    var imagePacket_count: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //let navigationVC = self.parentViewController as! UINavigationController
        //let navigationItem_height = navigationVC.navigationBar.bounds.height
        let navigationItem_height = CGFloat(44)
        scrollView.backgroundColor = UIColor.blackColor()
        scrollView.pagingEnabled = true
        scrollView.contentSize = CGSizeMake(CGFloat(picCount)*self.view.bounds.size.width, self.view.bounds.size.height-navigationItem_height)
        
        //Setup each view sizeMPMoviePlayerController
        viewSize = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-navigationItem_height)
        
        if mode == "Member" {
            imagePacket_count = 0
            narratorServiceBrowser.imageDelegate = self
        }
        else {
            for i in 0 ..< picCount {
                let url = mediaSet[i]["media_url"].stringValue
                let downloadURL = NSURL(string: url)
                let data = NSData(contentsOfURL: downloadURL!)
                let image = UIImage(data: data!)!
                image.af_inflate()
            
                //Offset view size
                if i != 0 {
                    viewSize = CGRectOffset(viewSize, self.view.bounds.size.width, 0)
                }
            
                //Setup and add images
                let imgView = UIImageView(frame: viewSize)
                imgView.image = image
                imgView.contentMode = .ScaleAspectFit
            
                scrollView.addSubview(imgView)
            
                /* Narrator : send image to clients */
                if mode == "Narrator" {
                    let imagePacket = Packet(objectType: ObjectType.imagePacket, object: image)
                    narratorService.sendPacket(imagePacket)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePacket(img: UIImage) {
        imagePacket_count += 1
    
        //Offset view size
        if imagePacket_count != 1 {
            viewSize = CGRectOffset(viewSize, self.view.bounds.size.width, 0)
        }
        
        //Setup and add images
        let imgView = UIImageView(frame: viewSize)
        imgView.image = img
        imgView.contentMode = .ScaleAspectFit
        
        scrollView.addSubview(imgView)

    }

}
