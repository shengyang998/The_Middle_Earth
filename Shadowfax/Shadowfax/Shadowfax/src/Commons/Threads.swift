//
//  Threads.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/5.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

func syncInMain<T>(_ todo: () throws -> T) rethrows -> T {
    if Thread.isMainThread { return try todo() }
    return try DispatchQueue.main.sync(execute: todo)
}

func nextRunLoopPeriod(_ todo: @escaping () -> ()) {
    assert(Thread.isMainThread)
    DispatchQueue.main.async(execute: todo)
}
