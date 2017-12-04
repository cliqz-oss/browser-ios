//
//  FavoritesDataSource.swift
//  Client
//
//  Created by Mahmoud Adam on 10/23/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

let FavoriteRemovedNotification = NSNotification.Name(rawValue: "favorites-removed")

class FavoritesDataSource: HistoryDataSource {

    override func reloadHistory(completion: (() -> Void )?) {
        HistoryModule.getFavorites(profile: profile) { [weak self] (historyEntries, error) in
            if error == nil,
                let orderedEntries = self?.groupByDate(historyEntries) {
                self?.sortedDetails = orderedEntries
                completion?()
            }
        }
    }
    
    override func useLeftExpandedCell() -> Bool {
        return true
    }
    
    override func deleteItem(at indexPath: IndexPath, completion: (() -> Void )?) {
        if let favoritesEntry = detail(indexPath: indexPath) as? HistoryUrlEntry {
            HistoryModule.removeFavoritesEntry(profile: profile, url: favoritesEntry.url, callback: { [weak self] in
                NotificationCenter.default.post(name: FavoriteRemovedNotification, object: favoritesEntry.url)
                self?.reloadHistory(completion: {
                    DispatchQueue.main.async {
                        self?.delegate?.dataSourceWasUpdated()
                    }
                    completion?()
                })
                
            })
        }
    }
}
