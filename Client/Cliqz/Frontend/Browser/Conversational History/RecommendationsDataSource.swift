//
//  RecommendationsDataSource.swift
//  Client
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

class RecommendationsDataSource: RecommendationsProtocol {
    
    func numberOfItems() -> Int {
        return 5
    }
    
    func cellType(indexPath: IndexPath) -> RecommendationsCellType {
        if indexPath.row % 2 == 0 {
            return .Recommendation
        }
        
        return .Reminder
    }
    
    func text(indexPath: IndexPath) -> String {
        return "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. "
    }
    
    func dateText(indexPath: IndexPath) -> String {
        return "20 Donnerstag"
    }
    
    func picture(indexPath: IndexPath) -> UIImage? {
        if indexPath.row % 2 == 0 {
            return UIImage(named:"conversationalBG")
        }
        return nil
    }
    
    func time(indexPath: IndexPath) -> String {
        if indexPath.row % 2 == 0 {
            return ""
        }
        
        return "12:30"
    }
}
