//
//  SynchronousArray.swift
//  Client
//
//  Created by Mahmoud Adam on 11/9/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class SynchronousArray {
    var array = [AnyObject]()
    let dispatchQueue = dispatch_queue_create("com.cliqz.synchronous.array", DISPATCH_QUEUE_SERIAL);

    
    var count: Int {
        get {
            return self.array.count;
        }
    }
    
    internal func getContents() -> [AnyObject] {
        return self.array
    }
    
    internal func append(newElement: AnyObject){
        dispatch_async(dispatchQueue) {
            self.array.append(newElement)
        }
    }
    
    internal func appendContentsOf(anotherArray: [AnyObject]) {
        dispatch_async(dispatchQueue) {
            self.array.appendContentsOf(anotherArray)
        }
    }
    
    internal func removeAll(){
        dispatch_async(dispatchQueue) {
            self.array.removeAll()
        }
    }
}
