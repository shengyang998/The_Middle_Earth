//
//  Chat.Cell.swift
//  WALL-E
//
//  Created by Tangent on 2018/4/26.
//  Copyright © 2018 Tangent. All rights reserved.
//

import UIKit

extension Chat {
    final class Cell: UITableViewCell {
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            contentView.addSubview(_dateLabel)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private var _offsetForAccessoryView: CGFloat = 0 {
            didSet { setNeedsLayout() }
        }
        
        private lazy var _dateLabel: UILabel = {
            let label = UILabel()
            label.textColor = .gray
            label.font = .boldSystemFont(ofSize: 12)
            label.textAlignment = .center
            return label
        }()
        
        var message: Message? {
            didSet {
                _dateLabel.text = message?.time.shortTimeString ?? ""
            }
        }
    }
}

extension Chat.Cell {
    override func layoutSubviews() {
        super.layoutSubviews()
        _dateLabel.sizeToFit()
        _dateLabel.width = ui.dateLabelWidth
        _dateLabel.center.y = 0.5 * contentView.height
        _dateLabel.x = width
        
        // For accessoryView
        contentView.x = -_offsetForAccessoryView
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        _offsetForAccessoryView = 0
    }
}

extension Chat.Cell: AccessoryViewRevealable {
    func revealAccessoryView(withOffset offset: CGFloat, animated: Bool) {
        _offsetForAccessoryView = offset
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }
    
    func preferredOffsetToRevealAccessoryView() -> CGFloat? {
        return ui.dateLabelWidth
    }
    
    var allowAccessoryViewRevealing: Bool {
        return true
    }
}

extension UI where Base: Chat.Cell {
    var dateLabelWidth: CGFloat { return 60 }
}
