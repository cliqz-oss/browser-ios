/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import SwiftKeychainWrapper

private let log = Logger.syncLogger

/*
 * This file includes types that manage intra-sync and inter-sync metadata
 * for the use of synchronizers and the state machine.
 *
 * See docs/sync.md for details on what exactly we need to persist.
 */

public struct Fetched<T: Equatable>: Equatable {
    let value: T
    let timestamp: Timestamp
}

public func ==<T: Equatable>(lhs: Fetched<T>, rhs: Fetched<T>) -> Bool {
    return lhs.timestamp == rhs.timestamp &&
           lhs.value == rhs.value
}

public enum LocalCommand: CustomStringConvertible, Hashable {
    // We've seen something (a blank server, a changed global sync ID, a
    // crypto/keys with a different meta/global) that requires us to reset all
    // local engine timestamps (save the ones listed) and possibly re-upload.
    case ResetAllEngines(except: Set<String>)

    // We've seen something (a changed engine sync ID, a crypto/keys with a
    // different per-engine bulk key) that requires us to reset our local engine
    // timestamp and possibly re-upload.
    case ResetEngine(engine: String)

    // We've seen a change in meta/global: an engine has come or gone.
    case EnableEngine(engine: String)
    case DisableEngine(engine: String)

    public func toJSON() -> JSON {
        switch (self) {
        case let .ResetAllEngines(except):
            return JSON(["type": "ResetAllEngines", "except": Array(except).sort()])

        case let .ResetEngine(engine):
            return JSON(["type": "ResetEngine", "engine": engine])

        case let .EnableEngine(engine):
            return JSON(["type": "EnableEngine", "engine": engine])

        case let .DisableEngine(engine):
            return JSON(["type": "DisableEngine", "engine": engine])
        }
    }

    public static func fromJSON(json: JSON) -> LocalCommand? {
        if json.isError {
            return nil
        }
        guard let type = json["type"].asString else {
            return nil
        }
        switch type {
        case "ResetAllEngines":
            if let except = json["except"].asArray where except.every({$0.isString}) {
                return .ResetAllEngines(except: Set(except.map({$0.asString!})))
            }
            return nil
        case "ResetEngine":
            if let engine = json["engine"].asString {
                return .ResetEngine(engine: engine)
            }
            return nil
        case "EnableEngine":
            if let engine = json["engine"].asString {
                return .EnableEngine(engine: engine)
            }
            return nil
        case "DisableEngine":
            if let engine = json["engine"].asString {
                return .DisableEngine(engine: engine)
            }
            return nil
        default:
            return nil
        }
    }

    public var description: String {
        return self.toJSON().toString()
    }

    public var hashValue: Int {
        return self.description.hashValue
    }
}

public func ==(lhs: LocalCommand, rhs: LocalCommand) -> Bool {
    switch (lhs, rhs) {
    case (let .ResetAllEngines(exceptL), let .ResetAllEngines(exceptR)):
        return exceptL == exceptR

    case (let .ResetEngine(engineL), let .ResetEngine(engineR)):
        return engineL == engineR

    case (let .EnableEngine(engineL), let .EnableEngine(engineR)):
        return engineL == engineR

    case (let .DisableEngine(engineL), let .DisableEngine(engineR)):
        return engineL == engineR

    default:
        return false
    }
}

/*
 * Persistence pref names.
 * Note that syncKeyBundle isn't persisted by us.
 *
 * Note also that fetched keys aren't kept in prefs: we keep the timestamp ("PrefKeysTS"),
 * and we keep a 'label'. This label is used to find the real fetched keys in the Keychain.
 */

private let PrefVersion = "_v"
private let PrefGlobal = "global"
private let PrefGlobalTS = "globalTS"
private let PrefKeyLabel = "keyLabel"
private let PrefKeysTS = "keysTS"
private let PrefLastFetched = "lastFetched"
private let PrefLocalCommands = "localCommands"
private let PrefClientName = "clientName"
private let PrefClientGUID = "clientGUID"
private let PrefEngineConfiguration = "engineConfiguration"

class PrefsBackoffStorage: BackoffStorage {
    let prefs: Prefs
    private let key = "timestamp"

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    var serverBackoffUntilLocalTimestamp: Timestamp? {
        get {
            return self.prefs.unsignedLongForKey(self.key)
        }

        set(value) {
            if let value = value {
                self.prefs.setLong(value, forKey: self.key)
            } else {
                self.prefs.removeObjectForKey(self.key)
            }
        }
    }

