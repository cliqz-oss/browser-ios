//
//  CliqzMainWindow.swift
//  Client
//
//  Created by Mahmoud Adam on 10/19/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class CliqzMainWindow: UIWindow {
    let contextMenuHandler = CliqzContextMenu()

    override func sendEvent(_ event: UIEvent) {
        contextMenuHandler.sendEvent(event, window: self)

        super.sendEvent(event)
    }
}
