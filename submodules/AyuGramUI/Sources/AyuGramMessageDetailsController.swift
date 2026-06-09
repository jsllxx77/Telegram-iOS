import Foundation
import UIKit
import AccountContext
import AyuGramCore
import Display
import ItemListUI
import Postbox
import PresentationDataUtils
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData

private final class AyuGramMessageDetailsControllerArguments {
    let copyValue: (String) -> Void

    init(copyValue: @escaping (String) -> Void) {
        self.copyValue = copyValue
    }
}

private enum AyuGramMessageDetailsSection: Int32 {
    case details
    case copy
}

private enum AyuGramMessageDetailsEntryId: Hashable {
    case details(String)
    case copy(Int32)
}

private enum AyuGramMessageDetailsControllerEntry: ItemListNodeEntry {
    case details(String)
    case copy(Int32, String, String)

    var section: ItemListSectionId {
        switch self {
        case .details:
            return AyuGramMessageDetailsSection.details.rawValue
        case .copy:
            return AyuGramMessageDetailsSection.copy.rawValue
        }
    }

    var stableId: AyuGramMessageDetailsEntryId {
        switch self {
        case let .details(text):
            return .details(text)
        case let .copy(index, _, _):
            return .copy(index)
        }
    }

    static func <(lhs: AyuGramMessageDetailsControllerEntry, rhs: AyuGramMessageDetailsControllerEntry) -> Bool {
        switch (lhs, rhs) {
        case (.details, .details):
            return false
        case (.details, .copy):
            return true
        case (.copy, .details):
            return false
        case let (.copy(lhsIndex, _, _), .copy(rhsIndex, _, _)):
            return lhsIndex < rhsIndex
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramMessageDetailsControllerArguments

        switch self {
        case let .details(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section,
                style: .blocks
            )
        case let .copy(_, title, value):
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.copyValue(value)
                }
            )
        }
    }
}

private struct AyuGramMessageDetailsData {
    let lines: [String]
    let copyActions: [(String, String)]

    var fullText: String {
        return self.lines.joined(separator: "\n")
    }
}

private func ayuGramMessageDetailsControllerEntries(
    details: AyuGramMessageDetailsData
) -> [AyuGramMessageDetailsControllerEntry] {
    var entries: [AyuGramMessageDetailsControllerEntry] = []

    entries.append(.details(details.fullText))

    var index: Int32 = 0
    for (title, value) in details.copyActions {
        entries.append(.copy(index, title, value))
        index += 1
    }

    return entries
}

