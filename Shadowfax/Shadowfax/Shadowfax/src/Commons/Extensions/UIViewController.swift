//
//  UIViewController.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/24.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import RxSwift

// MARK: - StatusBarDelegate
private struct _AssociatedHelper {
    static var _statusBarStyleKey: UInt8 = 32
    static var _preStatusBarStyleKey: UInt8 = 34
    static func _lock<T>(in obj: AnyObject, _ todo: () -> T) -> T {
        objc_sync_enter(obj); defer { objc_sync_exit(obj) }
        return todo()
    }
}
extension UIViewController {
    static func adaptStatusBarStyle() {
        let vwa_old = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewWillAppear(_:)))!
        let vwa_new = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.WALL__viewWillAppear(_:)))!
        method_exchangeImplementations(vwa_new, vwa_old)
        
        let vwd_old = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewWillDisappear(_:)))!
        let vwd_new = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.WALL__viewWillDisappear(_:)))!
        method_exchangeImplementations(vwd_old, vwd_new)
    }
    
    var statusBarStyle: UIStatusBarStyle? {
        get {
            return _AssociatedHelper._lock(in: self) {
                return objc_getAssociatedObject(self, &_AssociatedHelper._statusBarStyleKey) as? UIStatusBarStyle
            }
        }
        
        set {
            _AssociatedHelper._lock(in: self) {
                objc_setAssociatedObject(self, &_AssociatedHelper._statusBarStyleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    private var _preStatusBarStyle: UIStatusBarStyle? {
        get {
            return _AssociatedHelper._lock(in: self) {
                return objc_getAssociatedObject(self, &_AssociatedHelper._preStatusBarStyleKey) as? UIStatusBarStyle
            }
        }
        
        set {
            _AssociatedHelper._lock(in: self) {
                objc_setAssociatedObject(self, &_AssociatedHelper._preStatusBarStyleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    @objc private func WALL__viewWillAppear(_ animated: Bool) {
        WALL__viewWillAppear(animated)
        if let style = statusBarStyle {
            _preStatusBarStyle = UIApplication.shared.statusBarStyle
            UIApplication.shared.statusBarStyle = style
        }
    }
    
    @objc private func WALL__viewWillDisappear(_ animated: Bool) {
        WALL__viewWillDisappear(animated)
        if let preStyle = _preStatusBarStyle, statusBarStyle != preStyle {
            UIApplication.shared.statusBarStyle = preStyle
        }
    }
}

// MARK: - Show Alert
extension UIViewController {
    @discardableResult
    func showAlert(title: String? = nil, message: String? = nil, okAction: (() -> ())? = nil, completion: (() -> ())? = nil ) -> UIAlertController {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { _ in okAction?() }
        ac.addAction(action)
        present(ac, animated: true, completion: completion)
        return ac
    }
    
    @discardableResult
    func showChooseAlert(title: String? = nil, message: String? = nil, yesAction: (() -> ())? = nil, noAction: (() -> ())? = nil, completion: (() -> ())? = nil) -> UIAlertController {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let yes = UIAlertAction(title: "YES", style: .default) { _ in yesAction?() }
        let no = UIAlertAction(title: "NO", style: .cancel) { _ in noAction?() }
        ac.addAction(yes)
        ac.addAction(no)
        present(ac, animated: true, completion: completion)
        return ac
    }
}

// MARK: - Add
extension UIViewController {
    func add(_ child: UIViewController, shouldAddView: Bool = true, viewFrame: CGRect = .zero) {
        addChildViewController(child)
        if shouldAddView { view.addSubview(child.view) }
        if viewFrame != .zero { child.view.frame = viewFrame }
        child.didMove(toParentViewController: self)
    }
}

// MARK: - Topmost
extension UIViewController {
    static var topMost: UIViewController? {
        guard let window = UIApplication.shared.delegate?.window, let rootVC = window?.rootViewController else {
            return nil
        }
        return rootVC.topMost
    }
    
    var topMost: UIViewController? {
        if let presentedVC = presentedViewController {
            return presentedVC.topMost
        }
        if let tabBarC = self as? UITabBarController,
            let selectedVC = tabBarC.selectedViewController {
            return selectedVC.topMost
        }
        if let navC = self as? UINavigationController,
            let visibleVC = navC.visibleViewController {
            return visibleVC.topMost
        }
        return self
    }
}
