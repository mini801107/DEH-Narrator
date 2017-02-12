//
//  NarratorService.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/27.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import AVKit
import AVFoundation

class NarratorService: NSObject, NSNetServiceDelegate, GCDAsyncSocketDelegate, AVAudioPlayerDelegate {
    
    var service: NSNetService?
    var services = [NSNetService]()
    var socket: GCDAsyncSocket!
    var client_sockets = [GCDAsyncSocket]()
    
    override init(){}
    
    init(clients: [GCDAsyncSocket]) {
        client_sockets = clients
    }
    
    func startBroadcast() {
        socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        do {
            try socket.acceptOnPort(0) //use 0 here to make CocoaAsyncSocket choose a port which isn't in use
            //domain = "" : broadcasts to the whole subnet
            service = NSNetService(domain: "", type: "_narrator._tcp", name: "DEH_Narrator", port: Int32(socket.localPort))
        } catch {
            print("Error listening on port")
        }
        if let service = service {
            service.delegate = self
            service.publish()
        }
    }
    
    func netServiceDidPublish(sender: NSNetService) {
        guard let service = service else {
            return
        }
        print("Published successfully on port \(service.port) / domain: \(service.domain) / \(service.type) / \(service.name))")
    }

    func socket(sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("New socket accepted on host: \(newSocket.connectedHost), port: \(newSocket.connectedPort)")
        client_sockets.append(newSocket)
        socket = newSocket
        socket.delegate = self
        startBroadcast()
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        guard let sock = sock else {
            return
        }
        
        for i in 0 ..< client_sockets.count {
            if sock == client_sockets[i] {
                client_sockets.removeAtIndex(i)
                print("One socket disconnected")
                return
            }
        }
        
    }
    
    func sendPacket(packet: Packet) {
        //convert the packet to NSData using the NSKeyedArchiver (this makes use of the NSCoding)
        let packetData = NSKeyedArchiver.archivedDataWithRootObject(packet)
        var packetDataLength = packetData.length
        
        let buffer = NSMutableData(bytes: &packetDataLength, length: sizeof(Int32))
        buffer.appendData(packetData)
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        for i in 0 ..< client_sockets.count {
            let clientSocket = client_sockets[i]
            dispatch_async(queue) { () -> Void in
                clientSocket.writeData(buffer, withTimeout: -1, tag: 0) //timeout = -1 means forever
            }
        }
        
    }
    
    func getClientSockets() -> [GCDAsyncSocket] {
        return client_sockets
    }
    
    func streamData(data: NSData, type: String) {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        for i in 0 ..< client_sockets.count {
            let clientSocket = client_sockets[i]
            
            dispatch_async(queue) { () -> Void in
                //Send the length of audio file to clients first
                
                let infoPacket = (type == "audio") ? Packet(objectType: ObjectType.audioInfoPacket, object: data.length) : Packet(objectType: ObjectType.videoInfoPacket, object: data.length)
                let infoPacketData = NSKeyedArchiver.archivedDataWithRootObject(infoPacket)
                var infoPacketDataLength = infoPacketData.length
                
                let infoBuffer = NSMutableData(bytes: &infoPacketDataLength, length: sizeof(Int32))
                infoBuffer.appendData(infoPacketData)
                
                clientSocket.writeData(infoBuffer, withTimeout: -1, tag: 0) //timeout = -1 means forever
                
                //Then send the audio stream to clients
                let packet_count = data.length / 4096 + 1
                
                for k in 0 ..< packet_count {
                    let tmp = data.subdataWithRange(NSMakeRange(k*4096, 4096))
                    
                    let audioPacket = (type == "audio") ? Packet(objectType: ObjectType.audioPacket, object: tmp) : Packet(objectType: ObjectType.videoPacket, object: tmp)
                    let packetData = NSKeyedArchiver.archivedDataWithRootObject(audioPacket)
                    var packetDataLength = packetData.length
                    
                    let buffer = NSMutableData(bytes: &packetDataLength, length: sizeof(Int32))
                    buffer.appendData(packetData)
                    
                    clientSocket.writeData(buffer, withTimeout: -1, tag: 0) //timeout = -1 means forever
                }
            }
        }
    }
    
}