    func clearServerBackoff() {
        self.prefs.removeObjectForKey(self.key)
    }

    func isInBackoff(now: Timestamp) -> Timestamp? {
        if let ts = self.serverBackoffUntilLocalTimestamp where now < ts {
            return ts
        }
        return nil
    }
}

/**
 * The scratchpad consists of the following:
 *
 * 1. Cached records. We cache meta/global and crypto/keys until they change.
 * 2. Metadata like timestamps, both for cached records and for server fetches.
 * 3. User preferences -- engine enablement.
 * 4. Client record state.
 * 5. Local commands that have yet to be processed.
 *
 * Note that the scratchpad itself is immutable, but is a class passed by reference.
 * Its mutable fields can be mutated, but you can't accidentally e.g., switch out
 * meta/global and get confused.
 *
 * TODO: the Scratchpad needs to be loaded from persistent storage, and written
 * back at certain points in the state machine (after a replayable action is taken).
 */
public class Scratchpad {
    public class Builder {
        var syncKeyBundle: KeyBundle         // For the love of god, if you change this, invalidate keys, too!
        private var global: Fetched<MetaGlobal>?
        private var keys: Fetched<Keys>?
        private var keyLabel: String
        var localCommands: Set<LocalCommand>
        var engineConfiguration: EngineConfiguration?
        var clientGUID: String
        var clientName: String
        var prefs: Prefs

        init(p: Scratchpad) {
            self.syncKeyBundle = p.syncKeyBundle
            self.prefs = p.prefs

            self.global = p.global

            self.keys = p.keys
            self.keyLabel = p.keyLabel
            self.localCommands = p.localCommands
            self.engineConfiguration = p.engineConfiguration
            self.clientGUID = p.clientGUID
            self.clientName = p.clientName
        }

        public func clearLocalCommands() -> Builder {
            self.localCommands.removeAll()
            return self
        }

        public func addLocalCommandsFromKeys(keys: Fetched<Keys>?) -> Builder {
            // Getting new keys can force local collection resets.
            guard let freshKeys = keys?.value, staleKeys = self.keys?.value where staleKeys.valid else {
                // Removing keys, or new keys and either we didn't have old keys or they weren't valid.  Everybody gets a reset!
                self.localCommands.insert(LocalCommand.ResetAllEngines(except: []))
                return self
            }

            // New keys, and we have valid old keys.
            if freshKeys.defaultBundle != staleKeys.defaultBundle {
                // Default bundle has changed.  Reset everything but collections that have unchanged bulk keys.
                var except: Set<String> = Set()
                // Symmetric difference, like an animal.  Swift doesn't allow Hashable tuples; don't fight it.
                for (collection, keyBundle) in staleKeys.collectionKeys {
                    if keyBundle == freshKeys.forCollection(collection) {
                        except.insert(collection)
                    }
                }
                for (collection, keyBundle) in freshKeys.collectionKeys {
                    if keyBundle == staleKeys.forCollection(collection) {
                        except.insert(collection)
                    }
                }
                self.localCommands.insert(.ResetAllEngines(except: except))
            } else {
                // Default bundle is the same.  Reset collections that have changed bulk keys.
                for (collection, keyBundle) in staleKeys.collectionKeys {
                    if keyBundle != freshKeys.forCollection(collection) {
                        self.localCommands.insert(.ResetEngine(engine: collection))
                    }
                }
                for (collection, keyBundle) in freshKeys.collectionKeys {
                    if keyBundle != staleKeys.forCollection(collection) {
                        self.localCommands.insert(.ResetEngine(engine: collection))
                    }
                }
            }
            return self
        }

        public func setKeys(keys: Fetched<Keys>?) -> Builder {
            self.keys = keys
            return self
        }

        public func setGlobal(global: Fetched<MetaGlobal>?) -> Builder {
            self.global = global
            if let global = global {
                // We always take the incoming meta/global's engine configuration.
                self.engineConfiguration = global.value.engineConfiguration()
            }
            return self
        }

        public func setEngineConfiguration(engineConfiguration: EngineConfiguration?) -> Builder {
            self.engineConfiguration = engineConfiguration
            return self
        }

        public func build() -> Scratchpad {
            return Scratchpad(
                    b: self.syncKeyBundle,
                    m: self.global,
                    k: self.keys,
                    keyLabel: self.keyLabel,
                    localCommands: self.localCommands,
                    engines: self.engineConfiguration,
                    clientGUID: self.clientGUID,
                    clientName: self.clientName,
                    persistingTo: self.prefs
            )
        }
    }

