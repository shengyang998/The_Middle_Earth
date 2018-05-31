//
//  URL+Image.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/10.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

// For Qiniu
extension URL {
    func resize(to size: CGSize) -> URL {
        if isFileURL { return self }
        guard var comps = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return self
        }
        let scale = UIScreen.main.scale
        comps.query = "imageView2/1/w/\(Int(scale * size.width))/h/\(Int(scale * size.height))"
        return comps.url ?? self
    }
}
