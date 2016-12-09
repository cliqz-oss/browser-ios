/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared

private let log = Logger.syncLogger

private class CachedSource {
    // We track not just mappings between values and non-nil items, but also whether we've tried
    // to look up a value at all. This allows us to distinguish between a cache miss and a
    // cache hit that didn't find an item in the backing store.
    // We expect, given our prefetching, that cache misses will be rare.
    private var cache: [GUID: BookmarkMirrorItem] = [:]
    private var seen: Set<GUID> = Set()

    subscript(guid: GUID) -> BookmarkMirrorItem? {
        get {
            return self.cache[guid]
        }

        set(value) {
            self.cache[guid] = value
        }
    }

    func lookup(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>? {
        guard self.seen.contains(guid) else {
            log.warning("Cache miss for \(guid).")
            return nil
        }

        guard let found = self.cache[guid] else {
            log.verbose("Cache hit, but no record found for \(guid).")
            return deferMaybe(NoSuchRecordError(guid: guid))
        }

        log.verbose("Cache hit for \(guid).")
        return deferMaybe(found)
    }

    var isEmpty: Bool {
        return self.cache.isEmpty
    }

    // fill and seen are separate: we won't find every item in the DB.
    func fill(items: [GUID: BookmarkMirrorItem]) -> Success {
        for (x, y) in items {
            self.cache[x] = y
        }
        return succeed()
    }

    func markSeen(guid: GUID) {
        self.seen.insert(guid)
    }

    func markSeen<T: CollectionType where T.Generator.Element == GUID>(guids: T) {
        self.seen.unionInPlace(guids)
    }

    func takingGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> {
        var out: [GUID: BookmarkMirrorItem] = [:]
        guids.forEach {
            if let v = self.cache[$0] {
                out[$0] = v
            }
        }
        return deferMaybe(out)
    }
}

// Sorry about the boilerplate.
// These are separate protocols so that the method names don't collide when implemented
// by the same class, but that means extracting more base implementation is more trouble than
// it's worth.
public class CachingLocalItemSource: LocalItemSource {
    private let cache: CachedSource
    private let source: LocalItemSource

    public init(source: LocalItemSource) {
        self.cache = CachedSource()
        self.source = source
    }

    public func getLocalItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        if let found = self.cache.lookup(guid) {
            return found
        }

        return self.source.getLocalItemWithGUID(guid) >>== effect {
            self.cache.markSeen(guid)
            self.cache[guid] = $0
        }
    }

    public func getLocalItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> {
        return self.prefetchLocalItemsWithGUIDs(guids) >>> { self.cache.takingGUIDs(guids) }
    }

    public func prefetchLocalItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success {
        log.debug("Prefetching \(guids.count) local items: \(guids.prefix(10))….")
        if guids.isEmpty {
            return succeed()
        }

        return self.source.getLocalItemsWithGUIDs(guids) >>== {
            self.cache.markSeen(guids)
            return self.cache.fill($0)
        }
    }
}

public class CachingMirrorItemSource: MirrorItemSource {
    private let cache: CachedSource
    private let source: MirrorItemSource

    public init(source: MirrorItemSource) {
        self.cache = CachedSource()
        self.source = source
    }

    public func getMirrorItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        if let found = self.cache.lookup(guid) {
            return found
        }

        return self.source.getMirrorItemWithGUID(guid) >>== effect {
            self.cache.markSeen(guid)
            self.cache[guid] = $0
        }
    }

    public func getMirrorItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> {
        return self.prefetchMirrorItemsWithGUIDs(guids) >>> { self.cache.takingGUIDs(guids) }
    }

    public func prefetchMirrorItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success {
        log.debug("Prefetching \(guids.count) mirror items: \(guids.prefix(10))….")
        if guids.isEmpty {
            return succeed()
        }

        return self.source.getMirrorItemsWithGUIDs(guids) >>== {
            self.cache.markSeen(guids)
            return self.cache.fill($0)
        }
    }
}

public class CachingBufferItemSource: BufferItemSource {
    private let cache: CachedSource
    private let source: BufferItemSource

    public init(source: BufferItemSource) {
        self.cache = CachedSource()
        self.source = source
    }

    public func getBufferItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        if let found = self.cache.lookup(guid) {
            return found
        }

        return self.source.getBufferItemWithGUID(guid) >>== effect {
            self.cache.markSeen(guid)
            self.cache[guid] = $0
        }
    }

    public func getBufferItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> {
        return self.prefetchBufferItemsWithGUIDs(guids) >>> { self.cache.takingGUIDs(guids) }
    }

    public func prefetchBufferItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success {
        log.debug("Prefetching \(guids.count) buffer items: \(guids.prefix(10))….")
        if guids.isEmpty {
            return succeed()
        }

        return self.source.getBufferItemsWithGUIDs(guids) >>== {
            self.cache.markSeen(guids)
            return self.cache.fill($0)
        }
    }
}