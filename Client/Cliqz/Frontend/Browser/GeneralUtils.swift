//
//  GeneralUtils.swift
//  Client
//
//  Created by Tim Palade on 8/23/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class GeneralUtils {
    class func groupBy<A, B:Hashable>(array:[A], hashF:(A) -> B) -> Dictionary<B, [A]>{
        var dict: Dictionary<B, [A]> = [:]
        
        for elem in array {
            let key = hashF(elem)
            if var array = dict[key] {
                array.append(elem)
                dict[key] = array
            }
            else {
                dict[key] = [elem]
            }
        }
        
        return dict
    }
}