    public lazy var backoffStorage: BackoffStorage = {
        return PrefsBackoffStorage(prefs: self.prefs.branch("backoff.storage"))
    }()

    public func evolve() -> Scratchpad.Builder {
        return Scratchpad.Builder(p: self)
    }

    // This is never persisted.
    let syncKeyBundle: KeyBundle

    // Cached records.
    // This cached meta/global is what we use to add or remove enabled engines. See also
    // engineConfiguration, below.
    // We also use it to detect when meta/global hasn't changed -- compare timestamps.
    //
    // Note that a Scratchpad held by a Ready state will have the current server meta/global
    // here. That means we don't need to track syncIDs separately (which is how desktop and
    // Android are implemented).
    // If we don't have a meta/global, and thus we don't know syncIDs, it means we haven't
    // synced with this server before, and we'll do a fresh sync.
    let global: Fetched<MetaGlobal>?

    // We don't store these keys (so-called "collection keys" or "bulk keys") in Prefs.
    // Instead, we store a label, which is seeded when you first create a Scratchpad.
    // This label is used to retrieve the real keys from your Keychain.
    //
    // Note that we also don't store the syncKeyBundle here. That's always created from kB,
    // provided by the Firefox Account.
    //
    // Why don't we derive the label from your Sync Key? Firstly, we'd like to be able to
    // clean up without having your key. Secondly, we don't want to accidentally load keys
    // from the Keychain just because the Sync Key is the same -- e.g., after a node
    // reassignment. Randomly generating a label offers all of the benefits with none of the
    // problems, with only the cost of persisting that label alongside the rest of the state.
    let keys: Fetched<Keys>?
    let keyLabel: String

    // Local commands.
    var localCommands: Set<LocalCommand>

    // Enablement states.
    let engineConfiguration: EngineConfiguration?

    // What's our client name?
    let clientName: String
    let clientGUID: String

    // Where do we persist when told?
    let prefs: Prefs

    init(b: KeyBundle,
         m: Fetched<MetaGlobal>?,
         k: Fetched<Keys>?,
         keyLabel: String,
         localCommands: Set<LocalCommand>,
         engines: EngineConfiguration?,
         clientGUID: String,
         clientName: String,
         persistingTo prefs: Prefs
        ) {
        self.syncKeyBundle = b
        self.prefs = prefs

        self.keys = k
        self.keyLabel = keyLabel
        self.global = m
        self.engineConfiguration = engines
        self.localCommands = localCommands
        self.clientGUID = clientGUID
        self.clientName = clientName
    }

    // This should never be used in the end; we'll unpickle instead.
    // This should be a convenience initializer, but... Swift compiler bug?
    init(b: KeyBundle, persistingTo prefs: Prefs) {
        self.syncKeyBundle = b
        self.prefs = prefs

        self.keys = nil
        self.keyLabel = Bytes.generateGUID()
        self.global = nil
        self.engineConfiguration = nil
        self.localCommands = Set()
        self.clientGUID = Bytes.generateGUID()
        self.clientName = DeviceInfo.defaultClientName()
    }

    func freshStartWithGlobal(global: Fetched<MetaGlobal>) -> Scratchpad {
        // TODO: I *think* a new keyLabel is unnecessary.
        return self.evolve()
                   .setGlobal(global)
                   .addLocalCommandsFromKeys(nil)
                   .setKeys(nil)
                   .build()
    }

    private class func unpickleV1FromPrefs(prefs: Prefs, syncKeyBundle: KeyBundle) -> Scratchpad {
        let b = Scratchpad(b: syncKeyBundle, persistingTo: prefs).evolve()

        if let mg = prefs.stringForKey(PrefGlobal) {
            if let mgTS = prefs.unsignedLongForKey(PrefGlobalTS) {
                if let global = MetaGlobal.fromJSON(JSON.parse(mg)) {
                    b.setGlobal(Fetched(value: global, timestamp: mgTS))
                } else {
                    log.error("Malformed meta/global in prefs. Ignoring.")
                }
            } else {
                // This should never happen.
                log.error("Found global in prefs, but not globalTS!")
            }
        }

