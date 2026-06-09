import Foundation

public struct AyuGramFilterMatchInput: Equatable {
    public var text: String
    public var dialogId: Int64?

    public init(text: String, dialogId: Int64? = nil) {
        self.text = text
        self.dialogId = dialogId
    }
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

public func ayuGramShouldHideChatMessage(
    settings: AyuGramSettings,
    store: AyuGramFilterStore,
    text: String,
    dialogId: Int64?
) -> Bool {
    guard settings.filtersEnabled && settings.filtersEnabledInChats else {
        return false
    }
    return ayuGramShouldHideMessage(store: store, text: text, dialogId: dialogId)
}
