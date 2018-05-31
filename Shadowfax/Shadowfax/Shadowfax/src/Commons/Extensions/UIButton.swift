//
//  UIButton.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/22.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

extension UIButton {
    // h: Horizontal v: Vertical
    enum LayoutStyle {
        case hImageLabel
        case hLabelImage
        case vImageLabel
        case vLabelImage
    }
}

extension UIButton {
    func layout(with style: LayoutStyle, space: CGFloat) {
        let imageWidth = imageView?.bounds.height ?? 0
        let imageHeight = imageView?.bounds.height ?? 0
        
        let labelWidth: CGFloat
        let labelHeight: CGFloat
        if #available(iOS 8.0, *) {
            labelWidth = titleLabel?.intrinsicContentSize.width ?? 0
            labelHeight = titleLabel?.intrinsicContentSize.height ?? 0
        } else {
            labelWidth = titleLabel?.bounds.width ?? 0
            labelHeight = titleLabel?.bounds.height ?? 0
        }
        
        let imageEdgeInsets: UIEdgeInsets
        let labelEdgeInsets: UIEdgeInsets
        
        switch style {
        case .hImageLabel:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -space * 0.5, bottom: 0, right: space * 0.5)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: 0, right: -space * 0.5)
        case .hLabelImage:
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth - space * 0.5, bottom: 0, right: imageWidth + space * 0.5)
            imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth + space * 0.5, bottom: 0, right: -labelWidth - space * 0.5)
        case .vImageLabel:
            imageEdgeInsets = UIEdgeInsets(top: -labelHeight - space * 0.5, left: 0, bottom: 0, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: -imageHeight - space * 0.5, right: 0)
        case .vLabelImage:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -labelHeight - space * 0.5, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets(top: -imageHeight - space * 0.5, left: -imageWidth, bottom: 0, right: 0)
        }
        self.titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
}
