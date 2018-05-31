//
//  DBConnection.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/31.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation
import RealmSwift

class DBConnection {
    static var db: Realm {
        return try! Realm()
    }
}
