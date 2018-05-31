//
//  CrossSizeHittableView.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/25.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

class CrossSizeHittableView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled && !isHidden && alpha > 0.01 else { return nil }
        
        // In Normal Views
//        guard point(inside: point, with: event) else { return nil }
        
        for subview in subviews.reversed() {
            let point = subview.convert(point, from: self)
            if let view = subview.hitTest(point, with: event) {
                return view
            }
        }
        
        return nil
    }
}
