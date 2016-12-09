/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

let BookmarkStatusChangedNotification = "BookmarkStatusChangedNotification"

// MARK: - Placeholder strings for Bug 1232810.

let deleteWarningTitle = NSLocalizedString("This folder isn't empty.", tableName: "BookmarkPanelDeleteConfirm", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
let deleteWarningDescription = NSLocalizedString("Are you sure you want to delete it and its contents?", tableName: "BookmarkPanelDeleteConfirm", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
let deleteCancelButtonLabel = NSLocalizedString("Cancel", tableName: "BookmarkPanelDeleteConfirm", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.")
let deleteDeleteButtonLabel = NSLocalizedString("Delete", tableName: "BookmarkPanelDeleteConfirm", comment: "Button label for the button that deletes a folder and all of its children.")

// Placeholder strings for Bug 1248034
let emptyBookmarksText = NSLocalizedString("Bookmarks you save will show up here.", comment: "Status label for the empty Bookmarks state.")

// MARK: - UX constants.

struct BookmarksPanelUX {
    private static let BookmarkFolderHeaderViewChevronInset: CGFloat = 10
    private static let BookmarkFolderChevronSize: CGFloat = 20
    private static let BookmarkFolderChevronLineWidth: CGFloat = 4.0
    private static let BookmarkFolderTextColor = UIColor(red: 92/255, green: 92/255, blue: 92/255, alpha: 1.0)
    private static let WelcomeScreenPadding: CGFloat = 15
    private static let WelcomeScreenItemTextColor = UIColor.grayColor()
    private static let WelcomeScreenItemWidth = 170
    private static let SeparatorRowHeight: CGFloat = 0.5
}

class BookmarksPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var source: BookmarksModel?
    var parentFolders = [BookmarkFolder]()
    var bookmarkFolder: BookmarkFolder?
    private lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverlayView()

    private let BookmarkFolderCellIdentifier = "BookmarkFolderIdentifier"
    private let BookmarkSeparatorCellIdentifier = "BookmarkSeparatorIdentifier"
    private let BookmarkFolderHeaderViewIdentifier = "BookmarkFolderHeaderIdentifier"

    init() {
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BookmarksPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)

        self.tableView.registerClass(SeparatorTableCell.self, forCellReuseIdentifier: BookmarkSeparatorCellIdentifier)
        self.tableView.registerClass(BookmarkFolderTableViewCell.self, forCellReuseIdentifier: BookmarkFolderCellIdentifier)
        self.tableView.registerClass(BookmarkFolderTableViewHeader.self, forHeaderFooterViewReuseIdentifier: BookmarkFolderHeaderViewIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // If we've not already set a source for this panel, fetch a new model from
        // the root; otherwise, just use the existing source to select a folder.
        guard let source = self.source else {
            // Get all the bookmarks split by folders
            if let bookmarkFolder = bookmarkFolder {
                profile.bookmarks.modelFactory >>== { $0.modelForFolder(bookmarkFolder).upon(self.onModelFetched) }
            } else {
                profile.bookmarks.modelFactory >>== { $0.modelForRoot().upon(self.onModelFetched) }
            }
            return
        }

        if let bookmarkFolder = bookmarkFolder {
            source.selectFolder(bookmarkFolder).upon(onModelFetched)
        } else {
            source.selectFolder(BookmarkRoots.MobileFolderGUID).upon(onModelFetched)
        }
        self.tableView.accessibilityIdentifier = "Bookmarks List"
    }

    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged:
            self.reloadData()
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    private func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.whiteColor()

        let logoImageView = UIImageView(image: UIImage(named: "emptyBookmarks"))
        overlayView.addSubview(logoImageView)
        logoImageView.snp_makeConstraints { make in
            make.centerX.equalTo(overlayView)

            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(overlayView).offset(HomePanelUX.EmptyTabContentOffset).priorityMedium()

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView).offset(50)
        }

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = emptyBookmarksText
        welcomeLabel.textAlignment = NSTextAlignment.Center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        welcomeLabel.textColor = BookmarksPanelUX.WelcomeScreenItemTextColor
        welcomeLabel.numberOfLines = 0
        welcomeLabel.adjustsFontSizeToFitWidth = true

        welcomeLabel.snp_makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.top.equalTo(logoImageView.snp_bottom).offset(BookmarksPanelUX.WelcomeScreenPadding)
            make.width.equalTo(BookmarksPanelUX.WelcomeScreenItemWidth)
        }
        
        return overlayView
    }

    private func updateEmptyPanelState() {
        if source?.current.count == 0 && source?.current.guid == BookmarkRoots.MobileFolderGUID {
            if self.emptyStateOverlayView.superview == nil {
                self.view.addSubview(self.emptyStateOverlayView)
                self.view.bringSubviewToFront(self.emptyStateOverlayView)
                self.emptyStateOverlayView.snp_makeConstraints { make -> Void in
                    make.edges.equalTo(self.tableView)
                }
            }
        } else {
            self.emptyStateOverlayView.removeFromSuperview()
        }
    }

    private func onModelFetched(result: Maybe<BookmarksModel>) {
        guard let model = result.successValue else {
            self.onModelFailure(result.failureValue)
            return
        }
        self.onNewModel(model)
    }

    private func onNewModel(model: BookmarksModel) {
        if NSThread.currentThread().isMainThread {
            self.source = model
            self.tableView.reloadData()
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            self.source = model
            self.tableView.reloadData()
            self.updateEmptyPanelState()
        }
    }

    private func onModelFailure(e: Any) {
        log.error("Error: failed to get data: \(e)")
    }

    override func reloadData() {
        self.source?.reloadData().upon(onModelFetched)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source?.current.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let source = source, bookmark = source.current[indexPath.row] else { return super.tableView(tableView, cellForRowAtIndexPath: indexPath) }
        switch (bookmark) {
        case let item as BookmarkItem:
            let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
            if item.title.isEmpty {
                cell.textLabel?.text = item.url
            } else {
                cell.textLabel?.text = item.title
            }
            if let url = bookmark.favicon?.url.asURL where url.scheme == "asset" {
                cell.imageView?.image = UIImage(named: url.host!)
            } else if let bookmarkURL = NSURL(string: item.url) {
                cell.imageView?.setIcon(bookmark.favicon, withPlaceholder: FaviconFetcher.getDefaultFavicon(bookmarkURL))
            } else {
                cell.imageView?.setIcon(bookmark.favicon, withPlaceholder: FaviconFetcher.defaultFavicon)
            }
            return cell
        case is BookmarkSeparator:
            return tableView.dequeueReusableCellWithIdentifier(BookmarkSeparatorCellIdentifier, forIndexPath: indexPath)
        case let bookmark as BookmarkFolder:
            let cell = tableView.dequeueReusableCellWithIdentifier(BookmarkFolderCellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = bookmark.title
            return cell
        default:
            // This should never happen.
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? BookmarkFolderTableViewCell {
            cell.textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        }
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Don't show a header for the root
        if source == nil || parentFolders.isEmpty {
            return nil
        }
        guard let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(BookmarkFolderHeaderViewIdentifier) as? BookmarkFolderTableViewHeader else { return nil }

        // register as delegate to ensure we get notified when the user interacts with this header
        if header.delegate == nil {
            header.delegate = self
        }

        if parentFolders.count == 1 {
            header.textLabel?.text = NSLocalizedString("Bookmarks", comment: "Panel accessibility label")
        } else if let parentFolder = parentFolders.last {
            header.textLabel?.text = parentFolder.title
        }

        return header
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let it = self.source?.current[indexPath.row] where it is BookmarkSeparator {
            return BookmarksPanelUX.SeparatorRowHeight
        }

        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Don't show a header for the root. If there's no root (i.e. source == nil), we'll also show no header.
        if source == nil || parentFolders.isEmpty {
            return 0
        }

        return SiteTableViewControllerUX.RowHeight
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? BookmarkFolderTableViewHeader {
            // for some reason specifying the font in header view init is being ignored, so setting it here
            header.textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        }
    }

    override func tableView(tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Show a full-width border for cells above separators, so they don't have a weird step.
        // Separators themselves already have a full-width border, but let's force the issue
        // just in case.
        let this = self.source?.current[indexPath.row]
        if (indexPath.row + 1) < self.source?.current.count {
            let below = self.source?.current[indexPath.row + 1]
            if this is BookmarkSeparator || below is BookmarkSeparator {
                return true
            }
        }
        return super.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath)
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        guard let source = source else {
            return
        }

        let bookmark = source.current[indexPath.row]

        switch (bookmark) {
        case let item as BookmarkItem:
            homePanelDelegate?.homePanel(self, didSelectURLString: item.url, visitType: VisitType.Bookmark)
            break

        case let folder as BookmarkFolder:
            log.debug("Selected \(folder.guid)")
            let nextController = BookmarksPanel()
            nextController.parentFolders = parentFolders + [source.current]
            nextController.bookmarkFolder = folder
            nextController.homePanelDelegate = self.homePanelDelegate
            nextController.profile = self.profile
            source.modelFactory.uponQueue(dispatch_get_main_queue()) { maybe in
                guard let factory = maybe.successValue else {
                    // Nothing we can do.
                    return
                }
                nextController.source = BookmarksModel(modelFactory: factory, root: folder)
                self.navigationController?.pushViewController(nextController, animated: true)
            }
            break

        default:
            // You can't do anything with separators.
            break
        }
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        guard let source = source else {
            return .None
        }

        if source.current[indexPath.row] is BookmarkSeparator {
            // Because the deletion block is too big.
            return .None
        }

        if source.current.itemIsEditableAtIndex(indexPath.row) ?? false {
            return .Delete
        }

        return .None
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        guard let source = self.source else {
            return [AnyObject]()
        }

        let title = NSLocalizedString("Delete", tableName: "BookmarkPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.")

        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title, handler: { (action, indexPath) in
            guard let bookmark = source.current[indexPath.row] else {
                return
            }

            assert(!(bookmark is BookmarkFolder))
            if bookmark is BookmarkFolder {
                // TODO: check whether the folder is empty (excluding separators). If it isn't
                // then we must ask the user to confirm. Bug 1232810.
                log.debug("Not deleting folder.")
                return
            }

            log.debug("Removing rows \(indexPath).")

            // Block to do this -- this is UI code.
            guard let factory = source.modelFactory.value.successValue else {
                log.error("Couldn't get model factory. This is unexpected.")
                self.onModelFailure(DatabaseError(description: "Unable to get factory."))
                return
            }

            if let err = factory.removeByGUID(bookmark.guid).value.failureValue {
                log.debug("Failed to remove \(bookmark.guid).")
                self.onModelFailure(err)
                return
            }

            guard let reloaded = source.reloadData().value.successValue else {
                log.debug("Failed to reload model.")
                return
            }

            self.tableView.beginUpdates()
            self.source = reloaded
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
            self.tableView.endUpdates()
            self.updateEmptyPanelState()

            NSNotificationCenter.defaultCenter().postNotificationName(BookmarkStatusChangedNotification, object: bookmark, userInfo:["added": false])
        })

        return [delete]
    }
}