        if let keyLabel = prefs.stringForKey(PrefKeyLabel) {
            b.keyLabel = keyLabel
            if let ckTS = prefs.unsignedLongForKey(PrefKeysTS) {
                if let keys = KeychainWrapper.stringForKey("keys." + keyLabel) {
                    // We serialize as JSON.
                    let keys = Keys(payload: KeysPayload(keys))
                    if keys.valid {
                        log.debug("Read keys from Keychain with label \(keyLabel).")
                        b.setKeys(Fetched(value: keys, timestamp: ckTS))
                    } else {
                        log.error("Invalid keys extracted from Keychain. Discarding.")
                    }
                } else {
                    log.error("Found keysTS in prefs, but didn't find keys in Keychain!")
                }
            }
        }

        b.clientGUID = prefs.stringForKey(PrefClientGUID) ?? {
            log.error("No value found in prefs for client GUID! Generating one.")
            return Bytes.generateGUID()
        }()

        b.clientName = prefs.stringForKey(PrefClientName) ?? {
            log.error("No value found in prefs for client name! Using default.")
            return DeviceInfo.defaultClientName()
        }()

        if let localCommands: [String] = prefs.stringArrayForKey(PrefLocalCommands) {
            b.localCommands = Set(localCommands.flatMap({LocalCommand.fromJSON(JSON.parse($0))}))
        }

        if let engineConfigurationString = prefs.stringForKey(PrefEngineConfiguration) {
            if let engineConfiguration = EngineConfiguration.fromJSON(JSON.parse(engineConfigurationString)) {
                b.engineConfiguration = engineConfiguration
            } else {
                log.error("Invalid engineConfiguration found in prefs. Discarding.")
            }
        }

        return b.build()
    }

    /**
     * Remove anything that might be left around after prefs is wiped.
     */
    public class func clearFromPrefs(prefs: Prefs) {
        if let keyLabel = prefs.stringForKey(PrefKeyLabel) {
            log.debug("Removing saved key from keychain.")
            KeychainWrapper.removeObjectForKey(keyLabel)
        } else {
            log.debug("No key label; nothing to remove from keychain.")
        }
    }

    public class func restoreFromPrefs(prefs: Prefs, syncKeyBundle: KeyBundle) -> Scratchpad? {
        if let ver = prefs.intForKey(PrefVersion) {
            switch (ver) {
            case 1:
                return unpickleV1FromPrefs(prefs, syncKeyBundle: syncKeyBundle)
            default:
                return nil
            }
        }

        log.debug("No scratchpad found in prefs.")
        return nil
    }

    /**
     * Persist our current state to our origin prefs.
     * Note that calling this from multiple threads with either mutated or evolved
     * scratchpads will cause sadness — individual writes are thread-safe, but the
     * overall pseudo-transaction is not atomic.
     */
    public func checkpoint() -> Scratchpad {
        return pickle(self.prefs)
    }

    func pickle(prefs: Prefs) -> Scratchpad {
        prefs.setInt(1, forKey: PrefVersion)
        if let global = global {
            prefs.setLong(global.timestamp, forKey: PrefGlobalTS)
            prefs.setString(global.value.asPayload().toString(), forKey: PrefGlobal)
        } else {
            prefs.removeObjectForKey(PrefGlobal)
            prefs.removeObjectForKey(PrefGlobalTS)
        }

        // We store the meat of your keys in the Keychain, using a random identifier that we persist in prefs.
        prefs.setString(self.keyLabel, forKey: PrefKeyLabel)
        if let keys = self.keys {
            let payload = keys.value.asPayload().toString(false)
            let label = "keys." + self.keyLabel
            log.debug("Storing keys in Keychain with label \(label).")
            prefs.setString(self.keyLabel, forKey: PrefKeyLabel)
            prefs.setLong(keys.timestamp, forKey: PrefKeysTS)

            // TODO: I could have sworn that we could specify kSecAttrAccessibleAfterFirstUnlock here.
            KeychainWrapper.setString(payload, forKey: label)
        } else {
            log.debug("Removing keys from Keychain.")
            KeychainWrapper.removeObjectForKey(self.keyLabel)
        }

        prefs.setString(clientName, forKey: PrefClientName)
        prefs.setString(clientGUID, forKey: PrefClientGUID)

        let localCommands: [String] = Array(self.localCommands).map({$0.toJSON().toString()})
        prefs.setObject(localCommands, forKey: PrefLocalCommands)

        if let engineConfiguration = self.engineConfiguration {
            prefs.setString(engineConfiguration.toJSON().toString(), forKey: PrefEngineConfiguration)
        } else {
            prefs.removeObjectForKey(PrefEngineConfiguration)
        }

        return self
    }
}
