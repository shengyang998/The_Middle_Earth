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
    @objc dynamic var sender: Contact?
    @objc dynamic var isSentBySelf = false

    class func set(id: Int,
                   payload: String,
                   time: Date,
                   type: Int = 0,
                   sender: Contact? = nil,
                   isread: Bool = false,
                   isSentBySelf: Bool = false) -> Message {
        let msg = Message()
        msg.id = id
        msg.payload = payload
        msg.time = time
        msg.type = type
        msg.isread = isread
        msg.sender = sender
        msg.isSentBySelf = isSentBySelf
        return msg
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func indexedProperties() -> [String] {
        return ["payload"]
    }

}

//extension Message {
//    var isSentBySelf: Bool {
////        return sender?.uuid == GlobalConstants.selfUUID
//        return id % 2 == 0
//    }
//}

extension Message {
    static func makeTestMessages(sender: Contact?) -> [Message] {
        let date = Date()
        let ids = sequence(first: 1) { $0 + 1 }.prefix(30)
        return ids.map {
            return Message.set(id: $0, payload: "Message --- Hello worl \($0)", time: date, type: 0, sender: sender)
        }
    }
}
