import XCTest
import AyuGramCore

final class AyuGramFilterEngineTests: XCTestCase {
    func testNormalRegexMatch() {
        let filter = AyuGramFilter(text: "hello")

        XCTAssertTrue(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "well hello there")))
        XCTAssertFalse(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "well hi there")))
    }

    func testReversedMatch() {
        let filter = AyuGramFilter(text: "spam", reversed: true)

        XCTAssertFalse(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "spam message")))
        XCTAssertTrue(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "ordinary message")))
    }

    func testCaseInsensitiveMatch() {
        let insensitiveFilter = AyuGramFilter(text: "hello", caseInsensitive: true)
        let sensitiveFilter = AyuGramFilter(text: "hello", caseInsensitive: false)

        XCTAssertTrue(ayuGramFilterMatches(insensitiveFilter, input: AyuGramFilterMatchInput(text: "HELLO")))
        XCTAssertFalse(ayuGramFilterMatches(sensitiveFilter, input: AyuGramFilterMatchInput(text: "HELLO")))
    }

    func testDisabledFilterDoesNotMatch() {
        let filter = AyuGramFilter(text: "hello", enabled: false)

        XCTAssertFalse(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "hello")))
    }

    func testPerDialogFilterOnlyMatchesSpecifiedDialog() {
        let filter = AyuGramFilter(text: "hello", dialogId: 42)

        XCTAssertTrue(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "hello", dialogId: 42)))
        XCTAssertFalse(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "hello", dialogId: 24)))
        XCTAssertFalse(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "hello", dialogId: nil)))
    }

    func testGlobalFilterExclusions() {
        let filter = AyuGramFilter(text: "hello", exclusions: Set([42]))

        XCTAssertFalse(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "hello", dialogId: 42)))
        XCTAssertTrue(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "hello", dialogId: 24)))
        XCTAssertTrue(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "hello", dialogId: nil)))
    }

    func testInvalidRegexDoesNotMatch() {
        let filter = AyuGramFilter(text: "[")

        XCTAssertFalse(ayuGramFilterMatches(filter, input: AyuGramFilterMatchInput(text: "[")))
    }

    func testMatchingFiltersAndShouldHideMessage() {
        let matchingFilter = AyuGramFilter(id: "match", text: "hello")
        let nonMatchingFilter = AyuGramFilter(id: "miss", text: "bye")
        let store = AyuGramFilterStore(filters: [matchingFilter, nonMatchingFilter])

        XCTAssertEqual(ayuGramMatchingFilters(store: store, input: AyuGramFilterMatchInput(text: "hello")).map(\.id), ["match"])
        XCTAssertTrue(ayuGramShouldHideMessage(store: store, text: "hello", dialogId: nil))
        XCTAssertFalse(ayuGramShouldHideMessage(store: store, text: "neutral", dialogId: nil))
    }

    func testChatMessageFilteringRequiresBothSettings() {
        let store = AyuGramFilterStore(filters: [AyuGramFilter(text: "hello")])

        XCTAssertFalse(ayuGramShouldHideChatMessage(settings: AyuGramSettings(filtersEnabled: false, filtersEnabledInChats: true), store: store, text: "hello", dialogId: nil))
        XCTAssertFalse(ayuGramShouldHideChatMessage(settings: AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: false), store: store, text: "hello", dialogId: nil))
        XCTAssertTrue(ayuGramShouldHideChatMessage(settings: AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: true), store: store, text: "hello", dialogId: nil))
    }

    func testChatMessageFilteringCanMatchEmptyTextWithReversedFilter() {
        let store = AyuGramFilterStore(filters: [AyuGramFilter(text: "hello", reversed: true)])
        let settings = AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: true)

        XCTAssertTrue(ayuGramShouldHideChatMessage(settings: settings, store: store, text: "", dialogId: nil))
    }

    func testBlockedPeerReasonRequiresSetting() {
        let store = AyuGramFilterStore(filters: [])

        XCTAssertNil(ayuGramChatMessageFilterReason(
            settings: AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: true, hideFromBlocked: false),
            store: store,
            input: AyuGramFilterMatchInput(text: "hello", isBlockedPeer: true)
        ))
        XCTAssertEqual(ayuGramChatMessageFilterReason(
            settings: AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: true, hideFromBlocked: true),
            store: store,
            input: AyuGramFilterMatchInput(text: "hello", isBlockedPeer: true)
        ), .blockedPeer)
    }

    func testShadowBannedAuthorReason() {
        let store = AyuGramFilterStore(filters: [])
        let settings = AyuGramSettings(shadowBanIds: Set([123]), filtersEnabled: true, filtersEnabledInChats: true)

        XCTAssertEqual(ayuGramChatMessageFilterReason(
            settings: settings,
            store: store,
            input: AyuGramFilterMatchInput(text: "hello", authorPeerId: 123)
        ), .shadowBannedPeer)
        XCTAssertNil(ayuGramChatMessageFilterReason(
            settings: settings,
            store: store,
            input: AyuGramFilterMatchInput(text: "hello", authorPeerId: 456)
        ))
    }

    func testRegexReasonIncludesFilterId() {
        let store = AyuGramFilterStore(filters: [AyuGramFilter(id: "greeting", text: "hello")])
        let settings = AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: true)

        XCTAssertEqual(ayuGramChatMessageFilterReason(
            settings: settings,
            store: store,
            input: AyuGramFilterMatchInput(text: "hello")
        ), .filter("greeting"))
    }

    func testActiveChatFiltersIncludesBlockedAndShadowBanRulesWithoutTextFilters() {
        let emptyStore = AyuGramFilterStore(filters: [])

        XCTAssertFalse(ayuGramHasActiveChatFilters(
            settings: AyuGramSettings(filtersEnabled: false, filtersEnabledInChats: true, hideFromBlocked: true),
            store: emptyStore
        ))
        XCTAssertFalse(ayuGramHasActiveChatFilters(
            settings: AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: false, shadowBanIds: Set([123])),
            store: emptyStore
        ))
        XCTAssertTrue(ayuGramHasActiveChatFilters(
            settings: AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: true, hideFromBlocked: true),
            store: emptyStore
        ))
        XCTAssertTrue(ayuGramHasActiveChatFilters(
            settings: AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: true, shadowBanIds: Set([123])),
            store: emptyStore
        ))
        XCTAssertTrue(ayuGramHasActiveChatFilters(
            settings: AyuGramSettings(filtersEnabled: true, filtersEnabledInChats: true),
            store: AyuGramFilterStore(filters: [AyuGramFilter(text: "hello")])
        ))
    }
}
