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
    
	let logoVersionUpdatedDateKey: String = "logoVersionUpdatedDate"
	let logoVersionKey: String = "logoVersion"
    let topDomains = ["co": "cc", "uk": "cc", "ru": "cc", "gb": "cc", "de": "cc", "net": "na", "com": "na", "org": "na", "edu": "na", "gov": "na", "ac":"cc"]
    
    
     func loadLogo(url: String, completionBlock:(image:UIImage?, error: NSError?) -> Void){
        self.constructImageURL(url) { (imageUrl) in
            
            guard (imageUrl != nil) else {completionBlock(image: nil, error: self.errorWithMessage("imageUrl is nil")); return}
            
            guard let url = NSURL(string: imageUrl!) else {completionBlock(image: nil, error: self.errorWithMessage("could not convert imageUrl to NSURL")); return}
            
            SDWebImageManager.sharedManager().downloadImageWithURL(url, options:SDWebImageOptions.HighPriority, progress:{ (receivedSize, expectedSize) in },
                completed: { (image , error , cacheType , finished, url) in
                    if error == nil && image != nil {completionBlock(image: image, error: nil)}
                    else {completionBlock(image:nil, error: self.errorWithMessage("image download failed"))}
            })
        }
    }

	func generateFakeLogo(url: String?) -> UIView? {
        guard (url != nil) else {return nil}
        let hostComps = self.getHostComponents(forURL: url!)
        guard hostComps.count > 0 else {return nil}
        let hostName = hostComps[0]
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
    
    
    func errorWithMessage(message:String!) -> NSError{
        return NSError(domain: "com.cliqz.LogoLoader", code: 501, userInfo: ["error":message])
    }
    
    
    func constructImageURL(url: String, completionBlock:(imageUrl: String?) -> Void) {
        lastLogoVersion() { (version) in
            if version == nil {completionBlock(imageUrl: nil); return}
            let hostComps = self.getHostComponents(forURL: url)
            if hostComps.count < 1 {completionBlock(imageUrl: nil); return}
            let mainURL = "http://cdn.cliqz.com/brands-database/database/\(version)/pngs"
            
            let first = hostComps[0]
            let second : String
            
            var imageURL = "\(mainURL)/\(first)/$_192.png"
            
            if hostComps.count > 1 {
                second = !hostComps[1].isEmpty ? hostComps[1] + "." : hostComps[1]
                imageURL = "\(mainURL)/\(first)/\(second)$_192.png"
            }
            
            completionBlock(imageUrl: imageURL)
        }
    }


    func isLogoVersionExpired() -> Bool {
		let date = LocalDataStore.objectForKey(logoVersionUpdatedDateKey)
		if date == nil { return true }
		if let d = date as? NSDate where NSDate().daysSinceDate(d) > 1 {
			return true
		}
		return false
	}

	func lastLogoVersion(completionBlock: (String!) -> Void) {
		if self.isLogoVersionExpired() {
			let logoVersionURL = "https://newbeta.cliqz.com/api/v1/config"
			if let url = NSURL(string: logoVersionURL) {
				Alamofire.request(.GET, url).responseJSON { response in
					if response.result.isSuccess,
						let data = response.result.value as? [String: AnyObject],
						let versionID = data["logoVersion"] as? String {
						LocalDataStore.setObject(versionID, forKey: self.logoVersionKey)
						LocalDataStore.setObject(NSDate(), forKey: self.logoVersionUpdatedDateKey)
						completionBlock(versionID)
					} else {
						completionBlock(nil)
					}
				}
			} else {
				completionBlock(nil)
			}
			return
		} else if let currentVersion = LocalDataStore.objectForKey(logoVersionKey) as? String {
			completionBlock(currentVersion)
		} else {
			completionBlock(nil)
		}
	}

    func getHostComponents(forURL url: String) -> [String] {
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



