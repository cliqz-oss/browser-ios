//
//  Telemetry.swift
//  Client
//
//  Created by Tim Palade on 12/29/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import React

@objc(Telemetry)
open class TelemetryJS: RCTEventEmitter {
    
    open override static func moduleName() -> String! {
        return "Telemetry"
    }
    
    @objc(sendTelemetry:)
    func sendTelemetry(data: NSString) {
        debugPrint("send telemetry -- \(data)")
    }
}

