/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sentry

public enum SentryTag: String {
    case swiftData = "SwiftData"
    case browserDB = "BrowserDB"
    case notificationService = "NotificationService"
    case unifiedTelemetry = "UnifiedTelemetry"
    case general = "General"
    case tabManager = "TabManager"
    case bookmarks = "Bookmarks"
}

public class Sentry {
    public static let shared = Sentry()
    
    public static var crashedLastLaunch: Bool {
        return Client.shared?.crashedLastLaunch() ?? false
    }
    
    private let SentryDSNKey = "SentryDSN"
    private let SentryDeviceAppHashKey = "SentryDeviceAppHash"
    private let DefaultDeviceAppHash = "0000000000000000000000000000000000000000"
    private let DeviceAppHashLength = UInt(20)
    
    private var enabled = false
    
    private var attributes: [String: Any] = [:]
    
    public func setup(sendCrashReports: Bool) {
        assert(!enabled, "Sentry.setup() should only be called once")

        if !sendCrashReports {
            print("Not enabling Sentry; Not enabled by user choice")
            return
        }
        
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: SentryDSNKey) as? String, !dsn.isEmpty else {
            print("Not enabling Sentry; Not configured in Info.plist")
            return
        }
        
        print("Enabling Sentry crash handler")
        
        do {
            Client.shared = try Client(dsn: dsn)
            try Client.shared?.startCrashHandler()
            enabled = true
            
            // If we have not already for this install, generate a completely random identifier
            // for this device.
            let defaults = UserDefaults.standard
            if defaults.string(forKey: SentryDeviceAppHashKey) == nil {
                defaults.set(generateRandomBytes(DeviceAppHashLength).hexEncodedString, forKey: SentryDeviceAppHashKey)
                defaults.synchronize()
            }
            
            
            Client.shared?.beforeSerializeEvent = { event in
                event.context?.appContext?["device_app_hash"] = self.DefaultDeviceAppHash
                
                var attributes = event.extra ?? [:]
                attributes.merge(self.attributes, uniquingKeysWith: { (first, _) in first })
                event.extra = attributes
            }
        } catch let error {
            print("Failed to initialize Sentry: \(error)")
        }
        
    }
    
    public func crash() {
        Client.shared?.crash()
    }
    
    /*
     This is the behaviour we want for Sentry logging
     .info .error .severe
     Debug      y      y       y
     Beta       y      y       y
     Relase     n      n       y
     */
    private func shouldNotSendEventFor(_ severity: SentrySeverity) -> Bool {
        return !enabled || (AppStatus.sharedInstance.isRelease() && severity != .fatal)
    }
    
    private func makeEvent(message: String, tag: String, severity: SentrySeverity, extra: [String: Any]?) -> Event {
        let event = Event(level: severity)
        event.message = message
        event.tags = ["tag": tag]
        if let extra = extra {
            event.extra = extra
        }
        return event
    }
    
    private func generateRandomBytes(_ len: UInt) -> Data {
        let len = Int(len)
        var data = Data(count: len)
        data.withUnsafeMutableBytes { (p: UnsafeMutablePointer<UInt8>) in
            if (SecRandomCopyBytes(kSecRandomDefault, len, p) != errSecSuccess) {
                fatalError("Random byte generation failed.")
            }
        }
        return data
    }
}

