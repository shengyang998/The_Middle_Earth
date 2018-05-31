//
//  AccessoryViewRevealer.swift
//
//  Copy from:
//  https://github.com/badoo/Chatto/blob/master/Chatto/Source/ChatController/Collaborators/AccessoryViewRevealer.swift
//

import Foundation
import UIKit

public protocol AccessoryViewRevealable {
    func revealAccessoryView(withOffset offset: CGFloat, animated: Bool)
    func preferredOffsetToRevealAccessoryView() -> CGFloat? // This allows to sync size in case cells have different sizes for the accessory view. Nil -> no restriction
    var allowAccessoryViewRevealing: Bool { get }
}

public struct AccessoryViewRevealerConfig {
    public let angleThresholdInRads: CGFloat
    public let translationTransform: (_ rawTranslation: CGFloat) -> CGFloat
    public init(angleThresholdInRads: CGFloat, translationTransform: @escaping (_ rawTranslation: CGFloat) -> CGFloat) {
        self.angleThresholdInRads = angleThresholdInRads
        self.translationTransform = translationTransform
    }
    
    public static func defaultConfig() -> AccessoryViewRevealerConfig {
        return self.init(
            angleThresholdInRads: 0.0872665, // ~5 degrees
            translationTransform: { (rawTranslation) -> CGFloat in
                let threshold: CGFloat = 30
                return max(0, rawTranslation - threshold) / 2
        })
    }
}

class AccessoryViewRevealer: NSObject, UIGestureRecognizerDelegate {
    
    private let panRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer()
    private let tableView: UITableView
    
    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        self.tableView.addGestureRecognizer(self.panRecognizer)
        self.panRecognizer.addTarget(self, action: #selector(AccessoryViewRevealer.handlePan(_:)))
        self.panRecognizer.delegate = self
    }
    
    deinit {
        self.panRecognizer.delegate = nil
        self.tableView.removeGestureRecognizer(self.panRecognizer)
    }
    
    var isEnabled: Bool = true {
        didSet {
            self.panRecognizer.isEnabled = self.isEnabled
        }
    }
    
    var config = AccessoryViewRevealerConfig.defaultConfig()
    
    @objc
    private func handlePan(_ panRecognizer: UIPanGestureRecognizer) {
        switch panRecognizer.state {
        case .began:
            break
        case .changed:
            let translation = panRecognizer.translation(in: self.tableView)
            self.revealAccessoryView(atOffset: self.config.translationTransform(-translation.x))
        case .ended, .cancelled, .failed:
            self.revealAccessoryView(atOffset: 0)
        default:
            break
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer != self.panRecognizer {
            return true
        }
        
        let translation = self.panRecognizer.translation(in: self.tableView)
        let x = abs(translation.x), y = abs(translation.y)
        let angleRads = atan2(y, x)
        return angleRads <= self.config.angleThresholdInRads
    }
    
    private func revealAccessoryView(atOffset offset: CGFloat) {
        // Find max offset (cells can have slighlty different timestamp size ( 3.00 am vs 11.37 pm )
        let cells: [AccessoryViewRevealable] = self.tableView.visibleCells.compactMap({ $0 as? AccessoryViewRevealable })
        let offset = min(offset, cells.reduce(0) { (current, cell) -> CGFloat in
            return max(current, cell.preferredOffsetToRevealAccessoryView() ?? 0)
        })
        
        for cell in self.tableView.visibleCells {
            if let cell = cell as? AccessoryViewRevealable, cell.allowAccessoryViewRevealing {
                cell.revealAccessoryView(withOffset: offset, animated: offset == 0)
            }
        }
    }
}
