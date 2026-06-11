import XCTest
import AyuGramCore

final class AyuGramMessageHistoryStoreTests: XCTestCase {
    func testSnapshotCodablePreservesMediaMetadata() throws {
        let snapshot = self.makeSnapshot(
            accountPeerId: 1,
            peerId: 2,
            messageId: 10,
            text: "photo",
            globallyUniqueId: 111,
            groupingKey: 222,
            mediaKind: "image",
            mediaResourceId: "telegram-cloud-photo-size-1-2-x",
            mediaThumbnailResourceId: "telegram-cloud-photo-size-1-2-m",
            mediaMimeType: "image/jpeg",
            mediaFileName: "photo.jpg",
            mediaDuration: 12.5,
            mediaDimensions: "1280x720",
            mediaResourceLocalPath: "/app/ayu/primary.jpg",
            mediaThumbnailLocalPath: "/app/ayu/thumb.jpg",
            forwardAuthorPeerId: 3,
            forwardSourcePeerId: 4,
            forwardSourceMessageNamespace: 0,
            forwardSourceMessageId: 5,
            forwardDate: 999,
            forwardAuthorSignature: "channel",
            forwardPsaType: "psa",
            forwardFlags: 1,
            replyMessagePeerId: 6,
            replyMessageNamespace: 0,
            replyMessageId: 7,
            replyThreadMessagePeerId: 8,
            replyThreadMessageNamespace: 0,
            replyThreadMessageId: 9,
            replyIsQuote: true
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(AyuGramMessageSnapshot.self, from: data)

        XCTAssertEqual(decoded.globallyUniqueId, 111)
        XCTAssertEqual(decoded.groupingKey, 222)
        XCTAssertEqual(decoded.mediaKind, "image")
        XCTAssertEqual(decoded.mediaResourceId, "telegram-cloud-photo-size-1-2-x")
        XCTAssertEqual(decoded.mediaThumbnailResourceId, "telegram-cloud-photo-size-1-2-m")
        XCTAssertEqual(decoded.mediaMimeType, "image/jpeg")
        XCTAssertEqual(decoded.mediaFileName, "photo.jpg")
        XCTAssertEqual(decoded.mediaDuration, 12.5)
        XCTAssertEqual(decoded.mediaDimensions, "1280x720")
        XCTAssertEqual(decoded.mediaResourceLocalPath, "/app/ayu/primary.jpg")
        XCTAssertEqual(decoded.mediaThumbnailLocalPath, "/app/ayu/thumb.jpg")
        XCTAssertEqual(decoded.forwardAuthorPeerId, 3)
        XCTAssertEqual(decoded.forwardSourcePeerId, 4)
        XCTAssertEqual(decoded.forwardSourceMessageNamespace, 0)
        XCTAssertEqual(decoded.forwardSourceMessageId, 5)
        XCTAssertEqual(decoded.forwardDate, 999)
        XCTAssertEqual(decoded.forwardAuthorSignature, "channel")
        XCTAssertEqual(decoded.forwardPsaType, "psa")
        XCTAssertEqual(decoded.forwardFlags, 1)
        XCTAssertEqual(decoded.replyMessagePeerId, 6)
        XCTAssertEqual(decoded.replyMessageNamespace, 0)
        XCTAssertEqual(decoded.replyMessageId, 7)
        XCTAssertEqual(decoded.replyThreadMessagePeerId, 8)
        XCTAssertEqual(decoded.replyThreadMessageNamespace, 0)
        XCTAssertEqual(decoded.replyThreadMessageId, 9)
        XCTAssertEqual(decoded.replyIsQuote, true)
    }

    func testSnapshotCodableDefaultsMissingMediaMetadataToNil() throws {
        let data = Data("""
        {
            "accountPeerId": 1,
            "peerId": 2,
            "messageNamespace": 0,
            "messageId": 10,
            "timestamp": 1000,
            "text": "legacy",
            "createdAt": 1001
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(AyuGramMessageSnapshot.self, from: data)

        XCTAssertNil(decoded.mediaKind)
        XCTAssertNil(decoded.mediaResourceId)
        XCTAssertNil(decoded.mediaThumbnailResourceId)
        XCTAssertNil(decoded.mediaMimeType)
        XCTAssertNil(decoded.mediaFileName)
        XCTAssertNil(decoded.mediaDuration)
        XCTAssertNil(decoded.mediaDimensions)
        XCTAssertNil(decoded.mediaResourceLocalPath)
        XCTAssertNil(decoded.mediaThumbnailLocalPath)
        XCTAssertNil(decoded.globallyUniqueId)
        XCTAssertNil(decoded.groupingKey)
        XCTAssertNil(decoded.forwardAuthorPeerId)
        XCTAssertNil(decoded.forwardSourcePeerId)
        XCTAssertNil(decoded.forwardSourceMessageNamespace)
        XCTAssertNil(decoded.forwardSourceMessageId)
        XCTAssertNil(decoded.forwardDate)
        XCTAssertNil(decoded.forwardAuthorSignature)
        XCTAssertNil(decoded.forwardPsaType)
        XCTAssertNil(decoded.forwardFlags)
        XCTAssertNil(decoded.replyMessagePeerId)
        XCTAssertNil(decoded.replyMessageNamespace)
        XCTAssertNil(decoded.replyMessageId)
        XCTAssertNil(decoded.replyThreadMessagePeerId)
        XCTAssertNil(decoded.replyThreadMessageNamespace)
        XCTAssertNil(decoded.replyThreadMessageId)
        XCTAssertNil(decoded.replyIsQuote)
    }

    func testRemoveDeletedSnapshotRemovesOnlyMatchingMessageIdentity() {
        var store = AyuGramMessageHistoryStore()
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 10, text: "remove"))
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 11, text: "keep"))
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 3, messageId: 10, text: "other peer"))

        XCTAssertTrue(store.removeDeletedSnapshot(accountPeerId: 1, peerId: 2, messageNamespace: 0, messageId: 10))

        XCTAssertEqual(
            store.listDeletedSnapshots(accountPeerId: 1, peerId: 2).map(\.messageId),
            [11]
        )
        XCTAssertEqual(
            store.listDeletedSnapshots(accountPeerId: 1, peerId: 3).map(\.messageId),
            [10]
        )
    }

    func testRemoveDeletedSnapshotReportsMissingRecord() {
        var store = AyuGramMessageHistoryStore()
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 10, text: "keep"))

        XCTAssertFalse(store.removeDeletedSnapshot(accountPeerId: 1, peerId: 2, messageNamespace: 0, messageId: 99))
        XCTAssertEqual(store.listDeletedSnapshots(accountPeerId: 1, peerId: 2).map(\.messageId), [10])
    }

    func testDeletedSnapshotsSearchMatchesMediaSummaryAndFileName() {
        var store = AyuGramMessageHistoryStore()
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 10, text: "", mediaSummary: "TelegramMediaImage"))
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 11, text: "", mediaFileName: "invoice.pdf"))
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 12, text: "plain text"))

        XCTAssertEqual(store.listDeletedSnapshots(accountPeerId: 1, peerId: 2, searchQuery: "image").map(\.messageId), [10])
        XCTAssertEqual(store.listDeletedSnapshots(accountPeerId: 1, peerId: 2, searchQuery: "invoice").map(\.messageId), [11])
    }

    func testDeletedSnapshotsPaginationUsesDescendingHistoryOrder() {
        var store = AyuGramMessageHistoryStore()
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 10, text: "old"))
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 11, text: "middle"))
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 12, text: "new"))

        let page = store.listDeletedSnapshots(accountPeerId: 1, peerId: 2, offset: 1, limit: 1)

        XCTAssertEqual(page.map(\.messageId), [11])
    }

    func testDeletedSnapshotLimitEvictsOldestSnapshots() {
        var store = AyuGramMessageHistoryStore()
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 10, text: "old"), limit: 2)
        store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 11, text: "middle"), limit: 2)
        let evicted = store.addDeletedSnapshot(self.makeSnapshot(accountPeerId: 1, peerId: 2, messageId: 12, text: "new"), limit: 2)

        XCTAssertEqual(evicted.map(\.messageId), [10])
        XCTAssertEqual(store.listDeletedSnapshots(accountPeerId: 1, peerId: 2).map(\.messageId), [12, 11])
    }

    private func makeSnapshot(
        accountPeerId: Int64,
        peerId: Int64,
        messageId: Int32,
        text: String,
        mediaSummary: String? = nil,
        globallyUniqueId: Int64? = nil,
        groupingKey: Int64? = nil,
        mediaKind: String? = nil,
        mediaResourceId: String? = nil,
        mediaThumbnailResourceId: String? = nil,
        mediaMimeType: String? = nil,
        mediaFileName: String? = nil,
        mediaDuration: Double? = nil,
        mediaDimensions: String? = nil,
        mediaResourceLocalPath: String? = nil,
        mediaThumbnailLocalPath: String? = nil,
        forwardAuthorPeerId: Int64? = nil,
        forwardSourcePeerId: Int64? = nil,
        forwardSourceMessageNamespace: Int32? = nil,
        forwardSourceMessageId: Int32? = nil,
        forwardDate: Int32? = nil,
        forwardAuthorSignature: String? = nil,
        forwardPsaType: String? = nil,
        forwardFlags: Int32? = nil,
        replyMessagePeerId: Int64? = nil,
        replyMessageNamespace: Int32? = nil,
        replyMessageId: Int32? = nil,
        replyThreadMessagePeerId: Int64? = nil,
        replyThreadMessageNamespace: Int32? = nil,
        replyThreadMessageId: Int32? = nil,
        replyIsQuote: Bool? = nil
    ) -> AyuGramMessageSnapshot {
        return AyuGramMessageSnapshot(
            accountPeerId: accountPeerId,
            peerId: peerId,
            threadId: nil,
            messageNamespace: 0,
            messageId: messageId,
            stableId: Int64(messageId),
            globallyUniqueId: globallyUniqueId,
            groupingKey: groupingKey,
            authorPeerId: 3,
            timestamp: 1000 + messageId,
            editTimestamp: nil,
            text: text,
            entitiesData: nil,
            views: nil,
            forwardInfoData: nil,
            mediaSummary: mediaSummary,
            mediaKind: mediaKind,
            mediaResourceId: mediaResourceId,
            mediaThumbnailResourceId: mediaThumbnailResourceId,
            mediaMimeType: mediaMimeType,
            mediaFileName: mediaFileName,
            mediaDuration: mediaDuration,
            mediaDimensions: mediaDimensions,
            mediaResourceLocalPath: mediaResourceLocalPath,
            mediaThumbnailLocalPath: mediaThumbnailLocalPath,
            forwardAuthorPeerId: forwardAuthorPeerId,
            forwardSourcePeerId: forwardSourcePeerId,
            forwardSourceMessageNamespace: forwardSourceMessageNamespace,
            forwardSourceMessageId: forwardSourceMessageId,
            forwardDate: forwardDate,
            forwardAuthorSignature: forwardAuthorSignature,
            forwardPsaType: forwardPsaType,
            forwardFlags: forwardFlags,
            replyMessagePeerId: replyMessagePeerId,
            replyMessageNamespace: replyMessageNamespace,
            replyMessageId: replyMessageId,
            replyThreadMessagePeerId: replyThreadMessagePeerId,
            replyThreadMessageNamespace: replyThreadMessageNamespace,
            replyThreadMessageId: replyThreadMessageId,
            replyIsQuote: replyIsQuote,
            createdAt: 1000 + messageId
        )
    }
}
