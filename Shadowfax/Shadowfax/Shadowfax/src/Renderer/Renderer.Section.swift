//
//  Renderer.Section.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/9.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import RealmSwift

struct RenderSection<Item: RenderItem> {
    typealias Entity = Item.Entity
    
    let itemType: Item.Type
    let filter: NSPredicate?
    let sort: RenderSort?
    
    init(type: Item.Type, filter: NSPredicate? = nil, sort: RenderSort? = nil) {
        itemType = type
        self.filter = filter
        self.sort = sort
    }
}

struct RenderSort {
    let sortDescriptors: [SortDescriptor]
    init(by sortDescriptors: [SortDescriptor]) {
        self.sortDescriptors = sortDescriptors
    }
    init(_ keyPath: String, ascending: Bool = true) {
        sortDescriptors = [SortDescriptor(keyPath: keyPath, ascending: ascending)]
    }
}

extension RenderSection {
    func fetchEntities() -> Results<Entity> {
        let mappers: [(Results<Entity>) -> Results<Entity>] = [
            filter == nil ? nil : flip(Results<Entity>.filter)(filter!),
            sort == nil ? nil : flip(Results<Entity>.sorted)(sort!.sortDescriptors)
        ].compactMap { $0 }
        return mappers.reduce(SDFAXDB.makeConnection().objects(Entity.self), |>)
    }
}
