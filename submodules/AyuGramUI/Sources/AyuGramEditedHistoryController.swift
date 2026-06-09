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
        switch self {
        case let .snapshot(index, snapshot):
            let text = ayuGramHistorySnapshotText(snapshot, ordinal: index + 1, mode: .edited)
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section,
                style: .blocks
            )
        case .empty:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("No edited history saved for this message."),
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
    let arguments = AyuGramEditedHistoryControllerArguments()
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
        let snapshots = store.listEditedSnapshots(
            accountPeerId: accountPeerId,
            peerId: peerId,
            messageNamespace: messageId.namespace,
            messageId: messageId.id
        )

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Edit History"),
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

func ayuGramHistorySnapshotText(_ snapshot: AyuGramMessageSnapshot, ordinal: Int, mode: AyuGramHistorySnapshotMode) -> String {
    var lines: [String] = []
    lines.append("#\(ordinal)")

    if !snapshot.text.isEmpty {
        lines.append(snapshot.text)
    } else if let mediaSummary = snapshot.mediaSummary, !mediaSummary.isEmpty {
        lines.append("[\(mediaSummary)]")
    } else {
        lines.append("[No text]")
    }

    lines.append("Author: \(ayuGramOptionalInt64String(snapshot.authorPeerId))")
    lines.append("Message ID: \(snapshot.messageNamespace):\(snapshot.messageId)")
    lines.append("Date: \(ayuGramHistoryDateString(snapshot.timestamp))")

    switch mode {
    case .edited:
        if let editTimestamp = snapshot.editTimestamp {
            lines.append("Edit Date: \(ayuGramHistoryDateString(editTimestamp))")
        } else {
            lines.append("Edit Date: Unknown")
        }
    case .deleted:
        if let editTimestamp = snapshot.editTimestamp {
            lines.append("Edit Date: \(ayuGramHistoryDateString(editTimestamp))")
        } else {
            lines.append("Edit Date: Unknown")
        }
        lines.append("Captured: \(ayuGramHistoryDateString(snapshot.createdAt))")
    }

    if let stableId = snapshot.stableId {
        lines.append("Stable ID: \(stableId)")
    }
    if let threadId = snapshot.threadId {
        lines.append("Thread ID: \(threadId)")
    }
    if let mediaSummary = snapshot.mediaSummary, !mediaSummary.isEmpty, !snapshot.text.isEmpty {
        lines.append("Media: \(mediaSummary)")
    }

    return lines.joined(separator: "\n")
}

func ayuGramHistoryDateString(_ timestamp: Int32) -> String {
    let date = Date(timeIntervalSince1970: Double(timestamp))
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter.string(from: date)
}

func ayuGramOptionalInt64String(_ value: Int64?) -> String {
    if let value = value {
        return "\(value)"
    } else {
        return "Unknown"
    }
}
