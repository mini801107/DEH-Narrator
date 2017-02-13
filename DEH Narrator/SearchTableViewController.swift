//
//  SearchTableViewController.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/26.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation //for current location
import Foundation
import Alamofire
import SwiftyJSON
import CocoaAsyncSocket

class SearchTableViewController: UIViewController, CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDelegate, UITableViewDataSource, POIInfoPacketHandleDelegate {
    
    @IBOutlet weak var settingsWindow: UIView!
    @IBOutlet weak var searchingTypeSelector: UIPickerView!
    @IBOutlet weak var searchingRadiusLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var listLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    let sendhttprequest = SendHttpRequest()
    var searchingRadius: Int = 3000
    var searchingType: String = "附近景點"
    var username: String = ""
    var password: String = ""
    var dataArray = Array<JSON>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsWindow.hidden = true
        settingsWindow.layer.cornerRadius = 10
        searchingTypeSelector.dataSource = self
        searchingTypeSelector.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        if Var.userMode == "Member" {
            searchButton.enabled = false
            Var.narratorServiceBrowser.poiDelegate = self
        }
        else {
            /* Get current location */
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if Var.userMode == "Member" {
            searchButton.enabled = false
            Var.narratorServiceBrowser.poiDelegate = self
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /***************************** definitions of searching types pickerview ******************************/
    let options = [NSLocalizedString("NEARBY_POIS", comment:"nearby_pois"),
                   NSLocalizedString("NEARBY_LOIS", comment:"nearby_lois"),
                   NSLocalizedString("NEARBY_AOIS", comment:"nearby_aois"),
                   NSLocalizedString("MY_POIS", comment:"my_pois"),
                   NSLocalizedString("MY_LOIS", comment:"my_lois"),
                   NSLocalizedString("MY_AOIS", comment:"my_aois")]
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if username == "" {
            return 3
        }
        else {
            return options.count
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        searchingType = options[pickerView.selectedRowInComponent(0)]
    }
    /******************************************************************************************************/

    
    /********************** definitions and functions of components in submit window **********************/
    @IBAction func searchingRadiusChanged(sender: AnyObject) {
        let currentValue = Int(radiusSlider.value)
        searchingRadius = currentValue * 1000
        searchingRadiusLabel.text = NSLocalizedString("RANGE", comment:"range") + " : \(currentValue)" + NSLocalizedString("KM", comment:"km")
    }
    
    @IBAction func submitButtonTapped(sender: AnyObject) {
        searchDataFromServer(currentLocation.coordinate)
        settingsWindow.hidden = true
    }
   
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        settingsWindow.hidden = true
    }

    /******************************************************************************************************/
    
    
    /***************************** Login and Search Button in Navigation Item ****************************/
    @IBAction func loginButtonTapped(sender: AnyObject) {
        if username == "" {   // when user has not login
            var userTextField: UITextField?
            var pwdTextField: UITextField?
            
            let loginAlert = UIAlertController(title: NSLocalizedString("LOGIN", comment:"login") ,message: NSLocalizedString("ENTER_ACC_AND_PWD", comment:"enter_acc_and_pwd"), preferredStyle: .Alert)
            loginAlert.addAction(UIAlertAction(title: NSLocalizedString("SUBMIT", comment:"submit"), style: .Default, handler: { action in
                if userTextField!.text! == "" || pwdTextField!.text! == "" {
                    let alert = UIAlertController(title: NSLocalizedString("LOGIN_FAILED", comment:"login_failed"), message: NSLocalizedString("INVALID_ACC_OR_PWD", comment:"invalid_acc_or_pwd"), preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:"ok"), style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else {
                    self.sendhttprequest.authorization(){ token in
                        self.sendhttprequest.userLogin(token!, user: userTextField!.text!, pwd: pwdTextField!.text!){ msg in
                            let msgString = msg!.dataUsingEncoding(NSUTF8StringEncoding)
                            let JSONObj = JSON(data: msgString!)
                            let uname = JSONObj["username"].stringValue
                            if uname != userTextField!.text! {
                                let alert = UIAlertController(title: NSLocalizedString("LOGIN_FAILED", comment:"login_failed"), message: NSLocalizedString("INVALID_ACC_OR_PWD", comment:"invalid_acc_or_pwd"), preferredStyle: .Alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:"ok"), style: .Default, handler: nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                            }
                            else {
                                self.username = uname
                                self.password = pwdTextField!.text!
                                self.searchingTypeSelector.reloadAllComponents()
                                let alert = UIAlertController(title: NSLocalizedString("LOGIN_SUCCESS", comment:"login_success"), message: uname+NSLocalizedString("WELCOME_BACK", comment:"welcome_back"), preferredStyle: .Alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:"ok"), style: .Default, handler: nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                                
                            }
                        }
                    }
                }
            }))
            loginAlert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment:"cancel"), style: .Cancel, handler: nil))
            loginAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                textField.placeholder = NSLocalizedString("ACCOUNT", comment:"account")
                textField.secureTextEntry = false
                userTextField = textField
            })
            loginAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                textField.placeholder = NSLocalizedString("PASSWORD", comment:"password")
                textField.secureTextEntry = true
                pwdTextField = textField
            })
            self.presentViewController(loginAlert, animated: true, completion: nil)
        }
        else {  // when user has login
            username = ""
            password = ""
            clearTable()
            searchingTypeSelector.reloadAllComponents()
            let alert = UIAlertController(title: NSLocalizedString("LOGOUT_SUCCESS", comment:"logout_success"), message: NSLocalizedString("GUEST_STATE", comment:"guest_state"), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:"ok"), style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func searchButtonTapped(sender: AnyObject) {
        settingsWindow.hidden = false
    }
    
    @IBAction func homeButtonTapped(sender: AnyObject) {
        performSegueWithIdentifier("BackToIndexUnwind", sender: self)
    }
    
    /******************************************************************************************************/
    
    
    /************************************** Table view data source ****************************************/
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 70
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! CustomCell
        
        let str = searchingType as NSString
        if str.substringWithRange(NSRange(location: 2, length: 2)) == "景點" {
            cell.title.text = dataArray[indexPath.row]["POI_title"].stringValue
            cell.desc.text = dataArray[indexPath.row]["POI_description"].stringValue
        }
        else if str.substringWithRange(NSRange(location: 2, length: 2)) == "景線" {
            cell.title.text = dataArray[indexPath.row]["LOI_title"].stringValue
            cell.desc.text = dataArray[indexPath.row]["LOI_description"].stringValue
        }
        else if str.substringWithRange(NSRange(location: 2, length: 2)) == "景區" {
            cell.title.text = dataArray[indexPath.row]["AOI_title"].stringValue
            cell.desc.text = dataArray[indexPath.row]["AOI_description"].stringValue
        }
        
        
        let identifier = dataArray[indexPath.row]["identifier"].stringValue
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
        
        if str.substringWithRange(NSRange(location: 2, length: 2)) == "景點" {
            let media_set = dataArray[indexPath.row]["media_set"].arrayValue
            if media_set != [] {
                let media_type: String! = media_set[0]["media_type"].stringValue
                switch media_type {
                case "jpg" :
                    cell.POIicon.image = UIImage(named: "table_type_image")
                    break
                case "aac" :
                    cell.POIicon.image = UIImage(named: "table_type_audio")
                    break
                case "mp4" :
                    cell.POIicon.image = UIImage(named: "table_type_video")
                    break
                default :
                    cell.POIicon.image = nil
                    break
                }
            }
            else {
                cell.POIicon.image = nil
            }
        }
        else {
            cell.POIicon.image = nil
        }
        
        return cell
    }
    
    func clearTable()
    {
        dataArray.removeAll()
        listLabel.text = NSLocalizedString("LIST", comment:"list")
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let str = searchingType as NSString
        if str.substringWithRange(NSRange(location: 2, length: 2)) == "景點" {
            //send POI info to clients
            if Var.userMode == "Narrator" {
                do{
                    let POIdata = try dataArray[indexPath.row].rawData()
                    let POIinfoPacket = Packet(objectType: ObjectType.POIInfoPacket, object: POIdata)
                    Var.narratorService.sendPacket(POIinfoPacket)
                } catch {
                    print("Error sending POI info to clients")
                }
            }
            performSegueWithIdentifier("TableToDetail", sender: indexPath.row)
        }
        else {
            performSegueWithIdentifier("TableToInfo", sender: indexPath.row)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TableToDetail" {
            if let destinationVC = segue.destinationViewController as? DetailViewController {
                destinationVC.POIinfo = dataArray[(sender?.integerValue)!]
            }
        }
        
        if segue.identifier == "TableToInfo" {
            let POIset = dataArray[(sender?.integerValue)!]["POI_set"].arrayValue
            if let destinationVC = segue.destinationViewController as? InfoViewController {
                let str = searchingType as NSString
                if str.substringWithRange(NSRange(location: 2, length: 2)) == "景線" {
                    destinationVC.LOI_AOI_title = dataArray[(sender?.integerValue)!]["LOI_title"].stringValue
                    destinationVC.desc = dataArray[(sender?.integerValue)!]["LOI_description"].stringValue
                    destinationVC.rights = dataArray[(sender?.integerValue)!]["rights"].stringValue
                }
                else if str.substringWithRange(NSRange(location: 2, length: 2)) == "景區" {
                    destinationVC.LOI_AOI_title = dataArray[(sender?.integerValue)!]["AOI_title"].stringValue
                    destinationVC.desc = dataArray[(sender?.integerValue)!]["AOI_description"].stringValue
                    destinationVC.rights = dataArray[(sender?.integerValue)!]["rights"].stringValue
                }
                destinationVC.POIset = POIset
            }
        }
        if segue.identifier == "BackToIndexUnwind" {
            dataArray.removeAll()
            username = ""
            password = ""
            Var.narratorService = nil
            Var.narratorServiceBrowser = nil
            Var.userMode = ""
        }
    }
    /******************************************************************************************************/
    
    
    /********************************* MARK : - Location Delegate Methods *********************************/
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        currentLocation = locations.last!
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Errors: " + error.localizedDescription)
    }
    /******************************************************************************************************/

    
    /******************* MARK : - Send HTTP request to get POI/LOI/AOI data from server *******************/
    func searchDataFromServer(coordinate: CLLocationCoordinate2D)
    {
        print("latitude = \(coordinate.latitude), longitude = \(coordinate.longitude)\n")
        
        /* display loading view */
        let loadingView = UIAlertController(title: nil, message: "Loading ...", preferredStyle: .Alert)
        loadingView.view.tintColor = UIColor.blackColor()
        let loadingIndicator = UIActivityIndicatorView(frame: CGRectMake(10, 5, 50, 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        loadingIndicator.startAnimating()
        loadingView.view.addSubview(loadingIndicator)
        presentViewController(loadingView, animated: true, completion: nil)
        
        let str = searchingType as NSString
        if str.substringWithRange(NSRange(location: 0, length: 2)) == "附近" {
            var url = String()
            if searchingType == "附近景點" {
                url = "https://api.deh.csie.ncku.edu.tw/api/v1/pois?"
                url += ("lat=" + "\(coordinate.latitude)&lng=" + "\(coordinate.longitude)&dis=" + "\(searchingRadius)")
            }
            else if searchingType == "附近景線" {
                url = "https://api.deh.csie.ncku.edu.tw/api/v1/lois?"
                url += ("lat=" + "\(coordinate.latitude)&lng=" + "\(coordinate.longitude)")
        
            }
            else if searchingType == "附近景區" {
                url = "https://api.deh.csie.ncku.edu.tw/api/v1/aois?"
                url += ("lat=" + "\(coordinate.latitude)&lng=" + "\(coordinate.longitude)")
            }
        
            sendhttprequest.authorization(){ token in
                self.sendhttprequest.getNearbyData(url, token: token!){ JSONString in
                    let JSONData = JSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                    let jsonObj = JSON(data: JSONData!)
                    self.dataArray.removeAll()
                    self.dataArray = jsonObj["results"].arrayValue
        
                    switch self.searchingType {
                        case "附近景點": self.listLabel.text = NSLocalizedString("NEARBY_POIS", comment:"nearby_pois"); break
                        case "附近景線": self.listLabel.text = NSLocalizedString("NEARBY_LOIS", comment:"nearby_lois"); break
                        case "附近景區": self.listLabel.text = NSLocalizedString("NEARBY_AOIS", comment:"nearby_aois"); break
                        case "我的景點": self.listLabel.text = NSLocalizedString("MY_POIS", comment:"my_pois"); break
                        case "我的景線": self.listLabel.text = NSLocalizedString("MY_LOIS", comment:"my_lois"); break
                        case "我的景區": self.listLabel.text = NSLocalizedString("MY_AOIS", comment:"my_aois"); break
                        default: self.listLabel.text = NSLocalizedString("LIST", comment:"list"); break
                    }
                    self.tableView.reloadData()
                    self.dismissViewControllerAnimated(false, completion: nil)
                }
            }
        }
        else if str.substringWithRange(NSRange(location: 0, length: 2)) == "我的" {
            var url = String()
            if searchingType == "我的景點" {
                url = "https://api.deh.csie.ncku.edu.tw/api/v1/users/pois?"
                url += ("lat=" + "\(coordinate.latitude)&lng=" + "\(coordinate.longitude)&dis=" + "\(searchingRadius)")
            }
            else if searchingType == "我的景線" {
                url = "https://api.deh.csie.ncku.edu.tw/api/v1/users/lois?"
                url += ("lat=" + "\(coordinate.latitude)&lng=" + "\(coordinate.longitude)")
                
            }
            else if searchingType == "我的景區" {
                url = "https://api.deh.csie.ncku.edu.tw/api/v1/users/aois?"
                url += ("lat=" + "\(coordinate.latitude)&lng=" + "\(coordinate.longitude)")
            }
            
            sendhttprequest.authorization(){ token in
                self.sendhttprequest.getUserData(url, token: token!, user: self.username, pwd: self.password){ JSONString in
                    let JSONData = JSONString!.dataUsingEncoding(NSUTF8StringEncoding)
                    let jsonObj = JSON(data: JSONData!)
                    self.dataArray.removeAll()
                    self.dataArray = jsonObj["results"].arrayValue
                    
                    switch self.searchingType {
                        case "附近景點": self.listLabel.text = NSLocalizedString("NEARBY_POIS", comment:"nearby_pois"); break
                        case "附近景線": self.listLabel.text = NSLocalizedString("NEARBY_LOIS", comment:"nearby_lois"); break
                        case "附近景區": self.listLabel.text = NSLocalizedString("NEARBY_AOIS", comment:"nearby_aois"); break
                        case "我的景點": self.listLabel.text = NSLocalizedString("MY_POIS", comment:"my_pois"); break
                        case "我的景線": self.listLabel.text = NSLocalizedString("MY_LOIS", comment:"my_lois"); break
                        case "我的景區": self.listLabel.text = NSLocalizedString("MY_AOIS", comment:"my_aois"); break
                        default: self.listLabel.text = NSLocalizedString("LIST", comment:"list"); break
                    }
                    self.tableView.reloadData()
                    self.dismissViewControllerAnimated(false, completion: nil)
                }
            }
        }
    }
    /******************************************************************************************************/
    
    func POIInfoPacket(POIdata: NSData) {
        let json = JSON(data: POIdata)
        let POIinfo = json
        dataArray.removeAll()
        dataArray.append(POIinfo)
        performSegueWithIdentifier("TableToDetail", sender: 0)
    }
    
    @IBAction func unwindToTable(segue: UIStoryboardSegue) {
    }
}
