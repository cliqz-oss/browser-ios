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
    
    
    class func loadLogoImageOrFakeLogo(url:String, completed:(image: UIImage?, fakeLogo:UIView?, error: NSError?) -> Void){
        LogoLoader.loadLogo(url) { (image, error) in
            if let img = image {
                completed(image: img, fakeLogo: nil, error: error)
            }
            else{
                completed(image: nil, fakeLogo: LogoLoader.generateFakeLogo(url), error: error)
            }
        }
    }
    
    
     class func loadLogo(url: String, completionBlock:(image:UIImage?, error: NSError?) -> Void){
        LogoLoader.constructImageURL(url) { (imageUrl, hasSecond, urlWithoutSecond) in
            
            guard (imageUrl != nil) else {completionBlock(image: nil, error: LogoLoader.errorWithMessage("imageUrl is nil")); return}
            
            guard let url = NSURL(string: imageUrl!) else {completionBlock(image: nil, error: LogoLoader.errorWithMessage("could not convert imageUrl to NSURL")); return}
            
            LogoLoader.downloadImage(url, completed: { (image, error) in
                if error == nil && image != nil {completionBlock(image: image, error: nil)}
                else
                {
                    if hasSecond == true {
                        if let urlString = urlWithoutSecond, let url = NSURL(string: urlString){
                            LogoLoader.downloadImage(url, completed: { (image, error) in
                                if error == nil && image != nil {completionBlock(image: image, error: nil)}
                                else{
                                    completionBlock(image:nil, error: LogoLoader.errorWithMessage("image download failed - \(url)"))
                                }
                            })
                        }
                        else{
                            completionBlock(image: nil, error: LogoLoader.errorWithMessage("could not convert imageUrl to NSURL - urlWithoutFirst"))
                        }
                    }
                    else{
                       completionBlock(image:nil, error: LogoLoader.errorWithMessage("image download failed - \(url)"))
                    }
                }
            })
        }
    }
    
    class func downloadImage(url:NSURL, completed:(image:UIImage?, error: NSError?) -> Void){
        SDWebImageManager.sharedManager().downloadImageWithURL(url, options:SDWebImageOptions.HighPriority, progress:{ (receivedSize, expectedSize) in },
                                                               completed: { (image , error , cacheType , finished, url) in  completed(image:image, error:error)})
    }

	class func generateFakeLogo(url: String?) -> UIView? {
        guard (url != nil) else {return nil}
        let hostComps = LogoLoader.getHostComponents(forURL: url!)
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
    
    
    class func errorWithMessage(message:String!) -> NSError{
        return NSError(domain: "com.cliqz.LogoLoader", code: 501, userInfo: ["error":message])
    }
    
    
    class func constructImageURL(url: String, completionBlock:(imageUrl: String?, hasSecond: Bool?, urlWithoutSecond: String?) -> Void) {
        LogoLoader.lastLogoVersion() { (version) in
            if version == nil {completionBlock(imageUrl: nil, hasSecond: nil, urlWithoutSecond: nil); return}
            let hostComps = LogoLoader.getHostComponents(forURL: url)
            if hostComps.count < 1 {completionBlock(imageUrl: nil, hasSecond: nil, urlWithoutSecond: nil); return}
            let mainURL = "http://cdn.cliqz.com/brands-database/database/\(version)/pngs"
            
            var hasSecond = false
            
            let first = hostComps[0]
            let second : String
            
            var imageURL = "\(mainURL)/\(first)/$_192.png"
            
            if hostComps.count > 1 {
                hasSecond = true
                second = !hostComps[1].isEmpty ? hostComps[1] + "." : hostComps[1]
                imageURL = "\(mainURL)/\(first)/\(second)$_192.png"
            }
            
            completionBlock(imageUrl: imageURL, hasSecond: hasSecond, urlWithoutSecond:"\(mainURL)/\(first)/$_192.png")
        }
    }


    class func isLogoVersionExpired() -> Bool {
		let date = LocalDataStore.objectForKey(logoVersionUpdatedDateKey)
		if date == nil { return true }
		if let d = date as? NSDate where NSDate().daysSinceDate(d) > 1 {
			return true
		}
		return false
	}

	class func lastLogoVersion(completionBlock: (String!) -> Void) {
		if LogoLoader.isLogoVersionExpired() {
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
		} else if let currentVersion = LocalDataStore.objectForKey(logoVersionKey) as? String {
			completionBlock(currentVersion)
		} else {
			completionBlock(nil)
		}
	}

    class func getHostComponents(forURL url: String) -> [String] {
		var result = [String]()
		var domainIndex = Int.max
		let excludablePrefixes: Set<String> = ["www", "m", "mobile"]
		if let url = NSURL(string: url),
			host = url.host {
			let comps = host.componentsSeparatedByString(".")
			domainIndex = comps.count - 1
			if let lastComp = comps.last,
				firstLevel = LogoLoader.topDomains[lastComp] where firstLevel == "cc" && comps.count > 2 {
				if let _ = LogoLoader.topDomains[comps[comps.count - 2]] {
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

extension UICollectionViewCell{
    func loadLogo(url: String, completed:(image: UIImage?, fakeLogo:UIView?, error: NSError?) -> Void){
        LogoLoader.loadLogoImageOrFakeLogo(url) { (image, fakeLogo, error) in
            completed(image: image, fakeLogo: fakeLogo, error: error)
        }
    }
}

extension UITableViewCell{
    func loadLogo(url: String, completed:(image: UIImage?, fakeLogo:UIView?, error: NSError?) -> Void){
        LogoLoader.loadLogoImageOrFakeLogo(url) { (image, fakeLogo, error) in
            completed(image: image, fakeLogo: fakeLogo, error: error)
        }
    }
}




