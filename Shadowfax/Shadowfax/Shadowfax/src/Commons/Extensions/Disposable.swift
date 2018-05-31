//
//  Disposable.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/22.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation
import RxSwift

private struct _DisposeBagAssociatedHelper {
    static var key = "disposeBag"
    
    static func lock<T>(in obj: AnyObject, todo: () -> T) -> T{
        objc_sync_enter(obj); defer { objc_sync_exit(obj) }
        return todo()
    }
}

extension Reactive where Base: NSObject {
    var disposeBag: DisposeBag {
        return _DisposeBagAssociatedHelper.lock(in: base) {
            let create: () -> DisposeBag = {
                let bag = DisposeBag()
                objc_setAssociatedObject(self.base, &_DisposeBagAssociatedHelper.key, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return bag
            }
            return objc_getAssociatedObject(self.base, &_DisposeBagAssociatedHelper.key) as? DisposeBag ?? create()
        }
    }
}
