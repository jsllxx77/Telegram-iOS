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

private struct AyuGramFilterEditState: Equatable {
    var text: String
    var enabled: Bool
    var reversed: Bool
    var caseInsensitive: Bool
    var dialogIdText: String
    var exclusionsText: String

    var canSave: Bool {
        return !self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private final class AyuGramFilterEditControllerArguments {
    let context: AccountContext
    let updateState: ((AyuGramFilterEditState) -> AyuGramFilterEditState) -> Void
    let save: () -> Void
    let delete: () -> Void

    init(
        context: AccountContext,
        updateState: @escaping ((AyuGramFilterEditState) -> AyuGramFilterEditState) -> Void,
        save: @escaping () -> Void,
        delete: @escaping () -> Void
    ) {
        self.context = context
        self.updateState = updateState
        self.save = save
        self.delete = delete
    }
}

private enum AyuGramFilterEditSection: Int32 {
    case pattern
    case scope
    case options
    case actions
}

private enum AyuGramFilterEditEntryId: Hashable {
    case pattern
    case dialogId
    case exclusions
    case info
    case enabled
    case reversed
    case caseInsensitive
    case delete
}

private enum AyuGramFilterEditControllerEntry: ItemListNodeEntry {
    case pattern(String)
    case dialogId(String)
    case exclusions(String)
    case info(String)
    case enabled(Bool)
    case reversed(Bool)
    case caseInsensitive(Bool)
    case delete

    var section: ItemListSectionId {
        switch self {
        case .pattern:
            return AyuGramFilterEditSection.pattern.rawValue
        case .dialogId, .exclusions, .info:
            return AyuGramFilterEditSection.scope.rawValue
        case .enabled, .reversed, .caseInsensitive:
            return AyuGramFilterEditSection.options.rawValue
        case .delete:
            return AyuGramFilterEditSection.actions.rawValue
        }
    }

    var stableId: AyuGramFilterEditEntryId {
        switch self {
        case .pattern:
            return .pattern
        case .dialogId:
            return .dialogId
        case .exclusions:
            return .exclusions
        case .info:
            return .info
        case .enabled:
            return .enabled
        case .reversed:
            return .reversed
        case .caseInsensitive:
            return .caseInsensitive
        case .delete:
            return .delete
        }
    }

    static func <(lhs: AyuGramFilterEditControllerEntry, rhs: AyuGramFilterEditControllerEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    private var sortIndex: Int32 {
        switch self {
        case .pattern:
            return 0
        case .dialogId:
            return 100
        case .exclusions:
            return 101
        case .info:
            return 102
        case .enabled:
            return 200
        case .reversed:
            return 201
        case .caseInsensitive:
            return 202
        case .delete:
            return 300
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramFilterEditControllerArguments

        switch self {
        case let .pattern(text):
            return ItemListSingleLineInputItem(
                context: arguments.context,
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(),
                text: text,
                placeholder: "Regular expression",
                type: .regular(capitalization: false, autocorrection: false),
                returnKeyType: .done,
                clearType: .always,
                sectionId: self.section,
                textUpdated: { value in
                    arguments.updateState { state in
                        var state = state
                        state.text = value
                        return state
                    }
                },
                action: {
                    arguments.save()
                }
            )
        case let .dialogId(text):
            return ItemListSingleLineInputItem(
                context: arguments.context,
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(string: "Dialog"),
                text: text,
                placeholder: "Empty means global",
                type: .number,
                returnKeyType: .done,
                clearType: .always,
                sectionId: self.section,
                textUpdated: { value in
                    arguments.updateState { state in
                        var state = state
                        state.dialogIdText = value
                        return state
                    }
                },
                action: {}
            )
        case let .exclusions(text):
            return ItemListSingleLineInputItem(
                context: arguments.context,
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(string: "Exclude"),
                text: text,
                placeholder: "Global exclusions, comma separated",
                type: .regular(capitalization: false, autocorrection: false),
                returnKeyType: .done,
                clearType: .always,
                sectionId: self.section,
                textUpdated: { value in
                    arguments.updateState { state in
                        var state = state
                        state.exclusionsText = value
                        return state
                    }
                },
                action: {}
            )
        case let .info(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section
            )
        case let .enabled(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Enabled",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateState { state in
                        var state = state
                        state.enabled = value
                        return state
                    }
                }
            )
        case let .reversed(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Reverse Match",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateState { state in
                        var state = state
                        state.reversed = value
                        return state
                    }
                }
            )
        case let .caseInsensitive(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Case Insensitive",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateState { state in
                        var state = state
                        state.caseInsensitive = value
                        return state
                    }
                }
            )
        case .delete:
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Delete Filter",
                kind: .destructive,
                alignment: .center,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.delete()
                }
            )
        }
    }
}

