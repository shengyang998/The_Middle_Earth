//
//  HUD.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/7.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import JGProgressHUD

private var hudKey: UInt8 = 23
extension UIViewController {
    func showHUD(style: JGProgressHUDStyle = .dark, error: Error) {
        syncInMain {
            let hud = JGProgressHUD(style: style)
            hud.interactionType = .blockAllTouches
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = error.localizedDescription
            hud.show(in: view)
            hud.dismiss(afterDelay: 2, animated: true)
        }
    }
    
    func showHUD(style: JGProgressHUDStyle = .dark, successText: String) {
        syncInMain {
            let hud = JGProgressHUD(style: style)
            hud.interactionType = .blockAllTouches
            hud.indicatorView = JGProgressHUDSuccessIndicatorView()
            hud.textLabel.text = successText
            hud.show(in: view)
            hud.dismiss(afterDelay: 2, animated: true)
        }
    }
    
    func showHUD(style: JGProgressHUDStyle = .dark) {
        syncInMain {
            if let pre = _hud {
                pre.dismiss(animated: true)
                _hud = nil
            }
            
            let hud = JGProgressHUD(style: style)
            hud.interactionType = .blockAllTouches
            hud.show(in: view)
            _hud = hud
        }
    }
    
    func dismissHUD() {
        syncInMain {
            _hud?.dismiss(animated: true)
            _hud = nil
        }
    }
    
    private var _hud: JGProgressHUD? {
        set {
            objc_setAssociatedObject(self, &hudKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &hudKey) as? JGProgressHUD
        }
    }
}

struct HUD {
    private static var _hud: JGProgressHUD?

    static func show(style: JGProgressHUDStyle = .dark) {
        syncInMain {
            _hud?.dismiss(animated: true)
            guard let window = UIApplication.shared.keyWindow else { return }
            let hud = _create(style: style)
            hud.show(in: window)
            _hud = hud
        }
    }
    
    static func dismiss() {
        syncInMain {
            _hud?.dismiss(animated: true)
            _hud = nil
        }
    }
    
    private static func _create(style: JGProgressHUDStyle) -> JGProgressHUD {
        let hud = JGProgressHUD(style: style)
        hud.interactionType = .blockAllTouches
        return hud
    }
}
