//
//  Observable.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/23.
//  Copyright © 2018 Tangent. All rights reserved.
//

import RxSwift

extension ObservableType {
    func ignoreNil<T>() -> Observable<T> where E == T? {
        return filter { $0 != nil }.map { $0! }
    }
    
    func subscribeOnMain<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        return observeOn(MainScheduler.instance)
            .subscribe(observer)
    }

    func subscribeOnMain(_ on: @escaping (Event<E>) -> ()) -> Disposable {
        return observeOn(MainScheduler.instance)
            .subscribe(on)
    }
    
    func subscribeOnMain(onNext: ((E) -> ())? = nil, onCompleted: (() -> ())? = nil, onError: ((Error) -> ())? = nil, onDisposed: (() -> ())? = nil) -> Disposable {
        return observeOn(MainScheduler.instance)
            .subscribe(onNext: onNext, onError: onError, onCompleted: onCompleted, onDisposed: onDisposed)
    }
}
