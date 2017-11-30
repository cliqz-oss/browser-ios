//
//  PrivateBrowsing.swift
//  Client
//
//  Reference: https://github.com/brave/browser-ios/blob/development/brave/src/webview/PrivateBrowsing.swift

import Shared
import Deferred

private let _singleton = PrivateBrowsing()

class PrivateBrowsing {
    class var singleton: PrivateBrowsing {
        return _singleton
    }
    
    fileprivate(set) var isOn = false
    
    var nonprivateCookies = [HTTPCookie: Bool]()
    
    // On startup we are no longer in private mode, if there is a .public cookies file, it means app was killed in private mode, so restore the cookies file
    func startupCheckIfKilledWhileInPBMode() {
        webkitDirLocker(false)
        cookiesFileDiskOperation(.restorePublicBackup)
    }
    
    enum MoveCookies {
        case savePublicBackup
        case restorePublicBackup
        case deletePublicBackup
    }
    
    // GeolocationSites.plist cannot be blocked any other way than locking the filesystem so that webkit can't write it out
    // TODO: after unlocking, verify that sites from PB are not in the written out GeolocationSites.plist, based on manual testing this
    // doesn't seem to be the case, but more rigourous test cases are needed
    fileprivate func webkitDirLocker(_ lock: Bool) {
        let fm = FileManager.default
        let baseDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        let webkitDirs = [baseDir + "/WebKit", baseDir + "/Caches"]
        for dir in webkitDirs {
            do {
                try fm.setAttributes([FileAttributeKey.posixPermissions: (lock ? NSNumber(value: 0 as Int16) : NSNumber(value: 0o755 as Int16))], ofItemAtPath: dir)
            } catch {
                print(error)
            }
        }
    }
    
