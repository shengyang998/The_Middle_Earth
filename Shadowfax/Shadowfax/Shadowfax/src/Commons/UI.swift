//
//  UI.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/22.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

struct UI<Base> {
    let base: Base
    
    init(_ base: Base) {
        self.base = base
    }
}

protocol UICompatible {
    associatedtype CompatibleType
    static var ui: UI<CompatibleType>.Type { get }
    var ui: UI<CompatibleType> { get }
}

extension UICompatible {
    var ui: UI<Self> {
        return UI(self)
    }
    
    static var ui: UI<Self>.Type {
        return UI<Self>.self
    }
}

extension NSObject: UICompatible { }

extension UIView {
    var width: CGFloat {
        get { return frame.size.width }
        set { frame.size.width = newValue }
    }
    
    var height: CGFloat {
        get { return frame.size.height }
        set { frame.size.height = newValue }
    }
    
    var size: CGSize {
        get { return frame.size }
        set { frame.size = newValue }
    }
    
    var x: CGFloat {
        get { return frame.origin.x }
        set { frame.origin.x = newValue }
    }
    
    var y: CGFloat {
        get { return frame.origin.y }
        set { frame.origin.y = newValue }
    }
    
    var origin: CGPoint {
        get { return frame.origin }
        set { frame.origin = newValue }
    }
}

// Color
typealias RGB = (r: CGFloat, g: CGFloat, b: CGFloat)
extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, alpha: CGFloat = 1) {
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }
    
    convenience init(rgb: RGB, alpha: CGFloat = 1) {
        self.init(r: rgb.r, g: rgb.g, b: rgb.b, alpha: alpha)
    }
}

// Corner
extension UIView {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: .init(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
