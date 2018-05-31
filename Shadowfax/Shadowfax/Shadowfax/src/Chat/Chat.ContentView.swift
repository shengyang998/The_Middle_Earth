//
//  Chat.ContentView.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/26.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import LayoutKit
import RxSwift
import RxCocoa
import MessageListener
import RealmSwift

extension Chat {
    final class ContentView: UITableViewController {
        private let _messages: Results<Message>
        private let _refresh: Observable<Presenter.ContentViewRefreshing>
        private let _eventCallback: (Event) -> ()
        
        init(messages: Results<Message>, refresh: Observable<Presenter.ContentViewRefreshing>, eventCallback: @escaping (Event) -> ()) {
            _messages = messages
            _refresh = refresh
            _eventCallback = eventCallback
            super.init(style: .plain)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private lazy var _revealer = AccessoryViewRevealer(tableView: tableView)
        private lazy var _adapter = ReloadableViewLayoutAdapter(reloadableView: tableView)
        
        // Variable
        private var _isScrollTooFar = false
    }
}

extension Chat.ContentView {
    enum Event {
        case tap
        case scrollTooFar(Bool)
    }
}

extension Chat.ContentView {
    override func loadView() {
        super.loadView()
        // isa-swizzling
        object_setClass(view, Chat.TableView.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _bindEvents()
        _setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.scrollToBottom(animated: false)
    }
}

// MARK: - DataSource
extension Chat.ContentView {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return _adapter.currentArrangement.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _adapter.currentArrangement[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ui.reuseIdentifier, for: indexPath) as! Chat.Cell
        // Item
        let item = _adapter.currentArrangement[indexPath.section].items[indexPath.item]
        item.makeViews(in: cell.contentView)
        // Date
        cell.message = _messages[indexPath.row]
        return cell
    }
}

private extension Chat.ContentView {
    func _setupTableView() {
        tableView.register(Chat.Cell.self, forCellReuseIdentifier: ui.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.delegate = _adapter
        // Activate revealer
        _ = _revealer
    }
    
    func _reload(layouts: [Layout], batchUpdates: BatchUpdates?) {
        _adapter.reload(width: UIScreen.main.bounds.width, synchronous: true, batchUpdates: batchUpdates, layoutProvider: {
            return [Section(header: nil, items: layouts, footer: nil)]
        }) { [weak self] in
            nextRunLoopPeriod { nextRunLoopPeriod {
                guard batchUpdates == nil || (batchUpdates != nil && (batchUpdates?.insertItems.count ?? 0) > 0) else { return }
                guard let count = self?.tableView.numberOfRows(inSection: 0), count > 0 else { return }
                self?.tableView.scrollToRow(at: IndexPath(row: count - 1, section: 0), at: .top, animated: batchUpdates != nil)
            }}
        }
    }
    
    func _bindEvents() {
        // In
        _refresh.subscribeOnMain(onNext: { [weak self] in
            guard let `self` = self else { return }
            switch $0 {
            case .nodes(let layouts, let batchUpdates):
                self._reload(layouts: layouts, batchUpdates: batchUpdates)
            case .scrollWithKeyboard(let info):
                // FIXME
                guard self.tableView.isAtBottom == true else { return }
                UIView.animate(withDuration: info.duration, delay: 0, options: info.animationOptions, animations: {
                    self.tableView.contentOffset.y -= info.constant
                })
            case .scrollToBottom:
                self.tableView.scrollToBottom(animated: true)
            }
        }).disposed(by: rx.disposeBag)
        
        // Out
        view.tap { [weak self] _ in self?._eventCallback(.tap) }
        _adapter.listen(#selector(UITableViewDelegate.scrollViewDidScroll(_:)), in: UITableViewDelegate.self) { [weak self] _ in
            guard let `self` = self else { return }
            let offsetY = self.tableView.contentOffset.y
            let flag = offsetY < self._bottomOffset.y - 2 * UIScreen.main.bounds.height
            guard self._isScrollTooFar != flag else { return }
            self._eventCallback(.scrollTooFar(flag))
            self._isScrollTooFar = flag
        }
    }
}

private extension Chat.ContentView {
    var _bottomOffset: CGPoint {
        return CGPoint(x: 0, y: tableView.contentSize.height - tableView.height + tableView.contentInset.bottom)
    }
}

extension UI where Base: Chat.ContentView {
    var reuseIdentifier: String { return "Chat.Identifier" }
}
