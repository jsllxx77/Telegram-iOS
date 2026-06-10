import Foundation
import UIKit
import AccountContext
import AyuGramCore
import Display
import ItemListUI
import Postbox
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData

private final class AyuGramEditedHistoryControllerArguments {
    let policy: AyuGramStreamerModePolicy

    init(policy: AyuGramStreamerModePolicy) {
        self.policy = policy
    }
}

private enum AyuGramEditedHistorySection: Int32 {
    case history
}

private enum AyuGramEditedHistoryEntryId: Hashable {
    case snapshot(
        Int64,
        Int64,
        Int64?,
        Int32,
        Int32,
        Int64?,
        Int64?,
        Int32,
        Int32?,
        String,
        Data?,
        Int32?,
        Data?,
        String?,
        Int32
    )
    case empty
}

private enum AyuGramEditedHistoryControllerEntry: ItemListNodeEntry {
    case snapshot(Int, AyuGramMessageSnapshot)
    case empty

    var section: ItemListSectionId {
        return AyuGramEditedHistorySection.history.rawValue
    }

    var stableId: AyuGramEditedHistoryEntryId {
        switch self {
        case let .snapshot(_, snapshot):
            return .snapshot(
                snapshot.accountPeerId,
                snapshot.peerId,
                snapshot.threadId,
                snapshot.messageNamespace,
                snapshot.messageId,
                snapshot.stableId,
                snapshot.authorPeerId,
                snapshot.timestamp,
                snapshot.editTimestamp,
                snapshot.text,
                snapshot.entitiesData,
                snapshot.views,
                snapshot.forwardInfoData,
                snapshot.mediaSummary,
                snapshot.createdAt
            )
        case .empty:
            return .empty
        }
    }

    static func <(lhs: AyuGramEditedHistoryControllerEntry, rhs: AyuGramEditedHistoryControllerEntry) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return false
        case (.empty, .snapshot):
            return false
        case (.snapshot, .empty):
            return true
        case let (.snapshot(lhsIndex, _), .snapshot(rhsIndex, _)):
            return lhsIndex < rhsIndex
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramEditedHistoryControllerArguments
        let languageCode = presentationData.strings.baseLanguageCode

        switch self {
        case let .snapshot(index, snapshot):
            let text = ayuGramHistorySnapshotText(snapshot, ordinal: index + 1, mode: .edited, policy: arguments.policy, languageCode: languageCode)
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section,
                style: .blocks
            )
        case .empty:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(ayuGramLocalized("No edited history saved for this message.", languageCode: languageCode)),
                sectionId: self.section,
                style: .blocks,
                textAlignment: .center
            )
        }
    }
}

private func ayuGramEditedHistoryControllerEntries(snapshots: [AyuGramMessageSnapshot]) -> [AyuGramEditedHistoryControllerEntry] {
    if snapshots.isEmpty {
        return [.empty]
    }

    return snapshots.enumerated().map { index, snapshot in
        return .snapshot(index, snapshot)
    }
}

