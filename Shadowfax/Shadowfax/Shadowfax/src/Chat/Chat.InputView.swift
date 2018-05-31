//
//  Chat.InputView.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/24.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import Photos
import TanImagePicker

extension Chat {
    final class InputView: UIViewController {
        private let _send: (Content) -> ()
        
        init(send: @escaping (Content) -> ()) {
            _send = send
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private lazy var _contentView: UITextView = {
            let tv = UITextView()
            tv.font = ui.font
            tv.textColor = ui.textColor
            tv.delegate = self
            tv.backgroundColor = .clear
            tv.textContainerInset = .zero
            tv.isScrollEnabled = false
            tv.showsVerticalScrollIndicator = false
            if ui._supportNewLine {
                tv.returnKeyType = .default
                tv.enablesReturnKeyAutomatically = false
            } else {
                tv.returnKeyType = .send
                tv.enablesReturnKeyAutomatically = true
            }
            return tv
        }()
        
        private lazy var _placeholderLabel: UILabel = {
            let label = UILabel()
            label.isUserInteractionEnabled = false
            label.font = ui.font
            label.text = ui.placeholder
            // TODO: Color
//            label.ui.adapt(themeKeyPath: \.mainColor, for: \.textColor) { $0.withAlphaComponent(0.8) }
            return label
        }()
        
        private lazy var _sendButton: UIButton = { (callback: @escaping () -> ()) in
            let button = UIButton(type: .system)
            button.tintColor = .gray
            button.setTitle("Send", for: .normal)
            button.on(.touchUpInside) { _ in callback() }
            return button
        }(_imagesPickerHelper.prepareSend)
        
        private lazy var _imagesPickerHelper = ImagesPickerAdapter(self, sendAssets: _sendAssets)

        private var _contentViewHeightConstraint: NSLayoutConstraint?
        private var _sendButtonWidthAndRightConstraint: (width: NSLayoutConstraint, right: NSLayoutConstraint)?
        private var _isSendButtonShowed = false
    }
}

extension Chat {
    enum InputType {
        case keyboard
        case imagesPicker
        
        var extraButtonImage: UIImage? {
            // TODO: R.image
            switch self {
            case .keyboard:
                ()
//                return R.image.chat_images()
            case .imagesPicker:
                ()
//                return R.image.chat_keyboard()
            }
            return UIImage()
        }
    }
    
    enum Content {
        case text(String)
    }
}

extension Chat.InputView {
    override func loadView() {
        view = CrossSizeHittableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(_placeholderLabel)
        view.addSubview(_contentView)
        view.addSubview(_sendButton)
        _layoutViews()
        
        view.addSubview(_imagesPickerHelper.indicationView)
        _setupPicker()
    }
    
    private func _layoutViews() {
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        _sendButton.translatesAutoresizingMaskIntoConstraints = false
        _imagesPickerHelper.indicationView.translatesAutoresizingMaskIntoConstraints = false
        
        // ContentView & PlaceholderView
        _contentView.sizeToFit()
        let initialContentViewHeight = _contentView.height
        
        func fillConstraints(_ aView: UIView) -> [NSLayoutConstraint] {
            let isPlaceholder = aView === _placeholderLabel
            var ret = [
                aView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -ui.bottomSpacing),
                aView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: ui.horizontalSpacing - (isPlaceholder ? -2 : 5)),
                aView.rightAnchor.constraint(equalTo: _sendButton.leftAnchor, constant: -ui.horizontalSpacing + (isPlaceholder ? 2 : 9)),
            ]
            
            if isPlaceholder {
                ret += [aView.heightAnchor.constraint(equalToConstant: initialContentViewHeight)]
            } else {
                ret += [aView.topAnchor.constraint(equalTo: view.topAnchor, constant: ui.topSpacing)]
            }
            
            return ret
        }
        
        let contentViewHeightConstraint = _contentView.heightAnchor.constraint(equalToConstant: initialContentViewHeight)
        _contentViewHeightConstraint = contentViewHeightConstraint
        
