//
//  Chat.ViewModel.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/11.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation
import RxSwift
import Photos
import RealmSwift

extension Chat {
    final class ViewModel {
        private let _contact: Contact
        private let _bag = DisposeBag()
        private var _token: NotificationToken?

        private(set) lazy var messages = SDFAXDB.makeConnection().objects(Message.self)
        
        init(contact: Contact) {
            _contact = contact
        }
        
        deinit {
            _token?.invalidate()
        }
        
        private(set) lazy var change: Observable<RealmCollectionChange<Results<Message>>> = {
            return Observable.create { [weak self] subscribe in
                let token = self?.messages.observe {
                    subscribe.onNext($0)
                }
                self?._token = token
                return Disposables.create()
            }
        }()
        
        // Status
        private var _didSendTyping = false
        private var _didShowTyping = false
        private var _dismissTypingWI: DispatchWorkItem?
    }
}

extension Chat.ViewModel {
    func send(_ text: String) {
        // TODO: Send Test Message
    }
}
