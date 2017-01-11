//
//  LogoLoader.swift
//  Client
//
//  Created by Sahakyan on 1/2/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import Alamofire
import SnapKit

class LogoLoader {
	static let logoVersionUpdatedDateKey: String = "logoVersionUpdatedDate"
	static let logoVersionKey: String = "logoVersion"
	
	static let topDomains = ["co": "cc", "uk": "cc", "ru": "cc", "gb": "cc", "de": "cc", "net": "na", "com": "na", "org": "na", "edu": "na", "gov": "na", "ac":"cc"]

	internal static func getLogoURL(forDomain domainURL: String, completed completionBlock: (String!, String) -> Void) {
		self.lastLogoVersion() { (version) in
			let hostComps = self.getHostComponents(forURL: domainURL)
			var first = ""
			var second = ""
			if hostComps.count > 0 {
				first = hostComps[0]
			}
			if hostComps.count > 1 {
				second = hostComps[1]
			}
			if version != nil {
				let url = "http://cdn.cliqz.com/brands-database/database/\(version)/pngs"
				completionBlock("\(url)/\(first)/\(second)$_72.png", first)
			} else {
				completionBlock(nil, first)
			}
		}
	}

	internal static func generateCustomLogo(forHost hostName: String) -> UIView {
		let v = UIView()
		v.backgroundColor = UIColor.blackColor()
		let l = UILabel()
		l.textColor = UIColor.whiteColor()
		if hostName.characters.count > 1 {
			l.text = hostName.substringToIndex(hostName.startIndex.advancedBy(2)).capitalizedString
		} else if hostName.characters.count > 0 {
			l.text = hostName.substringToIndex(hostName.startIndex.advancedBy(1)).capitalizedString
		} else {
			l.text = "N/A"
		}
		v.addSubview(l)
		l.snp_makeConstraints(closure: { (make) in
			make.center.equalTo(v)
		})
		return v
	}

	private static func isLogoVersionExpired() -> Bool {
		let date = LocalDataStore.objectForKey(LogoLoader.logoVersionUpdatedDateKey)
		if date == nil { return true }
		if let d = date as? NSDate where NSDate().daysSinceDate(d) > 1 {
			return true
		}
		return false
	}

	private static func lastLogoVersion(completionBlock: (String!) -> Void) {
		if isLogoVersionExpired() {
			let logoVersionURL = "https://newbeta.cliqz.com/api/v1/config"
			if let url = NSURL(string: logoVersionURL) {
				Alamofire.request(.GET, url).responseJSON { response in
					if response.result.isSuccess,
						let data = response.result.value as? [String: AnyObject],
						let versionID = data["logoVersion"] as? String {
						LocalDataStore.setObject(versionID, forKey: LogoLoader.logoVersionKey)
						LocalDataStore.setObject(NSDate(), forKey: LogoLoader.logoVersionUpdatedDateKey)
						completionBlock(versionID)
					} else {
						completionBlock(nil)
					}
				}
			} else {
				completionBlock(nil)
			}
			return
		} else if let currentVersion = LocalDataStore.objectForKey(LogoLoader.logoVersionKey) as? String {
			completionBlock(currentVersion)
		} else {
			completionBlock(nil)
		}
	}

	private static func getHostComponents(forURL url: String) -> [String] {
		var result = [String]()
		var secondIndexLimit = Int.max
		if let url = NSURL(string: url),
			host = url.host {
			let comps = host.componentsSeparatedByString(".")
			if let lastComp = comps.last {
				if let firstLevel = self.topDomains[lastComp] where firstLevel == "cc" && comps.count > 2 {
					if let _ = self.topDomains[comps[comps.count - 2]] {
						secondIndexLimit = comps.count - 2
					}
				}
			}
			var firstIndex = -1
			var secondIndex = -1
			if comps.count >= 2 {
				if comps[0] == "www" {
					if comps[1] == "m" {
						if comps.count > 2 {
							firstIndex = 2
						}
						if comps.count >= 5 {
							secondIndex = 3
						}
					} else {
						firstIndex = 1
						if comps.count >= 4 {
							secondIndex = 2
						}
					}
				} else {
					if comps[0] == "m" {
						firstIndex = 1
						if comps.count > 3 {
							secondIndex = 2
						}
					} else {
						firstIndex = 0
						if comps.count > 2 {
							secondIndex = 1
						}
					}
				}
			}
			if firstIndex > -1 {
				result.append(comps[firstIndex])
			}
			if secondIndex > -1 && secondIndex < secondIndexLimit {
				result.append(comps[secondIndex])
			}
		}
		return result
	}

}

public typealias LogoCompletionBlock = (UIView?) -> Void

extension UIImageView {

	internal func loadLogo(forDomain domainURL: String, completed completionBlock: LogoCompletionBlock) {
		LogoLoader.getLogoURL(forDomain: domainURL, completed: { (urlString, hostName) in
			if let u = urlString,
				url = NSURL(string: u) {
				self.sd_setImageWithURL(url, completed: { (image, error, imageType, url) in
					if error != nil {
						completionBlock(LogoLoader.generateCustomLogo(forHost: hostName))
					} else {
						completionBlock(nil)
					}
				})
			} else {
				completionBlock(LogoLoader.generateCustomLogo(forHost: hostName))
			}
 		})
	}

}
