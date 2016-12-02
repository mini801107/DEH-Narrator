//
//  NarratorServiceBrowser.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/27.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import Foundation
import SwiftyJSON
import CocoaAsyncSocket

protocol PacketHandleDelegate: class {
    func textPacket(text: String)
    func imageInfoPacket(count: Int)
    func audioPacket(audio: NSData)
    func audioInfoPacket(length: Int)
    func POIInfoPacket(POIdata: NSData)
}

protocol ImagePacketHandleDelegate: class {
    func imagePacket(img: UIImage)
}

protocol VideoPacketHandleDelegate: class {
    func videoPacket(video: NSData)
    func videoInfoPacket(length: Int)
}

protocol POIInfoPacketHandleDelegate: class {
    func POIInfoPacket(POIdata: NSData)
}

class NarratorServiceBrowser: NSObject, NSNetServiceDelegate, NSNetServiceBrowserDelegate, GCDAsyncSocketDelegate {
    
    weak var delegate: PacketHandleDelegate?
    weak var imageDelegate: ImagePacketHandleDelegate?
    weak var videoDeledate: VideoPacketHandleDelegate?
    weak var poiDelegate: POIInfoPacketHandleDelegate?
    
    internal var connectToServer: Bool = false
    var socket: GCDAsyncSocket!
    var services: NSMutableArray!
    var serviceBrowser: NSNetServiceBrowser!
    var service: NSNetService!
    
    override init(){}
    
    init(sock: GCDAsyncSocket){
        socket = sock
    }
    
    func startBrowsing() {
        if services != nil {
            services.removeAllObjects()
        } else {
            services = NSMutableArray()
        }
        
        serviceBrowser = NSNetServiceBrowser()
        serviceBrowser.delegate = self
        serviceBrowser.searchForServicesOfType("_narrator._tcp", inDomain: "")
    }
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        services.addObject(service)
        connect() //automatically call the function connect when a service is found
    }
    
    func connect() {
        service = services.firstObject! as! NSNetService
        service.delegate = self
        service.resolveWithTimeout(30.0)
    }
    
    func disconnect() {
        socket.disconnect()
        connectToServer = false
        print("Disconnect with service")
    }
    
    func netServiceDidResolveAddress(sender: NSNetService) {
        if connectWithService(sender) {
            connectToServer = true
            print("Did connect with service")
        } else {
            print("Error connecting with service")
        }
    }
    
    func connectWithService(service: NSNetService) -> Bool {
        var isConnected = false
        let addresses: NSArray = service.addresses!
        
        if ( socket == nil || !socket.isConnected ) {
            socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
            
            //Every service has a list of addresses from which multiple might not work
            //So we need to iterate through all addresses and try to find one that works
            var count = 0
            while( !isConnected && addresses.count >= count ) {
                let address = addresses.objectAtIndex(count) as! NSData
                count += 1
                do {
                    try socket.connectToAddress(address)
                    isConnected = true
                } catch {
                    print("Failed to connect")
                }
            }
        } else {
            isConnected = socket.isConnected
        }
        return isConnected
    }
    
    func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        service.delegate = nil
    }
    
    func getSocket() -> GCDAsyncSocket {
        return socket
    }
    
    //add the delegate function that will get called when the socket is connected
    func socket(sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        socket.readDataToLength(UInt(sizeof(Int32)), withTimeout: -1, tag: 1)
        print("connect to host")
    }
    
    func socket(sock: GCDAsyncSocket, didReadData data: NSData, withTag tag: Int) {
        //when the tag is 1, read the number from the header that contains the length of the body
        if tag == 1 {
            var bodyLength: Int32 = 0
            data.getBytes(&bodyLength, length: sizeof(Int32))
            print("Header received with bodylength: \(bodyLength)")
            socket.readDataToLength(UInt(bodyLength), withTimeout: -1, tag:2)
        } else if tag == 2 {
            //use the NSKeyedUnarchiver (which makes use of NSCoding) to convert the NSData back to our Packet object
            let packet = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Packet
            handlePacket(packet)
            socket.readDataToLength(UInt(sizeof(Int32)), withTimeout: -1, tag:1)
        }
        
    }
    
    //Define types of received packet and send to view controller
    func handlePacket(packet: Packet) {
        switch packet.objectType! {
        case .textPacket :
            let text = packet.getObject() as String
            delegate?.textPacket(text)
            break
        case .imagePacket :
            let img = packet.getObject() as UIImage
            imageDelegate?.imagePacket(img)
            break
        case .audioPacket :
            let audio = packet.getObject() as NSData
            delegate?.audioPacket(audio)
            break
        case .videoPacket :
            let video = packet.getObject() as NSData
            videoDeledate?.videoPacket(video)
            break
        case .imageInfoPacket :
            let count = packet.getObject() as Int
            delegate?.imageInfoPacket(count)
            break
        case .audioInfoPacket :
            let length = packet.getObject() as Int
            delegate?.audioInfoPacket(length)
            break
        case .videoInfoPacket :
            let length = packet.getObject() as Int
            videoDeledate?.videoInfoPacket(length)
            break
        case .POIInfoPacket :
            let POIdata = packet.getObject() as NSData
            if(delegate != nil) {
                delegate?.POIInfoPacket(POIdata)
            }
            else if(poiDelegate != nil) {
                poiDelegate?.POIInfoPacket(POIdata)
            }
            break
        }
        
    }
    
}