//
//  Chat.NodeLayout.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/26.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import LayoutKit
import RxSwift
import Kingfisher

protocol ChatNodeLayoutProvider {
    var isMyOwn: Bool { get }
    var insets: UIEdgeInsets { get }
    func layout(event: PublishSubject<Chat.Presenter.NodeEvent>) -> Layout
}

final class TextLayoutProvider: ChatNodeLayoutProvider {
    private let _msg: Message
    
    init(message: Message) {
        _msg = message
    }
    
    var isMyOwn: Bool {
        return _msg.isSentBySelf
    }
    
    var insets: UIEdgeInsets {
        return .init(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    func layout(event: PublishSubject<Chat.Presenter.NodeEvent>) -> Layout {
        let isMyOwn = self.isMyOwn
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let attributedString = NSAttributedString(
            string: _msg.payload,
            attributes: [
                .paragraphStyle: paragraph,
            ]
        )
        
        let sublayouts: [Layout] = [
            LabelLayout(
                text: .attributed(attributedString),
                font: .boldSystemFont(ofSize: 16),
                viewReuseId: "LabelLayout"
            ) {
                $0.textColor = isMyOwn ? .gray : .white
            },
        ]
        return StackLayout(
            axis: .vertical,
            spacing: 8,
            viewReuseId: "TextContentLayout",
            sublayouts: sublayouts
        )
    }
}

//final class TypingProvider: ChatNodeLayoutProvider {
//    // Always return false
//    var isMyOwn: Bool { return false }
//
//    var insets: UIEdgeInsets {
//        return .init(top: 16, left: 16, bottom: 16, right: 16)
//    }
//
//    func layout(event: PublishSubject<Chat.Presenter.NodeEvent>) -> Layout {
//        return SizeLayout<Chat.NodeTypingView>(size: Chat.NodeTypingView.size, viewReuseId: "TypingContentLayout") { _ in }
//    }
//}
//
//final class ImageProvider: ChatNodeLayoutProvider {
//    private let _msg: Message
//    init(_ msg: Message) {
//        _msg = msg
//    }
//
//    private static let _maxSize = CGSize(width: 0.6 * UIScreen.main.bounds.width, height: 0.7 * UIScreen.main.bounds.height)
//    private static let _minSize = CGSize(width: 50, height: 50)
//
//    private static func _calcSize(_ original: CGSize) -> CGSize {
//        guard original.width != 0, original.height != 0 else { return _minSize }
//        var ret: CGSize = original
//        let ratio = original.height / original.width
//        if ret.width > _maxSize.width {
//            ret.width = _maxSize.width
//            ret.height = ret.width * ratio
//        }
//        if ret.height > _maxSize.height {
//            ret.height = _maxSize.height
//            ret.width = ret.height / ratio
//        }
//        return ret
//    }
//
//    var isMyOwn: Bool {
//        return _msg.isSentBySelf
//    }
//
//    var insets: UIEdgeInsets {
//        return .init(top: 5, left: 5, bottom: 5, right: 5)
//    }
//
//    func layout(event: PublishSubject<Chat.Presenter.NodeEvent>) -> Layout {
//        let size = ImageProvider._calcSize(.init(width: CGFloat(_msg.imageWidth), height: CGFloat(_msg.imageHeight)))
//        return SizeLayout<UIImageView>(size: size, viewReuseId: "ImageContentLayout") { [_msg] imageView in
//            guard let url = URL(string: _msg.imageURL) else { return }
//            imageView.kf.setImage(with: url.resize(to: size), placeholder: nil, options: KingfisherOptionsInfo.normalImageOptions(size: size, corner: 20), progressBlock: nil, completionHandler: nil)
//        }
//    }
//}
