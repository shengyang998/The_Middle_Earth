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
        // MARK: to be continue...
    }

    func syncFullname() {
        self.fullName = "\(self.lastName) \(self.firstName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Contact {
    static func makeTest() -> Contact {
        let contact = Contact()
        contact.uuid = "HELLLLLO"
        contact.fullName = "与生养"
        return contact
    }
}
