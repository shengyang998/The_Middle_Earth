//
//  Chat.Presenter.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/24.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import YYText
import RxSwift
import LayoutKit
import RealmSwift

extension Chat {
    final class Presenter: NSObject {
        private weak var _chatView: Chat.View?
        private let _change: Observable<RealmCollectionChange<Results<Message>>>

        init(change: Observable<RealmCollectionChange<Results<Message>>>, chatView: Chat.View) {
            _change = change
            _chatView = chatView
            super.init()
            YYTextKeyboardManager.default()?.add(self)
            _bindNodeEvents()
        }
        
        deinit {
            YYTextKeyboardManager.default()?.remove(self)
        }
        
        // Keyboard
        typealias KeyboardChangedInfo = (constant: CGFloat, duration: TimeInterval, animationOptions: UIViewAnimationOptions)
        private let _keyboardChangedSubject = PublishSubject<KeyboardChangedInfo>()

        // Node Event
        private let _nodeEventSubject = PublishSubject<NodeEvent>()
        
        // ContentView Refresh
        private(set) lazy var refreshContentView: Observable<ContentViewRefreshing> = Observable.merge(
            _renderObserver,
            _keyboardChangedSubject.asObserver().map { .scrollWithKeyboard($0) },
            _scrollToBottomSubject.map { .scrollToBottom }
        )
        
        private let _scrollToBottomSubject = PublishSubject<()>()

        // Token for messages results
        private var _token: NotificationToken?
    }
}

// MARK: - Open Methods
extension Chat.Presenter {
    func dismissKeyboard() {
        _chatView?.view.endEditing(true)
    }
    
    func scrollToBottom() {
        _scrollToBottomSubject.onNext(())
    }
}

// MARK: - ContentViewRefresh
private extension Chat.Presenter {
    var _renderObserver: Observable<Chat.Presenter.ContentViewRefreshing> {
        let mapper: (Results<Message>) -> [Layout] = { [weak self] in
            guard let `self` = self else { return [] }
            return $0.map(Chat.Presenter._message2NodeMapper(event: self._nodeEventSubject))
        }
        
        return _change.map {
            switch $0 {
            case .initial(let messages):
                return .nodes(layouts: mapper(messages), batchUpdates: nil)
            case .update(let messages, let deletions, let insertions, let modifications):
                let bu: BatchUpdates = {
                    let bu = BatchUpdates()
                    bu.insertItems = insertions.map { IndexPath(row: $0, section: 0) }
                    bu.deleteItems = deletions.map { IndexPath(row: $0, section: 0) }
                    bu.reloadItems = modifications.map { IndexPath(row: $0, section: 0) }
                    return bu
                }()
                return .nodes(layouts: mapper(messages), batchUpdates: bu)
            default:
                return nil
            }
        }.ignoreNil()
    }
    
    static func _message2NodeMapper(event: PublishSubject<Chat.Presenter.NodeEvent>) -> (Message) -> Chat.Node {
        return { msg in
            let provider: ChatNodeLayoutProvider = {
                return TextLayoutProvider(message: msg)
            }()
            
            return Chat.Node(provider: provider, event: event)
        }
    }
}

// MARK: - NodeEvents
private extension Chat.Presenter {
    func _bindNodeEvents() {
        _nodeEventSubject.subscribeOnMain(onNext: { event in
            print(event)
        }).disposed(by: rx.disposeBag)
    }
}

// MARK: - Keyboard Adapter
extension Chat.Presenter: YYTextKeyboardObserver {
    func keyboardChanged(with transition: YYTextKeyboardTransition) {
        let info: KeyboardChangedInfo = (
            transition.toVisible.boolValue ? -transition.toFrame.height : 0,
            transition.animationDuration,
            transition.animationOption
        )
        _keyboardChangedSubject.onNext(info)
    }
    
    func fitKeyboard(for inputViewBottomConstraint: NSLayoutConstraint) {
        _keyboardChangedSubject.subscribeOnMain(onNext: { [weak view = _chatView?.view] info in
            let finalConstant: CGFloat = {
                if #available(iOS 11, *) {
                    return info.constant == 0 ? 0 : info.constant + (view?.safeAreaInsets.bottom ?? 0)
                } else {
                    return info.constant
                }
            }()
            inputViewBottomConstraint.constant = finalConstant
            UIView.animate(withDuration: info.duration, delay: 0, options: info.animationOptions, animations: {
                view?.layoutIfNeeded()
            })
        }).disposed(by: rx.disposeBag)
    }
}

// MARK: - Events
extension Chat.Presenter {
    enum ContentViewRefreshing {
        case nodes(layouts: [Layout], batchUpdates: BatchUpdates?)
        case scrollWithKeyboard(KeyboardChangedInfo)
        case scrollToBottom
    }
    
    enum NodeEvent {
        case longPress(on: UIView)
    }
}
