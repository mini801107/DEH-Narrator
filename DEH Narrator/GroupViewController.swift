//
//  GroupViewController.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/26.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit

class GroupViewController: UIViewController {

    var mode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func NarratorModeSelected(sender: UIButton) {
        mode = "Narrator"
        performSegueWithIdentifier("GroupToTable", sender: mode)
    }
    

    @IBAction func MemberModeSelected(sender: UIButton) {
        mode = "Member"
        performSegueWithIdentifier("GroupToTable", sender: mode)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GroupToTable" {
            if let destinationVC = segue.destinationViewController as? UINavigationController {
                if let tableVC = destinationVC.topViewController as? SearchTableViewController {
                    tableVC.mode = String(sender)
                }
            }
        }
    }
    
}
