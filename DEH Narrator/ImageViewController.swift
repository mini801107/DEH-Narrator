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

class ImageViewController: UIViewController, ImagePacketHandleDelegate, POIInfoPacketHandleDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    
    var mediaSet = [JSON]()
    var picCount: Int = 0
    var viewSize = CGRect()
    var imagePacket_count: Int = 0
    var redundantPacket: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let navigationVC = self.parentViewController as! UINavigationController
        let navigationItem_height = navigationVC.navigationBar.bounds.height
        scrollView.backgroundColor = UIColor.blackColor()
        scrollView.pagingEnabled = true
        scrollView.contentSize = CGSizeMake(CGFloat(picCount)*self.view.bounds.size.width, self.view.bounds.size.height-navigationItem_height)
        
        //Setup each view sizeMPMoviePlayerController
        viewSize = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-navigationItem_height)
        
        if Var.userMode == "Member" {
            imagePacket_count = 0
            redundantPacket = false
            Var.narratorServiceBrowser.imageDelegate = self
            Var.narratorServiceBrowser.poiDelegate = self
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
                if Var.userMode == "Narrator" {
                    let imagePacket = Packet(objectType: ObjectType.imagePacket, object: image)
                    Var.narratorService.sendPacket(imagePacket)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePacket(img: UIImage) {
        if redundantPacket == true {
            print("drop packet")
           return
        }
        
        imagePacket_count += 1
    
        // Offset view size
        if imagePacket_count != 1 {
            viewSize = CGRectOffset(viewSize, self.view.bounds.size.width, 0)
        }
        
        // Setup and add images
        let imgView = UIImageView(frame: viewSize)
        imgView.image = img
        imgView.contentMode = .ScaleAspectFit
        
        scrollView.addSubview(imgView)
    }
    
    // When receive same image info, ignore
    func imageInfoPacket(count: Int) {
        redundantPacket = true
        print("redundant packet")
    }
    
    // When receive POI info, unwind to Detail View and present new POI info
    func POIInfoPacket(POIdata: NSData) {
        redundantPacket = false
        let str = POIdata.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        performSegueWithIdentifier("ImageToDetailUnwind", sender: str)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ImageToDetailUnwind" {
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
