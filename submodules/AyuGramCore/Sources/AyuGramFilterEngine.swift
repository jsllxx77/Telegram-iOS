import Foundation

public struct AyuGramFilterMatchInput: Equatable {
    public var text: String
    public var dialogId: Int64?
    public var authorPeerId: Int64?
    public var isBlockedPeer: Bool

    public init(text: String, dialogId: Int64? = nil, authorPeerId: Int64? = nil, isBlockedPeer: Bool = false) {
        self.text = text
        self.dialogId = dialogId
        self.authorPeerId = authorPeerId
        self.isBlockedPeer = isBlockedPeer
    }
}

public enum AyuGramFilterMatchReason: Equatable {
    case filter(String)
    case blockedPeer
    case shadowBannedPeer
}

public func ayuGramFilterMatches(_ filter: AyuGramFilter, input: AyuGramFilterMatchInput) -> Bool {
    guard filter.enabled else {
        return false
    }

    let trimmedText = filter.text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else {
        return false
    }

    if let filterDialogId = filter.dialogId {
        guard input.dialogId == filterDialogId else {
            return false
        }
    } else if let dialogId = input.dialogId, filter.exclusions.contains(dialogId) {
        return false
    }

    var options: NSRegularExpression.Options = []
    if filter.caseInsensitive {
        options.insert(.caseInsensitive)
    }

    guard let expression = try? NSRegularExpression(pattern: trimmedText, options: options) else {
        return false
    }

    let range = NSRange(input.text.startIndex..<input.text.endIndex, in: input.text)
    let hasMatch = expression.firstMatch(in: input.text, options: [], range: range) != nil

    if filter.reversed {
        return !hasMatch
    } else {
        return hasMatch
    }
}

public func ayuGramMatchingFilters(store: AyuGramFilterStore, input: AyuGramFilterMatchInput) -> [AyuGramFilter] {
    return store.filters.filter { filter in
        return ayuGramFilterMatches(filter, input: input)
    }
}

public func ayuGramShouldHideMessage(store: AyuGramFilterStore, text: String, dialogId: Int64?) -> Bool {
    return !ayuGramMatchingFilters(store: store, input: AyuGramFilterMatchInput(text: text, dialogId: dialogId)).isEmpty
}

public func ayuGramChatMessageFilterReason(
    settings: AyuGramSettings,
    store: AyuGramFilterStore,
    input: AyuGramFilterMatchInput
) -> AyuGramFilterMatchReason? {
    guard settings.filtersEnabled && settings.filtersEnabledInChats else {
        return nil
    }

    if settings.hideFromBlocked && input.isBlockedPeer {
        return .blockedPeer
    }

    if let authorPeerId = input.authorPeerId, settings.shadowBanIds.contains(authorPeerId) {
        return .shadowBannedPeer
    }

    if let filter = ayuGramMatchingFilters(store: store, input: input).first {
        return .filter(filter.id)
    }

    return nil
}

public func ayuGramHasActiveChatFilters(settings: AyuGramSettings, store: AyuGramFilterStore) -> Bool {
    guard settings.filtersEnabled && settings.filtersEnabledInChats else {
        return false
    }
    return !store.filters.isEmpty || settings.hideFromBlocked || !settings.shadowBanIds.isEmpty
}

public func ayuGramShouldHideChatMessage(
    settings: AyuGramSettings,
    store: AyuGramFilterStore,
    text: String,
    dialogId: Int64?
) -> Bool {
    return ayuGramChatMessageFilterReason(
        settings: settings,
        store: store,
        input: AyuGramFilterMatchInput(text: text, dialogId: dialogId)
    ) != nil
}