        // Buttons
        func layoutButton(_ btn: UIButton) -> [NSLayoutConstraint] {
            btn.sizeToFit()
            let isSendBtn = btn === _sendButton
            let widthConstraint = btn.widthAnchor.constraint(equalToConstant: isSendBtn ? 0 : btn.width)
            let rightConstraint = btn.rightAnchor.constraint(equalTo: isSendBtn ? view.rightAnchor : _sendButton.leftAnchor,
                                                             constant: isSendBtn ? 0 : -ui.horizontalSpacing)
            
            if isSendBtn { _sendButtonWidthAndRightConstraint = (widthConstraint, rightConstraint) }
            
            return [
                btn.centerYAnchor.constraint(equalTo: _placeholderLabel.centerYAnchor),
                rightConstraint,
                widthConstraint
            ]
        }

        NSLayoutConstraint.activate(
            fillConstraints(_contentView) + fillConstraints(_placeholderLabel)
            + [contentViewHeightConstraint]
            + layoutButton(_sendButton)
        )
    }
    
    private func _setupPicker() {
        let indicationView = _imagesPickerHelper.indicationView
        indicationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicationView.leftAnchor.constraint(equalTo: view.leftAnchor),
            indicationView.rightAnchor.constraint(equalTo: view.rightAnchor),
            indicationView.heightAnchor.constraint(equalToConstant: ui.imagesPickerIndicationViewHeight),
            indicationView.bottomAnchor.constraint(equalTo: view.topAnchor)
        ])

        _imagesPickerHelper.shouldShowSendButton = { [weak self] in
            guard let `self` = self else { return }
            var shouldShow = $0
            if self.ui._supportNewLine {
                shouldShow = shouldShow || !self._text.isEmpty
            }
            self._switchSendButtonDisplayIfNeeds(shouldShow)
        }
    }
    
    private func _switchSendButtonDisplayIfNeeds(_ shouldShow: Bool) {
        guard _isSendButtonShowed != shouldShow, let constraints = _sendButtonWidthAndRightConstraint else { return }
        if shouldShow {
            self._sendButton.sizeToFit()
            constraints.width.constant = _sendButton.width
            constraints.right.constant = -ui.horizontalSpacing
        } else {
            forEach(constraints) { $0.constant = 0 }
        }
        UIView.animate(withDuration: 0.25) {
            self.view.superview?.layoutIfNeeded()
        }
        _isSendButtonShowed = shouldShow
    }
}

extension Chat.InputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        _contentChanged()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard !text._shouldSend || ui._supportNewLine else { _prepareSend(); return false }
        return true
    }
    
    var _text: String {
        return _contentView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Chat.InputView {
    // For TextView
    func _contentChanged() {
        _placeholderLabel.isHidden = !_text.isEmpty
        if ui._supportNewLine {
            _switchSendButtonDisplayIfNeeds(!_text.isEmpty || _imagesPickerHelper.hasSelectedAssets)
        }

        // Check: Should re-layout height
        let expectedContentViewHeight = min(_contentView.sizeThatFits(.init(width: _contentView.width, height: .infinity)).height, ui.maxHeightForContentView)
        guard
            let contentViewHeightConstraint = _contentViewHeightConstraint,
            contentViewHeightConstraint.constant != expectedContentViewHeight
        else { return }
        _contentView.isScrollEnabled = expectedContentViewHeight == ui.maxHeightForContentView
        contentViewHeightConstraint.constant = expectedContentViewHeight
        UIView.animate(withDuration: 0.25) {
            self.view.superview?.layoutIfNeeded()
        }
    }
    
    // For sending
    func _prepareSend() {
        if _imagesPickerHelper.hasSelectedAssets {
            _imagesPickerHelper.prepareSend()
        } else {
            _sendText()
        }
    }
    
    func _sendText() {
        guard !_text.isEmpty else { return }
        _send(.text(_text))
        _contentView.text = ""
        _contentChanged()
    }
    
    var _sendAssets: ([PHAsset]) -> () {
        return { [weak self] _ in
            self?._sendText()
        }
    }
}

extension UI where Base: Chat.InputView {
    var font: UIFont { return .boldSystemFont(ofSize: 17) }
    var textColor: UIColor { return .gray }
    var placeholder: String { return "type something" }
    var horizontalSpacing: CGFloat { return 20 }
    var topSpacing: CGFloat { return 16 }
    var bottomSpacing: CGFloat { return 20 }
    var imagesPickerIndicationViewHeight: CGFloat { return 60 }
    var maxHeightForContentView: CGFloat { return 0.3 * UIScreen.main.bounds.height}
    // Support keyboard new line
    var _supportNewLine: Bool { return true }
}

fileprivate extension String {
    var _shouldSend: Bool { return self == "\n" }
}
