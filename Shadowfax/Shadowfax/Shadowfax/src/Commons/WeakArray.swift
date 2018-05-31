//
//  WeakArray.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/24.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

private struct _Weak<T: AnyObject> {
    private(set) weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
    
    var isNull: Bool { return value == nil }
}

// MARK: - Thread-safe WeakArray
// 线程安全的弱引用数组
final class WeakArray<T: AnyObject> {
    private var _arr: [_Weak<T>]
    private let _lock = NSRecursiveLock()
    private var _runloopObserver: CFRunLoopObserver!
    
    init(_ arr: [T] = []) {
        _arr = arr.map(_Weak.init)
        let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 0) { [weak self] _, _ in
            self?._clear()
        }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        _runloopObserver = observer
    }
    
    deinit {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _runloopObserver, .commonModes)
    }
    
    @discardableResult
    private func _lock<T>(_ todo: () -> T) -> T {
        _lock.lock(); defer { _lock.unlock() }
        return todo()
    }
    
    private func _clear() {
        _lock { _arr = _arr.filter { !$0.isNull } }
    }
    
    func append(_ value: T) {
        _lock { _arr.append(.init(value)) }
    }
    
    func append<S: Sequence>(contentsOf arr: S) where S.Element == T {
        _lock { _arr.append(contentsOf: arr.map(_Weak.init)) }
    }
    
    var array: [T] {
        return _lock { _arr.map { $0.value }.compactMap { $0 } }
    }
}

extension WeakArray: ExpressibleByArrayLiteral {
    convenience init(arrayLiteral elements: T...) {
        self.init(elements)
    }
}

extension WeakArray {
    struct Iterator: IteratorProtocol {
        private let _instance: WeakArray<T>
        private var _index: Int = 0
        
        init(_ instance: WeakArray<T>) {
            _instance = instance
        }
        
        mutating func next() -> T? {
            return _instance._lock {
                while _index < _instance._arr.endIndex {
                    guard let value = _instance._arr[_index].value else {
                        _instance._arr.formIndex(after: &_index)
                        continue
                    }
                    return value
                }
                return nil
            }
        }
    }
}

extension WeakArray: Sequence {
    func makeIterator() -> WeakArray<T>.Iterator {
        return Iterator(self)
    }
}
