//
//  IndexViewController.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/26.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit

struct Var {
    static var userMode: String = ""
    static var narratorService: NarratorService! = nil
    static var narratorServiceBrowser: NarratorServiceBrowser! = nil
}

class IndexViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func GroupModeSelected(sender: UIButton) {
        Var.userMode = "Group"
        performSegueWithIdentifier("IndexToGroup", sender: nil)
    }

    @IBAction func IndividualModeSelected(sender: UIButton) {
        Var.userMode = "Individual"
        performSegueWithIdentifier("IndexToTable", sender: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "IndexToGroup" {
            //if let destinationVC = segue.destinationViewController as? GroupViewController {
            //}
        }
        
        if segue.identifier == "IndexToTable" {
            //if let destinationVC = segue.destinationViewController as? UINavigationController {
                //if let tableVC = destinationVC.topViewController as? SearchTableViewController {
                //}
            //}
        }
    }
}
