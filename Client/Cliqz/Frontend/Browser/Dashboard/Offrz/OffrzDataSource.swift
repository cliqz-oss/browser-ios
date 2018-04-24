//
//  OffrzDataSource.swift
//  Client
//
//  Created by Sahakyan on 12/5/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

class OffrzDataSource {
	
	private var currentOffr: Offr?
	private static let LastOffrID = "LastOffrID"
    private static let LastOffrSeenStatus = "LastOffrSeenStatus"
	private static let OffrzOnboardingKey = "OffrzOnboardingNeeded"

	var myOffrz = [Offr]()

	init() {
		self.updateMyOffrzList()
	}

	func getCurrentOffr() -> Offr? {
		if let o = self.currentOffr,
			self.isExpiredOffr(o) {
			self.currentOffr = nil
			// TODO: Impl notify on currentOffr change....
			self.updateMyOffrzList()
		}
		return self.currentOffr
	}

	func shouldShowOffrz() -> Bool {
		return SettingsPrefs.shared.getUserRegionPref() == "DE"
	}

	func hasUnseenOffrz() -> Bool {
		return !(self.currentOffr?.isSeen ?? true)
	}

	func markCurrentOffrSeen() {
		self.currentOffr?.isSeen = true
		LocalDataStore.setObject(true, forKey: OffrzDataSource.LastOffrSeenStatus)
	}

    func hasOffrz() -> Bool {
        return self.getCurrentOffr() != nil
    }

    func shouldShowOnBoarding() -> Bool {
		guard let _ = LocalDataStore.objectForKey(OffrzDataSource.OffrzOnboardingKey)
			else {
			return true
		}
        return false
    }

    func hideOnBoarding() {
		LocalDataStore.setObject("closed", forKey: OffrzDataSource.OffrzOnboardingKey)
    }

	private func updateMyOffrzList() {
		OffrzDataService.shared.getMyOffrz { (offrz, error) in
			if error == nil && offrz.count > 0 {
				self.myOffrz = offrz
				if let o = self.getLastOffr() {
					self.currentOffr = o
					self.currentOffr?.isSeen = LocalDataStore.objectForKey(OffrzDataSource.LastOffrSeenStatus) as? Bool ?? false
				} else {
					self.currentOffr = self.getNotExpiredOffr()
                    
                    LocalDataStore.setObject(self.currentOffr?.uid, forKey: OffrzDataSource.LastOffrID)
                    LocalDataStore.setObject(false, forKey: OffrzDataSource.LastOffrSeenStatus)
                    self.sendNewOfferTelemetrySignal()
                    
				}
			}
		}
	}

	private func getNotExpiredOffr() -> Offr? {
		for o in self.myOffrz {
			if !self.isExpiredOffr(o) {
				return o
			}
		}
		return nil
	}
    
	private func getLastOffr() -> Offr? {
		let offrID = self.getLastOffrID()
		for o in self.myOffrz {
			if o.uid == offrID {
				if !self.isExpiredOffr(o) {
					return o
				}
			}
		}
		return nil
    }

	private func getLastOffrID() -> String? {
		return LocalDataStore.objectForKey(OffrzDataSource.LastOffrID) as? String
	}

	private func isExpiredOffr(_ offr: Offr) -> Bool {
		let now =  Date()
		if let start = offr.startDate,
			let end = offr.endDate {
			return start > now || end < now
		}
		return false
	}
    
    private func sendNewOfferTelemetrySignal() {
        TelemetryLogger.sharedInstance.logEvent(.MyOffrz("new", ["count" : "1"]))
    }
}
