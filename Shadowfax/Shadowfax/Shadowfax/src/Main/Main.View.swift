//
//  Main.View.swift
//  Shadowfax
//
//  Created by Tangent on 2018/5/31.
//  Copyright © 2018 Ysy. All rights reserved.
//

import UIKit

enum Main { }

extension Main {
    final class View: UIViewController {
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            guard let contact = SDFAXDB.makeConnection().objects(Contact.self).filter("uuid == \"9f7f6da0-bbb1-4c24-abb3-85e22809983a\"").last else { return }
            UIApplication.shared.keyWindow?.rootViewController = Chat.View(contact: contact)
        }
    }
}

extension Main.View {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
}
