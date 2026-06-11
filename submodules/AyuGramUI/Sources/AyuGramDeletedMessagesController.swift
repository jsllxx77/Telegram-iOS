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
    let loadMore: () -> Void
    let clearHistory: () -> Void
    let presentController: (ViewController, Any?) -> Void

    init(
        context: AccountContext,
        updateSearchQuery: @escaping (String) -> Void,
        loadMore: @escaping () -> Void,
        clearHistory: @escaping () -> Void,
        presentController: @escaping (ViewController, Any?) -> Void
    ) {
        self.context = context
        self.updateSearchQuery = updateSearchQuery
        self.loadMore = loadMore
        self.clearHistory = clearHistory
        self.presentController = presentController
    }
}

private let ayuGramDeletedMessagesPageSize = 100

private func ayuGramRemoveDeletedSnapshotLocalMediaFiles(_ snapshots: [AyuGramMessageSnapshot]) {
    var paths = Set<String>()
    for snapshot in snapshots {
        if let path = snapshot.mediaResourceLocalPath {
            paths.insert(path)
        }
        if let path = snapshot.mediaThumbnailLocalPath {
            paths.insert(path)
        }
    }
    for path in paths {
        try? FileManager.default.removeItem(atPath: path)
    }
}

private enum AyuGramDeletedMessagesSection: Int32 {
    case search
    case history
}

private enum AyuGramDeletedMessagesEntryId: Hashable {
    case search
    case snapshot(Int64, Int64, Int64?, Int32, Int32, Int32, Int32?, Int64?, String, String?)
    case loadMore
    case empty
}

private enum AyuGramDeletedMessagesControllerEntry: ItemListNodeEntry {
    case search(String)
    case snapshot(Int, AyuGramMessageSnapshot)
    case loadMore(Int, Int)
    case empty(String)

    var section: ItemListSectionId {
        switch self {
        case .search:
            return AyuGramDeletedMessagesSection.search.rawValue
        case .snapshot, .loadMore, .empty:
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
        case .loadMore:
            return .loadMore
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
        case (.empty, .snapshot), (.empty, .loadMore):
            return false
        case (.snapshot, .empty), (.loadMore, .empty):
            return true
        case (.loadMore, .loadMore):
            return false
        case (.loadMore, .snapshot):
            return false
        case (.snapshot, .loadMore):
            return true
        case let (.snapshot(lhsIndex, _), .snapshot(rhsIndex, _)):
            return lhsIndex < rhsIndex
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramDeletedMessagesControllerArguments
        let languageCode = presentationData.strings.baseLanguageCode

        switch self {
        case let .search(query):
            return ItemListSingleLineInputItem(
                context: arguments.context,
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(),
                text: query,
                placeholder: ayuGramLocalized("Search", languageCode: languageCode),
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
            let policy = AyuGramStreamerModePolicy(isEnabled: arguments.context.isAyuGramStreamerModeEnabled)
            let text = ayuGramHistorySnapshotText(snapshot, ordinal: index + 1, mode: .deleted, policy: policy, languageCode: languageCode)
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section,
                style: .blocks
            )
        case let .loadMore(visibleCount, totalCount):
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "\(ayuGramLocalized("Load More", languageCode: languageCode)) (\(visibleCount)/\(totalCount))",
                kind: .generic,
                alignment: .center,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.loadMore()
                }
            )
        case let .empty(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(ayuGramLocalized(text, languageCode: languageCode)),
                sectionId: self.section,
                style: .blocks,
                textAlignment: .center
            )
        }
    }
}

private func ayuGramDeletedMessagesControllerEntries(
    snapshots: [AyuGramMessageSnapshot],
    searchQuery: String,
    visibleCount: Int,
    totalCount: Int
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
    if visibleCount < totalCount {
        entries.append(.loadMore(visibleCount, totalCount))
    }

    return entries
}

