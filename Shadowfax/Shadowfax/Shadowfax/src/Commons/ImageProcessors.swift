//
//  ImageProcessors.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/23.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit
import Kingfisher

func resizeAndCroppingProcessor(targetSize: CGSize, withCorner radius: CGFloat = 0) -> ImageProcessor {
    let resizeSize = CGSize(width: targetSize.width , height: targetSize.height)
    var ret = ResizingImageProcessor(referenceSize: resizeSize, mode: .aspectFill) >> CroppingImageProcessor(size: resizeSize)
    if radius > 0 {
        ret = ret >> RoundCornerImageProcessor(cornerRadius: radius,  backgroundColor: .clear)
    }
    return ret
}

extension KingfisherOptionsInfoItem {
    static func resizeAndCropping(targetSize: CGSize, withCorner radius: CGFloat = 0) -> KingfisherOptionsInfoItem {
        let ret = resizeAndCroppingProcessor(targetSize: targetSize, withCorner: radius)
        return .processor(ret)
    }
    static let pngCacheSerializer: KingfisherOptionsInfoItem = .cacheSerializer(FormatIndicatedCacheSerializer.png)
}

extension Array where Element == KingfisherOptionsInfoItem {
    static func normalAvatarOptions(sizeValue: CGFloat) -> [KingfisherOptionsInfoItem] {
        return [
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.25)),
            .resizeAndCropping(targetSize: .init(width: sizeValue, height: sizeValue), withCorner: 0.5 * sizeValue),
            .pngCacheSerializer
        ]
    }
    
    static func normalImageOptions(size: CGSize, corner: CGFloat) -> [KingfisherOptionsInfoItem] {
        return [
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.25)),
            .resizeAndCropping(targetSize: size, withCorner: corner),
            .pngCacheSerializer
        ]
    }
}
