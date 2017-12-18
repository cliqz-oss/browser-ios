/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Shared
import Alamofire
import XCGLogger
import Deferred
import WebImage


private let log = Logger.browserLogger
private let queue = DispatchQueue(label: "FaviconFetcher", attributes: DispatchQueue.Attributes.concurrent)

class FaviconFetcherErrorType: MaybeErrorType {
    let description: String
    init(description: String) {
        self.description = description
    }
}

/* A helper class to find the favicon associated with a URL.
 * This will load the page and parse any icons it finds out of it.
 * If that fails, it will attempt to find a favicon.ico in the root host domain.
 */
open class FaviconFetcher : NSObject, XMLParserDelegate {
    open static var userAgent: String = ""
    static let ExpirationTime = TimeInterval(60*60*24*7) // Only check for icons once a week
    fileprivate static var characterToFaviconCache = [String : UIImage]()
    static var defaultFavicon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    class func getForURL(_ url: URL, profile: Profile) -> Deferred<Maybe<[Favicon]>> {
        let f = FaviconFetcher()
        return f.loadFavicons(url, profile: profile)
    }

    fileprivate func loadFavicons(_ url: URL, profile: Profile, oldIcons: [Favicon] = [Favicon]()) -> Deferred<Maybe<[Favicon]>> {
        if isIgnoredURL(url) {
            return deferMaybe(FaviconFetcherErrorType(description: "Not fetching ignored URL to find favicons."))
        }

        let deferred = Deferred<Maybe<[Favicon]>>()
        
        var oldIcons: [Favicon] = oldIcons

        queue.async { _ in
            self.parseHTMLForFavicons(url).bind({ (result: Maybe<[Favicon]>) -> Deferred<[Maybe<Favicon>]> in
                var deferreds = [Deferred<Maybe<Favicon>>]()
                if let icons = result.successValue {
                    deferreds = icons.map { self.getFavicon(url, icon: $0, profile: profile) }
                }
                return all(deferreds)
            }).bind({ (results: [Maybe<Favicon>]) -> Deferred<Maybe<[Favicon]>> in
                for result in results {
                    if let icon = result.successValue {
                        oldIcons.append(icon)
                    }
                }

                oldIcons = oldIcons.sorted {
                    return $0.width! > $1.width!
                }

                return deferMaybe(oldIcons)
            }).upon({ (result: Maybe<[Favicon]>) in
                deferred.fill(result)
                return
            })
        }

        return deferred
    }

	lazy fileprivate var alamofire: SessionManager = {
		let configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForRequest = 5
		
		return SessionManager.managerWithUserAgent(userAgent, configuration: configuration)
	}()

    fileprivate func fetchDataForURL(_ url: URL) -> Deferred<Maybe<Data>> {
        let deferred = Deferred<Maybe<Data>>()
		alamofire.request(url).response { response in
            // Don't cancel requests just because our Manager is deallocated.
            withExtendedLifetime(self.alamofire) {
                if response.error == nil {
                    if let data = response.data {
                        deferred.fill(Maybe(success: data))
                        return
                    }
                }
                let errorDescription = response.error?.localizedDescription ?? "No content."
                deferred.fill(Maybe(failure: FaviconFetcherErrorType(description: errorDescription)))
            }
        }
        return deferred
    }

    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    fileprivate func parseHTMLForFavicons(_ url: URL) -> Deferred<Maybe<[Favicon]>> {
        return fetchDataForURL(url).bind({ result -> Deferred<Maybe<[Favicon]>> in
            var icons = [Favicon]()

            if let data = result.successValue, result.isSuccess,
               let element = RXMLElement(fromHTMLData: data as Data!), element.isValid {
                var reloadUrl: URL? = nil
                element.iterate("head.meta") { meta in
                    if let refresh = meta?.attribute("http-equiv"), refresh == "Refresh",
                        let content = meta?.attribute("content"),
                        let index = content.range(of: "URL="),
						let url = URL(string: content.substring(from: index.upperBound)) {
                            reloadUrl = url
                    }
                }

                if let url = reloadUrl {
                    return self.parseHTMLForFavicons(url)
                }

                var bestType = IconType.noneFound
                element.iterate(withRootXPath: "//head//link[contains(@rel, 'icon')]") { link in
                    var iconType: IconType? = nil
                    if let rel = link?.attribute("rel") {
                        switch (rel) {
                            case "shortcut icon":
                                iconType = .icon
                            case "icon":
                                iconType = .icon
                            case "apple-touch-icon":
                                iconType = .appleIcon
                            case "apple-touch-icon-precomposed":
                                iconType = .appleIconPrecomposed
                            default:
                                iconType = nil
                        }
                    }

                    guard let href = link?.attribute("href"), iconType != nil else {
                        return
                    }

                    if (href.endsWith(".ico")) {
                        iconType = .guess
                    }

                    if let type = iconType, !bestType.isPreferredTo(type),
                        let iconUrl = NSURL(string: href, relativeTo: url) {
                            let icon = Favicon(url: iconUrl.absoluteString!, date: Date(), type: type)
                            // If we already have a list of Favicons going already, then add it…
                            if (type == bestType) {
                                icons.append(icon)
                            } else {
                                // otherwise, this is the first in a new best yet type.
                                icons = [icon]
                                bestType = type
                            }
                    }
                }

                // If we haven't got any options icons, then use the default at the root of the domain.
				if let url = NSURL(string: "/favicon.ico", relativeTo: url as URL), icons.isEmpty, let absoluteString = url.absoluteString {
                    let icon = Favicon(url: absoluteString, date: Date() as Date, type: .guess)
                    icons = [icon]
                }
            }
            return deferMaybe(icons)
        })
    }

    func getFavicon(_ siteUrl: URL, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let url = icon.url
        let manager = SDWebImageManager.shared()
        let site = Site(url: siteUrl.absoluteString, title: "")

        var fav = Favicon(url: url, type: icon.type)
        if let url = url.asURL {
            manager?.downloadImage(with: url,
                options: SDWebImageOptions.lowPriority,
                progress: nil,
                completed: { (img, err, cacheType, success, url) -> Void in
                fav = Favicon(url: url!.absoluteString,
                    type: icon.type)

                if let img = img {
                    fav.width = Int(img.size.width)
                    fav.height = Int(img.size.height)
                    //profile.favicons.addFavicon(fav, forSite: site)
                } else {
                    fav.width = 0
                    fav.height = 0
                }

                deferred.fill(Maybe(success: fav))
            })
        } else {
            return deferMaybe(FaviconFetcherErrorType(description: "Invalid URL \(url)"))
        }

        return deferred
    }

    // Returns the default favicon for a site based on the first letter of the site's domain
    class func getDefaultFavicon(_ url: URL) -> UIImage {
        guard let character = url.baseDomain()?.characters.first else {
            return defaultFavicon
        }

        let faviconLetter = String(character).uppercased()

        if let cachedFavicon = characterToFaviconCache[faviconLetter] {
            return cachedFavicon
        }

        var faviconImage = UIImage()
        let faviconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: TwoLineCellUX.ImageSize, height: TwoLineCellUX.ImageSize))
        faviconLabel.text = faviconLetter
        faviconLabel.textAlignment = .center
        faviconLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
        faviconLabel.textColor = UIColor.gray
        UIGraphicsBeginImageContextWithOptions(faviconLabel.bounds.size, false, 0.0)
        faviconLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        faviconImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        characterToFaviconCache[faviconLetter] = faviconImage
        return faviconImage
    }
}

