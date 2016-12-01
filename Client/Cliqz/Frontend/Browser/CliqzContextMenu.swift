/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Using suggestions from: http://www.icab.de/blog/2010/07/11/customize-the-contextual-menu-of-uiwebview/


class CliqzContextMenu {
    var tapLocation: CGPoint = CGPointZero
    var tappedElement: ContextMenuHelper.Elements?
    
    var timer1_cancelDefaultMenu: NSTimer = NSTimer()
    var timer2_showMenuIfStillPressed: NSTimer = NSTimer()
    
    static let initialDelayToCancelBuiltinMenu = 0.20 // seconds, must be <0.3 or built-in menu can't be cancelled
    static let totalDelayToShowContextMenu = 0.65 - initialDelayToCancelBuiltinMenu // 850 is copied from Safari
    
    private func resetTimer() {
        if (!timer1_cancelDefaultMenu.valid && !timer2_showMenuIfStillPressed.valid) {
            return
        }
        
//        if let url = tappedElement?.link {
//            getCurrentWebView()?.loadRequest(NSURLRequest(URL: url))
//        }
        
        [timer1_cancelDefaultMenu, timer2_showMenuIfStillPressed].forEach { $0.invalidate() }
        tappedElement = nil
    }
    
    private func isBrowserTopmostAndNoPanelsOpen() ->  Bool {
        let rootViewController = getApp().rootViewController
        var navigationController: UINavigationController?
        
        if let notificatinoViewController =  rootViewController as? NotificationRootViewController {
            navigationController = notificatinoViewController.rootViewController as? UINavigationController
        } else {
            navigationController = rootViewController as? UINavigationController
        }
        
        
        if let _ = navigationController?.visibleViewController as? BrowserViewController {
            return true
        } else {
            return false
        }
    }
    
    func sendEvent(event: UIEvent, window: UIWindow) {
        if !isBrowserTopmostAndNoPanelsOpen() {
            resetTimer()
            return
        }
        
        guard let cliqzWebView = getCurrentWebView() else { return }
        
        if let touches = event.touchesForWindow(window), let touch = touches.first where touches.count == 1 {
            //            cliqzWebView.lastTappedTime = NSDate()
            switch touch.phase {
            case .Began:  // A finger touched the screen
                guard let touchView = event.allTouches()?.first?.view where touchView.isDescendantOfView(cliqzWebView) else {
                    resetTimer()
                    return
                }
                
                tapLocation = touch.locationInView(window)
                resetTimer()
                timer1_cancelDefaultMenu = NSTimer.scheduledTimerWithTimeInterval(CliqzContextMenu.initialDelayToCancelBuiltinMenu, target: self, selector: #selector(cancelDefaultMenuAndFindTappedItem), userInfo: nil, repeats: false)
                break
            case .Moved, .Stationary:
                let p1 = touch.locationInView(window)
                let p2 = touch.previousLocationInView(window)
                let distance =  hypotf(Float(p1.x) - Float(p2.x), Float(p1.y) - Float(p2.y))
                if distance > 10.0 { // my test for this: tap with edge of finger, then roll to opposite edge while holding finger down, is 5-10 px of movement; don't want this to be a move
                    resetTimer()
                }
                break
            case .Ended, .Cancelled:
                if let url = tappedElement?.link {
                    getCurrentWebView()?.loadRequest(NSURLRequest(URL: url))
                }
                resetTimer()
                break
            }
        } else {
            resetTimer()
        }
    }
    
    @objc func showContextMenu() {
        func showContextMenuForElement(tappedElement:  ContextMenuHelper.Elements) {
            guard let bvc = getApp().browserViewController else { return }
            if bvc.urlBar.inOverlayMode {
                return
            }
            bvc.showContextMenu(elements: tappedElement, touchPoint: tapLocation)
            resetTimer()
            return
        }
        
        
        if let tappedElement = tappedElement {
            showContextMenuForElement(tappedElement)
        }
    }
    
    // This is called 2x, once at .25 seconds to ensure the native context menu is cancelled,
    // then again at .5 seconds to show our context menu. (This code was borne of frustration, not ideal flow)
    @objc func cancelDefaultMenuAndFindTappedItem() {
        if !isBrowserTopmostAndNoPanelsOpen() {
            resetTimer()
            return
        }
        
        guard let webView = getCurrentWebView() else { return }
        
        let hit: (url: String?, image: String?, urlTarget: String?)?
        
        if [".jpg", ".png", ".gif"].filter({ webView.URL?.absoluteString?.endsWith($0) ?? false }).count > 0 {
            // web view is just showing an image
            hit = (url:nil, image:webView.URL!.absoluteString, urlTarget:nil)
        } else {
            hit = ElementAtPoint().getHit(tapLocation)
        }
        if hit == nil {
            // No link or image found, not for this class to handle
            resetTimer()
            return
        }
        
        tappedElement = ContextMenuHelper.Elements(link: hit!.url != nil ? NSURL(string: hit!.url!) : nil, image: hit!.image != nil ? NSURL(string: hit!.image!) : nil)
        
        func blockOtherGestures(views: [UIView]?) {
            guard let views = views else { return }
            for view in views {
                if let gestures = view.gestureRecognizers as [UIGestureRecognizer]! {
                    for gesture in gestures {
                        if gesture is UILongPressGestureRecognizer {
                            // toggling gets the gesture to ignore this long press
                            gesture.enabled = false
                            gesture.enabled = true
                        }
                    }
                }
            }
        }
        
        blockOtherGestures(getCurrentWebView()?.scrollView.subviews)
        
        timer2_showMenuIfStillPressed = NSTimer.scheduledTimerWithTimeInterval(CliqzContextMenu.totalDelayToShowContextMenu, target: self, selector: #selector(showContextMenu), userInfo: nil, repeats: false)
    }
}
