/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


class HistorySwiper : NSObject {
    
    var topLevelView: UIView!
    var webViewContainer: UIView!
    
    func setup(topLevelView topLevelView: UIView, webViewContainer: UIView) {
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
    
    private func handleSwipe(recognizer: UIGestureRecognizer) {
        if getApp().browserViewController.homePanelController != nil {
            return
        }
        
        guard let tab = getApp().browserViewController.tabManager.selectedTab, webview = tab.webView else { return }
        let p = recognizer.locationInView(recognizer.view)
        let shouldReturnToZero = recognizer == goBackSwipe ? p.x < screenWidth() / 2.0 : p.x > screenWidth() / 2.0
        
        if recognizer.state == .Ended || recognizer.state == .Cancelled || recognizer.state == .Failed {
            UIView.animateWithDuration(0.25, animations: {
                if shouldReturnToZero {
                    self.webViewContainer.transform = CGAffineTransformMakeTranslation(0, self.webViewContainer.transform.ty)
                } else {
                    let x = recognizer == self.goBackSwipe ? self.screenWidth() : -self.screenWidth()
                    self.webViewContainer.transform = CGAffineTransformMakeTranslation(x, self.webViewContainer.transform.ty)
                    self.webViewContainer.alpha = 0
                }
                }, completion: { (Bool) -> Void in
                    if !shouldReturnToZero {
                        if recognizer == self.goBackSwipe {
                            getApp().browserViewController.goBack()
                        } else {
                            getApp().browserViewController.goForward()
                        }
                        
                        self.webViewContainer.transform = CGAffineTransformMakeTranslation(0, self.webViewContainer.transform.ty)
                        
                        // when content size is updated
                        postAsyncToMain(3.0) {
                            self.restoreWebview()
                        }
                        NSNotificationCenter.defaultCenter().removeObserver(self)
                        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistorySwiper.updateDetected), name: CliqzWebViewConstants.kNotificationPageInteractive, object: webview)
                        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistorySwiper.updateDetected), name: CliqzWebViewConstants.kNotificationWebViewLoadCompleteOrFailed, object: webview)
                    }
            })
        } else {
            let tx = recognizer == goBackSwipe ? p.x : p.x - screenWidth()
            webViewContainer.transform = CGAffineTransformMakeTranslation(tx, self.webViewContainer.transform.ty)
            
        }
    }
    
    func restoreWebview() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
            postAsyncToMain(0.4) { // after a render detected, allow ample time for drawing to complete
                UIView.animateWithDuration(0.2) {
                    self.webViewContainer.alpha = 1.0
                }
            }
    }
    
    @objc func screenRightEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer) {
        handleSwipe(recognizer)
    }
    
    @objc func screenLeftEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer) {
        handleSwipe(recognizer)
    }
}

extension HistorySwiper : UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(recognizer: UIGestureRecognizer) -> Bool {
        guard let tab = getApp().browserViewController.tabManager.selectedTab else { return false}
        if (recognizer == goBackSwipe && !tab.canGoBack) ||
            (recognizer == goForwardSwipe && !tab.canGoForward) {
            return false
        }
        
        guard let recognizer = recognizer as? UIPanGestureRecognizer else { return false }
        let v = recognizer.velocityInView(recognizer.view)
        if fabs(v.x) < fabs(v.y) {
            return false
        }
        
        let tolerance = CGFloat(30.0)
        let p = recognizer.locationInView(recognizer.view)
        return recognizer == goBackSwipe ? p.x < tolerance : p.x > screenWidth() - tolerance
    }
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
