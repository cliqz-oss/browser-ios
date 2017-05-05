//
//  StatisticsCollector.swift
//  Client
//
//  Created by Mahmoud Adam on 10/27/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class StatisticsCollector {

    //MARK: - Singltone
    static let sharedInstance = StatisticsCollector()
    private init() {
        
    }

    //MARK: - Private Variables
    private let padingLength = 25
    private var eventStatistics = [(String, Int)]()
    private var eventStartTimes = [String :Double]()
    private var sumLatency = 0

    //MARK: - Public Variables
    var averageLatencyTime : Int {
        get{
            return sumLatency/eventStatistics.count
        }
    }
    
    //MARK: - Public Methods
    //MARK: Start/End Events
    func startEvent(eventName: String) {
        eventStartTimes[eventName] = NSDate.getCurrentMillis()
    }
    
    func endEvent(eventName: String) {
        let endTime = NSDate.getCurrentMillis()
        let startTime = eventStartTimes[eventName]!
        let latency = Int(endTime - startTime)
        sumLatency += latency
        eventStatistics.append((eventName, latency))
    }
    
    //MARK: Print/Clear Statistics
    func debugPrintStatistics() {
        // debugPrint header
        debugPrint("========== Statistics ========== ")
        let paddedHeader = "Query".stringByPaddingToLength(padingLength, withString: " ", startingAtIndex: 0)
        debugPrint("\(paddedHeader): latency")
        
        // debugPrint query/latency
        for (eventName, latency) in eventStatistics {
            let paddedEventName = eventName.stringByPaddingToLength(padingLength, withString: " ", startingAtIndex: 0)
            debugPrint("\(paddedEventName): \(latency)")
        }
        
        //debugPrint extra information
        debugPrint("Average latency time : \(self.averageLatencyTime)")
    }
    
    func clearStatistics() {
        eventStatistics.removeAll()
        eventStartTimes.removeAll()
    }
}
