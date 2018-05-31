//
//  MessageListener+Rx.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/7.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation
import MessageListener
import RxSwift

extension Reactive where Base: NSObject {
    func listen(_ selector: Selector, in pro: Protocol? = nil) -> Observable<[Any]> {
        return Observable.create { [weak obj = base] subscribe in
            obj?.listen(selector, in: pro) {
                subscribe.onNext($0)
            }
            return Disposables.create()
        }
    }
}
