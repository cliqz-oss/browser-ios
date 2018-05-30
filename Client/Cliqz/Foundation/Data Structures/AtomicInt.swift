//
//  AtomicInt.swift
//  Client
//
//  Created by Mahmoud Adam on 11/5/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class AtomicInt {
    private var currentValue: Int
    let dispatchQueue = dispatch_queue_create("com.cliqz.atomic.int", DISPATCH_QUEUE_SERIAL);
    
    init(initialValue: Int) {
        currentValue = initialValue
    }
    
    internal func get()-> Int {
        return currentValue
    }
    
    internal func incrementAndGet()-> Int {
        dispatch_sync(dispatchQueue) {
            if self.currentValue < Int.max {
                self.currentValue++
            } else {
                self.currentValue = 0
            }
        }
        return currentValue
    }
    
    
    internal func decrementAndGet()-> Int {
        dispatch_sync(dispatchQueue) {
            if self.currentValue > 0 {
                self.currentValue--
            } else {
                self.currentValue = 0
            }
        }
        return currentValue
    }
    
}
