/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

struct SiteTableViewControllerUX {
    static let HeaderHeight = CGFloat(25)
    static let RowHeight = CGFloat(58)
    static let HeaderBorderColor = UIColor(rgb: 0xCFD5D9).colorWithAlphaComponent(0.8)
    static let HeaderTextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x232323)
    static let HeaderBackgroundColor = UIColor(rgb: 0xECF0F3).colorWithAlphaComponent(0.3)
    static let HeaderFont = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
    static let HeaderTextMargin = CGFloat(10)
}

class SiteTableViewHeader : UITableViewHeaderFooterView {
    // I can't get drawRect to play nicely with the glass background. As a fallback
    // we just use views for the top and bottom borders.
    let topBorder = UIView()
    let bottomBorder = UIView()
    let titleLabel = UILabel()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        topBorder.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        bottomBorder.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor

        titleLabel.font = SiteTableViewControllerUX.HeaderFont
        titleLabel.textColor = SiteTableViewControllerUX.HeaderTextColor
        titleLabel.textAlignment = .Left
        contentView.backgroundColor = SiteTableViewControllerUX.HeaderBackgroundColor

        addSubview(topBorder)
        addSubview(bottomBorder)
        contentView.addSubview(titleLabel)

        topBorder.snp_makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }

        // A table view will initialize the header with CGSizeZero before applying the actual size. Hence, the label's constraints
        // must not impose a minimum width on the content view.
        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(contentView).offset(SiteTableViewControllerUX.HeaderTextMargin).priorityHigh()
            make.right.equalTo(contentView).offset(-SiteTableViewControllerUX.HeaderTextMargin).priorityHigh()
            make.left.greaterThanOrEqualTo(contentView) // Fallback for when the left space constraint breaks
            make.right.lessThanOrEqualTo(contentView) // Fallback for when the right space constraint breaks
            make.centerY.equalTo(contentView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 * Provides base shared functionality for site rows and headers.
 */
class SiteTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let CellIdentifier = "CellIdentifier"
    private let HeaderIdentifier = "HeaderIdentifier"
    var profile: Profile! {
        didSet {
            reloadData()
        }
    }
    var data: Cursor<Site> = Cursor<Site>(status: .Success, msg: "No data set")
    var tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(TwoLineTableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.registerClass(SiteTableViewHeader.self, forHeaderFooterViewReuseIdentifier: HeaderIdentifier)
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.accessibilityIdentifier = "SiteTable"

        if #available(iOS 9, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    func reloadData() {
        if data.status != .Success {
            print("Err: \(data.statusMessage)", terminator: "\n")
        } else {
            self.tableView.reloadData()
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath)
        if self.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        return cell
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier(HeaderIdentifier)
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SiteTableViewControllerUX.HeaderHeight
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return SiteTableViewControllerUX.RowHeight
    }

    func tableView(tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}
