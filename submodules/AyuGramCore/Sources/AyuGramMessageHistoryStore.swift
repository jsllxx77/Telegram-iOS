import Foundation

public struct AyuGramMessageHistoryStore: Codable, Equatable {
    public private(set) var editedSnapshots: [AyuGramMessageSnapshot]
    public private(set) var deletedSnapshots: [AyuGramMessageSnapshot]

    public static let empty = AyuGramMessageHistoryStore()

    private enum CodingKeys: String, CodingKey {
        case editedSnapshots
        case deletedSnapshots
    }

    public init(
        editedSnapshots: [AyuGramMessageSnapshot] = [],
        deletedSnapshots: [AyuGramMessageSnapshot] = []
    ) {
        self.editedSnapshots = editedSnapshots
        self.deletedSnapshots = deletedSnapshots
    }

    public mutating func addEditedSnapshot(_ snapshot: AyuGramMessageSnapshot) {
        if !self.editedSnapshots.contains(where: { Self.areEditedSnapshotsEquivalent($0, snapshot) }) {
            self.editedSnapshots.append(snapshot)
        }
    }

    public mutating func addDeletedSnapshot(_ snapshot: AyuGramMessageSnapshot) {
        if let index = self.deletedSnapshots.firstIndex(where: { $0.hasSameMessageIdentity(as: snapshot) }) {
            self.deletedSnapshots[index] = snapshot
        } else {
            self.deletedSnapshots.append(snapshot)
        }
    }

    public func listEditedSnapshots(
        accountPeerId: Int64,
        peerId: Int64,
        messageNamespace: Int32,
        messageId: Int32
    ) -> [AyuGramMessageSnapshot] {
        return self.editedSnapshots.filter { snapshot in
            return snapshot.hasMessageIdentity(
                accountPeerId: accountPeerId,
                peerId: peerId,
                messageNamespace: messageNamespace,
                messageId: messageId
            )
        }.sorted(by: Self.areSnapshotsInAscendingHistoryOrder)
    }

    public func listDeletedSnapshots(
        accountPeerId: Int64,
        peerId: Int64,
        searchQuery: String? = nil
    ) -> [AyuGramMessageSnapshot] {
        return self.filteredDeletedSnapshots(
            accountPeerId: accountPeerId,
            peerId: peerId,
            searchQuery: searchQuery,
            threadMatches: { _ in true }
        )
    }

    public func listDeletedSnapshotsInThread(
        accountPeerId: Int64,
        peerId: Int64,
        threadId: Int64,
        searchQuery: String? = nil
    ) -> [AyuGramMessageSnapshot] {
        return self.filteredDeletedSnapshots(
            accountPeerId: accountPeerId,
            peerId: peerId,
            searchQuery: searchQuery,
            threadMatches: { snapshot in snapshot.threadId == threadId }
        )
    }

    public func listDeletedSnapshotsWithoutThread(
        accountPeerId: Int64,
        peerId: Int64,
        searchQuery: String? = nil
    ) -> [AyuGramMessageSnapshot] {
        return self.filteredDeletedSnapshots(
            accountPeerId: accountPeerId,
            peerId: peerId,
            searchQuery: searchQuery,
            threadMatches: { snapshot in snapshot.threadId == nil }
        )
    }

    @discardableResult
    public mutating func clearDeletedSnapshots(
        accountPeerId: Int64,
        peerId: Int64
    ) -> Int {
        return self.removeDeletedSnapshots { snapshot in
            return snapshot.accountPeerId == accountPeerId && snapshot.peerId == peerId
        }
    }

    @discardableResult
    public mutating func clearDeletedSnapshotsInThread(
        accountPeerId: Int64,
        peerId: Int64,
        threadId: Int64
    ) -> Int {
        return self.removeDeletedSnapshots { snapshot in
            return snapshot.accountPeerId == accountPeerId
                && snapshot.peerId == peerId
                && snapshot.threadId == threadId
        }
    }

