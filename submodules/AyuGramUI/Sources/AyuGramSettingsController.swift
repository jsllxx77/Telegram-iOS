import Foundation
import UIKit
import AccountContext
import AyuGramCore
import Display
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences

private final class AyuGramSettingsControllerArguments {
    let updateSettings: (@escaping (AyuGramSettings) -> AyuGramSettings) -> Void

    init(updateSettings: @escaping (@escaping (AyuGramSettings) -> AyuGramSettings) -> Void) {
        self.updateSettings = updateSettings
    }
}

private enum AyuGramSettingsSection: Int32 {
    case ghostMode
    case messageHistory
    case filters
    case appearance
    case chatControls
    case translation
    case advanced
}

private enum AyuGramSettingsControllerEntry: ItemListNodeEntry {
    case ghostModeHeader
    case useGlobalGhostMode(Bool)

    case messageHistoryHeader
    case saveDeletedMessages(Bool)
    case saveMessagesHistory(Bool)

    case filtersHeader
    case filtersEnabled(Bool)

    case appearanceHeader
    case semiTransparentDeletedMessages(Bool)
    case removeMessageTail(Bool)

    case chatControlsHeader
    case hideFastShare(Bool)
    case showPeerId(AyuPeerIdDisplay)
    case showMessageSeconds(Bool)

    case translationHeader
    case translationProvider(AyuTranslationProvider)

    case advancedHeader
    case crashReporting(Bool)

    var section: ItemListSectionId {
        switch self {
        case .ghostModeHeader, .useGlobalGhostMode:
            return AyuGramSettingsSection.ghostMode.rawValue
        case .messageHistoryHeader, .saveDeletedMessages, .saveMessagesHistory:
            return AyuGramSettingsSection.messageHistory.rawValue
        case .filtersHeader, .filtersEnabled:
            return AyuGramSettingsSection.filters.rawValue
        case .appearanceHeader, .semiTransparentDeletedMessages, .removeMessageTail:
            return AyuGramSettingsSection.appearance.rawValue
        case .chatControlsHeader, .hideFastShare, .showPeerId, .showMessageSeconds:
            return AyuGramSettingsSection.chatControls.rawValue
        case .translationHeader, .translationProvider:
            return AyuGramSettingsSection.translation.rawValue
        case .advancedHeader, .crashReporting:
            return AyuGramSettingsSection.advanced.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostModeHeader:
            return 0
        case .useGlobalGhostMode:
            return 1
        case .messageHistoryHeader:
            return 100
        case .saveDeletedMessages:
            return 101
        case .saveMessagesHistory:
            return 102
        case .filtersHeader:
            return 200
        case .filtersEnabled:
            return 201
        case .appearanceHeader:
            return 300
        case .semiTransparentDeletedMessages:
            return 301
        case .removeMessageTail:
            return 302
        case .chatControlsHeader:
            return 400
        case .hideFastShare:
            return 401
        case .showPeerId:
            return 402
        case .showMessageSeconds:
            return 403
        case .translationHeader:
            return 500
        case .translationProvider:
            return 501
        case .advancedHeader:
            return 600
        case .crashReporting:
            return 601
        }
    }

