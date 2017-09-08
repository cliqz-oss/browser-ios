//
//  TabHistory.swift
//  Client
//
//  Created by Sahakyan on 9/7/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

enum TabNavigationState {
	case web(String)
	case home
	case search(String)
}

func ==(state1: TabNavigationState, state2: TabNavigationState) -> Bool {
	switch (state1, state2) {
	case let (.web(a),   .web(b)),
	     let (.search(a), .search(b)):
		return a == b
	case (.home, .home):
		return true
	default:
		return false
	}
}

class TabNavigationHistory {

	private var history = [TabNavigationState]()
	private var currentNavigationState: Int = -1

	func isEmpty() -> Bool {
		return history.isEmpty
	}

	func addState(state: TabNavigationState) {
		if self.currentNavigationState < self.history.count - 1 {
			self.history.removeLast(self.history.count - self.currentNavigationState - 1)
		}
		self.history.append(state)
		self.currentNavigationState += 1
	}

	func currentState() -> TabNavigationState {
		assert(self.currentNavigationState >= 0)
		return self.history[self.currentNavigationState]
	}

	func canGoBack() -> Bool {
		return self.currentNavigationState > 0
	}

	func canGoForward() -> Bool {
		return self.currentNavigationState < self.history.count - 1
	}

	func goBack() -> TabNavigationState {
		assert(self.currentNavigationState > 0)
		self.currentNavigationState -= 1
		return self.history[self.currentNavigationState]
	}

	func goForward() -> TabNavigationState {
		assert(self.currentNavigationState < self.history.count - 1)
		self.currentNavigationState += 1
		return self.history[self.currentNavigationState]
	}

}
