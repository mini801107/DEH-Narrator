//
//  Packet.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/27.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import Foundation
import SwiftyJSON

enum ObjectType: Int {
    case textPacket = 1
    case imagePacket = 2
    case audioPacket = 3
    case videoPacket = 4
    case imageInfoPacket = 5
    case audioInfoPacket = 6
    case videoInfoPacket = 7
    case POIInfoPacket = 8
}

@objc(Packet)
class Packet: NSObject, NSCoding {
    var objectType: ObjectType!
    var object: AnyObject!
    
    required convenience init(coder decoder: NSCoder) {
        self.init()
        objectType = ObjectType(rawValue: decoder.decodeObjectForKey("objectType") as! Int)
        object = decoder.decodeObjectForKey("object") as! NSObject
    }
    
    convenience init(objectType: ObjectType, object: AnyObject) {
        self.init()
        self.objectType = objectType
        self.object = object
    }
    
    func encodeWithCoder(coder: NSCoder) {
        if let objectType = objectType {
            coder.encodeObject(objectType.rawValue, forKey: "objectType")
        }
        
        if let object = object {
            coder.encodeObject(object, forKey: "object")
        }
    }
    
    func getObject<Element>() -> Element {
        return object as! Element
    }
    
    func size() -> Int {
        return object.size()
    }
    
}
