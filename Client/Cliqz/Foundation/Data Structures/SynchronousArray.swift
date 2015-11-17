//
//  SynchronousArray.swift
//  Client
//
//  Created by Mahmoud Adam on 11/9/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class SynchronousArray {
    var array: [AnyObject]
    var dispatchQueue: dispatch_queue_t
    
    var count: Int {
        get {
            return self.array.count;
        }
    }
    
    init(){
        array = [AnyObject]()
        dispatchQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    }
    
    internal func getContents() -> [AnyObject] {
        return self.array
    }
    
    internal func append(newElement: AnyObject){
        dispatch_sync(dispatchQueue) {
            self.array.append(newElement)
        }
    }
    
    internal func appendContentsOf(anotherArray: [AnyObject]) {
        dispatch_sync(dispatchQueue) {
            self.array.appendContentsOf(anotherArray)
        }
    }
    
    internal func removeAll(){
        dispatch_sync(dispatchQueue) {
            self.array.removeAll()
        }
    }
}
