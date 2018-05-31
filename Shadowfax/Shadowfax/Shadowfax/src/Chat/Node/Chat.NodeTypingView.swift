//
//  Chat.NodeTypingView.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/11.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

private let pointCount = 3
private let pointSizeValue: CGFloat = 8
private let pointMargin: CGFloat = 9
private let animationDuration: TimeInterval = 0.75

extension Chat {
    final class NodeTypingView: UIView {
        init() {
            super.init(frame: CGRect(x: 0, y: 0, width: NodeTypingView.width, height: NodeTypingView.height))
            _setup()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension Chat.NodeTypingView {
    static let width = CGFloat(pointCount) * pointSizeValue + (CGFloat(pointCount) - 1) * pointMargin
    static let height = pointSizeValue
    static let size = CGSize(width: width, height: height)
}

private extension Chat.NodeTypingView {
    func _setup() {
        for (index, point) in (0...pointCount - 1).map({ _ in Chat.NodeTypingView._fetchPoint() }).enumerated() {
            layer.addSublayer(point)
            point.frame.origin.x = CGFloat(index) * (pointSizeValue + pointMargin)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 * TimeInterval(index) * animationDuration) { point._fade() }
        }
    }
    
    static func _fetchPoint() -> CALayer {
        let size = CGSize(width: pointSizeValue, height: pointSizeValue)
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0.5 * pointSizeValue).cgPath
        let layer = CAShapeLayer()
        layer.frame.origin.y = 0
        layer.frame.size = size
        layer.path = path
        layer.fillColor = UIColor.white.cgColor
        layer.isOpaque = false
        layer.opacity = 0
        return layer
    }
}

fileprivate extension CALayer {
    func _fade() {
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        fade.autoreverses = true
        fade.duration = animationDuration
        fade.repeatCount = .infinity
        add(fade, forKey: "Fade")
    }
}
