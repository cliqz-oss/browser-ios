//
//  ProfileExtension.swift
//  Client
//
//  Created by Sahakyan on 3/31/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

private let TogglesPrefKey = "clearprivatedata.toggles"

public enum ClearHistoryType {
	case None, NotFavorites, All
}

extension Profile {
	
	private var toggles: [Bool] {
		get {
			if var savedToggles = self.prefs.arrayForKey(TogglesPrefKey) as? [Bool] {
				if savedToggles.count == 4 {
					savedToggles.insert(true, atIndex:1)
				}
				return savedToggles
			}
			return [true, true, true, true, true]
		}
	}

	func historyTypeShouldBeCleared() -> ClearHistoryType {
		if self.toggles[1] {
			return .All
		}
		if self.toggles[0] {
			return .NotFavorites
		}
		return .None
	}

	func clearPrivateData(tabManager: TabManager) {
		let clearables: [Clearable] = [
			HistoryClearable(profile: self),
			FavoriteHistoryClearable(profile: self),
			CacheClearable(tabManager: tabManager),
			CookiesClearable(tabManager: tabManager),
			SiteDataClearable(tabManager: tabManager),
		]
		
		for (i, c) in clearables.enumerate() {
			guard self.toggles[i] else {
				continue
			}
			c.clear()
		}
	}

}