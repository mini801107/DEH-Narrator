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

class ImageViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    var mediaSet = [JSON]()
    var picCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let navigationVC = self.parentViewController as! UINavigationController
        let navigationItem_height = navigationVC.navigationBar.bounds.height
        
        scrollView.backgroundColor = UIColor.blackColor()
        scrollView.pagingEnabled = true
        scrollView.contentSize = CGSizeMake(CGFloat(picCount)*self.view.bounds.size.width, self.view.bounds.size.height-navigationItem_height)
        
        //Setup each view sizeMPMoviePlayerController
        var viewSize = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-navigationItem_height)
        
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
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