    static func <(lhs: AyuGramSettingsControllerEntry, rhs: AyuGramSettingsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramSettingsControllerArguments
        switch self {
        case .ghostModeHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "GHOST MODE", sectionId: self.section)
        case let .useGlobalGhostMode(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Use Global Ghost Mode", value: value, section: self.section, arguments: arguments, keyPath: \.useGlobalGhostMode)

        case .messageHistoryHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "MESSAGE HISTORY", sectionId: self.section)
        case let .saveDeletedMessages(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Save Deleted Messages", value: value, section: self.section, arguments: arguments, keyPath: \.saveDeletedMessages)
        case let .saveMessagesHistory(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Save Message Edit History", value: value, section: self.section, arguments: arguments, keyPath: \.saveMessagesHistory)

        case .filtersHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "FILTERS", sectionId: self.section)
        case let .filtersEnabled(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Enable Filters", value: value, section: self.section, arguments: arguments, keyPath: \.filtersEnabled)

        case .appearanceHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "APPEARANCE", sectionId: self.section)
        case let .semiTransparentDeletedMessages(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Semi-Transparent Deleted Messages", value: value, section: self.section, arguments: arguments, keyPath: \.semiTransparentDeletedMessages)
        case let .removeMessageTail(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Remove Message Tail", value: value, section: self.section, arguments: arguments, keyPath: \.removeMessageTail)

        case .chatControlsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "CHAT CONTROLS", sectionId: self.section)
        case let .hideFastShare(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Hide Fast Share", value: value, section: self.section, arguments: arguments, keyPath: \.hideFastShare)
        case let .showPeerId(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Show Peer ID", label: stringForPeerIdDisplay(value), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
        case let .showMessageSeconds(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Show Message Seconds", value: value, section: self.section, arguments: arguments, keyPath: \.showMessageSeconds)

        case .translationHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "TRANSLATION", sectionId: self.section)
        case let .translationProvider(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Translation Provider", label: stringForTranslationProvider(value), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)

        case .advancedHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ADVANCED", sectionId: self.section)
        case let .crashReporting(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Crash Reporting", value: value, section: self.section, arguments: arguments, keyPath: \.crashReporting)
        }
    }
}

private func ayuGramSwitchItem(
    presentationData: ItemListPresentationData,
    title: String,
    value: Bool,
    section: ItemListSectionId,
    arguments: AyuGramSettingsControllerArguments,
    keyPath: WritableKeyPath<AyuGramSettings, Bool>
) -> ListViewItem {
    return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: section, style: .blocks, updated: { value in
        arguments.updateSettings { settings in
            var settings = settings
            settings[keyPath: keyPath] = value
            return settings
        }
    })
}

private func ayuGramSettingsControllerEntries(settings: AyuGramSettings) -> [AyuGramSettingsControllerEntry] {
    var entries: [AyuGramSettingsControllerEntry] = []

    entries.append(.ghostModeHeader)
    entries.append(.useGlobalGhostMode(settings.useGlobalGhostMode))

    entries.append(.messageHistoryHeader)
    entries.append(.saveDeletedMessages(settings.saveDeletedMessages))
    entries.append(.saveMessagesHistory(settings.saveMessagesHistory))

    entries.append(.filtersHeader)
    entries.append(.filtersEnabled(settings.filtersEnabled))

    entries.append(.appearanceHeader)
    entries.append(.semiTransparentDeletedMessages(settings.semiTransparentDeletedMessages))
    entries.append(.removeMessageTail(settings.removeMessageTail))

    entries.append(.chatControlsHeader)
    entries.append(.hideFastShare(settings.hideFastShare))
    entries.append(.showPeerId(settings.showPeerId))
    entries.append(.showMessageSeconds(settings.showMessageSeconds))

    entries.append(.translationHeader)
    entries.append(.translationProvider(settings.translationProvider))

    entries.append(.advancedHeader)
    entries.append(.crashReporting(settings.crashReporting))

    return entries
}

private func stringForPeerIdDisplay(_ value: AyuPeerIdDisplay) -> String {
    switch value {
    case .hidden:
        return "Hidden"
    case .telegramApi:
        return "Telegram API"
    case .botApi:
        return "Bot API"
    }
}

private func stringForTranslationProvider(_ value: AyuTranslationProvider) -> String {
    switch value {
    case .telegram:
        return "Telegram"
    case .google:
        return "Google"
    case .yandex:
        return "Yandex"
    case .native:
        return "Native"
    }
}

public func ayuGramSettingsController(context: AccountContext) -> ViewController {
    let arguments = AyuGramSettingsControllerArguments(updateSettings: { f in
        let _ = updateAyuGramSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    })

    let signal = combineLatest(
        context.sharedContext.presentationData,
        context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.ayuGramSettings])
    )
    |> deliverOnMainQueue
    |> map { presentationData, sharedData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let settings = ayuGramSettings(sharedData: sharedData)

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("AyuGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuGramSettingsControllerEntries(settings: settings),
            style: .blocks,
            animateChanges: false
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
