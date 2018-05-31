//
//  Operators.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/22.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

precedencegroup Bind {
    associativity: left
    higherThan: DefaultPrecedence
}

precedencegroup FunctorMap {
    associativity: left
    higherThan: Bind
}

precedencegroup FunctionApplicative {
    associativity: left
    higherThan: MultiplicationPrecedence
}

precedencegroup FunctionCompositionR {
    associativity: right
    higherThan: FunctionApplicative
}

precedencegroup FunctionCompositionL {
    associativity: left
    higherThan: FunctionCompositionR
}

infix operator <^> : FunctorMap
infix operator <*> : FunctorMap
infix operator >>- : Bind
infix operator <<< : FunctionCompositionR
infix operator >>> : FunctionCompositionL
infix operator |> : FunctionApplicative
