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
    
    var serverSocket: GCDAsyncSocket?
    var clientSocket: GCDAsyncSocket?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func NarratorModeSelected(sender: UIButton) {
        if Var.userMode == "Member" {
            Var.narratorServiceBrowser = nil
        }
        Var.userMode = "Narrator"
        Var.narratorService = NarratorService()
        Var.narratorService.startBroadcast()
        
        let alert = UIAlertController(title: "開放連線", message: "等待成員連線即可開始導覽", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "確認", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        startButton.hidden = false
    }
    

    @IBAction func MemberModeSelected(sender: UIButton) {
        if Var.userMode == "Narrator" {
            Var.narratorService = nil
        }
        Var.userMode = "Member"
        Var.narratorServiceBrowser = NarratorServiceBrowser()
        Var.narratorServiceBrowser.startBrowsing()
        startButton.hidden = false
    }

    @IBAction func startButtonTapped(sender: AnyObject) {
        if Var.userMode == "Narrator" {
            performSegueWithIdentifier("GroupToTable", sender: nil)
        }
        else if Var.userMode == "Member" {
            if Var.narratorServiceBrowser.connectToServer == false {
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
//            if let destinationVC = segue.destinationViewController as? UINavigationController {
//                if let tableVC = destinationVC.topViewController as? SearchTableViewController {
//                    
//                }
//            }
        }
    }
    
}
