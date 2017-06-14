//
//  AtomicInt.swift
//  Client
//
//  Created by Mahmoud Adam on 11/5/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class AtomicInt {
    fileprivate var currentValue: Int
    let dispatchQueue = DispatchQueue(label: "com.cliqz.atomic.int", attributes: []);
    
    init(initialValue: Int) {
        currentValue = initialValue
    }
    
    internal func get()-> Int {
        return currentValue
    }
    
    internal func incrementAndGet()-> Int {
        dispatchQueue.sync {
            if self.currentValue < Int.max {
                self.currentValue += 1
            } else {
                self.currentValue = 0
            }
        }
        return currentValue
    }
    
    
    internal func decrementAndGet()-> Int {
        dispatchQueue.sync {
            if self.currentValue > 0 {
                self.currentValue -= 1
            } else {
                self.currentValue = 0
            }
        }
        return currentValue
    }
    
}
