/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import Deferred

private let log = Logger.syncLogger

/**
 * This exists to pass in external context: e.g., the UIApplication can
 * expose notification functionality in this way.
 */
public protocol SyncDelegate {
    func displaySentTabForURL(URL: NSURL, title: String)
    // TODO: storage.
}

/**
 * We sometimes want to make a synchronizer start from scratch: to throw away any
 * metadata and reset storage to match, allowing us to respond to significant server
 * changes.
 *
 * But instantiating a Synchronizer is a lot of work if we simply want to change some
 * persistent state. This protocol describes a static func that fits most synchronizers.
 *
 * When the returned `Deferred` is filled with a success value, the supplied prefs and
 * storage are ready to sync from scratch.
 *
 * Persisted long-term/local data is kept, and will later be reconciled as appropriate.
 */
public protocol ResettableSynchronizer {
    static func resetSynchronizerWithStorage(storage: ResettableSyncStorage, basePrefs: Prefs, collection: String) -> Success
}

// TODO: return values?
/**
 * A Synchronizer is (unavoidably) entirely in charge of what it does within a sync.
 * For example, it might make incremental progress in building a local cache of remote records, never actually performing an upload or modifying local storage.
 * It might only upload data. Etc.
 *
 * Eventually I envision an intent-like approach, or additional methods, to specify preferences and constraints
 * (e.g., "do what you can in a few seconds", or "do a full sync, no matter how long it takes"), but that'll come in time.
 *
 * A Synchronizer is a two-stage beast. It needs to support synchronization, of course; that
 * needs a completely configured client, which can only be obtained from Ready. But it also
 * needs to be able to do certain things beforehand:
 *
 * * Wipe its collections from the server (presumably via a delegate from the state machine).
 * * Prepare to sync from scratch ("reset") in response to a changed set of keys, syncID, or node assignment.
 * * Wipe local storage ("wipeClient").
 *
 * Those imply that some kind of 'Synchronizer' exists throughout the state machine. We *could*
 * pickle instructions for eventual delivery next time one is made and synchronized…
 */
public protocol Synchronizer {
    init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs)

    /**
     * Return a reason if the current state of this synchronizer -- particularly prefs and scratchpad --
     * prevent a routine sync from occurring.
     */
    func reasonToNotSync(_: Sync15StorageClient) -> SyncNotStartedReason?
}

/**
 * We sometimes wish to return something more nuanced than simple success or failure.
 * For example, refusing to sync because the engine was disabled isn't success (nothing was transferred!)
 * but it also isn't an error.
 *
 * To do this we model real failures -- something went wrong -- as failures in the Result, and
 * everything else in this status enum. This will grow as we return more details from a sync to allow
 * for batch scheduling, success-case backoff and so on.
 */
public enum SyncStatus {
    case Completed                 // TODO: we pick up a bunch of info along the way. Pass it along.
    case NotStarted(SyncNotStartedReason)
    case Partial

    public var description: String {
        switch self {
        case .Completed:
            return "Completed"
        case let .NotStarted(reason):
            return "Not started: \(reason.description)"
        case .Partial:
            return "Partial"
        }
    }
}


typealias DeferredTimestamp = Deferred<Maybe<Timestamp>>
public typealias SyncResult = Deferred<Maybe<SyncStatus>>

public enum SyncNotStartedReason {
    case NoAccount
    case Offline
    case Backoff(remainingSeconds: Int)
    case EngineRemotelyNotEnabled(collection: String)
    case EngineFormatOutdated(needs: Int)
    case EngineFormatTooNew(expected: Int)   // This'll disappear eventually; we'll wipe the server and upload m/g.
    case StorageFormatOutdated(needs: Int)
    case StorageFormatTooNew(expected: Int)  // This'll disappear eventually; we'll wipe the server and upload m/g.
    case StateMachineNotReady                // Because we're not done implementing.
    case RedLight
    case Unknown                             // Likely a programming error.

    var description: String {
        switch self {
        case .NoAccount:
            return "no account"
        case let .Backoff(remaining):
            return "in backoff: \(remaining) seconds remaining"
        default:
            return "undescribed reason"
        }
    }
}

