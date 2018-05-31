//
//  Renderer.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/9.
//  Copyright © 2018 Tangent. All rights reserved.
//  Realm -> Render UI

import UIKit
import RealmSwift

final class Renderer<Item: RenderItem>: NSObject, UITableViewDataSource, UICollectionViewDataSource {
    typealias Entity = Item.Entity
    
    private unowned let _view: RenderView
    private let _data: [Results<Entity>]
    private var _tokens: [NotificationToken] = []
    private var _hasLoaded = false

    init<V: RenderView>(view: V, sections: [RenderSection<Item>]) where V: UIView {
        _view = view
        _data = sections.map { $0.fetchEntities() }
        sections.forEach { view.register(for: $0.itemType) }

        super.init()
        view.adapt(to: self)
        nextRunLoopPeriod {
            self._tokens = self._data.enumerated().map(self._renderWork(view: view))
        }
    }
    
    deinit {
        _tokens.forEach { $0.invalidate() }
    }

    // MARK: - DataSource
    // TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return _data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        _hookLoading()
        return _data[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return Item.obtainAndRender(from: tableView, indexPath: indexPath, entity: _data[indexPath.section][indexPath.row])
    }
    
    // CollectionView
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return _data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        _hookLoading()
        return _data[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return Item.obtainAndRender(from: collectionView, indexPath: indexPath, entity: _data[indexPath.section][indexPath.item])
    }
    
    // Load Completed
    @objc private func _loadCompleted() {
        _hasLoaded = true
    }
    private var _loadCompletedSelector = #selector(Renderer._loadCompleted)
    
    // 当加载完最后一个Cell的时候，触发勾子
    private func _hookLoading() {
        // 取消上一次的执行请求，因为构建Cell是在同一个Runloop周期中，所以上一次构建
        // Cell时调用此方法执行的Perform命令的方法还未被调用（在下一个Runloo周期才调用）
        Renderer.cancelPreviousPerformRequests(withTarget: self, selector: _loadCompletedSelector, object: nil)
        // 并不是立即执行，放到下一个Runloop周期中
        perform(_loadCompletedSelector, with: nil, afterDelay: 0)
    }
}

private extension Renderer {
    func _renderWork(view: RenderView) -> (Int, Results<Entity>) -> NotificationToken {
        return { [weak view, weak self] section, results in
            results.observe { changes in
                switch changes {
                case .initial:
                    view?.render(type: .initial)
                case .update(_, let deletions, let insertions, let modifications) where self?._hasLoaded == true:
                    view?.render(type: .update(
                        insert: (section: section, items: insertions),
                        delete: (section: section, items: deletions),
                        reload: (section: section, items: modifications))
                    )
                case .error(let error):
                    print(error)
                default: ()
                }
            }
        }
    }
}

extension Renderer {
    func entity(of indexPath: IndexPath) -> Entity {
        return _data[indexPath.section][_view is UITableView ? indexPath.row : indexPath.item]
    }
}

// MARK: - RenderType
enum RenderType {
    typealias IP = (section: Int, items: [Int])
    case initial
    case update(insert: IP, delete: IP, reload: IP)
}

extension Array where Element == IndexPath {
    static func create(_ ip: RenderType.IP, forTable: Bool = true) -> [IndexPath] {
        if forTable {
            return ip.items.map { IndexPath(row: $0, section: ip.section) }
        } else {
            return ip.items.map { IndexPath(item: $0, section: ip.section) }
        }
    }
}

// MARK: - RenderItem
protocol RenderItem {
    associatedtype Entity: Object
    func render(entity: Entity)
}

extension RenderItem {
    static var identifier: String {
        return String(describing: type(of: self))
    }
}

extension RenderItem {
    static func obtain(from view: RenderView, indexPath: IndexPath) -> Self {
        return view.obtainItem(with: self, indexPath: indexPath)
    }
    
    static func obtainAndRender<T>(from view: RenderView, indexPath: IndexPath, entity: Entity) -> T {
        let item = obtain(from: view, indexPath: indexPath)
        item.render(entity: entity)
        guard let ret = item as? T else {
            fatalError("The item type is not adapt to render view cell type")
        }
        return ret
    }
}

// MARK: - RenderView
protocol RenderView: AnyObject {
    func obtainItem<T: RenderItem>(with type: T.Type, indexPath: IndexPath) -> T
    func register<T: RenderItem>(for type: T.Type)
    func render(type: RenderType)
    func adapt<T>(to renderer: Renderer<T>)
}

// MARK: - RenderView -> TableView
extension UITableView: RenderView {
    func obtainItem<T>(with type: T.Type, indexPath: IndexPath) -> T where T : RenderItem {
        guard let item = dequeueReusableCell(withIdentifier: type.identifier, for: indexPath) as? T
            else { fatalError("The item has not yet been registered: \(type.identifier)") }
        return item
    }
    
    func register<T>(for type: T.Type) where T: RenderItem {
        guard let cellType = type as? UITableViewCell.Type else {
            fatalError("Item is not a table view cell")
        }
        register(cellType, forCellReuseIdentifier: type.identifier)
    }
    
    func render(type: RenderType) {
        switch type {
        case .initial:
            reloadData()
        case .update(let insert, let delete, let reload):
            beginUpdates()
            insertRows(at: .create(insert), with: .automatic)
            deleteRows(at: .create(delete), with: .automatic)
            reloadRows(at: .create(reload), with: .automatic)
            endUpdates()
        }
    }
    
    func adapt<T>(to renderer: Renderer<T>) where T : RenderItem {
        dataSource = renderer
    }
}

// MARK: - RenderView -> CollectionView
extension UICollectionView: RenderView {
    func obtainItem<T>(with type: T.Type, indexPath: IndexPath) -> T where T : RenderItem {
        guard let item = dequeueReusableCell(withReuseIdentifier: type.identifier, for: indexPath) as? T
            else { fatalError("The item has not yet been registered: \(type.identifier)") }
        return item
    }
    
    func register<T>(for type: T.Type) where T : RenderItem {
        guard let cellType = type as? UICollectionViewCell.Type else {
            fatalError("Item is not a collection view cell!")
        }
        register(cellType, forCellWithReuseIdentifier: type.identifier)
    }
    
    func render(type: RenderType) {
        switch type {
        case .initial:
            reloadData()
        case .update(let insert, let delete, let reload):
            performBatchUpdates({
                insertItems(at: .create(insert))
                deleteItems(at: .create(delete))
                reloadItems(at: .create(reload))
            })
        }
    }
    
    func adapt<T>(to renderer: Renderer<T>) where T : RenderItem {
        dataSource = renderer
    }
}

// MARK: - Extension
private var _rendererKey: UInt8 = 32
extension UITableView {
    @discardableResult
    func setupRenderer<Item: RenderItem>(sections: [RenderSection<Item>]) -> Renderer<Item> {
        return syncInMain {
            let renderer = Renderer(view: self, sections: sections)
            objc_setAssociatedObject(self, &_rendererKey, renderer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return renderer
        }
    }
}

extension UICollectionView {
    @discardableResult
    func setupRenderer<Item: RenderItem>(sections: [RenderSection<Item>]) -> Renderer<Item> {
        return syncInMain {
            let renderer = Renderer(view: self, sections: sections)
            objc_setAssociatedObject(self, &_rendererKey, renderer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return renderer
        }
    }
}
