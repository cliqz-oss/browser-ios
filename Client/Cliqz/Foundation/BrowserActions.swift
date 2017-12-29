//
//  BrowserActions.swift
//  Client
//
//  Created by Tim Palade on 12/29/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import React

@objc(BrowserActions)
open class BrowserActions: RCTEventEmitter {

    @objc(searchHistory:callback:)
    func searchHistory(query: NSString, callback: RCTResponseSenderBlock) {
        debugPrint("searchHistory")
        
        //don't send empty stuff
        //callback([""])
    }

}
