//
//  Message.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/31.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation
import RealmSwift

class Message: Object {
    
    @objc dynamic var id: Int = 1
    @objc dynamic var payload: String = ""
    @objc dynamic var time: Date = Date()
    @objc dynamic var type: Int = 1
    @objc dynamic var isread: Bool = false

    class func set(id: Int, payload: String, time: Date, type: Int = 0, isread: Bool = false) -> Message {
        let msg = Message()
        msg.id = id
        msg.payload = payload
        msg.time = time
        msg.type = type
        msg.isread = isread
        return msg
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func indexedProperties() -> [String] {
        return ["payload"]
    }

}
