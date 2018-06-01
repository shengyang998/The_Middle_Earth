//
//  Testing.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/31.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation

fileprivate let test_phone = "13432889167"

func test_getAddress_grpc() {
    let t = SDFAXNetworking.sharedInstance
//    t.getUUID(phone: test_phone) { (uuid) in
    let uuid = "12345678"
    Logger.info(message: "Get UUID: \(uuid)")
    t.getAddress(uuid: uuid, { (address) in
        Logger.info(message: "Get Address: \(address.ip): \(address.port)")
    })
//    }
}
