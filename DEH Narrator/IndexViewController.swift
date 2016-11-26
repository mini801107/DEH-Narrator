//
//  IndexViewController.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/26.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit

class IndexViewController: UIViewController {

    var mode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func GroupModeSelected(sender: UIButton) {
        mode = "Group"
        performSegueWithIdentifier("IndexToGroup", sender: mode)
    }

    @IBAction func IndividualModeSelected(sender: UIButton) {
        mode = "Individual"
        performSegueWithIdentifier("IndexToTable", sender: mode)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "IndexToGroup" {
            if let destinationVC = segue.destinationViewController as? GroupViewController {
                destinationVC.mode = String(sender)
            }
        }
        
        if segue.identifier == "IndexToTable" {
            if let destinationVC = segue.destinationViewController as? UINavigationController {
                if let tableVC = destinationVC.topViewController as? SearchTableViewController {
                    tableVC.mode = String(sender)
                }
            }
        }
    }
}
