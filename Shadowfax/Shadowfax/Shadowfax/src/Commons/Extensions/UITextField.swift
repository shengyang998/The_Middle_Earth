//
//  UITextField.swift
//  WALL-E
//
//  Created by Tangent on 2018/5/7.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

extension UITextField {
    func validateAndGetText(minCount: Int = 0, maxCount: Int = .max, callback: (UITextField, Bool) -> ()) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            else { callback(self, false); return nil }
        let count = text.count
        if count < minCount { callback(self, false); return nil }
        if count > maxCount { callback(self, false); return nil }
        callback(self, true)
        return text
    }
}
