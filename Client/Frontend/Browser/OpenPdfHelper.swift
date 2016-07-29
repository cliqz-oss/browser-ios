/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import SnapKit

import Shared

import XCGLogger

private let log = Logger.browserLogger

struct OpenInViewUX {
    static let ViewHeight: CGFloat = 40.0
    static let TextFont = UIFont.systemFontOfSize(16)
    static let TextColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 1.0)
    static let TextOffset = -15
    static let OpenInString = NSLocalizedString("Open in…", comment: "String indicating that the file can be opened in another application on the device")
}

enum FileType : String {
    case PDF = "pdf"
}

protocol OpenInHelper {
    var openInView: OpenInView { get }
    static func canOpen(url: NSURL) -> Bool
    func open()
}

struct OpenInHelperFactory {
    static func helperForURL(url: NSURL) -> OpenInHelper? {
        if OpenPdfInHelper.canOpen(url) {
            return OpenPdfInHelper(url: url)
        }

        return nil
    }
}

class OpenPdfInHelper: NSObject, OpenInHelper, UIDocumentInteractionControllerDelegate {
    private var url: NSURL
    private var docController: UIDocumentInteractionController? = nil
    private var openInURL: NSURL?

    lazy var openInView: OpenInView = getOpenInView(self)()

    init(url: NSURL) {
        self.url = url
        super.init()
    }

    deinit {
        guard let url = openInURL else { return }
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtURL(url)
        } catch {
            log.error("failed to delete file at \(url): \(error)")
        }
    }
    
    static func canOpen(url: NSURL) -> Bool {
        guard let pathExtension = url.pathExtension else { return false }
        return pathExtension == FileType.PDF.rawValue && UIApplication.sharedApplication().canOpenURL(NSURL(string: "itms-books:")!)
    }

    func getOpenInView() -> OpenInView {
        let overlayView = OpenInView()

        overlayView.openInButton.addTarget(self, action: #selector(OpenPdfInHelper.open), forControlEvents: .TouchUpInside)
        return overlayView
    }

    func createDocumentControllerForURL(url: NSURL) {
        docController = UIDocumentInteractionController(URL: url)
        docController?.delegate = self
        self.openInURL = url
    }

    func createLocalCopyOfPDF() {
        guard let lastPathComponent = url.lastPathComponent else {
            log.error("failed to create proper URL")
            return
        }
        if docController == nil{
            // if we already have a URL but no document controller, just create the document controller
            if let url = openInURL {
                createDocumentControllerForURL(url)
                return
            }
            let contentsOfFile = NSData(contentsOfURL: url)
            let dirPath = NSURL(string: NSTemporaryDirectory())!.URLByAppendingPathComponent("pdfs")
            let filePath = dirPath.URLByAppendingPathComponent(lastPathComponent)
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.createDirectoryAtPath(dirPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
                if fileManager.createFileAtPath(filePath.absoluteString, contents: contentsOfFile, attributes: nil) {
                    let openInURL = NSURL(fileURLWithPath: filePath.absoluteString)
                    createDocumentControllerForURL(openInURL)
                } else {
                    log.error("Unable to create local version of PDF file at \(filePath)")
                }
            } catch {
                log.error("Error on creating directory at \(dirPath)")
            }
        }
    }

    func open() {
        createLocalCopyOfPDF()
        guard let _parentView = self.openInView.superview, docController = self.docController else { log.error("view doesn't have a superview so can't open anything"); return }
        // iBooks should be installed by default on all devices we care about, so regardless of whether or not there are other pdf-capable
        // apps on this device, if we can open in iBooks we can open this PDF
        // simulators do not have iBooks so the open in view will not work on the simulator
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: "itms-books:")!) {
            log.info("iBooks installed: attempting to open pdf")
            docController.presentOpenInMenuFromRect(CGRectZero, inView: _parentView, animated: true)
        } else {
            log.info("iBooks is not installed")
        }
    }
}

class OpenInView: UIView {
    let openInButton = UIButton()

    init() {
        super.init(frame: CGRectZero)
        openInButton.setTitleColor(OpenInViewUX.TextColor, forState: UIControlState.Normal)
        openInButton.setTitle(OpenInViewUX.OpenInString, forState: UIControlState.Normal)
        openInButton.titleLabel?.font = OpenInViewUX.TextFont
        openInButton.sizeToFit()
        self.addSubview(openInButton)
        openInButton.snp_makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.trailing.equalTo(self).offset(OpenInViewUX.TextOffset)
        }
        self.backgroundColor = UIColor.whiteColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}