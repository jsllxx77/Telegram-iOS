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

private final class AyuGramDeletedMessagesControllerArguments {
    let context: AccountContext
    let updateSearchQuery: (String) -> Void
    let clearHistory: () -> Void
    let presentController: (ViewController, Any?) -> Void

    init(
        context: AccountContext,
        updateSearchQuery: @escaping (String) -> Void,
        clearHistory: @escaping () -> Void,
        presentController: @escaping (ViewController, Any?) -> Void
    ) {
        self.context = context
        self.updateSearchQuery = updateSearchQuery
        self.clearHistory = clearHistory
        self.presentController = presentController
    }
}

private enum AyuGramDeletedMessagesSection: Int32 {
    case search
    case history
}

private enum AyuGramDeletedMessagesEntryId: Hashable {
    case search
    case snapshot(Int64, Int64, Int64?, Int32, Int32, Int32, Int32?, Int64?, String, String?)
    case empty
}

private enum AyuGramDeletedMessagesControllerEntry: ItemListNodeEntry {
    case search(String)
    case snapshot(Int, AyuGramMessageSnapshot)
    case empty(String)

    var section: ItemListSectionId {
        switch self {
        case .search:
            return AyuGramDeletedMessagesSection.search.rawValue
        case .snapshot, .empty:
            return AyuGramDeletedMessagesSection.history.rawValue
        }
    }

    var stableId: AyuGramDeletedMessagesEntryId {
        switch self {
        case .search:
            return .search
        case let .snapshot(_, snapshot):
            return .snapshot(
                snapshot.accountPeerId,
                snapshot.peerId,
                snapshot.threadId,
                snapshot.messageNamespace,
                snapshot.messageId,
                snapshot.createdAt,
                snapshot.editTimestamp,
                snapshot.stableId,
                snapshot.text,
                snapshot.mediaSummary
            )
        case .empty:
            return .empty
        }
    }

    static func <(lhs: AyuGramDeletedMessagesControllerEntry, rhs: AyuGramDeletedMessagesControllerEntry) -> Bool {
        switch (lhs, rhs) {
        case (.search, .search):
            return false
        case (.search, _):
            return true
        case (_, .search):
            return false
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
        let arguments = arguments as! AyuGramDeletedMessagesControllerArguments

        switch self {
        case let .search(query):
            return ItemListSingleLineInputItem(
                context: arguments.context,
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(),
                text: query,
                placeholder: "Search",
                type: .regular(capitalization: false, autocorrection: false),
                returnKeyType: .search,
                clearType: .always,
                sectionId: self.section,
                textUpdated: { value in
                    arguments.updateSearchQuery(value)
                },
                action: {}
            )
        case let .snapshot(index, snapshot):
            let text = ayuGramHistorySnapshotText(snapshot, ordinal: index + 1, mode: .deleted)
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section,
                style: .blocks
            )
        case let .empty(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section,
                style: .blocks,
                textAlignment: .center
            )
        }
    }
}

private func ayuGramDeletedMessagesControllerEntries(
    snapshots: [AyuGramMessageSnapshot],
    searchQuery: String
) -> [AyuGramDeletedMessagesControllerEntry] {
    var entries: [AyuGramDeletedMessagesControllerEntry] = []

    entries.append(.search(searchQuery))

    if snapshots.isEmpty {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            entries.append(.empty("No deleted messages saved for this chat."))
        } else {
            entries.append(.empty("No deleted messages match this search."))
        }
        return entries
    }

    for (index, snapshot) in snapshots.enumerated() {
        entries.append(.snapshot(index, snapshot))
    }

    return entries
}

public func ayuGramDeletedMessagesController(context: AccountContext, peerId: PeerId, threadId: Int64? = nil) -> ViewController {
    let storeKey = PreferencesKeys.ayuGramMessageHistoryStore()
    let accountPeerId = context.account.peerId.toInt64()
    let peerIdValue = peerId.toInt64()
    let searchQuery = ValuePromise<String>("", ignoreRepeated: true)

    let clearHistory: () -> Void = {
        let _ = context.engine.preferences.update(id: storeKey) { entry -> EnginePreferencesEntry? in
            var store = entry?.get(AyuGramMessageHistoryStore.self) ?? .empty
            if let threadId = threadId {
                store.clearDeletedSnapshotsInThread(
                    accountPeerId: accountPeerId,
                    peerId: peerIdValue,
                    threadId: threadId
                )
            } else {
                store.clearDeletedSnapshots(
                    accountPeerId: accountPeerId,
                    peerId: peerIdValue
                )
            }
            return EnginePreferencesEntry(store)
        }.start()
    }

    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let arguments = AyuGramDeletedMessagesControllerArguments(
        context: context,
        updateSearchQuery: { value in
            searchQuery.set(value)
        },
        clearHistory: clearHistory,
        presentController: { controller, arguments in
            presentControllerImpl?(controller, arguments)
        }
    )

    let historyStore = context.engine.data.subscribe(
        TelegramEngine.EngineData.Item.Configuration.ApplicationSpecificPreference(key: storeKey)
    )
    |> map { entry -> AyuGramMessageHistoryStore in
        return entry?.get(AyuGramMessageHistoryStore.self) ?? .empty
    }
    |> distinctUntilChanged

    let signal = combineLatest(
        context.sharedContext.presentationData,
        historyStore,
        searchQuery.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, store, searchQuery -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let allSnapshots: [AyuGramMessageSnapshot]
        let snapshots: [AyuGramMessageSnapshot]
        if let threadId = threadId {
            allSnapshots = store.listDeletedSnapshotsInThread(
                accountPeerId: accountPeerId,
                peerId: peerIdValue,
                threadId: threadId
            )
            snapshots = store.listDeletedSnapshotsInThread(
                accountPeerId: accountPeerId,
                peerId: peerIdValue,
                threadId: threadId,
                searchQuery: searchQuery
            )
        } else {
            allSnapshots = store.listDeletedSnapshots(
                accountPeerId: accountPeerId,
                peerId: peerIdValue
            )
            snapshots = store.listDeletedSnapshots(
                accountPeerId: accountPeerId,
                peerId: peerIdValue,
                searchQuery: searchQuery
            )
        }

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Deleted Messages"),
            leftNavigationButton: nil,
            rightNavigationButton: ItemListNavigationButton(
                content: .text("Clear"),
                style: .regular,
                enabled: !allSnapshots.isEmpty,
                action: {
                    let actionSheet = ActionSheetController(presentationData: presentationData)
                    let dismissAction: () -> Void = { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                    }
                    actionSheet.setItemGroups([
                        ActionSheetItemGroup(items: [
                            ActionSheetTextItem(title: "Clear saved deleted-message history for this chat?"),
                            ActionSheetButtonItem(title: "Clear", color: .destructive, action: {
                                dismissAction()
                                arguments.clearHistory()
                            })
                        ]),
                        ActionSheetItemGroup(items: [
                            ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: {
                                dismissAction()
                            })
                        ])
                    ])
                    arguments.presentController(actionSheet, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
                }
            ),
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuGramDeletedMessagesControllerEntries(snapshots: snapshots, searchQuery: searchQuery),
            style: .blocks,
            animateChanges: false
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] controllerToPresent, arguments in
        controller?.present(controllerToPresent, in: .window(.root), with: arguments)
    }
    return controller
}
