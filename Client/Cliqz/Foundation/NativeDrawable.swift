//
//  ReactNativeDrawableManager.swift
//  Client
//
//  Created by Tim Palade on 12/27/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import React

@objc(NativeDrawable)
open class NativeDrawable : RCTViewManager {
    open override static func moduleName() -> String! {
        return "NativeDrawable"
    }
}