public func ayuGramEditedHistoryController(context: AccountContext, messageId: MessageId) -> ViewController {
    let arguments = AyuGramEditedHistoryControllerArguments(policy: AyuGramStreamerModePolicy(isEnabled: context.isAyuGramStreamerModeEnabled))
    let storeKey = PreferencesKeys.ayuGramMessageHistoryStore()
    let accountPeerId = context.account.peerId.toInt64()
    let peerId = messageId.peerId.toInt64()

    let historyStore = context.engine.data.subscribe(
        TelegramEngine.EngineData.Item.Configuration.ApplicationSpecificPreference(key: storeKey)
    )
    |> map { entry -> AyuGramMessageHistoryStore in
        return entry?.get(AyuGramMessageHistoryStore.self) ?? .empty
    }
    |> distinctUntilChanged

    let signal = combineLatest(
        context.sharedContext.presentationData,
        historyStore
    )
    |> deliverOnMainQueue
    |> map { presentationData, store -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let languageCode = presentationData.strings.baseLanguageCode
        let snapshots = store.listEditedSnapshots(
            accountPeerId: accountPeerId,
            peerId: peerId,
            messageNamespace: messageId.namespace,
            messageId: messageId.id
        )

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(ayuGramLocalized("Edit History", languageCode: languageCode)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuGramEditedHistoryControllerEntries(snapshots: snapshots),
            style: .blocks,
            animateChanges: false
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

enum AyuGramHistorySnapshotMode {
    case edited
    case deleted
}

func ayuGramHistorySnapshotText(_ snapshot: AyuGramMessageSnapshot, ordinal: Int, mode: AyuGramHistorySnapshotMode, policy: AyuGramStreamerModePolicy = .disabled, languageCode: String = "en") -> String {
    let localized: (String) -> String = { value in
        return ayuGramLocalized(value, languageCode: languageCode)
    }
    var lines: [String] = []
    lines.append("#\(ordinal)")

    if !snapshot.text.isEmpty {
        lines.append(AyuGramStreamerRedaction.messagePreview(snapshot.text, policy: policy))
    } else if let mediaSummary = snapshot.mediaSummary, !mediaSummary.isEmpty {
        lines.append("[\(mediaSummary)]")
    } else {
        lines.append("[\(localized("No text"))]")
    }

    let hiddenValue = AyuGramStreamerRedaction.hiddenValue
    let displayAuthorId = policy.isEnabled ? hiddenValue : ayuGramOptionalInt64String(snapshot.authorPeerId, languageCode: languageCode)
    let displayMessageId = policy.isEnabled ? hiddenValue : "\(snapshot.messageNamespace):\(snapshot.messageId)"
    lines.append("\(localized("Author")): \(displayAuthorId)")
    lines.append("\(localized("Message ID")): \(displayMessageId)")
    lines.append("\(localized("Date")): \(ayuGramHistoryDateString(snapshot.timestamp, languageCode: languageCode))")

    switch mode {
    case .edited:
        if let editTimestamp = snapshot.editTimestamp {
            lines.append("\(localized("Edit Date")): \(ayuGramHistoryDateString(editTimestamp, languageCode: languageCode))")
        } else {
            lines.append("\(localized("Edit Date")): \(localized("Unknown"))")
        }
    case .deleted:
        if let editTimestamp = snapshot.editTimestamp {
            lines.append("\(localized("Edit Date")): \(ayuGramHistoryDateString(editTimestamp, languageCode: languageCode))")
        } else {
            lines.append("\(localized("Edit Date")): \(localized("Unknown"))")
        }
        lines.append("\(localized("Captured")): \(ayuGramHistoryDateString(snapshot.createdAt, languageCode: languageCode))")
    }

    if let stableId = snapshot.stableId {
        let displayStableId = policy.isEnabled ? hiddenValue : "\(stableId)"
        lines.append("\(localized("Stable ID")): \(displayStableId)")
    }
    if let threadId = snapshot.threadId {
        let displayThreadId = policy.isEnabled ? hiddenValue : "\(threadId)"
        lines.append("\(localized("Thread ID")): \(displayThreadId)")
    }
    if let mediaSummary = snapshot.mediaSummary, !mediaSummary.isEmpty, !snapshot.text.isEmpty {
        lines.append("\(localized("Media")): \(mediaSummary)")
    }

    return lines.joined(separator: "\n")
}

func ayuGramHistoryDateString(_ timestamp: Int32, languageCode: String = "en") -> String {
    let date = Date(timeIntervalSince1970: Double(timestamp))
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: languageCode)
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter.string(from: date)
}

func ayuGramOptionalInt64String(_ value: Int64?, languageCode: String = "en") -> String {
    if let value = value {
        return "\(value)"
    } else {
        return ayuGramLocalized("Unknown", languageCode: languageCode)
    }
}
