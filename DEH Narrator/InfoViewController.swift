//
//  InfoViewController.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/26.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import CocoaAsyncSocket

class InfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    let sendhttprequest = SendHttpRequest()
    var POIset = [JSON]()
    var POIinfo: JSON = nil
    var desc: String = ""
    var LOI_AOI_title: String = "景線名稱"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        titleLabel.text = LOI_AOI_title
        descriptionTextView.text = desc
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Implement TableView data source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return POIset.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("simpleCell", forIndexPath: indexPath) as! SimpleCustomCell
        cell.title.text = POIset[indexPath.row]["title"].stringValue
        
        let identifier = POIset[indexPath.row]["identifier"].stringValue
        switch identifier {
        case "user" :
            cell.identifier.image = UIImage(named: "table_icon_user")
            break
        case "expert" :
            cell.identifier.image = UIImage(named: "table_icon_expert")
            break
        case "docent" :
            cell.identifier.image = UIImage(named: "table_icon_docent")
            break
        default :
            cell.identifier.image = UIImage(named: "table_icon_default")
            break
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        sendhttprequest.authorization(){ token in
            let id = self.POIset[indexPath.row]["id"].stringValue
            let specific_poi_function = "https://api.deh.csie.ncku.edu.tw/api/v1/pois/search" + "?q=" + id
            
            self.sendhttprequest.getNearbyData(specific_poi_function, token: token!){ PoiJSONString in
                let PoiJSONData = PoiJSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                let PoiJSONObj = JSON(data: PoiJSONData!)
                let PoiJSONArray = PoiJSONObj["results"].arrayValue
                self.POIinfo = PoiJSONArray[0]
                
                //send POI info to clients
                if Var.userMode == "Narrator" {
                    do{
                        let POIdata = try self.POIinfo.rawData()
                        let POIinfoPacket = Packet(objectType: ObjectType.POIInfoPacket, object: POIdata)
                        Var.narratorService.sendPacket(POIinfoPacket)
                    } catch {
                        print("Error sending POI info to clients")
                    }
                }
     
                self.performSegueWithIdentifier("InfoToDetail", sender: self)
            }
        }
    }
    
    // MARK : - Peform unwind segue to MapView
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "InfoToDetail" {
            if let destinationVC = segue.destinationViewController as? DetailViewController {
                destinationVC.POIinfo = POIinfo
            }
        }
    }

    
}
