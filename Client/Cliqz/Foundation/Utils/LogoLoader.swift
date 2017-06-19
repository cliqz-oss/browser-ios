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
    
    
    class func loadLogoImageOrFakeLogo(_ url:String, completed:@escaping (_ image: UIImage?, _ fakeLogo:UIView?, _ error: Error?) -> Void) {
        LogoLoader.loadLogo(url) { (image, error) in
            if let img = image {
                completed(img, nil, error)
            }
            else{
                completed(nil, LogoLoader.generateFakeLogo(url: url, fontSize: 16), error)
            }
        }
    }
    
    
     class func loadLogo(_ url: String, completionBlock:@escaping (_ image:UIImage?, _ error: Error?) -> Void){
        LogoLoader.constructImageURL(url) { (imageUrl, hasSecond, urlWithoutSecond) in
            
            guard let imageUrl = imageUrl else { completionBlock(nil, LogoLoader.errorWithMessage("imageUrl is nil")); return
			}
            
            guard let url = URL(string: imageUrl) else { completionBlock(nil, LogoLoader.errorWithMessage("could not convert imageUrl to NSURL")); return
			}
            
            LogoLoader.downloadImage(url, completed: { (image, error) in
                if error == nil && image != nil {completionBlock(image, nil)}
                else
                {
                    if hasSecond == true {
                        if let urlString = urlWithoutSecond, let url = URL(string: urlString){
                            LogoLoader.downloadImage(url, completed: { (image, error) in
                                if error == nil && image != nil {completionBlock(image, nil)}
                                else{
                                    completionBlock(nil, LogoLoader.errorWithMessage("image download failed - \(url)"))
                                }
                            })
                        }
                        else{
                            completionBlock(nil, LogoLoader.errorWithMessage("could not convert imageUrl to NSURL - urlWithoutFirst"))
                        }
                    }
                    else{
                       completionBlock(nil, LogoLoader.errorWithMessage("image download failed - \(url)"))
                    }
                }
            })
        }
    }
    
    class func downloadImage(_ url:URL, completed:@escaping (_ image: UIImage?, _ error:  Error?) -> Void) {
        SDWebImageManager.shared().downloadImage(with: url, options:SDWebImageOptions.highPriority, progress: { (receivedSize, expectedSize) in },
                                                 completed: { (image, error, _, _, _) in completed(image, error)} as SDWebImageCompletionWithFinishedBlock)
    }

    class func generateFakeLogo(url: String?, fontSize: Int) -> UIView? {
        guard (url != nil) else {return nil}
        let hostComps = getHostComponents(forURL: url!)
        guard hostComps.count > 0 else {return nil}
        let hostName = hostComps[0]
		let v = UIView()
		v.backgroundColor = UIColor.black
		let l = UILabel()
		l.textColor = UIColor.white
		if hostName.characters.count > 1 {
			l.text = hostName.substring(to: hostName.characters.index(hostName.startIndex, offsetBy: 2)).capitalized
		} else if hostName.characters.count > 0 {
			l.text = hostName.substring(to: hostName.characters.index(hostName.startIndex, offsetBy: 1)).capitalized
		} else {
			l.text = "N/A"
		}
        l.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
		v.addSubview(l)
		l.snp_makeConstraints({ (make) in
			make.center.equalTo(v)
		})
		return v
	}
    
    
    class func errorWithMessage(_ message:String!) -> NSError{
        return NSError(domain: "com.cliqz.LogoLoader", code: 501, userInfo: ["error":message])
    }
    
    
    class func constructImageURL(_ url: String, completionBlock:@escaping (_ imageUrl: String?, _ hasSecond: Bool?, _ urlWithoutSecond: String?) -> Void) {
        LogoLoader.lastLogoVersion() { (version) in
            guard let version = version else {
				completionBlock(nil, nil, nil)
				return
			}
            let hostComps = getHostComponents(forURL: url)
            guard hostComps.count > 0 else {
				completionBlock(nil, nil, nil)
				return
			}
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
            
            completionBlock(imageURL, hasSecond, "\(mainURL)/\(first)/$_192.png")
        }
    }


    class func isLogoVersionExpired() -> Bool {
		let date = LocalDataStore.objectForKey(logoVersionUpdatedDateKey)
		if date == nil { return true }
		if let d = date as? Date, Date().daysSinceDate(d) > 1 {
			return true
		}
		return false
	}

	class func lastLogoVersion(_ completionBlock: @escaping (String?) -> Void) {
		if LogoLoader.isLogoVersionExpired() {
			let logoVersionURL = "https://newbeta.cliqz.com/api/v1/config"
			if let url = URL(string: logoVersionURL) {
				Alamofire.request(url, method: .get).responseJSON { response in
					if response.result.isSuccess,
						let data = response.result.value as? [String: AnyObject],
						let versionID = data["png_logoVersion"] as? String {
						LocalDataStore.setObject(versionID, forKey: LogoLoader.logoVersionKey)
						LocalDataStore.setObject(Date(), forKey: LogoLoader.logoVersionUpdatedDateKey)
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


}

