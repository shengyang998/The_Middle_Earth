//
//  Error.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/7.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

struct UnknowError: Error { }

enum WALLError: Error {
    case casting(obj: Any, toType: Any.Type)
}
