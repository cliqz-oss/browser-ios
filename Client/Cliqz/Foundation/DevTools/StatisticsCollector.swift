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
    fileprivate init() {
        
    }

    //MARK: - Private Variables
    fileprivate let padingLength = 25
    fileprivate var eventStatistics = [(String, Int)]()
    fileprivate var eventStartTimes = [String :Double]()
    fileprivate var sumLatency = 0

    //MARK: - Public Variables
    var averageLatencyTime : Int {
        get{
            return sumLatency/eventStatistics.count
        }
    }
    
    //MARK: - Public Methods
    //MARK: Start/End Events
    func startEvent(_ eventName: String) {
        eventStartTimes[eventName] = Date.getCurrentMillis()
    }
    
    func endEvent(_ eventName: String) {
        let endTime = Date.getCurrentMillis()
        let startTime = eventStartTimes[eventName]!
        let latency = Int(endTime - startTime)
        sumLatency += latency
        eventStatistics.append((eventName, latency))
    }
    
    //MARK: Print/Clear Statistics
    func printStatistics() {
        // print header
        debugPrint("========== Statistics ========== ")
        let paddedHeader = "Query".padding(toLength: padingLength, withPad: " ", startingAt: 0)
        debugPrint("\(paddedHeader): latency")
        
        // debugPrint query/latency
        for (eventName, latency) in eventStatistics {
            let paddedEventName = eventName.padding(toLength: padingLength, withPad: " ", startingAt: 0)
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
