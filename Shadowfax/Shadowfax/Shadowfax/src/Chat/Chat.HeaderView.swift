//
//  Chat.HeaderView.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/24.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import Tactile

extension Chat {
    final class HeaderView: UIViewController {
        private let _contact: Contact
        
        init(contact: Contact) {
            _contact = contact
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private lazy var _backButton: UIButton = { (dismiss: @escaping () -> ()) in
            let button = UIButton(type: .system)
            // TODO: Color And R.image
//            button.ui.adapt(themeKeyPath: \.mainColor, for: \.tintColor)
//            button.setImage(R.image.chat_back()?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.on(.touchUpInside) { _ in dismiss() }
            return button
        } { [weak self] in self?.dismiss(animated: true, completion: nil) }
        
        private lazy var _avatarView = AvatarView(_contact, sizeValue: ui.avatarSizeValue, action: .showProfile(showChatButton: false))
        
        private lazy var _nickLabel: UILabel = {
            let label = UILabel()
            label.text = _contact.fullName
            label.font = .boldSystemFont(ofSize: 20)
            label.numberOfLines = 1
            label.textColor = .gray
            return label
        }()
    }
}

extension Chat.HeaderView {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(_backButton)
        view.addSubview(_avatarView)
        view.addSubview(_nickLabel)

        _backButton.translatesAutoresizingMaskIntoConstraints = false
        _avatarView.translatesAutoresizingMaskIntoConstraints = false
        _nickLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _avatarView.widthAnchor.constraint(equalToConstant: ui.avatarSizeValue),
            _avatarView.heightAnchor.constraint(equalToConstant: ui.avatarSizeValue),
            _avatarView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            _avatarView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: ui.contentHorizontalPadding),
            
            _nickLabel.leftAnchor.constraint(equalTo: _avatarView.rightAnchor, constant: 16),
            _nickLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            _backButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -ui.contentHorizontalPadding),
            _backButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

extension UI where Base: Chat.HeaderView {
    var contentHorizontalPadding: CGFloat { return 20 }
    var avatarSizeValue: CGFloat { return 48 }
}