private protocol BookmarkFolderTableViewHeaderDelegate {
    func didSelectHeader()
}

extension BookmarksPanel: BookmarkFolderTableViewHeaderDelegate {
    private func didSelectHeader() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

class BookmarkFolderTableViewCell: TwoLineTableViewCell {
    private let ImageMargin: CGFloat = 12

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = SiteTableViewControllerUX.HeaderBackgroundColor
        textLabel?.backgroundColor = UIColor.clearColor()
        textLabel?.tintColor = BookmarksPanelUX.BookmarkFolderTextColor

        imageView?.image = UIImage(named: "bookmarkFolder")

        let chevron = ChevronView(direction: .Right)
        chevron.tintColor = BookmarksPanelUX.BookmarkFolderTextColor
        chevron.frame = CGRectMake(0, 0, BookmarksPanelUX.BookmarkFolderChevronSize, BookmarksPanelUX.BookmarkFolderChevronSize)
        chevron.lineWidth = BookmarksPanelUX.BookmarkFolderChevronLineWidth
        accessoryView = chevron

        separatorInset = UIEdgeInsetsZero
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Do this here as TwoLineTableViewCell changes the imageView frame
        // in its own layoutSubviews, and we have to make sure it is right.
        if let imageSize = imageView?.image?.size {
            imageView?.frame = CGRectMake(ImageMargin, (frame.height - imageSize.width) / 2, imageSize.width, imageSize.height)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class BookmarkFolderTableViewHeader : UITableViewHeaderFooterView {
    var delegate: BookmarkFolderTableViewHeaderDelegate?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIConstants.HighlightBlue
        return label
    }()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .Left)
        chevron.tintColor = UIConstants.HighlightBlue
        chevron.lineWidth = BookmarksPanelUX.BookmarkFolderChevronLineWidth
        return chevron
    }()

    lazy var topBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    lazy var bottomBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        userInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BookmarkFolderTableViewHeader.viewWasTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizer)

        addSubview(topBorder)
        addSubview(bottomBorder)
        contentView.addSubview(chevron)
        contentView.addSubview(titleLabel)

        chevron.snp_makeConstraints { make in
            make.left.equalTo(contentView).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
            make.size.equalTo(BookmarksPanelUX.BookmarkFolderChevronSize)
        }

        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(chevron.snp_right).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.right.greaterThanOrEqualTo(contentView).offset(-BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
        }

        topBorder.snp_makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func viewWasTapped(gestureRecognizer: UITapGestureRecognizer) {
        delegate?.didSelectHeader()
    }
}
