//
//  Time.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/8.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

func timeElapsed(_ block: () throws -> ()) rethrows -> TimeInterval {
    let start = CFAbsoluteTimeGetCurrent()
    try block()
    return CFAbsoluteTimeGetCurrent() - start
}

func after(_ timeInterval: TimeInterval, onMainThread: Bool = true, _ todo: @escaping () -> ()) {
    if onMainThread { DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval, execute: todo) }
    else { DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval, execute: todo) }
}
