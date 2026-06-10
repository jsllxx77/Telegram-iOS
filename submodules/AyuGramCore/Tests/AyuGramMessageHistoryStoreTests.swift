import XCTest
import AyuGramCore

final class AyuGramMessageHistoryStoreTests: XCTestCase {
    func testSnapshotCodablePreservesMediaMetadata() throws {
        let snapshot = self.makeSnapshot(
            accountPeerId: 1,
            peerId: 2,
            messageId: 10,
            text: "photo",
            mediaKind: "image",
            mediaResourceId: "telegram-cloud-photo-size-1-2-x",
            mediaThumbnailResourceId: "telegram-cloud-photo-size-1-2-m",
            mediaMimeType: "image/jpeg",
            mediaFileName: "photo.jpg",
            mediaDuration: 12.5,
            mediaDimensions: "1280x720"
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(AyuGramMessageSnapshot.self, from: data)

        XCTAssertEqual(decoded.mediaKind, "image")
        XCTAssertEqual(decoded.mediaResourceId, "telegram-cloud-photo-size-1-2-x")
        XCTAssertEqual(decoded.mediaThumbnailResourceId, "telegram-cloud-photo-size-1-2-m")
        XCTAssertEqual(decoded.mediaMimeType, "image/jpeg")
        XCTAssertEqual(decoded.mediaFileName, "photo.jpg")
        XCTAssertEqual(decoded.mediaDuration, 12.5)
        XCTAssertEqual(decoded.mediaDimensions, "1280x720")
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

    private func makeSnapshot(
        accountPeerId: Int64,
        peerId: Int64,
        messageId: Int32,
        text: String,
        mediaKind: String? = nil,
        mediaResourceId: String? = nil,
        mediaThumbnailResourceId: String? = nil,
        mediaMimeType: String? = nil,
        mediaFileName: String? = nil,
        mediaDuration: Double? = nil,
        mediaDimensions: String? = nil
    ) -> AyuGramMessageSnapshot {
        return AyuGramMessageSnapshot(
            accountPeerId: accountPeerId,
            peerId: peerId,
            threadId: nil,
            messageNamespace: 0,
            messageId: messageId,
            stableId: Int64(messageId),
            authorPeerId: 3,
            timestamp: 1000 + messageId,
            editTimestamp: nil,
            text: text,
            entitiesData: nil,
            views: nil,
            forwardInfoData: nil,
            mediaSummary: nil,
            mediaKind: mediaKind,
            mediaResourceId: mediaResourceId,
            mediaThumbnailResourceId: mediaThumbnailResourceId,
            mediaMimeType: mediaMimeType,
            mediaFileName: mediaFileName,
            mediaDuration: mediaDuration,
            mediaDimensions: mediaDimensions,
            createdAt: 1000 + messageId
        )
    }
}
