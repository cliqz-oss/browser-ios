/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCGLogger
import UIKit
import Shared

private let log = XCGLogger.default

open class SuggestedSite: Site {
    open let wordmark: Favicon
    open let backgroundColor: UIColor

    override open var tileURL: URL {
        return URL(string: url) ?? URL(string: "about:blank")!
    }

    let trackingId: Int
    init(data: SuggestedSiteData) {
        self.backgroundColor = UIColor(colorString: data.bgColor)
        self.trackingId = data.trackingId
        self.wordmark = Favicon(url: data.imageUrl, date: Date(), type: .icon)
        super.init(url: data.url, title: data.title, bookmarked: nil)
        self.icon = Favicon(url: data.faviconUrl, date: Date(), type: .icon)
    }
}

public let SuggestedSites: SuggestedSitesCursor = SuggestedSitesCursor()

open class SuggestedSitesCursor: ArrayCursor<SuggestedSite> {
    fileprivate init() {
        let locale = Locale.current
        let sites = DefaultSuggestedSites.sites[locale.identifier] ??
                    DefaultSuggestedSites.sites["default"]! as Array<SuggestedSiteData>
        let tiles = sites.map({data in SuggestedSite(data: data)})
        super.init(data: tiles, status: .Success, statusMessage: "Loaded")
    }
}

public struct SuggestedSiteData {
    var url: String
    var bgColor: String
    var imageUrl: String
    var faviconUrl: String
    var trackingId: Int
    var title: String
}
