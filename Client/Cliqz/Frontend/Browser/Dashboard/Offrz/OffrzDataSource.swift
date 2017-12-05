//
//  OffrzDataSource.swift
//  Client
//
//  Created by Sahakyan on 12/5/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

class OffrzDataSource {
	
	private var currentOffr: Offrz?

	init() {
		OffrzDataService.shared.getMyOffrz { (offrz, error) in
			if error == nil && offrz.count > 0 {
				self.currentOffr = offrz.first
			}
		}
	}

	func getCurrentOffr() -> Offrz? {
		return self.currentOffr
	}

	func hasUnreadOffrz() -> Bool {
		// TODO: ....
		return true
	}
}
