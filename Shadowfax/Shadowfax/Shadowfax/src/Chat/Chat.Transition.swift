//
//  Chat.Transition.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/24.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

extension Chat {
    final class Transition: NSObject {
        private var _isShowing = false
        
        private lazy var _maskView: UIButton = {
            let view = UIButton()
            view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            view.backgroundColor = .gray
            view.alpha = 0
            view.on(.touchUpInside) { [weak self] _ in self?._maskViewAction?() }
            return view
        }()
        
        private var _maskViewAction: (() -> ())?
    }
}

extension Chat.Transition: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return _triggerShowing(true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return _triggerShowing(false)
    }
    
    private func _triggerShowing(_ flag: Bool) -> UIViewControllerAnimatedTransitioning {
        _isShowing = flag
        return self
    }
}

extension Chat.Transition: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return ui.animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.viewController(forKey: .from)!.view!
        let toViewController = transitionContext.viewController(forKey: .to)!
        let toView = toViewController.view!
        let containerView = transitionContext.containerView
        
        func animate(_ animations: @escaping () -> (), completion: @escaping () -> ()) {
            UIView.animate(withDuration: ui.animationDuration, delay: 0, usingSpringWithDamping: 0.65,
                           initialSpringVelocity: 0, options: .curveEaseInOut,
                           animations: animations, completion: const(completion))
        }
        
        func show() {
            var finalViewFrame = containerView.frame
            finalViewFrame.origin.y = ui.viewTopPadding
            finalViewFrame.size.height -= ui.viewTopPadding
            (toView.frame, _maskView.frame) = (finalViewFrame, containerView.bounds)
            toView.transform = CGAffineTransform(translationX: 0, y: finalViewFrame.height)
            [_maskView, toView].forEach(containerView.addSubview)
            animate({
                self._maskView.alpha = 0.65
                fromView.layer.transform = self.ui.preViewFinalTransform
                toView.transform = .identity
            }) {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            _maskViewAction = { [weak vc = toViewController] in vc?.dismiss(animated: true, completion: nil) }
        }
        
        func dismiss() {
            animate({
                self._maskView.alpha = 0
                fromView.transform = CGAffineTransform(translationX: 0, y: fromView.height)
                toView.layer.transform = CATransform3DIdentity
            }) {
                self._maskView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                fromView.transform = .identity
            }
            _maskViewAction = nil
        }
        
        if _isShowing { show() }
        else { dismiss() }
    }
}

extension UI where Base: Chat.Transition {
    var animationDuration: TimeInterval { return 0.6 }
    var viewTopPadding: CGFloat { return UIApplication.shared.statusBarFrame.height + 20 }
    var viewCornerRadius: CGFloat { return 16 }
    var preViewFinalTransform: CATransform3D {
        var tran = CATransform3DIdentity
        tran.m34 = -1 / 700
        tran = CATransform3DScale(tran, 0.945, 0.945, 1)
        return tran
    }
}