private func ayuGramFilterEditControllerEntries(state: AyuGramFilterEditState, isEditingExistingFilter: Bool) -> [AyuGramFilterEditControllerEntry] {
    var entries: [AyuGramFilterEditControllerEntry] = []

    entries.append(.pattern(state.text))
    entries.append(.dialogId(state.dialogIdText))
    entries.append(.exclusions(state.exclusionsText))
    entries.append(.info("Global filters apply to every chat unless excluded. Dialog filters apply only to the specified dialog ID."))
    entries.append(.enabled(state.enabled))
    entries.append(.reversed(state.reversed))
    entries.append(.caseInsensitive(state.caseInsensitive))
    if isEditingExistingFilter {
        entries.append(.delete)
    }

    return entries
}

public func ayuGramFilterEditController(
    context: AccountContext,
    filter: AyuGramFilter? = nil,
    initialText: String = "",
    initialDialogId: Int64? = nil
) -> ViewController {
    let initialState = AyuGramFilterEditState(
        text: filter?.text ?? initialText,
        enabled: filter?.enabled ?? true,
        reversed: filter?.reversed ?? false,
        caseInsensitive: filter?.caseInsensitive ?? true,
        dialogIdText: (filter?.dialogId ?? initialDialogId).map { "\($0)" } ?? "",
        exclusionsText: ayuGramFilterExclusionsText(filter?.exclusions ?? Set())
    )

    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: (((AyuGramFilterEditState) -> AyuGramFilterEditState) -> Void) = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    var dismissImpl: (() -> Void)?

    let saveImpl: () -> Void = {
        let state = stateValue.with { $0 }
        guard state.canSave else {
            return
        }
        var updatedFilter = filter ?? AyuGramFilter(text: state.text)
        updatedFilter.text = state.text.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedFilter.enabled = state.enabled
        updatedFilter.reversed = state.reversed
        updatedFilter.caseInsensitive = state.caseInsensitive
        updatedFilter.dialogId = ayuGramFilterInt64(from: state.dialogIdText)
        updatedFilter.exclusions = ayuGramFilterInt64Set(from: state.exclusionsText)

        let _ = (updateAyuGramFilterStore(context: context) { store in
            var store = store
            store.upsert(updatedFilter)
            return store
        }
        |> deliverOnMainQueue).start(completed: {
            dismissImpl?()
        })
    }

    let deleteImpl: () -> Void = {
        guard let filter = filter else {
            return
        }
        let _ = (updateAyuGramFilterStore(context: context) { store in
            var store = store
            let _ = store.delete(id: filter.id)
            return store
        }
        |> deliverOnMainQueue).start(completed: {
            dismissImpl?()
        })
    }

    let arguments = AyuGramFilterEditControllerArguments(
        context: context,
        updateState: updateState,
        save: saveImpl,
        delete: deleteImpl
    )

    let signal = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(filter == nil ? "Add Filter" : "Edit Filter"),
            leftNavigationButton: nil,
            rightNavigationButton: ItemListNavigationButton(
                content: .text("Save"),
                style: .bold,
                enabled: state.canSave,
                action: {
                    saveImpl()
                }
            ),
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuGramFilterEditControllerEntries(state: state, isEditingExistingFilter: filter != nil),
            style: .blocks,
            animateChanges: false
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    dismissImpl = { [weak controller] in
        controller?.view.endEditing(true)
        if let navigationController = controller?.navigationController as? NavigationController {
            let _ = navigationController.popViewController(animated: true)
        } else {
            controller?.dismiss()
        }
    }
    return controller
}

private func ayuGramFilterExclusionsText(_ exclusions: Set<Int64>) -> String {
    return exclusions.sorted().map { "\($0)" }.joined(separator: ", ")
}

private func ayuGramFilterInt64(from text: String) -> Int64? {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else {
        return nil
    }
    return Int64(trimmedText)
}

private func ayuGramFilterInt64Set(from text: String) -> Set<Int64> {
    let components = text.split(separator: ",")
    var result = Set<Int64>()
    for component in components {
        let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int64(trimmed) {
            result.insert(value)
        }
    }
    return result
}
