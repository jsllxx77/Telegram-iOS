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

private final class AyuGramFiltersControllerArguments {
    let context: AccountContext
    let openFilter: (AyuGramFilter) -> Void
    let addFilter: () -> Void
    let updateFilter: (AyuGramFilter) -> Void
    let exportFilters: (AyuGramFilterStore) -> Void
    let importFilters: () -> Void

    init(
        context: AccountContext,
        openFilter: @escaping (AyuGramFilter) -> Void,
        addFilter: @escaping () -> Void,
        updateFilter: @escaping (AyuGramFilter) -> Void,
        exportFilters: @escaping (AyuGramFilterStore) -> Void,
        importFilters: @escaping () -> Void
    ) {
        self.context = context
        self.openFilter = openFilter
        self.addFilter = addFilter
        self.updateFilter = updateFilter
        self.exportFilters = exportFilters
        self.importFilters = importFilters
    }
}

private enum AyuGramFiltersSection: Int32 {
    case filters
    case actions
}

private enum AyuGramFiltersEntryId: Hashable {
    case empty
    case filter(String)
    case add
    case export
    case `import`
}

private enum AyuGramFiltersControllerEntry: ItemListNodeEntry {
    case empty
    case filter(Int, AyuGramFilter)
    case add
    case export(AyuGramFilterStore)
    case `import`

    var section: ItemListSectionId {
        switch self {
        case .empty, .filter:
            return AyuGramFiltersSection.filters.rawValue
        case .add, .export, .import:
            return AyuGramFiltersSection.actions.rawValue
        }
    }

    var stableId: AyuGramFiltersEntryId {
        switch self {
        case .empty:
            return .empty
        case let .filter(_, filter):
            return .filter(filter.id)
        case .add:
            return .add
        case .export:
            return .export
        case .import:
            return .import
        }
    }

    static func <(lhs: AyuGramFiltersControllerEntry, rhs: AyuGramFiltersControllerEntry) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return false
        case (.empty, .filter):
            return false
        case (.filter, .empty):
            return true
        case let (.filter(lhsIndex, _), .filter(rhsIndex, _)):
            return lhsIndex < rhsIndex
        case (.empty, _):
            return true
        case (_, .empty):
            return false
        case (.filter, _):
            return true
        case (_, .filter):
            return false
        case (.add, .add), (.export, .export), (.import, .import):
            return false
        case (.add, _):
            return true
        case (_, .add):
            return false
        case (.export, .import):
            return true
        case (.import, .export):
            return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramFiltersControllerArguments

        switch self {
        case .empty:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("No filters configured."),
                sectionId: self.section,
                style: .blocks,
                textAlignment: .center
            )
        case let .filter(_, filter):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: ayuGramFilterDisplayTitle(filter),
                text: ayuGramFilterDisplayLabel(filter),
                value: filter.enabled,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    var filter = filter
                    filter.enabled = value
                    arguments.updateFilter(filter)
                },
                action: {
                    arguments.openFilter(filter)
                }
            )
        case .add:
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Add Filter",
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.addFilter()
                }
            )
        case let .export(store):
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Export JSON to Clipboard",
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.exportFilters(store)
                }
            )
        case .import:
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Import JSON from Clipboard",
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.importFilters()
                }
            )
        }
    }
}

private func ayuGramFiltersControllerEntries(store: AyuGramFilterStore) -> [AyuGramFiltersControllerEntry] {
    var entries: [AyuGramFiltersControllerEntry] = []

    if store.filters.isEmpty {
        entries.append(.empty)
    } else {
        for (index, filter) in store.filters.enumerated() {
            entries.append(.filter(index, filter))
        }
    }

    entries.append(.add)
    entries.append(.export(store))
    entries.append(.import)

    return entries
}

public func ayuGramFiltersController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?

    let updateFilter: (AyuGramFilter) -> Void = { filter in
        let _ = updateAyuGramFilterStore(context: context) { store in
            var store = store
            store.upsert(filter)
            return store
        }.start()
    }

    let arguments = AyuGramFiltersControllerArguments(
        context: context,
        openFilter: { filter in
            pushControllerImpl?(ayuGramFilterEditController(context: context, filter: filter))
        },
        addFilter: {
            pushControllerImpl?(ayuGramFilterEditController(context: context))
        },
        updateFilter: updateFilter,
        exportFilters: { store in
            if let data = try? store.exportedJSONData(), let text = String(data: data, encoding: .utf8) {
                UIPasteboard.general.string = text
            }
        },
        importFilters: {
            guard let string = UIPasteboard.general.string, let data = string.data(using: .utf8), let store = try? AyuGramFilterStore.imported(from: data) else {
                return
            }
            let _ = updateAyuGramFilterStore(context: context) { _ in
                return store
            }.start()
        }
    )

    let filterStore = ayuGramFilterStoreSignal(context: context)

    let signal = combineLatest(
        context.sharedContext.presentationData,
        filterStore
    )
    |> deliverOnMainQueue
    |> map { presentationData, store -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Filters"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuGramFiltersControllerEntries(store: store),
            style: .blocks,
            animateChanges: false
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] controllerToPush in
        (controller?.navigationController as? NavigationController)?.pushViewController(controllerToPush)
    }
    return controller
}

private func ayuGramFilterDisplayTitle(_ filter: AyuGramFilter) -> String {
    let trimmedText = filter.text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedText.isEmpty {
        return "[Empty pattern]"
    }
    if trimmedText.count > 48 {
        return "\(trimmedText.prefix(45))..."
    }
    return trimmedText
}

private func ayuGramFilterDisplayLabel(_ filter: AyuGramFilter) -> String {
    var components: [String] = []
    components.append(filter.enabled ? "Enabled" : "Disabled")
    components.append(filter.reversed ? "Reversed" : "Regex")
    components.append(filter.caseInsensitive ? "Aa off" : "Aa on")
    if let dialogId = filter.dialogId {
        components.append("Dialog \(dialogId)")
    } else if filter.exclusions.isEmpty {
        components.append("Global")
    } else {
        components.append("Global, \(filter.exclusions.count) excluded")
    }
    return components.joined(separator: " - ")
}