    @discardableResult
    public mutating func clearDeletedSnapshotsWithoutThread(
        accountPeerId: Int64,
        peerId: Int64
    ) -> Int {
        return self.removeDeletedSnapshots { snapshot in
            return snapshot.accountPeerId == accountPeerId
                && snapshot.peerId == peerId
                && snapshot.threadId == nil
        }
    }

    @discardableResult
    public mutating func removeDeletedSnapshot(
        accountPeerId: Int64,
        peerId: Int64,
        messageNamespace: Int32,
        messageId: Int32
    ) -> Bool {
        return self.removeDeletedSnapshots { snapshot in
            return snapshot.hasMessageIdentity(
                accountPeerId: accountPeerId,
                peerId: peerId,
                messageNamespace: messageNamespace,
                messageId: messageId
            )
        } != 0
    }

    private func filteredDeletedSnapshots(
        accountPeerId: Int64,
        peerId: Int64,
        searchQuery: String?,
        threadMatches: (AyuGramMessageSnapshot) -> Bool
    ) -> [AyuGramMessageSnapshot] {
        let normalizedSearchQuery = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return self.deletedSnapshots.filter { snapshot in
            if snapshot.accountPeerId != accountPeerId || snapshot.peerId != peerId || !threadMatches(snapshot) {
                return false
            }
            if let normalizedSearchQuery = normalizedSearchQuery, !normalizedSearchQuery.isEmpty {
                return snapshot.text.lowercased().contains(normalizedSearchQuery)
            }
            return true
        }.sorted(by: Self.areSnapshotsInDescendingHistoryOrder)
    }

    private mutating func removeDeletedSnapshots(_ shouldRemove: (AyuGramMessageSnapshot) -> Bool) -> Int {
        let previousCount = self.deletedSnapshots.count
        self.deletedSnapshots.removeAll { snapshot in
            return shouldRemove(snapshot)
        }
        return previousCount - self.deletedSnapshots.count
    }

