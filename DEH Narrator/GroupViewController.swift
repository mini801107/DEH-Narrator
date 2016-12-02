//
//  GroupViewController.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/26.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class GroupViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    
    var mode: String = ""
    var serverSocket: GCDAsyncSocket?
    var clientSocket: GCDAsyncSocket?
    var narratorService: NarratorService!
    var narratorServiceBrowser: NarratorServiceBrowser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func NarratorModeSelected(sender: UIButton) {
        if mode == "Member" {
            narratorServiceBrowser = nil
        }
        mode = "Narrator"
        narratorService = NarratorService()
        narratorService.startBroadcast()
        
        let alert = UIAlertController(title: "開放連線", message: "等待成員連線即可開始導覽", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        startButton.hidden = false
    }
    

    @IBAction func MemberModeSelected(sender: UIButton) {
        if mode == "Narrator" {
            narratorService = nil
        }
        mode = "Member"
        narratorServiceBrowser = NarratorServiceBrowser()
        narratorServiceBrowser.startBrowsing()
        startButton.hidden = false
    }

    @IBAction func startButtonTapped(sender: AnyObject) {
        if mode == "Narrator" {
            performSegueWithIdentifier("GroupToTable", sender: nil)
        }
        else if mode == "Member" {
            if narratorServiceBrowser.connectToServer == false {
                let alert = UIAlertController(title: "尚未連線", message: "請點擊重試", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            else{
                performSegueWithIdentifier("GroupToTable", sender: nil)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GroupToTable" {
            if let destinationVC = segue.destinationViewController as? UINavigationController {
                if let tableVC = destinationVC.topViewController as? SearchTableViewController {
                    tableVC.mode = mode
                    if mode == "Narrator" {
                        tableVC.narratorService = self.narratorService
                    }
                    else if mode == "Member" {
                        tableVC.narratorServiceBrowser = self.narratorServiceBrowser
                    }
                }
            }
        }
    }
    
}
