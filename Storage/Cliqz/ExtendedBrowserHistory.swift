//
//  ExtendedBrowserHistory.swift
//  Client
//
//  Created by Mahmoud Adam on 11/18/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation
import Shared
import Deferred

public protocol ExtendedBrowserHistory {
    
    // Cliqz: added for telemetry signals
    func count() -> Int
    func getOldestVisitDate() -> NSDate? 

    // Cliqz: remove history
    func removeHistory(ids: [Int]) -> Success

    // Cliqz: getting History
    func getHistoryVisits(limit: Int) -> Deferred<Maybe<Cursor<Site>>>
}
