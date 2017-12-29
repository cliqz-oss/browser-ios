//
//  AutoCompletion.swift
//  Client
//
//  Created by Tim Palade on 12/29/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import React

@objc(AutoCompletion)
open class AutoCompletion: RCTEventEmitter {
    @objc(autoComplete:)
    func autoComplete(data: NSString) {
        debugPrint("autocomplete -- \(data)")
    }
}