public class FatalError: SyncError {
    let message: String
    init(message: String) {
        self.message = message
    }

    public var description: String {
        return self.message
    }
}

public protocol SingleCollectionSynchronizer {
    func remoteHasChanges(info: InfoCollections) -> Bool
}

public class BaseCollectionSynchronizer {
    let collection: String

    let scratchpad: Scratchpad
    let delegate: SyncDelegate
    let prefs: Prefs

    static func prefsForCollection(collection: String, withBasePrefs basePrefs: Prefs) -> Prefs {
        let branchName = "synchronizer." + collection + "."
        return basePrefs.branch(branchName)
    }

    init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs, collection: String) {
        self.scratchpad = scratchpad
        self.delegate = delegate
        self.collection = collection
        self.prefs = BaseCollectionSynchronizer.prefsForCollection(collection, withBasePrefs: basePrefs)

        log.info("Synchronizer configured with prefs '\(self.prefs.getBranchPrefix()).'")
    }

    var storageVersion: Int {
        assert(false, "Override me!")
        return 0
    }

    public func reasonToNotSync(client: Sync15StorageClient) -> SyncNotStartedReason? {
        let now = NSDate.now()
        if let until = client.backoff.isInBackoff(now) {
            let remaining = (until - now) / 1000
            return .Backoff(remainingSeconds: Int(remaining))
        }

        if let metaGlobal = self.scratchpad.global?.value {
            // There's no need to check the global storage format here; the state machine will already have
            // done so.
            if let engineMeta = metaGlobal.engines[collection] {
                if engineMeta.version > self.storageVersion {
                    return .EngineFormatOutdated(needs: engineMeta.version)
                }
                if engineMeta.version < self.storageVersion {
                    return .EngineFormatTooNew(expected: engineMeta.version)
                }
            } else {
                return .EngineRemotelyNotEnabled(collection: self.collection)
            }
        } else {
            // But a missing meta/global is a real problem.
            return .StateMachineNotReady
        }

        // Success!
        return nil
    }

    func encrypter<T>(encoder: RecordEncoder<T>) -> RecordEncrypter<T>? {
        return self.scratchpad.keys?.value.encrypter(self.collection, encoder: encoder)
    }

    func collectionClient<T>(encoder: RecordEncoder<T>, storageClient: Sync15StorageClient) -> Sync15CollectionClient<T>? {
        if let encrypter = self.encrypter(encoder) {
            return storageClient.clientForCollection(self.collection, encrypter: encrypter)
        }
        return nil
    }
}

/**
 * Tracks a lastFetched timestamp, uses it to decide if there are any
 * remote changes, and exposes a method to fast-forward after upload.
 */
public class TimestampedSingleCollectionSynchronizer: BaseCollectionSynchronizer, SingleCollectionSynchronizer {

    var lastFetched: Timestamp {
        set(value) {
            self.prefs.setLong(value, forKey: "lastFetched")
        }

        get {
            return self.prefs.unsignedLongForKey("lastFetched") ?? 0
        }
    }

    func setTimestamp(timestamp: Timestamp) {
        log.debug("Setting post-upload lastFetched to \(timestamp).")
        self.lastFetched = timestamp
    }

    public func remoteHasChanges(info: InfoCollections) -> Bool {
        return info.modified(self.collection) > self.lastFetched
    }
}

extension BaseCollectionSynchronizer: ResettableSynchronizer {
    public static func resetSynchronizerWithStorage(storage: ResettableSyncStorage, basePrefs: Prefs, collection: String) -> Success {
        let synchronizerPrefs = BaseCollectionSynchronizer.prefsForCollection(collection, withBasePrefs: basePrefs)
        synchronizerPrefs.removeObjectForKey("lastFetched")

        // Not all synchronizers use a batching downloader, but it's
        // convenient to just always reset it here.
        return storage.resetClient()
           >>> effect({ BatchingDownloader.resetDownloaderWithPrefs(synchronizerPrefs, collection: collection) })
    }
}