public func ayuGramMessageDetailsController(context: AccountContext, message: Message) -> ViewController {
    let policy = AyuGramStreamerModePolicy(isEnabled: context.isAyuGramStreamerModeEnabled)
    let details = ayuGramMessageDetailsData(message: message, policy: policy)
    let arguments = AyuGramMessageDetailsControllerArguments(copyValue: { value in
        UIPasteboard.general.string = value
    })

    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Message Details"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuGramMessageDetailsControllerEntries(details: details),
            style: .blocks,
            animateChanges: false
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

private func ayuGramMessageDetailsData(message: Message, policy: AyuGramStreamerModePolicy) -> AyuGramMessageDetailsData {
    let peerId = message.id.peerId.toInt64()
    let messageId = "\(message.id.namespace):\(message.id.id)"
    let authorId = message.author?.id.toInt64()
    let editDate = ayuGramMessageDetailsEditDate(message)
    let entityCount = ayuGramMessageDetailsEntityCount(message)
    let views = ayuGramMessageDetailsViewCount(message)
    let forwards = ayuGramMessageDetailsForwardCount(message)
    let mediaSummary = ayuGramMessageDetailsMediaSummary(message)
    let hiddenValue = AyuGramStreamerRedaction.hiddenValue

    let displayPeerId = policy.isEnabled ? hiddenValue : "\(peerId)"
    let displayMessageId = policy.isEnabled ? hiddenValue : messageId
    let displayAuthorId = policy.isEnabled ? hiddenValue : ayuGramOptionalInt64String(authorId)
    let displayThreadId = policy.isEnabled ? hiddenValue : ayuGramOptionalInt64String(message.threadId)

    var lines: [String] = []
    lines.append("Peer ID: \(displayPeerId)")
    lines.append("Message ID: \(displayMessageId)")
    lines.append("Author ID: \(displayAuthorId)")
    lines.append("Date: \(ayuGramHistoryDateString(message.timestamp))")
    lines.append("Edit Date: \(editDate.map(ayuGramHistoryDateString) ?? "Unknown")")
    lines.append("Views: \(views.map { "\($0)" } ?? "Unknown")")
    lines.append("Forwards: \(forwards.map { "\($0)" } ?? "Unknown")")
    lines.append("Entity Count: \(entityCount)")
    lines.append("Media: \(mediaSummary)")
    lines.append("Thread ID: \(displayThreadId)")

    if let globallyUniqueId = message.globallyUniqueId {
        let displayGloballyUniqueId = policy.isEnabled ? hiddenValue : "\(globallyUniqueId)"
        lines.append("Global Unique ID: \(displayGloballyUniqueId)")
    }
    let displayStableId = policy.isEnabled ? hiddenValue : "\(message.stableId)"
    lines.append("Stable ID: \(displayStableId)")
    if let groupingKey = message.groupingKey {
        let displayGroupingKey = policy.isEnabled ? hiddenValue : "\(groupingKey)"
        lines.append("Grouping Key: \(displayGroupingKey)")
    }
    if let sourceMessageId = message.forwardInfo?.sourceMessageId {
        let displaySourceMessageId = policy.isEnabled ? hiddenValue : "\(sourceMessageId.namespace):\(sourceMessageId.id)"
        let displaySourcePeerId = policy.isEnabled ? hiddenValue : "\(sourceMessageId.peerId.toInt64())"
        lines.append("Forward Source Message ID: \(displaySourceMessageId)")
        lines.append("Forward Source Peer ID: \(displaySourcePeerId)")
    }
    if let forwardDate = message.forwardInfo?.date {
        lines.append("Forward Date: \(ayuGramHistoryDateString(forwardDate))")
    }

    var copyActions: [(String, String)] = []
    copyActions.append(("Copy Peer ID", displayPeerId))
    copyActions.append(("Copy Message ID", displayMessageId))
    if let authorId = authorId {
        copyActions.append(("Copy Author ID", policy.isEnabled ? hiddenValue : "\(authorId)"))
    }
    if let threadId = message.threadId {
        copyActions.append(("Copy Thread ID", policy.isEnabled ? hiddenValue : "\(threadId)"))
    }
    if !message.text.isEmpty {
        copyActions.append(("Copy Message Text", AyuGramStreamerRedaction.messagePreview(message.text, policy: policy)))
    }
    copyActions.append(("Copy All Details", lines.joined(separator: "\n")))

    return AyuGramMessageDetailsData(lines: lines, copyActions: copyActions)
}

private func ayuGramMessageDetailsEditDate(_ message: Message) -> Int32? {
    for attribute in message.attributes {
        if let attribute = attribute as? EditedMessageAttribute, !attribute.isHidden, attribute.date != 0 {
            return attribute.date
        }
    }
    return nil
}

private func ayuGramMessageDetailsViewCount(_ message: Message) -> Int? {
    for attribute in message.attributes {
        if let attribute = attribute as? ViewCountMessageAttribute {
            return attribute.count
        }
    }
    return nil
}

private func ayuGramMessageDetailsForwardCount(_ message: Message) -> Int? {
    for attribute in message.attributes {
        if let attribute = attribute as? ForwardCountMessageAttribute {
            return attribute.count
        }
    }
    return nil
}

private func ayuGramMessageDetailsEntityCount(_ message: Message) -> Int {
    for attribute in message.attributes {
        if let attribute = attribute as? TextEntitiesMessageAttribute {
            return attribute.entities.count
        }
    }
    return 0
}

private func ayuGramMessageDetailsMediaSummary(_ message: Message) -> String {
    if message.media.isEmpty {
        return "None"
    }

    var values: [String] = []
    for media in message.media {
        values.append(ayuGramMessageDetailsMediaType(media))
    }
    return values.joined(separator: ", ")
}

private func ayuGramMessageDetailsMediaType(_ media: Media) -> String {
    if media is TelegramMediaImage {
        return "Image"
    } else if let file = media as? TelegramMediaFile {
        if file.isSticker {
            return "Sticker"
        } else if file.isInstantVideo {
            return "Instant Video"
        } else if file.isVideo {
            return "Video"
        } else if file.isMusic {
            return "Music"
        } else if file.isVoice {
            return "Voice"
        } else {
            return "File"
        }
    } else if media is TelegramMediaWebpage {
        return "Webpage"
    } else if media is TelegramMediaContact {
        return "Contact"
    } else if media is TelegramMediaMap {
        return "Map"
    } else if media is TelegramMediaPoll {
        return "Poll"
    } else if media is TelegramMediaDice {
        return "Dice"
    } else if media is TelegramMediaGame {
        return "Game"
    } else if media is TelegramMediaInvoice {
        return "Invoice"
    } else if media is TelegramMediaStory {
        return "Story"
    } else if media is TelegramMediaGiveaway {
        return "Giveaway"
    } else if media is TelegramMediaGiveawayResults {
        return "Giveaway Results"
    } else if media is TelegramMediaPaidContent {
        return "Paid Content"
    } else if media is TelegramMediaTodo {
        return "Todo"
    } else if media is TelegramMediaExpiredContent {
        return "Expired Content"
    } else if media is TelegramMediaAction {
        return "Action"
    } else {
        return "Media"
    }
}
