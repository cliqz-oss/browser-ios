//
//  FavoritesViewController.swift
//  Client
//
//  Created by Sahakyan on 8/16/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation


class FavoritesViewController: HistoryViewController {
    override init(profile: Profile) {
        super.init(profile: profile)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func createDataSource(_ profile: Profile) -> HistoryDataSource {
        return FavoritesDataSource(profile: profile)
    }
}

