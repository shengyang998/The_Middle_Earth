//
//  UIImage.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/7.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

extension UIImage {
    func resize(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: .init(origin: .zero, size: size), blendMode: .normal, alpha: 1)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