public func ayuGramDeletedMessagesController(context: AccountContext, peerId: PeerId, threadId: Int64? = nil) -> ViewController {
    let storeKey = PreferencesKeys.ayuGramMessageHistoryStore()
    let accountPeerId = context.account.peerId.toInt64()
    let peerIdValue = peerId.toInt64()
    let searchQuery = ValuePromise<String>("", ignoreRepeated: true)
    let visibleCount = ValuePromise<Int>(ayuGramDeletedMessagesPageSize, ignoreRepeated: true)
    var currentVisibleCount = ayuGramDeletedMessagesPageSize

    let clearHistory: () -> Void = {
        let _ = context.engine.preferences.update(id: storeKey) { entry -> EnginePreferencesEntry? in
            var store = entry?.get(AyuGramMessageHistoryStore.self) ?? .empty
            let removedSnapshots: [AyuGramMessageSnapshot]
            if let threadId = threadId {
                removedSnapshots = store.deletedSnapshots.filter { snapshot in
                    return snapshot.accountPeerId == accountPeerId
                        && snapshot.peerId == peerIdValue
                        && snapshot.threadId == threadId
                }
                store.clearDeletedSnapshotsInThread(
                    accountPeerId: accountPeerId,
                    peerId: peerIdValue,
                    threadId: threadId
                )
            } else {
                removedSnapshots = store.deletedSnapshots.filter { snapshot in
                    return snapshot.accountPeerId == accountPeerId
                        && snapshot.peerId == peerIdValue
                }
                store.clearDeletedSnapshots(
                    accountPeerId: accountPeerId,
                    peerId: peerIdValue
                )
            }
            ayuGramRemoveDeletedSnapshotLocalMediaFiles(removedSnapshots)
            return EnginePreferencesEntry(store)
        }.start()
    }

    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let arguments = AyuGramDeletedMessagesControllerArguments(
        context: context,
        updateSearchQuery: { value in
            currentVisibleCount = ayuGramDeletedMessagesPageSize
            searchQuery.set(value)
            visibleCount.set(currentVisibleCount)
        },
        loadMore: {
            currentVisibleCount += ayuGramDeletedMessagesPageSize
            visibleCount.set(currentVisibleCount)
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
        searchQuery.get(),
        visibleCount.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, store, searchQuery, visibleCount -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let languageCode = presentationData.strings.baseLanguageCode
        let allSnapshots: [AyuGramMessageSnapshot]
        let matchingSnapshots: [AyuGramMessageSnapshot]
        let snapshots: [AyuGramMessageSnapshot]
        let safeVisibleCount = max(ayuGramDeletedMessagesPageSize, visibleCount)
        if let threadId = threadId {
            allSnapshots = store.listDeletedSnapshotsInThread(
                accountPeerId: accountPeerId,
                peerId: peerIdValue,
                threadId: threadId
            )
            matchingSnapshots = store.listDeletedSnapshotsInThread(
                accountPeerId: accountPeerId,
                peerId: peerIdValue,
                threadId: threadId,
                searchQuery: searchQuery
            )
            snapshots = store.listDeletedSnapshotsInThread(
                accountPeerId: accountPeerId,
                peerId: peerIdValue,
                threadId: threadId,
                searchQuery: searchQuery,
                offset: 0,
                limit: safeVisibleCount
            )
        } else {
            allSnapshots = store.listDeletedSnapshots(
                accountPeerId: accountPeerId,
                peerId: peerIdValue
            )
            matchingSnapshots = store.listDeletedSnapshots(
                accountPeerId: accountPeerId,
                peerId: peerIdValue,
                searchQuery: searchQuery
            )
            snapshots = store.listDeletedSnapshots(
                accountPeerId: accountPeerId,
                peerId: peerIdValue,
                searchQuery: searchQuery,
                offset: 0,
                limit: safeVisibleCount
            )
        }

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(ayuGramLocalized("Deleted Messages", languageCode: languageCode)),
            leftNavigationButton: nil,
            rightNavigationButton: ItemListNavigationButton(
                content: .text(ayuGramLocalized("Clear", languageCode: languageCode)),
                style: .regular,
                enabled: !allSnapshots.isEmpty,
                action: {
                    let actionSheet = ActionSheetController(presentationData: presentationData)
                    let dismissAction: () -> Void = { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                    }
                    actionSheet.setItemGroups([
                        ActionSheetItemGroup(items: [
                            ActionSheetTextItem(title: ayuGramLocalized("Clear saved deleted-message history for this chat?", languageCode: languageCode)),
                            ActionSheetButtonItem(title: ayuGramLocalized("Clear", languageCode: languageCode), color: .destructive, action: {
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
            entries: ayuGramDeletedMessagesControllerEntries(
                snapshots: snapshots,
                searchQuery: searchQuery,
                visibleCount: snapshots.count,
                totalCount: matchingSnapshots.count
            ),
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
