/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class FindInPageActivity: UIActivity {
    fileprivate let callback: () -> ()

    init(callback: @escaping () -> ()) {
        self.callback = callback
    }

    override var activityTitle : String? {
        return NSLocalizedString("Find in Page", tableName: "FindInPage", comment: "Share action title")
    }

    override var activityImage : UIImage? {
        return UIImage(named: "shareFindInPage")
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType("com.cliqz.findinpage")
    }
    
    override func perform() {
        callback()
        activityDidFinish(true)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
}
