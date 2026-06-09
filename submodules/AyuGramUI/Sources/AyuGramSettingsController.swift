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
    let openFilters: () -> Void

    init(
        updateSettings: @escaping (@escaping (AyuGramSettings) -> AyuGramSettings) -> Void,
        openFilters: @escaping () -> Void
    ) {
        self.updateSettings = updateSettings
        self.openFilters = openFilters
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
    case globalSendReadMessages(Bool)

    case messageHistoryHeader
    case saveDeletedMessages(Bool)
    case saveMessagesHistory(Bool)

    case filtersHeader
    case filtersEnabled(Bool)
    case filtersEnabledInChats(Bool)
    case filtersList

    case appearanceHeader
    case semiTransparentDeletedMessages(Bool)
    case messageBubbleRadius(Int32)
    case avatarCorners(Int32)
    case singleCornerRadius(Bool)
    case removeMessageTail(Bool)
    case replaceBottomInfoWithIcons(Bool)

    case chatControlsHeader
    case hideFastShare(Bool)
    case showPeerId(AyuPeerIdDisplay)
    case showMessageSeconds(Bool)
    case hideSimilarChannels(Bool)
    case disableOpenLinkWarning(Bool)
    case disableAds(Bool)
    case disableStories(Bool)
    case hidePremiumStatuses(Bool)
    case hideNotificationCounters(Bool)
    case hideNotificationBadge(Bool)
    case hideAllChatsFolder(Bool)

    case translationHeader
    case translationProvider(AyuTranslationProvider)

    case advancedHeader
    case crashReporting(Bool)

    var section: ItemListSectionId {
        switch self {
        case .ghostModeHeader, .useGlobalGhostMode, .globalSendReadMessages:
            return AyuGramSettingsSection.ghostMode.rawValue
        case .messageHistoryHeader, .saveDeletedMessages, .saveMessagesHistory:
            return AyuGramSettingsSection.messageHistory.rawValue
        case .filtersHeader, .filtersEnabled, .filtersEnabledInChats, .filtersList:
            return AyuGramSettingsSection.filters.rawValue
        case .appearanceHeader, .semiTransparentDeletedMessages, .messageBubbleRadius, .avatarCorners, .singleCornerRadius, .removeMessageTail, .replaceBottomInfoWithIcons:
            return AyuGramSettingsSection.appearance.rawValue
        case .chatControlsHeader, .hideFastShare, .showPeerId, .showMessageSeconds, .hideSimilarChannels, .disableOpenLinkWarning, .disableAds, .disableStories, .hidePremiumStatuses, .hideNotificationCounters, .hideNotificationBadge, .hideAllChatsFolder:
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
        case .globalSendReadMessages:
            return 2
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
        case .filtersEnabledInChats:
            return 202
        case .filtersList:
            return 203
        case .appearanceHeader:
            return 300
        case .semiTransparentDeletedMessages:
            return 301
        case .removeMessageTail:
            return 302
        case .messageBubbleRadius:
            return 303
        case .avatarCorners:
            return 304
        case .singleCornerRadius:
            return 305
        case .replaceBottomInfoWithIcons:
            return 306
        case .chatControlsHeader:
            return 400
        case .hideFastShare:
            return 401
        case .showPeerId:
            return 402
        case .showMessageSeconds:
            return 403
        case .hideSimilarChannels:
            return 404
        case .disableOpenLinkWarning:
            return 405
        case .disableAds:
            return 406
        case .disableStories:
            return 407
        case .hidePremiumStatuses:
            return 408
        case .hideNotificationCounters:
            return 409
        case .hideNotificationBadge:
            return 410
        case .hideAllChatsFolder:
            return 411
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
        case let .globalSendReadMessages(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send Read Messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { settings in
                    var settings = settings
                    settings.globalGhostSettings.sendReadMessages = value
                    return settings
                }
            })

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
        case let .filtersEnabledInChats(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Apply Filters in Chats", value: value, section: self.section, arguments: arguments, keyPath: \.filtersEnabledInChats)
        case .filtersList:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Filters", label: "", sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openFilters()
            })

        case .appearanceHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "APPEARANCE", sectionId: self.section)
        case let .semiTransparentDeletedMessages(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Semi-Transparent Deleted Messages", value: value, section: self.section, arguments: arguments, keyPath: \.semiTransparentDeletedMessages)
        case let .messageBubbleRadius(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Message Bubble Radius", label: "\(value)", sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.updateSettings { settings in
                    var settings = settings
                    settings.messageBubbleRadius = nextValue(settings.messageBubbleRadius, values: [0, 4, 8, 12, 15, 16, 20, 24])
                    return settings
                }
            })
        case let .avatarCorners(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Avatar Corners", label: "\(value)", sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.updateSettings { settings in
                    var settings = settings
                    settings.avatarCorners = nextValue(settings.avatarCorners, values: [0, 6, 12, 18, 23])
                    return settings
                }
            })
        case let .singleCornerRadius(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Single Bubble Corner Radius", value: value, section: self.section, arguments: arguments, keyPath: \.singleCornerRadius)
        case let .removeMessageTail(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Remove Message Tail", value: value, section: self.section, arguments: arguments, keyPath: \.removeMessageTail)
        case let .replaceBottomInfoWithIcons(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Bottom Info Icons", value: value, section: self.section, arguments: arguments, keyPath: \.replaceBottomInfoWithIcons)

        case .chatControlsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "CHAT CONTROLS", sectionId: self.section)
        case let .hideFastShare(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Hide Fast Share", value: value, section: self.section, arguments: arguments, keyPath: \.hideFastShare)
        case let .showPeerId(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Show Peer ID", label: stringForPeerIdDisplay(value), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.updateSettings { settings in
                    var settings = settings
                    settings.showPeerId = nextPeerIdDisplay(settings.showPeerId)
                    return settings
                }
            })
        case let .showMessageSeconds(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Show Message Seconds", value: value, section: self.section, arguments: arguments, keyPath: \.showMessageSeconds)
        case let .hideSimilarChannels(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Hide Similar Channels", value: value, section: self.section, arguments: arguments, keyPath: \.hideSimilarChannels)
        case let .disableOpenLinkWarning(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Disable Open Link Warning", value: value, section: self.section, arguments: arguments, keyPath: \.disableOpenLinkWarning)
        case let .disableAds(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Disable Ads", value: value, section: self.section, arguments: arguments, keyPath: \.disableAds)
        case let .disableStories(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Disable Stories", value: value, section: self.section, arguments: arguments, keyPath: \.disableStories)
        case let .hidePremiumStatuses(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Hide Premium Statuses", value: value, section: self.section, arguments: arguments, keyPath: \.hidePremiumStatuses)
        case let .hideNotificationCounters(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Hide Notification Counters", value: value, section: self.section, arguments: arguments, keyPath: \.hideNotificationCounters)
        case let .hideNotificationBadge(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Hide Notification Badge", value: value, section: self.section, arguments: arguments, keyPath: \.hideNotificationBadge)
        case let .hideAllChatsFolder(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Hide All Chats Folder", value: value, section: self.section, arguments: arguments, keyPath: \.hideAllChatsFolder)

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
    if settings.useGlobalGhostMode {
        entries.append(.globalSendReadMessages(settings.globalGhostSettings.sendReadMessages))
    }

    entries.append(.messageHistoryHeader)
    entries.append(.saveDeletedMessages(settings.saveDeletedMessages))
    entries.append(.saveMessagesHistory(settings.saveMessagesHistory))

    entries.append(.filtersHeader)
    entries.append(.filtersEnabled(settings.filtersEnabled))
    entries.append(.filtersEnabledInChats(settings.filtersEnabledInChats))
    entries.append(.filtersList)

    entries.append(.appearanceHeader)
    entries.append(.semiTransparentDeletedMessages(settings.semiTransparentDeletedMessages))
    entries.append(.messageBubbleRadius(settings.messageBubbleRadius))
    entries.append(.avatarCorners(settings.avatarCorners))
    entries.append(.singleCornerRadius(settings.singleCornerRadius))
    entries.append(.removeMessageTail(settings.removeMessageTail))
    entries.append(.replaceBottomInfoWithIcons(settings.replaceBottomInfoWithIcons))

    entries.append(.chatControlsHeader)
    entries.append(.hideFastShare(settings.hideFastShare))
    entries.append(.showPeerId(settings.showPeerId))
    entries.append(.showMessageSeconds(settings.showMessageSeconds))
    entries.append(.hideSimilarChannels(settings.hideSimilarChannels))
    entries.append(.disableOpenLinkWarning(settings.disableOpenLinkWarning))
    entries.append(.disableAds(settings.disableAds))
    entries.append(.disableStories(settings.disableStories))
    entries.append(.hidePremiumStatuses(settings.hidePremiumStatuses))
    entries.append(.hideNotificationCounters(settings.hideNotificationCounters))
    entries.append(.hideNotificationBadge(settings.hideNotificationBadge))
    entries.append(.hideAllChatsFolder(settings.hideAllChatsFolder))

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

private func nextPeerIdDisplay(_ value: AyuPeerIdDisplay) -> AyuPeerIdDisplay {
    switch value {
    case .hidden:
        return .telegramApi
    case .telegramApi:
        return .botApi
    case .botApi:
        return .hidden
    }
}

private func nextValue(_ value: Int32, values: [Int32]) -> Int32 {
    guard !values.isEmpty else {
        return value
    }
    if let index = values.firstIndex(of: value) {
        return values[(index + 1) % values.count]
    }
    return values[0]
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
    var pushControllerImpl: ((ViewController) -> Void)?
    let arguments = AyuGramSettingsControllerArguments(updateSettings: { f in
        let _ = updateAyuGramSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }, openFilters: {
        pushControllerImpl?(ayuGramFiltersController(context: context))
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

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] controllerToPush in
        (controller?.navigationController as? NavigationController)?.pushViewController(controllerToPush)
    }
    return controller
}
