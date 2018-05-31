//
//  UIColor.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/26.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

extension UIColor {
    typealias RGBA = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
    func trim(_ transform: (inout RGBA) -> ()) -> UIColor {
        var rgba: RGBA = (0, 0, 0, 0)
        getRed(&rgba.red, green: &rgba.green, blue: &rgba.blue, alpha: &rgba.alpha)
        transform(&rgba)
        return UIColor(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha)
    }
}
