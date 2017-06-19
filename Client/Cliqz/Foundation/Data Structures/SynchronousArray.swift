//
//  SynchronousArray.swift
//  Client
//
//  Created by Mahmoud Adam on 11/9/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class SynchronousArray {
    var array = [Any]()
    let dispatchQueue = DispatchQueue(label: "com.cliqz.synchronous.array", attributes: []);

    
    var count: Int {
        get {
            return self.array.count;
        }
    }
    
    internal func getContents() -> [Any] {
		var result = [Any]()
		dispatchQueue.sync {
			result = [Any](self.array)
		}
		return result
    }
    
    internal func append(_ newElement: Any){
        dispatchQueue.async {
            self.array.append(newElement)
        }
    }
    
    internal func appendContentsOf(_ anotherArray: [Any]) {
        dispatchQueue.async {
            self.array.append(contentsOf: anotherArray)
        }
    }
    
    internal func removeAll(){
        dispatchQueue.async {
            self.array.removeAll()
        }
    }
}
