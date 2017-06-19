/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


class HistorySwiper : NSObject {
    
    var topLevelView: UIView!
    var webViewContainer: UIView!
    
    func setup(_ topLevelView: UIView, webViewContainer: UIView) {
        self.topLevelView = topLevelView
        self.webViewContainer = webViewContainer
        
        goBackSwipe.delegate = self
        goForwardSwipe.delegate = self
    }
    
    lazy var goBackSwipe: UIGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(HistorySwiper.screenLeftEdgeSwiped(_:)))
        self.topLevelView.addGestureRecognizer(pan)
        return pan
    }()
    
    lazy var goForwardSwipe: UIGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(HistorySwiper.screenRightEdgeSwiped(_:)))
        self.topLevelView.addGestureRecognizer(pan)
        return pan
    }()
    
    @objc func updateDetected() {
        restoreWebview()
    }
    
    func screenWidth() -> CGFloat {
        return topLevelView.frame.width
    }
    
    fileprivate func handleSwipe(_ recognizer: UIGestureRecognizer) {
        if getApp().browserViewController.homePanelController != nil {
            return
        }
        
        guard let tab = getApp().browserViewController.tabManager.selectedTab, let webview = tab.webView else { return }
        let p = recognizer.location(in: recognizer.view)
        let shouldReturnToZero = recognizer == goBackSwipe ? p.x < screenWidth() / 2.0 : p.x > screenWidth() / 2.0
        
        if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
            UIView.animate(withDuration: 0.25, animations: {
                if shouldReturnToZero {
                    self.webViewContainer.transform = CGAffineTransform(translationX: 0, y: self.webViewContainer.transform.ty)
                } else {
                    let x = recognizer == self.goBackSwipe ? self.screenWidth() : -self.screenWidth()
                    self.webViewContainer.transform = CGAffineTransform(translationX: x, y: self.webViewContainer.transform.ty)
                    self.webViewContainer.alpha = 0
                }
                }, completion: { (Bool) -> Void in
                    if !shouldReturnToZero {
                        if recognizer == self.goBackSwipe {
                            getApp().browserViewController.goBack()
                        } else {
                            getApp().browserViewController.goForward()
                        }
                        
                        self.webViewContainer.transform = CGAffineTransform(translationX: 0, y: self.webViewContainer.transform.ty)
                        
                        // when content size is updated
                        postAsyncToMain(3.0) {
                            self.restoreWebview()
                        }
                        NotificationCenter.default.removeObserver(self)
                        NotificationCenter.default.addObserver(self, selector: #selector(HistorySwiper.updateDetected), name: NSNotification.Name(rawValue: CliqzWebViewConstants.kNotificationPageInteractive), object: webview)
                        NotificationCenter.default.addObserver(self, selector: #selector(HistorySwiper.updateDetected), name: NSNotification.Name(rawValue: CliqzWebViewConstants.kNotificationWebViewLoadCompleteOrFailed), object: webview)
                    }
            })
        } else {
            let tx = recognizer == goBackSwipe ? p.x : p.x - screenWidth()
            webViewContainer.transform = CGAffineTransform(translationX: tx, y: self.webViewContainer.transform.ty)
            
        }
    }
    
    func restoreWebview() {
        NotificationCenter.default.removeObserver(self)
            postAsyncToMain(0.4) { // after a render detected, allow ample time for drawing to complete
                UIView.animate(withDuration: 0.2, animations: {
                    self.webViewContainer.alpha = 1.0
                }) 
            }
    }
    
    @objc func screenRightEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        handleSwipe(recognizer)
    }
    
    @objc func screenLeftEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        handleSwipe(recognizer)
    }
}

extension HistorySwiper : UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
        guard let tab = getApp().browserViewController.tabManager.selectedTab else { return false}
        if (recognizer == goBackSwipe && !tab.canGoBack) ||
            (recognizer == goForwardSwipe && !tab.canGoForward) {
            return false
        }
        
        guard let recognizer = recognizer as? UIPanGestureRecognizer else { return false }
        let v = recognizer.velocity(in: recognizer.view)
        if fabs(v.x) < fabs(v.y) {
            return false
        }
        
        let tolerance = CGFloat(30.0)
        let p = recognizer.location(in: recognizer.view)
        return recognizer == goBackSwipe ? p.x < tolerance : p.x > screenWidth() - tolerance
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
