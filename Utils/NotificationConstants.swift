/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

public let NotificationDataLoginDidChange = Notification.Name("Data:Login:DidChange")

// add a property to allow the observation of firefox accounts
public let NotificationFirefoxAccountChanged = Notification.Name("FirefoxAccountChangedNotification")

public let NotificationPrivateDataClearedHistory = Notification.Name("PrivateDataClearedHistoryNotification")

// Fired when the user finishes navigating to a page and the location has changed
public let NotificationOnLocationChange = Notification.Name("OnLocationChange")

// Fired when the login synchronizer has finished applying remote changes
public let NotificationDataRemoteLoginChangesWereApplied = Notification.Name("NotificationDataRemoteLoginChangesWereApplied")

// MARK: Notification UserInfo Keys
public let NotificationUserInfoKeyHasSyncableAccount = Notification.Name("NotificationUserInfoKeyHasSyncableAccount")

// Cliqz: Fired when trying to clear local history
public let NotificationPrivateDataClearQueries = "PrivateDataClearQueriesNotification"

// Cliqz: Fired when tryting to reset top-sites from settings
public let NotificationShowBlockedTopSites = "NotificationShowBlockedTopSitesNotification"

// Cliqz: Fired when Anti-Tracking module detects a bad request and modified it
public let NotificationBadRequestDetected = "NotificationBadRequestDetected"

// Cliqz: Fired when the background color of the AntiTracking Button needs to be changed
public let NotificationRefreshAntiTrackingButton = "NotificationRefreshAntiTrackingButton"

public let NotificationFirefoxAccountDeviceRegistrationUpdated = Notification.Name("FirefoxAccountDeviceRegistrationUpdated")
