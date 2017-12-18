/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Shared
import Storage
import XCGLogger
import Deferred

private let log = Logger.browserLogger

class RecentlyClosedTabsPanel: UIViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var profile: Profile!

    fileprivate lazy var recentlyClosedHeader: UILabel = {
        let headerLabel = UILabel()
        headerLabel.text = Strings.RecentlyClosedTabsPanelTitle
        headerLabel.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        headerLabel.textAlignment = .center
        headerLabel.backgroundColor = .white
        return headerLabel
    }()

    fileprivate var tableViewController = RecentlyClosedTabsPanelSiteTableViewController()

    fileprivate lazy var historyBackButton: HistoryBackButton = {
        let button = HistoryBackButton()
        button.addTarget(self, action: #selector(RecentlyClosedTabsPanel.historyBackButtonWasTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        tableViewController.profile = self.profile
        tableViewController.homePanelDelegate = homePanelDelegate
        tableViewController.recentlyClosedTabsPanel = self

        self.addChildViewController(tableViewController)
        self.view.addSubview(tableViewController.view)
        self.view.addSubview(historyBackButton)
        self.view.addSubview(recentlyClosedHeader)

        historyBackButton.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(50)
            make.bottom.equalTo(recentlyClosedHeader.snp.top)
        }

        recentlyClosedHeader.snp.makeConstraints { make in
            make.top.equalTo(historyBackButton.snp.bottom)
            make.height.equalTo(20)
            make.bottom.equalTo(tableViewController.view.snp.top).offset(-10)
            make.left.right.equalTo(self.view)
        }

        tableViewController.view.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self.view)
        }

        tableViewController.didMove(toParentViewController: self)
    }

    @objc fileprivate func historyBackButtonWasTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        self.navigationController?.popViewController(animated: true)
    }
}

class RecentlyClosedTabsPanelSiteTableViewController: SiteTableViewController {
    weak var homePanelDelegate: HomePanelDelegate?
    var recentlyClosedTabs: [ClosedTab] = []
    weak var recentlyClosedTabsPanel: RecentlyClosedTabsPanel?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "Recently Closed Tabs List"
        self.recentlyClosedTabs = profile.recentlyClosedTabs.tabs
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let cell = cell as? TwoLineTableViewCell {
            cell.setLines(recentlyClosedTabs[indexPath.row].title ?? "", detailText: recentlyClosedTabs[indexPath.row].url.absoluteString)
            cell.imageView?.sd_setImage(with: (recentlyClosedTabs[indexPath.row].faviconURL ?? "").asURL) { (img, err, type, url) -> Void in
                guard img != nil else {
                    if let url = URL(string: self.recentlyClosedTabs[indexPath.row].faviconURL ?? "") {
                        cell.imageView?.setIcon(nil, withPlaceholder: FaviconFetcher.getDefaultFavicon(url))
                    }
                    return
                }
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        guard let homePanelDelegate = homePanelDelegate,
              let recentlyClosedTabsPanel = recentlyClosedTabsPanel else {
            log.warning("No site or no URL when selecting row.")
            return
        }
        let visitType = VisitType.Typed    // Means History, too.
        homePanelDelegate.homePanel(recentlyClosedTabsPanel, didSelectURL: recentlyClosedTabs[indexPath.row].url, visitType: visitType)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    // Functions that deal with showing header rows.
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profile.recentlyClosedTabs.tabs.count
    }

}
