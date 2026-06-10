import XCTest
import AyuGramCore

final class AyuGramDeletedBubbleRenderingTests: XCTestCase {
    func testSyntheticLocalMessageIdIsDeterministicAndNegative() {
        let snapshot = self.makeSnapshot(messageId: 123, stableId: 456, text: "hello")

        XCTAssertEqual(
            ayuGramDeletedBubbleLocalMessageId(snapshot),
            ayuGramDeletedBubbleLocalMessageId(snapshot)
        )
        XCTAssertLessThan(ayuGramDeletedBubbleLocalMessageId(snapshot), 0)
    }

    func testDifferentSnapshotsUseDifferentLocalIds() {
        let first = self.makeSnapshot(messageId: 123, stableId: 456, text: "hello")
        let second = self.makeSnapshot(messageId: 124, stableId: 457, text: "hello")

        XCTAssertNotEqual(
            ayuGramDeletedBubbleLocalMessageId(first),
            ayuGramDeletedBubbleLocalMessageId(second)
        )
        XCTAssertNotEqual(
            ayuGramDeletedBubbleStableId(first),
            ayuGramDeletedBubbleStableId(second)
        )
    }

    func testDisplayTextCombinesDeletedMarkerTextAndMediaSummary() {
        let snapshot = self.makeSnapshot(messageId: 123, stableId: 456, text: "hello", mediaSummary: "Photo")

        XCTAssertEqual(
            ayuGramDeletedBubbleDisplayText(snapshot: snapshot, deletedMark: "Deleted", fallbackDeletedMark: "Deleted"),
            "Deleted\nhello\n[Photo]"
        )
    }

    func testDisplayTextUsesFallbackMarkerForBlankCustomMarker() {
        let snapshot = self.makeSnapshot(messageId: 123, stableId: 456, text: "", mediaSummary: "Video")

        XCTAssertEqual(
            ayuGramDeletedBubbleDisplayText(snapshot: snapshot, deletedMark: "   ", fallbackDeletedMark: "Deleted"),
            "Deleted\n[Video]"
        )
    }

    private func makeSnapshot(
        messageId: Int32,
        stableId: Int64?,
        text: String,
        mediaSummary: String? = nil
    ) -> AyuGramMessageSnapshot {
        return AyuGramMessageSnapshot(
            accountPeerId: 1,
            peerId: 2,
            threadId: nil,
            messageNamespace: 0,
            messageId: messageId,
            stableId: stableId,
            authorPeerId: 3,
            timestamp: 1000,
            editTimestamp: nil,
            text: text,
            entitiesData: nil,
            views: nil,
            forwardInfoData: nil,
            mediaSummary: mediaSummary,
            createdAt: 1001
        )
    }
}
