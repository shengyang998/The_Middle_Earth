//
//  UITableView+Rx.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/23.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

private struct _AssociatedTypeHelper {
    static var preContentOffsetKey: UInt8 = 23
    
    @discardableResult
    static func lock<T>(in obj: AnyObject, _ todo: () -> T) -> T{
        objc_sync_enter(obj); defer { objc_sync_exit(obj) }
        return todo()
    }
}

extension UIScrollView {
    enum HorizontalScrollDirection {
        case left
        case right
    }
    
    enum VerticalScrollDirection {
        case up
        case down
    }
    
    private var _preContentOffset: CGPoint {
        set {
            _AssociatedTypeHelper.lock(in: self) {
                objc_setAssociatedObject(self, &_AssociatedTypeHelper.preContentOffsetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
        
        get {
            return _AssociatedTypeHelper.lock(in: self) {
                let create: () -> CGPoint = {
                    objc_setAssociatedObject(self, &_AssociatedTypeHelper.preContentOffsetKey, self.contentOffset, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    return self.contentOffset
                }
                return objc_getAssociatedObject(self, &_AssociatedTypeHelper.preContentOffsetKey) as? CGPoint ?? create()
            }
        }
    }
    
    var horizontalScrollDirection: Observable<HorizontalScrollDirection> {
        return rx.observe(CGPoint.self, #keyPath(UIScrollView.contentOffset))
            .skip(1)
            .ignoreNil()
            .flatMap { [weak self] point -> Observable<HorizontalScrollDirection> in
                guard let `self` = self, point != self._preContentOffset else { return .empty() }
                if point.x > self._preContentOffset.x { return .just(.left) }
                else { return .just(.right) }
            }
            .do(onNext: { [weak self] _ in self?._preContentOffset = self?.contentOffset ?? .zero })
            .distinctUntilChanged()
    }
    
    var verticalScrollDirection: Observable<VerticalScrollDirection> {
        return rx.observe(CGPoint.self, #keyPath(UIScrollView.contentOffset))
            .skip(1)
            .ignoreNil()
            .flatMap { [weak self] point -> Observable<VerticalScrollDirection> in
                guard let `self` = self, point != self._preContentOffset else { return .empty() }
                if point.y > self._preContentOffset.y { return .just(.up) }
                else { return .just(.down) }
            }
            .do(onNext: { [weak self] _ in self?._preContentOffset = self?.contentOffset ?? .zero })
            .distinctUntilChanged()
    }
}
