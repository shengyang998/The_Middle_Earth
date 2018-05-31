//
//  UITableView.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/11.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

extension UITableView {
    var isAtBottom: Bool {
        return contentOffset.y._standard == (contentSize.height - height + contentInset.bottom)._standard
    }

    // Copy from `https://github.com/badoo/Chatto/blob/master/Chatto/Source/ChatController/BaseChatViewController%2BScrolling.swift#L82-L99`
    func scrollToBottom(animated: Bool) {
        // Cancel current scrolling
        setContentOffset(contentOffset, animated: false)
        
        // Note that we don't rely on collectionView's contentSize. This is because it won't be valid after performBatchUpdates or reloadData
        // After reload data, collectionViewLayout.collectionViewContentSize won't be even valid, so you may want to refresh the layout manually
        let offsetY = max(-contentInset.top, contentSize.height - height + contentInset.bottom)
        
        // Don't use setContentOffset(:animated). If animated, contentOffset property will be updated along with the animation for each frame update
        // If a message is inserted while scrolling is happening (as in very fast typing), we want to take the "final" content offset (not the "real time" one) to check if we should scroll to bottom again
        if animated {
            UIView.animate(withDuration: 0.33) {
                self.contentOffset = CGPoint(x: 0, y: offsetY)
            }
        } else {
            contentOffset = CGPoint(x: 0, y: offsetY)
        }
    }
}

fileprivate extension CGFloat {
    // 四舍五入
    var _standard: CGFloat {
        return self |> Float.init >>> roundf >>> CGFloat.init
    }
}

