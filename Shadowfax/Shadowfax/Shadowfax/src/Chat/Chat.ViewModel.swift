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
        private lazy var _id: Int = (SDFAXDB.makeConnection().objects(Message.self).sorted(byKeyPath: "id").last?.id)!

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
        self._id += 1
        SDFAXNetworking.sharedInstance.sendTo(uuid: _contact.uuid, message: text, id: UInt64(self._id))
        let msg = Message()
        msg.id = self._id
        msg.payload = text
        msg.isSentBySelf = true
        msg.sender = self._contact
        msg.time = Date()
        Logger.info(message: "Send button touched")
        let db = SDFAXDB.makeConnection()!
        try! db.write {
            db.add(msg, update: true)
        }
    }
}
