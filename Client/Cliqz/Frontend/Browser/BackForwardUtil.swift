//
//  BackForwardUtil.swift
//  Client
//
//  Created by Tim Palade on 9/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//This is supposed to go once the KVO of the webView is fixed
final class CurrentWebViewMonitor {
    static let shared = CurrentWebViewMonitor()
    
    var lastCanGoBack: Bool = false
    var lastCanGoForward: Bool = false

    var timer: Timer = Timer()

    init() {
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(update), userInfo: nil, repeats: true)//Timer(timeInterval: 0.1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        timer.fire()
    }

    @objc private func update() {
        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager, let currentWebView = tabManager.selectedTab?.webView {
            let canGoForward = currentWebView.canGoForward
            let canGoBack = currentWebView.canGoBack
            
            if canGoBack != lastCanGoBack || canGoForward != lastCanGoForward {
                //trigger and update
                StateManager.shared.handleAction(action: Action(type: .webNavigationUpdate))
                lastCanGoBack = canGoBack
                lastCanGoForward = canGoForward
            }
            
        }
    }
}

