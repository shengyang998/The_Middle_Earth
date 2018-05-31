//
//  ImagePicker+Rx.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/7.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import Photos
import MessageListener
import RxSwift

private var imagePickerDelegateKey: UInt8 = 23
extension UIImagePickerController {
    @available(iOS 11, *)
    static func pick(on viewController: UIViewController, config: ((UIImagePickerController) -> ())? = nil) -> Observable<(url: URL, image: UIImage)> {
        let picker = UIImagePickerController()
        config?(picker)
        let delegate = _Delegate()
        objc_setAssociatedObject(picker, &imagePickerDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        defer { picker.delegate = delegate }
        viewController.present(picker, animated: true, completion: nil)

        let selector = #selector(UIImagePickerControllerDelegate.imagePickerController(_:didFinishPickingMediaWithInfo:))
        return delegate.rx.listen(selector, in: UIImagePickerControllerDelegate.self)
            .do(onNext: { [weak picker] _ in picker?.dismiss(animated: true, completion: nil) })
            .map { $0[1] as! [String: Any] }
            .map { ($0[UIImagePickerControllerImageURL] as! URL, $0[UIImagePickerControllerOriginalImage] as! UIImage) }
    }
    
    private final class _Delegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate { }
}
