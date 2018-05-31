//
//  Chat.View.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/24.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import Tactile

extension Chat {
    final class View: UIViewController {
        private let _contact: Contact
        private let _transition = Transition()

        init(contact: Contact) {
            _contact = contact
            super.init(nibName: nil, bundle: nil)
            modalPresentationStyle = .custom
            transitioningDelegate = _transition
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // ViewModel
        private lazy var _viewModel = ViewModel(contact: _contact)
        
        // Views
        private lazy var _presenter = Presenter(change: _viewModel.change, chatView: self)
        private lazy var _headerView = HeaderView(contact: _contact)
        
        private lazy var _contentView = ContentView(messages: _viewModel.messages, refresh: _presenter.refreshContentView) { [weak self] event in
            switch event {
            case .tap:
                self?._presenter.dismissKeyboard()
            case .scrollTooFar(let flag):
                self?._scrollBottomButton.isHidden = !flag
            }
        }
        
        private lazy var _scrollBottomButton: UIButton = { (callback: @escaping () -> ()) in
            let button = UIButton(type: .system)
            button.isHidden = true
            // TODO: Color And R.image
//            button.ui.adapt(themeKeyPath: \.mainColor, for: \.tintColor)
//            button.setImage(R.image.scroll_bottom()?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.setShadow(color: .gray, offSet: .init(width: 1, height: 1), radius: 2, opacity: 0.6)
            button.on(.touchUpInside) { _ in callback() }
            return button
        } { [weak self] in
            self?._presenter.scrollToBottom()
        }

        private lazy var _inputView = InputView { [weak self] content in
            switch content {
            case let .text(text):
                self?._viewModel.send(text)
            }
        }
    }
}

extension Chat.View {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = .white
        statusBarStyle = .lightContent
        _setupViews()
        _layoutViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.roundCorners(.allCorners, radius: 16)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
}

private extension Chat.View {
    func _setupViews() {
        add(_headerView)
        add(_contentView)
        add(_inputView)
        view.addSubview(_scrollBottomButton)
    }
    
    func _layoutViews() {
        _headerView.view.translatesAutoresizingMaskIntoConstraints = false
        _inputView.view.translatesAutoresizingMaskIntoConstraints = false
        _contentView.view.translatesAutoresizingMaskIntoConstraints = false
        _scrollBottomButton.translatesAutoresizingMaskIntoConstraints = false

        let inputViewBottomAnchor: NSLayoutYAxisAnchor = {
            if #available(iOS 11, *) {
                return view.safeAreaLayoutGuide.bottomAnchor
            } else {
                return view.bottomAnchor
            }
        }()
        
        let inputViewBottomConstraint = _inputView.view.bottomAnchor.constraint(equalTo: inputViewBottomAnchor)
        _presenter.fitKeyboard(for: inputViewBottomConstraint)

        NSLayoutConstraint.activate([
            _headerView.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            _headerView.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            _headerView.view.topAnchor.constraint(equalTo: view.topAnchor),
            _headerView.view.heightAnchor.constraint(equalToConstant: ui.headerHeight),
            
            _contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            _contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            _contentView.view.topAnchor.constraint(equalTo: _headerView.view.bottomAnchor),
            _contentView.view.bottomAnchor.constraint(equalTo: _inputView.view.topAnchor),
            
            _inputView.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            _inputView.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            inputViewBottomConstraint,
            
            _scrollBottomButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -28),
            _scrollBottomButton.bottomAnchor.constraint(equalTo: _inputView.view.topAnchor, constant: -20)
        ])
    }
}

extension UI where Base: Chat.View {
    var headerHeight: CGFloat { return 68 }
}
