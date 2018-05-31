//
//  Chat.ImagesPickerAdapter.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/25.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import Photos
import TanImagePicker
import JGProgressHUD

extension Chat {
    final class ImagesPickerAdapter {
        private let _sendAssets: ([PHAsset]) -> ()
        
        init(_ viewController: UIViewController, sendAssets: @escaping ([PHAsset]) -> ()) {
            _sendAssets = sendAssets
            
            viewController.add(_imagePicker.contentView, shouldAddView: false)
            viewController.add(_imagePicker.indicationView, shouldAddView: false)
            _imagePicker.indicationView.view.isHidden = true
            _imagePicker.indicationView.view.setShadow(color: UIColor(white: 0, alpha: 0.2), offSet: CGSize(width: 0, height: -20), radius: 12, opacity: 0.4)
        }
        
        private lazy var _imagePicker: TanImagePicker = { (callback: @escaping ([PHAsset]) -> ()) in
            let ui: Set<TanImagePicker.UIItem> = [ ]
            let picker = TanImagePicker(UI: ui, mediaOption: .all, selectedLimit: 4, didSelectedAssets: callback)
            return picker
        } { [weak self] in
            self?._switchToShowIndicationView($0.count)
        }
        
        private lazy var _hud: JGProgressHUD = {
            let hud = JGProgressHUD(style: .light)
            let indicatorView = JGProgressHUDPieIndicatorView()
            hud.indicatorView = indicatorView
            // TODO: Color
//            indicatorView.ui.adapt(themeKeyPath: \.mainColor, for: \.color)
            indicatorView.fillColor = .white
            hud.interactionType = .blockAllTouches
            hud.shadow = JGProgressHUDShadow(color: .gray, offset: .init(width: 3, height: 3), radius: 7, opacity: 0.4)
            return hud
        }()

        // Outputs
        var contentView: UIView { return _imagePicker.contentView.view }
        var indicationView: UIView { return _imagePicker.indicationView.view }
        var shouldShowSendButton: ((Bool) -> ())?
        var hasSelectedAssets: Bool { return !_imagePicker.selectedAssets.isEmpty }
        var prepareSend: () -> () {
            return { [weak self] in
                self?._imagePicker.finishPickingImages { state in
                    switch state {
                    case .completed(let assets):
                        self?._sendAssets(assets)
                        self?._imagePicker.clear()
                        fallthrough
                    case .cancel:
                        guard self?._hud.isVisible == true else { return }
                        self?._hud.dismiss(animated: true)
                    case .progress(let progress):
                        self?._hud.progress = Float(progress)
                        
                        guard self?._hud.isVisible == false,
                            let view = UIViewController.topMost?.view
                        else { return }
                        self?._hud.show(in: view)
                    }
                }
            }
        }
    }
}

private extension Chat.ImagesPickerAdapter {
    func _switchToShowIndicationView(_ assetsCount: Int) {
        if assetsCount <= 0 && !indicationView.isHidden {
            indicationView.isHidden = true
            shouldShowSendButton?(false)
        }
        
        else if assetsCount > 0 && indicationView.isHidden {
            indicationView.isHidden = false
            shouldShowSendButton?(true)
        }
    }
}

// MARK: - Auth
extension Chat.ImagesPickerAdapter {
    func requestPHAuthIfNeeds() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .denied, .restricted:
            UIViewController.topMost?.showAlert(message: "Please allow WALL-E access your Photos")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                switch status {
                case .authorized:
                    self?._imagePicker.reloadAssets()
                default: ()
                }
            }
        default: ()
        }
    }
}