    private static func areEditedSnapshotsEquivalent(_ lhs: AyuGramMessageSnapshot, _ rhs: AyuGramMessageSnapshot) -> Bool {
        return lhs.hasSameMessageIdentity(as: rhs)
            && lhs.threadId == rhs.threadId
            && lhs.stableId == rhs.stableId
            && lhs.authorPeerId == rhs.authorPeerId
            && lhs.timestamp == rhs.timestamp
            && lhs.editTimestamp == rhs.editTimestamp
            && lhs.text == rhs.text
            && lhs.entitiesData == rhs.entitiesData
            && lhs.forwardInfoData == rhs.forwardInfoData
            && lhs.mediaSummary == rhs.mediaSummary
            && lhs.mediaKind == rhs.mediaKind
            && lhs.mediaResourceId == rhs.mediaResourceId
            && lhs.mediaThumbnailResourceId == rhs.mediaThumbnailResourceId
            && lhs.mediaMimeType == rhs.mediaMimeType
            && lhs.mediaFileName == rhs.mediaFileName
            && lhs.mediaDuration == rhs.mediaDuration
            && lhs.mediaDimensions == rhs.mediaDimensions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.editedSnapshots = container.decodeIfPresent([AyuGramMessageSnapshot].self, forKey: .editedSnapshots, fallback: [])
        self.deletedSnapshots = container.decodeIfPresent([AyuGramMessageSnapshot].self, forKey: .deletedSnapshots, fallback: [])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.editedSnapshots, forKey: .editedSnapshots)
        try container.encode(self.deletedSnapshots, forKey: .deletedSnapshots)
    }

    private static func areSnapshotsInAscendingHistoryOrder(
        _ lhs: AyuGramMessageSnapshot,
        _ rhs: AyuGramMessageSnapshot
    ) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        if lhs.accountPeerId != rhs.accountPeerId {
            return lhs.accountPeerId < rhs.accountPeerId
        }
        if lhs.peerId != rhs.peerId {
            return lhs.peerId < rhs.peerId
        }
        if lhs.threadId != rhs.threadId {
            return Self.isOptionalInt64Ascending(lhs.threadId, rhs.threadId)
        }
        if lhs.editTimestamp != rhs.editTimestamp {
            return Self.isOptionalInt32Ascending(lhs.editTimestamp, rhs.editTimestamp)
        }
        if lhs.timestamp != rhs.timestamp {
            return lhs.timestamp < rhs.timestamp
        }
        if lhs.messageNamespace != rhs.messageNamespace {
            return lhs.messageNamespace < rhs.messageNamespace
        }
        if lhs.messageId != rhs.messageId {
            return lhs.messageId < rhs.messageId
        }
        if lhs.stableId != rhs.stableId {
            return Self.isOptionalInt64Ascending(lhs.stableId, rhs.stableId)
        }
        if lhs.authorPeerId != rhs.authorPeerId {
            return Self.isOptionalInt64Ascending(lhs.authorPeerId, rhs.authorPeerId)
        }
        if lhs.text != rhs.text {
            return lhs.text < rhs.text
        }
        if lhs.entitiesData != rhs.entitiesData {
            return Self.optionalDataSortKey(lhs.entitiesData) < Self.optionalDataSortKey(rhs.entitiesData)
        }
        if lhs.views != rhs.views {
            return Self.isOptionalInt32Ascending(lhs.views, rhs.views)
        }
        if lhs.forwardInfoData != rhs.forwardInfoData {
            return Self.optionalDataSortKey(lhs.forwardInfoData) < Self.optionalDataSortKey(rhs.forwardInfoData)
        }
        if lhs.mediaSummary != rhs.mediaSummary {
            return Self.optionalStringSortKey(lhs.mediaSummary) < Self.optionalStringSortKey(rhs.mediaSummary)
        }
        if lhs.mediaKind != rhs.mediaKind {
            return Self.optionalStringSortKey(lhs.mediaKind) < Self.optionalStringSortKey(rhs.mediaKind)
        }
        if lhs.mediaResourceId != rhs.mediaResourceId {
            return Self.optionalStringSortKey(lhs.mediaResourceId) < Self.optionalStringSortKey(rhs.mediaResourceId)
        }
        if lhs.mediaThumbnailResourceId != rhs.mediaThumbnailResourceId {
            return Self.optionalStringSortKey(lhs.mediaThumbnailResourceId) < Self.optionalStringSortKey(rhs.mediaThumbnailResourceId)
        }
        if lhs.mediaMimeType != rhs.mediaMimeType {
            return Self.optionalStringSortKey(lhs.mediaMimeType) < Self.optionalStringSortKey(rhs.mediaMimeType)
        }
        if lhs.mediaFileName != rhs.mediaFileName {
            return Self.optionalStringSortKey(lhs.mediaFileName) < Self.optionalStringSortKey(rhs.mediaFileName)
        }
        if lhs.mediaDuration != rhs.mediaDuration {
            return Self.isOptionalDoubleAscending(lhs.mediaDuration, rhs.mediaDuration)
        }
        return Self.optionalStringSortKey(lhs.mediaDimensions) < Self.optionalStringSortKey(rhs.mediaDimensions)
    }

    private static func areSnapshotsInDescendingHistoryOrder(
        _ lhs: AyuGramMessageSnapshot,
        _ rhs: AyuGramMessageSnapshot
    ) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }
        if lhs.accountPeerId != rhs.accountPeerId {
            return lhs.accountPeerId > rhs.accountPeerId
        }
        if lhs.peerId != rhs.peerId {
            return lhs.peerId > rhs.peerId
        }
        if lhs.threadId != rhs.threadId {
            return Self.isOptionalInt64Descending(lhs.threadId, rhs.threadId)
        }
        if lhs.editTimestamp != rhs.editTimestamp {
            return Self.isOptionalInt32Descending(lhs.editTimestamp, rhs.editTimestamp)
        }
        if lhs.timestamp != rhs.timestamp {
            return lhs.timestamp > rhs.timestamp
        }
        if lhs.messageNamespace != rhs.messageNamespace {
            return lhs.messageNamespace > rhs.messageNamespace
        }
        if lhs.messageId != rhs.messageId {
            return lhs.messageId > rhs.messageId
        }
        if lhs.stableId != rhs.stableId {
            return Self.isOptionalInt64Descending(lhs.stableId, rhs.stableId)
        }
        if lhs.authorPeerId != rhs.authorPeerId {
            return Self.isOptionalInt64Descending(lhs.authorPeerId, rhs.authorPeerId)
        }
        if lhs.text != rhs.text {
            return lhs.text > rhs.text
        }
        if lhs.entitiesData != rhs.entitiesData {
            return Self.optionalDataSortKey(lhs.entitiesData) > Self.optionalDataSortKey(rhs.entitiesData)
        }
        if lhs.views != rhs.views {
            return Self.isOptionalInt32Descending(lhs.views, rhs.views)
        }
        if lhs.forwardInfoData != rhs.forwardInfoData {
            return Self.optionalDataSortKey(lhs.forwardInfoData) > Self.optionalDataSortKey(rhs.forwardInfoData)
        }
        if lhs.mediaSummary != rhs.mediaSummary {
            return Self.optionalStringSortKey(lhs.mediaSummary) > Self.optionalStringSortKey(rhs.mediaSummary)
        }
        if lhs.mediaKind != rhs.mediaKind {
            return Self.optionalStringSortKey(lhs.mediaKind) > Self.optionalStringSortKey(rhs.mediaKind)
        }
        if lhs.mediaResourceId != rhs.mediaResourceId {
            return Self.optionalStringSortKey(lhs.mediaResourceId) > Self.optionalStringSortKey(rhs.mediaResourceId)
        }
        if lhs.mediaThumbnailResourceId != rhs.mediaThumbnailResourceId {
            return Self.optionalStringSortKey(lhs.mediaThumbnailResourceId) > Self.optionalStringSortKey(rhs.mediaThumbnailResourceId)
        }
        if lhs.mediaMimeType != rhs.mediaMimeType {
            return Self.optionalStringSortKey(lhs.mediaMimeType) > Self.optionalStringSortKey(rhs.mediaMimeType)
        }
        if lhs.mediaFileName != rhs.mediaFileName {
            return Self.optionalStringSortKey(lhs.mediaFileName) > Self.optionalStringSortKey(rhs.mediaFileName)
        }
        if lhs.mediaDuration != rhs.mediaDuration {
            return Self.isOptionalDoubleDescending(lhs.mediaDuration, rhs.mediaDuration)
        }
        return Self.optionalStringSortKey(lhs.mediaDimensions) > Self.optionalStringSortKey(rhs.mediaDimensions)
    }

    private static func optionalDataSortKey(_ data: Data?) -> String {
        if let data = data {
            return "1:" + data.base64EncodedString()
        }
        return "0:"
    }

    private static func optionalStringSortKey(_ value: String?) -> String {
        if let value = value {
            return "1:" + value
        }
        return "0:"
    }

    private static func isOptionalInt32Ascending(_ lhs: Int32?, _ rhs: Int32?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return false
        case (nil, _?):
            return true
        case (_?, nil):
            return false
        case let (lhs?, rhs?):
            return lhs < rhs
        }
    }

    private static func isOptionalInt32Descending(_ lhs: Int32?, _ rhs: Int32?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return false
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case let (lhs?, rhs?):
            return lhs > rhs
        }
    }

    private static func isOptionalInt64Ascending(_ lhs: Int64?, _ rhs: Int64?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return false
        case (nil, _?):
            return true
        case (_?, nil):
            return false
        case let (lhs?, rhs?):
            return lhs < rhs
        }
    }

    private static func isOptionalInt64Descending(_ lhs: Int64?, _ rhs: Int64?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return false
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case let (lhs?, rhs?):
            return lhs > rhs
        }
    }

    private static func isOptionalDoubleAscending(_ lhs: Double?, _ rhs: Double?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return false
        case (nil, _?):
            return true
        case (_?, nil):
            return false
        case let (lhs?, rhs?):
            return lhs < rhs
        }
    }

    private static func isOptionalDoubleDescending(_ lhs: Double?, _ rhs: Double?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return false
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case let (lhs?, rhs?):
            return lhs > rhs
        }
    }
}
