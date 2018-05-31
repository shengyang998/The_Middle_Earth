//
//  Chat.TableView.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/11.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import LayoutKit

extension Chat {
    final class TableView: UITableView { }
}

extension Chat.TableView {
    @objc
    override func perform(batchUpdates: BatchUpdates, completion: (() -> Void)?) {
        beginUpdates()
        
        // Update items.
        if batchUpdates.insertItems.count > 0 {
            insertRows(at: batchUpdates.insertItems, with: .fade)
        }
        if batchUpdates.deleteItems.count > 0 {
            deleteRows(at: batchUpdates.deleteItems, with: .fade)
        }
        if batchUpdates.reloadItems.count > 0 {
            reloadRows(at: batchUpdates.reloadItems, with: .fade)
        }
        for move in batchUpdates.moveItems {
            moveRow(at: move.from, to: move.to)
        }
        
        // Update sections.
        if batchUpdates.insertSections.count > 0 {
            insertSections(batchUpdates.insertSections, with: .fade)
        }
        if batchUpdates.deleteSections.count > 0 {
            deleteSections(batchUpdates.deleteSections, with: .fade)
        }
        if batchUpdates.reloadSections.count > 0 {
            reloadSections(batchUpdates.reloadSections, with: .fade)
        }
        for move in batchUpdates.moveSections {
            moveSection(move.from, toSection: move.to)
        }
        
        endUpdates()
        
        completion?()
    }
}
