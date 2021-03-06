//
//  Contact.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/31.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation
import RealmSwift

class Contact: Object {
    @objc dynamic var uuid = ""
    @objc dynamic var phone = ""
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
    @objc dynamic var fullName = ""
    @objc dynamic var pinyin = ""
    @objc dynamic var avatarPath = ""
    
    override static func primaryKey() -> String {
        return "uuid"
    }
}

extension Contact {
    func syncPinyinFullname() {
        self.syncPinyin()
        self.syncFullname()
    }

    func syncPinyin() {
        // TODO: to be continue...
    }

    func syncFullname() {
        self.fullName = "\(self.lastName) \(self.firstName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Contact {
    static func makeAliceTest() -> Contact {
        let contact = Contact()
        contact.uuid = "3c817a80-6e93-4b68-9e5c-c5297625405f"
        contact.fullName = "Bob"
        return contact
    }
    static func makeBobTest() -> Contact {
        let contact = Contact()
        contact.uuid = "9f7f6da0-bbb1-4c24-abb3-85e22809983a"
        contact.fullName = "Alice"
        return contact
    }
}
