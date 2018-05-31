//
//  Chat.Node.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/26.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import LayoutKit
import RxSwift

private let ui = Chat.Node.UI()

extension Chat {
    final class Node: InsetLayout<UIView> {
        init(provider: ChatNodeLayoutProvider, event: PublishSubject<Presenter.NodeEvent>) {
            let contentLayout = _ContentLayout(provider: provider, event: event)
            super.init(
                insets: .init(
                    top: ui.verticalSpacing,
                    left: provider.isMyOwn ? 0 : ui.horizontalSpacing,
                    bottom: ui.verticalSpacing,
                    right: provider.isMyOwn ? ui.horizontalSpacing : 0
                ),
                alignment: .fill,
                sublayout: contentLayout
            )
        }
    }
}

private extension Chat.Node {
    final class _ContentLayout: SizeLayout<_ContentView> {
        init(provider: ChatNodeLayoutProvider, event: PublishSubject<Chat.Presenter.NodeEvent>) {
            let isMyOwn = provider.isMyOwn
            let minSizeValue = 2 * ui.cornerRadius
            let alignment: Alignment = isMyOwn ? .fillTrailing : .fillLeading
            
            let contentInsetLayout = InsetLayout(
                insets: provider.insets,
                viewReuseId: "ContentInsetLayout",
                sublayout: provider.layout(event: event)
            )
            
            super.init(
                minWidth: minSizeValue,
                maxWidth: ui.maxWidth,
                minHeight: minSizeValue,
                maxHeight: ui.maxHeight,
                alignment: alignment,
                viewReuseId: "ContentLayout",
                sublayout: contentInsetLayout
            ) {
                var corners: UIRectCorner = [.bottomLeft, .bottomRight]
                corners.insert(isMyOwn ? .topLeft : .topRight)
                $0.entity = (ui.cornerRadius, corners)
                $0.backgroundColor = ui.background(isMyOwn: isMyOwn)
                $0.longPress(.began) { event.onNext(.longPress(on: $0.view!)) }
            }
        }
    }
    
    final class _ContentView: UIView {
        typealias Entity = (radius: CGFloat, corners: UIRectCorner)
        var entity: Entity?

        private lazy var _backgroundLayer: CAShapeLayer = CAShapeLayer()
        
        override var backgroundColor: UIColor? {
            set {
                _noAnimation {
                    _backgroundLayer.fillColor = newValue?.cgColor
                }
            }
            get {
                guard let bc = _backgroundLayer.fillColor else { return nil }
                return UIColor(cgColor: bc)
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            super.backgroundColor = .clear
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func _noAnimation(_ todo: () -> ()) {
            CATransaction.begin(); defer { CATransaction.commit() }
            CATransaction.setDisableActions(true)
            todo()
        }
        
        private func _refreshBackgroundLayer() {
            guard let entity = entity else { _backgroundLayer.removeFromSuperlayer(); return }
            if layer.sublayers?.first !== _backgroundLayer {
                _backgroundLayer.removeFromSuperlayer()
                layer.insertSublayer(_backgroundLayer, at: 0)
            }
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: entity.corners, cornerRadii: .init(width: entity.radius, height: entity.radius))
            _noAnimation {
                _backgroundLayer.frame = layer.bounds
                _backgroundLayer.path = path.cgPath
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            _refreshBackgroundLayer()
        }
    }
}

private extension Chat.Node {
    struct UI {
        var cornerRadius: CGFloat { return 20 }
        var maxWidth: CGFloat { return UIScreen.main.bounds.width - 3 * horizontalSpacing }
        var maxHeight: CGFloat { return 1.8 * UIScreen.main.bounds.height }
        var horizontalSpacing: CGFloat { return 26 }
        var verticalSpacing: CGFloat { return 12 }
        func background(isMyOwn: Bool) -> UIColor {
            if isMyOwn {
                return UIColor(rgb: triple(235))
            } else {
                let magicNum: CGFloat = 5 / 255
                return UIColor(rgb: triple(235))
//                return Theme.shared.mainColor.trim {
//                    $0.red += magicNum
//                    $0.green += magicNum
//                    $0.blue += magicNum
//                }
            }
        }
    }
}
