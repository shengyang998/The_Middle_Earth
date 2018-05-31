//
//  UIView.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/25.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import YYText

extension UIView {
    func setShadow(color: UIColor, offSet: CGSize, radius: CGFloat, opacity: Float) {
        layer.shadowRadius = radius
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
    }
}

extension UIView {
    class SerialAnimation {
        private let _duration: TimeInterval
        private let _delay: TimeInterval
        private let _options: UIViewAnimationOptions
        private let _animations: () -> ()
        
        private var _preAnimation: SerialAnimation?
        private var _completion: (() -> ())?

        init(duration: TimeInterval, delay: TimeInterval = 0, options: UIViewAnimationOptions = .curveEaseInOut, animations: @escaping () -> ()) {
            _duration = duration
            _delay = delay
            _options = options
            _animations = animations
        }
        
        func next(duration: TimeInterval, delay: TimeInterval = 0, options: UIViewAnimationOptions = .curveEaseInOut, animations: @escaping () -> ()) -> SerialAnimation {
            let animation = SerialAnimation(duration: duration, delay: delay, options: options, animations: animations)
            animation._preAnimation = self
            // 在这里不使用弱引用animation，原因：
            // 为了保持链式引用： A <- B <- C <- D
            // D维持着上面所有对象的上面周期，因为有 _preAnimation 引用
            
            // 若不长维持着D的生命，只是在某个时机调用D的start，D会在动画完成前销毁
            // 所以需要这个闭包持有下一个Animation
            // 为了避免循环引用，在Animtion执行完动画后通知下一个去进行动画，会让下一个放弃对上一个的引用
            _completion = {
                animation._animate()
                animation._preAnimation = nil
            }
            return animation
        }
        
        private func _animate() {
            UIView.animate(withDuration: _duration, delay: _delay, options: _options, animations: _animations) { _ in self._completion?() }
        }
        
        func start() {
            if let pre = _preAnimation {
                pre.start()
            } else {
                _animate()
            }
        }
    }
}

private struct _ViewKeyboardAdapterHelper {
    static var _observerKey: UInt8 = 23
    static var _offsetKey: UInt8 = 32
    
    @discardableResult
    static func _lock<T>(obj: Any, todo: () -> T) -> T {
        objc_sync_enter(obj); defer { objc_sync_exit(obj) }
        return todo()
    }
}

// MARK: - Keyboard adapter
extension UIView {
    func adaptToKeyboard(minSpacingToKeyboard: CGFloat = 0, reference: UIView? = nil) {
        let observer = _KeyboardObserver { [unowned view = self, weak ref = reference] state in
            let reference = ref ?? view
            guard let superview = reference.superview,
                let keyWindow = UIApplication.shared.keyWindow
            else { return }
            
            switch state {
            case .dismiss:
                view.frame.origin.y += view._offset
            case .show(let frame):
                let bottomY = superview.convert(reference.origin, to: keyWindow).y + reference.height
                let offset = bottomY + minSpacingToKeyboard - frame.origin.y
                guard offset > 0 else { return }
                view.frame.origin.y -= offset
                view._offset = offset
            }
        }
        _keyboardObserver = observer
        YYTextKeyboardManager.default()?.add(observer)
    }
    
    func cancelAdaptingKeyboard() {
        guard let observer = _keyboardObserver else { return }
        YYTextKeyboardManager.default()?.remove(observer)
    }
    
    private var _offset: CGFloat {
        set {
            _ViewKeyboardAdapterHelper._lock(obj: self) {
                objc_setAssociatedObject(self, &_ViewKeyboardAdapterHelper._offsetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
        
        get {
            return _ViewKeyboardAdapterHelper._lock(obj: self) {
                objc_getAssociatedObject(self, &_ViewKeyboardAdapterHelper._offsetKey) as? CGFloat ?? 0
            }
        }
    }
    
    private var _keyboardObserver: _KeyboardObserver? {
        set {
            _ViewKeyboardAdapterHelper._lock(obj: self) {
                objc_setAssociatedObject(self, &_ViewKeyboardAdapterHelper._observerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
        get {
            return _ViewKeyboardAdapterHelper._lock(obj: self) {
                objc_getAssociatedObject(self, &_ViewKeyboardAdapterHelper._observerKey) as? _KeyboardObserver
            }
        }
    }
}

private extension UIView {
    enum _KeyboardDisplayState {
        case show(frame: CGRect)
        case dismiss
    }
    
    final class _KeyboardObserver: NSObject, YYTextKeyboardObserver {
        private let _animation: (_KeyboardDisplayState) -> ()
        
        init(_ animation: @escaping (_KeyboardDisplayState) -> ()) {
            _animation = animation
            super.init()
        }

        func keyboardChanged(with transition: YYTextKeyboardTransition) {
            guard transition.fromVisible.boolValue != transition.toVisible.boolValue else { return }

            let state: _KeyboardDisplayState = {
                if transition.toVisible.boolValue {
                    return .show(frame: transition.toFrame)
                } else {
                    return .dismiss
                }
            }()
            
            UIView.animate(withDuration: transition.animationDuration, delay: 0, options: transition.animationOption, animations: { [weak self] in
                self?._animation(state)
            })
        }
    }
}
