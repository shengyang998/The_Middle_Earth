//
//  Simple.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/22.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

func flip<A, B, C>(_ f: @escaping (A) -> (B) -> C) -> (B) -> (A) -> C {
    return { b in { a in f(a)(b) } }
}

func flip<A, B>(_ f: @escaping (A) -> () -> B) -> () -> (A) -> B {
    return { { a in f(a)() } }
}

func flip<A, B>(_ f: @escaping () -> (A) -> B) -> (A) -> () -> B {
    return { a in { f()(a) }}
}

func const<A, B>(_ v: @autoclosure @escaping () -> B) -> (A) -> B {
    return { _ in v() }
}

func const<A, B>(_ v: @escaping () -> B) -> (A) -> B {
    return { _ in v() }
}

func id<T>(_ v: T) -> T { return v }

func merge<T>(_ l: @escaping (T) -> (), _ r: @escaping (T) -> ()) -> (T) -> () {
    return { l($0); r($0) }
}

// Tuple
func first<A, B>(_ tuple: (A, B)) -> A { return tuple.0 }
func second<A, B>(_ tuple: (A, B)) -> B { return tuple.1 }

func first<A, B, C>(_ tuple: (A, B, C)) -> A { return tuple.0 }
func second<A, B, C>(_ tuple: (A, B, C)) -> B { return tuple.1 }
func third<A, B, C>(_ tuple: (A, B, C)) -> C { return tuple.2 }

func double<T>(_ value: T) -> (T, T) { return (value, value) }
func triple<T>(_ value: T) -> (T, T, T) { return (value, value, value) }

func double<T>(_ f: () -> T) -> (T, T) { return (f(), f()) }
func triple<T>(_ f: () -> T) -> (T, T, T) { return (f(), f(), f()) }

func compact<T>(_ tuple: (T?, T?)) -> (T, T)? {
    guard let one = tuple.0, let two = tuple.1 else { return nil }
    return (one, two)
}

func compact<T>(_ tuple: (T?, T?, T?)) -> (T, T, T)? {
    guard let one = tuple.0, let two = tuple.1, let three = tuple.2 else { return nil }
    return (one, two, three)
}

@discardableResult
func forEach<T, O>(_ tuple: (T, T), mapper: @escaping (T) -> O) -> (O, O) {
    return (tuple |> first >>> mapper, tuple |> second >>> mapper)
}

@discardableResult
func forEach<T, O>(_ tuple: (T, T, T), mapper: @escaping (T) -> O) -> (O, O, O) {
    return (
        tuple |> first >>> mapper,
        tuple |> second >>> mapper,
        tuple |> third >>> mapper
    )
}

// Composition & Applicative
func <<< <A, B, C>(lhs: @escaping (B) -> C, rhs: @escaping (A) -> B) -> (A) -> C {
    return { lhs(rhs($0)) }
}

func >>> <A, B, C>(lhs: @escaping (A) -> B, rhs: @escaping (B) -> C) -> (A) -> C {
    return { rhs(lhs($0)) }
}

func |> <A, B>(lhs: A, rhs: (A) -> B) -> B {
    return rhs(lhs)
}
