//
//  Helpers.swift
//  Shadowfax
//
//  Created by Ysy on 2018/5/26.
//  Copyright © 2018年 Ysy. All rights reserved.
//

import Foundation

class Helpers {
    
}

extension Data {

    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.pointee }
    }
    
}

extension Date {

    init(ticks: UInt64) {
        self.init(timeIntervalSince1970: Double(ticks)/10_000_000 - 62_135_596_800)
    }

    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }

}
