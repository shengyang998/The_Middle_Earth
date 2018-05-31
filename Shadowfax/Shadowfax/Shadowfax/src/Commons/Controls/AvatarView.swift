//
//  AvatarView.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/10.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import RealmSwift

final class AvatarView: UIView {
    private var _token: NotificationToken?
    private var _preContactId: String?
    private var _onlineStateViewSizeValue: CGFloat = 15
    private var _gestureRecognizer: UITapGestureRecognizer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(_imageView)
        addSubview(_onlineStateView)
    }
    
    convenience init(_ contact: Contact, sizeValue: CGFloat, showOnlineState: Bool = true, onlineStateViewSizeValue: CGFloat = 15, action: ActionType = .none) {
        self.init(frame: .zero)
        _onlineStateViewSizeValue = onlineStateViewSizeValue
        set(contact, sizeValue: sizeValue, showOnlineState: showOnlineState, action: action)
    }
    
    func set(_ contact: Contact, sizeValue: CGFloat, showOnlineState: Bool = true, action: ActionType = .none) {
        guard _preContactId != contact.uuid else { return }
        _token?.invalidate()

        // TODO: Set up avatar
//        _setImage(contact.iconURL, sizeValue: sizeValue)

        _onlineStateView.isHidden = true
        
        var actionHandler: ((Contact) -> ())?
        switch action {
        case .action(let callback):
            actionHandler = callback
        case .showProfile(let showChatButton):
            ()
        case .none: ()
        }
        
        if let gr = _gestureRecognizer {
            removeGestureRecognizer(gr)
        }
        if let ah = actionHandler {
            let gr = UITapGestureRecognizer()
            on(gr) { _ in ah(contact) }
        }

        _token = contact.observe { [weak self] change in
            switch change {
            case .change(let properties):
                for property in properties {
                    switch property.newValue {
                    case let isOnline as Bool where showOnlineState && property.name == "isOnline":
                        self?._setOnlineState(isOnline)
                    case let iconURL as String where property.name == "iconURL":
                        self?._setImage(iconURL, sizeValue: sizeValue)
                    default: ()
                    }
                }
            default: ()
            }
        }
        _preContactId = contact.uuid
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        _imageView.frame = bounds
        
        let ratio: CGFloat = 0.5 * (sin(0.25 * .pi) + 1)
        let onlineStateViewX = ratio * width - 0.5 * _onlineStateViewSizeValue
        let onlineStateViewY = ratio * height - 0.5 * _onlineStateViewSizeValue
        _onlineStateView.frame = CGRect(x: onlineStateViewX, y: onlineStateViewY, width: _onlineStateViewSizeValue, height: _onlineStateViewSizeValue)
    }
    
    deinit {
        _token?.invalidate()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let _imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return imageView
    }()
    
    private let _onlineStateView = _OnlineStateView()
}

extension AvatarView {
    enum ActionType {
        case none
        case action((Contact) -> ())
        case showProfile(showChatButton: Bool)
    }
}

private extension AvatarView {
    func _setImage(_ urlString: String, sizeValue: CGFloat) {
        guard let url = URL(string: urlString) else { return }
        _imageView.kf.setImage(with: url.resize(to: CGSize(width: sizeValue, height: sizeValue)), options: .normalAvatarOptions(sizeValue: sizeValue))
    }
    
    func _setOnlineState(_ isOnline: Bool) {
        _onlineStateView.isOnline = isOnline
    }
}

private extension AvatarView {
    final class _OnlineStateView: UIView {
        var isOnline = false {
            didSet {
                guard isOnline != oldValue else { return }
                setNeedsDisplay()
            }
        }
        
        init() {
            super.init(frame: .zero)
            isOpaque = false
            backgroundColor = .clear
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draw(_ rect: CGRect) {
            let contentInset: CGFloat = 3
            guard let context = UIGraphicsGetCurrentContext() else { return }
            UIColor.white.setFill()
            context.fillEllipse(in: rect)
            let contentColor: UIColor = isOnline ? .onlineContent : .gray
            contentColor.setFill()
            let contentRect = CGRect(x: contentInset, y: contentInset, width: rect.width - 2 * contentInset, height: rect.height - 2 * contentInset)
            context.fillEllipse(in: contentRect)
        }
    }
}

fileprivate extension UIColor {
    static let onlineContent: UIColor = UIColor(r: 100, g: 235, b: 100)
}
