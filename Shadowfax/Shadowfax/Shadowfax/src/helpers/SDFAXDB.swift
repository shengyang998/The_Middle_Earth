//
//  SDFAXDAO.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/27.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation
import RealmSwift

class SDFAXDB {

    class var databaseURL: URL? { return Realm.Configuration().fileURL }

    class func setDefaultRealmForUser(username: String) {
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("\(GlobalConstants.selfUUID).realm")
        Realm.Configuration.defaultConfiguration = config
    }

    @inline(__always)
    class func makeConnection() -> Realm! {
        do {
            return try Realm()
        } catch {
            Logger.severe(message: "Open Realm Database failed at path: \(String(describing: databaseURL?.absoluteString))")
            return nil
        }
    }

    @inline(__always)
    class func migrateDatabase(toVersion version: UInt64) {
        let config = Realm.Configuration(
            schemaVersion: version,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < version) {
                    Logger.info(message: "Migration database from version \(oldSchemaVersion) to version \(version) compeleted.")
                    // rename:
                    // migration.renameProperty(onType: Person.className(), from: "yearsSinceBirth", to: "age")
                }
        })
        Realm.Configuration.defaultConfiguration = config
    }

}
