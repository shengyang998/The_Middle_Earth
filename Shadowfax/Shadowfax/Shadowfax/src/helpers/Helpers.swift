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

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

extension SDFAXmsgSend {
    init(id: UInt64, payload: String, time: UInt64) {
        self.id = id
        self.payload = payload
        self.time = time
    }
}

extension SDFAXmsgRecv {
    init(id: UInt64, isread: Bool, time: UInt64) {
        self.id = id
        self.isread = isread
        self.time = time
    }
}

extension SDFAXSignalRequest {
    init(uuid: String, signal: Int32, msg: String) {
        self.uuid = uuid
        self.signal = signal
        self.msg = msg
    }
}

extension SDFAXSendToRequest {
    init(sourceUuid: String, distUuid: String) {
        self.sourceUuid = sourceUuid
        self.distUuid = distUuid
    }
}