    fileprivate func cookiesFileDiskOperation( _ type: MoveCookies) {
        let fm = FileManager.default
        let baseDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        let cookiesDir = baseDir + "/Cookies"
        let originSuffix = type == .savePublicBackup ? "cookies" : ".public"
        
        do {
            let contents = try fm.contentsOfDirectory(atPath: cookiesDir)
            for item in contents {
                if item.hasSuffix(originSuffix) {
                    if type == .deletePublicBackup {
                        try fm.removeItem(atPath: cookiesDir + "/" + item)
                    } else {
                        var toPath = cookiesDir + "/"
                        if type == .restorePublicBackup {
                            toPath += NSString(string: item).deletingPathExtension
                        } else {
                            toPath += item + ".public"
                        }
                        if fm.fileExists(atPath: toPath) {
                            do { try fm.removeItem(atPath: toPath) } catch {}
                        }
                        try fm.moveItem(atPath: cookiesDir + "/" + item, toPath: toPath)
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func enter() {
        if isOn {
            return
        }
        isOn = true
        
        getApp().tabManager.purgeTabs(includeSelectedTab: true)
        
        
        self.backupNonPrivateCookies()
        self.setupCacheDefaults(memoryCapacity: 0, diskCapacity: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PrivateBrowsing.cookiesChanged(_:)), name: NSNotification.Name.NSHTTPCookieManagerCookiesChanged, object: nil)
        
        webkitDirLocker(true)
    }
    
    fileprivate var exitDeferred = Deferred<Void>()
    @discardableResult func exit() -> Deferred<Void> {
        
        if !isOn {
            let immediateExit = Deferred<Void>()
            immediateExit.fill(())
            return immediateExit
        }
        
        // Since this an instance var, it needs to be used carefully.
        // The usage of this deferred, is async, and is generally handled, by a response to a notification
        //  if it is overwritten, it will lead to race conditions, and generally a dropped deferment, since the
        //  notification will be executed on _only_ the newest version of this property
        exitDeferred = Deferred<Void>()
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(allWebViewsKilled), name: NSNotification.Name(rawValue: kNotificationAllWebViewsDeallocated), object: nil)
        
        getApp().tabManager.purgeTabs(includeSelectedTab: true)
        
        postAsyncToMain(2) {
            if !self.exitDeferred.isFilled {
                self.allWebViewsKilled()
            }
        }
        
        isOn = false
        
        return exitDeferred
    }
    
    @objc func allWebViewsKilled() {
        struct ReentrantGuard {
            static var inFunc = false
        }
        
        if ReentrantGuard.inFunc {
            // This is kind of a predicament
            //  On one hand, we cannot drop promises,
            //  on the other, if processes are killing webviews, this could end up executing logic that should not happen
            //  so quickly. A better refactor would be to propogate some piece of data (e.g. Bool), that indicates
            //  the current state of promise chain (e.g. ReentrantGuard value)
            self.exitDeferred.fillIfUnfilled(())
            return
        }
        ReentrantGuard.inFunc = true
        NotificationCenter.default.removeObserver(self)

        postAsyncToMain(0.1) { // just in case any other webkit object cleanup needs to complete
            
            self.deleteAllCookies()
            self.cleanStorage()
            self.clearShareHistory()
            self.webkitDirLocker(false)
            self.cleanProfile()
            self.setupCacheDefaults(memoryCapacity: 8, diskCapacity: 50)
            self.restoreNonPrivateCookies()
            
            self.exitDeferred.fillIfUnfilled(())
            ReentrantGuard.inFunc = false
            
        }
    }
    
    private func setupCacheDefaults(memoryCapacity: Int, diskCapacity: Int) { // in MB
        URLCache.shared.memoryCapacity = memoryCapacity * 1024 * 1024;
        URLCache.shared.diskCapacity = diskCapacity * 1024 * 1024;
    }
    
    private func deleteAllCookies() {
        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }
    }
    
    private func cleanStorage() {
        if let clazz = NSClassFromString("Web" + "StorageManager") as? NSObjectProtocol {
            if clazz.responds(to: Selector("shared" + "WebStorageManager")) {
                if let storage = clazz.perform(Selector("shared" + "WebStorageManager")) {
                    let o = storage.takeUnretainedValue()
                    o.perform(Selector("delete" + "AllOrigins"))
                }
            }
        }
    }
    
    private func clearShareHistory() {
        if let clazz = NSClassFromString("Web" + "History") as? NSObjectProtocol {
            if clazz.responds(to: Selector("optional" + "SharedHistory")) {
                if let webHistory = clazz.perform(Selector("optional" + "SharedHistory")) {
                    let o = webHistory.takeUnretainedValue()
                    o.perform(Selector("remove" + "AllItems"))
                }
            }
        }
    }
    
    private func backupNonPrivateCookies() {
        self.cookiesFileDiskOperation(.savePublicBackup)
        
        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies {
            for cookie in cookies {
                self.nonprivateCookies[cookie] = true
                storage.deleteCookie(cookie)
            }
        }
    }
    
    private func restoreNonPrivateCookies() {
        self.cookiesFileDiskOperation(.deletePublicBackup)
        
        let storage = HTTPCookieStorage.shared
        for cookie in self.nonprivateCookies {
            storage.setCookie(cookie.0)
        }
        self.nonprivateCookies = [HTTPCookie: Bool]()
    }
    
    private func cleanProfile() {
        getApp().profile?.shutdown()
        getApp().profile?.db.reopenIfClosed()
    }
    
    @objc func cookiesChanged(_ info: Notification) {
        NotificationCenter.default.removeObserver(self)
        let storage = HTTPCookieStorage.shared
        var newCookies = [HTTPCookie]()
        if let cookies = storage.cookies {
            for cookie in cookies {
                if let readOnlyProps = cookie.properties {
                    var props = readOnlyProps as [HTTPCookiePropertyKey: Any]
                    let discard = props[HTTPCookiePropertyKey.discard] as? String
                    if discard == nil || discard! != "TRUE" {
                        props.removeValue(forKey: HTTPCookiePropertyKey.expires)
                        props[HTTPCookiePropertyKey.discard] = "TRUE"
                        storage.deleteCookie(cookie)
                        if let newCookie = HTTPCookie(properties: props) {
                            newCookies.append(newCookie)
                        }
                    }
                }
            }
        }
        for c in newCookies {
            storage.setCookie(c)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(PrivateBrowsing.cookiesChanged(_:)), name: NSNotification.Name.NSHTTPCookieManagerCookiesChanged, object: nil)
    }
}

