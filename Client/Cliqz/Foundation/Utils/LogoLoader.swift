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
import WebImage

class LogoLoader {
	static let logoVersionUpdatedDateKey: String = "logoVersionUpdatedDate"
	static let logoVersionKey: String = "logoVersion"
	
	static let topDomains = ["co": "cc", "uk": "cc", "ru": "cc", "gb": "cc", "de": "cc", "net": "na", "com": "na", "org": "na", "edu": "na", "gov": "na", "ac":"cc"]

	internal static func loadLogo(ofURL url: String, imageView: UIImageView, completed completionBlock: (String!) -> Void) {
		self.lastLogoVersion() { (version) in
			let hostComps = self.getHostComponents(forURL: url)
			var first = ""
			var second = ""
			if hostComps.count > 0 {
				first = hostComps[0]
			}
			if hostComps.count > 1 {
				second = hostComps[1]
				if !second.isEmpty {
					second += "."
				}
			}
			if version != nil {
				let mainURL = "http://cdn.cliqz.com/brands-database/database/\(version)/pngs"
				self.loadLogo(withURL: "\(mainURL)/\(first)/\(second)$_192.png", imageView: imageView, completed: { (image, error, imageType, url) in
					if error != nil && image == nil && !second.isEmpty {
						let secondAttempt = "\(mainURL)/\(first)/$_192.png"
						self.loadLogo(withURL: secondAttempt, imageView: imageView, completed: { (image, error, imageType, url) in
							if error != nil || image == nil {
								completionBlock(first)
							} else {
								completionBlock(nil)
							}
						})
					} else if image != nil {
						completionBlock(nil)
					} else {
						completionBlock(first)
					}
				})
			} else {
				completionBlock(first)
			}
		}
	}

	internal static func generateFakeLogo(forHost hostName: String) -> UIView {
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

	private static func loadLogo(withURL urlString: String, imageView: UIImageView, completed completionBlock:SDWebImageCompletionBlock!) {
		if let url = NSURL(string: urlString) {
			imageView.sd_setImageWithURL(url, completed: { (image, error, imageType, url) in
				completionBlock(image, error, imageType, url)
			})
		} else {
			completionBlock?(UIImage(), NSError(domain: "InvalidURL", code: 1, userInfo: nil), .None, NSURL())
		}
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
		var domainIndex = Int.max
		let excludablePrefixes: Set<String> = ["www", "m", "mobile"]
		if let url = NSURL(string: url),
			host = url.host {
			let comps = host.componentsSeparatedByString(".")
			domainIndex = comps.count - 1
			if let lastComp = comps.last,
				firstLevel = self.topDomains[lastComp] where firstLevel == "cc" && comps.count > 2 {
				if let _ = self.topDomains[comps[comps.count - 2]] {
					domainIndex = comps.count - 2
				}
			}
			let firstIndex = domainIndex - 1
			var secondIndex = -1
			if firstIndex > 0 {
				secondIndex = firstIndex - 1
			}
			if secondIndex >= 0 && excludablePrefixes.contains(comps[secondIndex]) {
				secondIndex = -1
			}
			if firstIndex > -1 {
				result.append(comps[firstIndex])
			}
			if secondIndex > -1 && secondIndex < domainIndex {
				result.append(comps[secondIndex])
			}
		}
		return result
	}

}

public typealias LogoLoaderCompletionBlock = (UIView?) -> Void

extension UIImageView {

	internal func loadLogo(ofURL url: String, completed completionBlock: LogoLoaderCompletionBlock) {
		LogoLoader.loadLogo(ofURL: url, imageView: self, completed: { (hostName) in
			if hostName != nil && !hostName.isEmpty {
				completionBlock(LogoLoader.generateFakeLogo(forHost: hostName))
			} else {
				completionBlock(nil)
			}
 		})
	}

}
