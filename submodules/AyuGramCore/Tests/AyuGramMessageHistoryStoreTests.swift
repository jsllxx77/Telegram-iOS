import XCTest
import AyuGramCore

final class AyuGramMessageHistoryStoreTests: XCTestCase {
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
        text: String
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
            createdAt: 1000 + messageId
        )
    }
}
