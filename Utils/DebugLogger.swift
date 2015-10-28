//
//  DebugLogger.swift
//  Client
//
//  Created by Mahmoud Adam on 10/27/15.
//  Copyright (c) 2015 Cliqz. All rights reserved.
//

import UIKit

class DebugLogger {
    class func log<T>(@autoclosure object: () -> T) {
        #if DEBUG
            let value = object()
            let stringRepresentation: String
            
            if let value = value as? CustomDebugStringConvertible {
                stringRepresentation = value.debugDescription
            } else if let value = value as? CustomStringConvertible {
                stringRepresentation = value.description
            } else {
				stringRepresentation = ""
                fatalError("printLog only works for values that conform to CustomDebugStringConvertible or CustomStringConvertible")
            }
			
			NSLog("[DEBUG] \(stringRepresentation)")
        #endif
    }
}
