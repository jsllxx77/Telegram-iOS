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
    let presentationData: () -> PresentationData
    let presentController: (ViewController, Any?) -> Void

    init(
        updateSettings: @escaping (@escaping (AyuGramSettings) -> AyuGramSettings) -> Void,
        openFilters: @escaping () -> Void,
        presentationData: @escaping () -> PresentationData,
        presentController: @escaping (ViewController, Any?) -> Void
    ) {
        self.updateSettings = updateSettings
        self.openFilters = openFilters
        self.presentationData = presentationData
        self.presentController = presentController
    }
}

private enum AyuGramSettingsSection: Int32 {
    case ghostMode
    case messageHistory
    case messageShot
    case filters
    case appearance
    case chatControls
    case composer
    case drawer
    case translation
    case webView
    case advanced
}

private enum AyuGramSettingsControllerEntry: ItemListNodeEntry {
    case ghostModeHeader
    case useGlobalGhostMode(Bool)
    case globalSendReadMessages(Bool)

    case messageHistoryHeader
    case saveDeletedMessages(Bool)
    case saveMessagesHistory(Bool)

    case messageShotHeader
    case showMessageShot(Bool)
    case messageShotShowBackground(Bool)
    case messageShotShowDate(Bool)
    case messageShotShowReactions(Bool)
    case messageShotShowHeaderDecorations(Bool)
    case messageShotShowColorfulReplies(Bool)
    case messageShotRevealSpoilers(Bool)
    case messageShotEmbeddedTheme(Bool)

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

    case composerHeader
    case showAttachButtonInMessageField(Bool)
    case showCommandsButtonInMessageField(Bool)
    case showEmojiButtonInMessageField(Bool)
    case showMicrophoneButtonInMessageField(Bool)
    case showAutoDeleteButtonInMessageField(Bool)
    case showGiftButtonInMessageField(Bool)
    case showAiEditorButtonInMessageField(Bool)
    case showAttachPopup(Bool)
    case showEmojiPopup(Bool)

    case drawerHeader
    case showMyProfileInDrawer(Bool)
    case showBotsInDrawer(Bool)
    case showNewGroupInDrawer(Bool)
    case showNewChannelInDrawer(Bool)
    case showContactsInDrawer(Bool)
    case showCallsInDrawer(Bool)
    case showSavedMessagesInDrawer(Bool)
    case showLReadToggleInDrawer(Bool)
    case showSReadToggleInDrawer(Bool)
    case showNightModeToggleInDrawer(Bool)
    case showGhostToggleInDrawer(Bool)
    case showStreamerToggleInDrawer(Bool)
    case showGhostToggleInTray(Bool)
    case showStreamerToggleInTray(Bool)

    case translationHeader
    case translationProvider(AyuTranslationProvider)

    case webViewHeader
    case spoofWebviewAsAndroid(Bool)
    case increaseWebviewHeight(Bool)
    case increaseWebviewWidth(Bool)

    case advancedHeader
    case streamerModeEnabled(Bool)
    case crashReporting(Bool)

    var section: ItemListSectionId {
        switch self {
        case .ghostModeHeader, .useGlobalGhostMode, .globalSendReadMessages:
            return AyuGramSettingsSection.ghostMode.rawValue
        case .messageHistoryHeader, .saveDeletedMessages, .saveMessagesHistory:
            return AyuGramSettingsSection.messageHistory.rawValue
        case .messageShotHeader, .showMessageShot, .messageShotShowBackground, .messageShotShowDate, .messageShotShowReactions, .messageShotShowHeaderDecorations, .messageShotShowColorfulReplies, .messageShotRevealSpoilers, .messageShotEmbeddedTheme:
            return AyuGramSettingsSection.messageShot.rawValue
        case .filtersHeader, .filtersEnabled, .filtersEnabledInChats, .filtersList:
            return AyuGramSettingsSection.filters.rawValue
        case .appearanceHeader, .semiTransparentDeletedMessages, .messageBubbleRadius, .avatarCorners, .singleCornerRadius, .removeMessageTail, .replaceBottomInfoWithIcons:
            return AyuGramSettingsSection.appearance.rawValue
        case .chatControlsHeader, .hideFastShare, .showPeerId, .showMessageSeconds, .hideSimilarChannels, .disableOpenLinkWarning, .disableAds, .disableStories, .hidePremiumStatuses, .hideNotificationCounters, .hideNotificationBadge, .hideAllChatsFolder:
            return AyuGramSettingsSection.chatControls.rawValue
        case .composerHeader, .showAttachButtonInMessageField, .showCommandsButtonInMessageField, .showEmojiButtonInMessageField, .showMicrophoneButtonInMessageField, .showAutoDeleteButtonInMessageField, .showGiftButtonInMessageField, .showAiEditorButtonInMessageField, .showAttachPopup, .showEmojiPopup:
            return AyuGramSettingsSection.composer.rawValue
        case .drawerHeader, .showMyProfileInDrawer, .showBotsInDrawer, .showNewGroupInDrawer, .showNewChannelInDrawer, .showContactsInDrawer, .showCallsInDrawer, .showSavedMessagesInDrawer, .showLReadToggleInDrawer, .showSReadToggleInDrawer, .showNightModeToggleInDrawer, .showGhostToggleInDrawer, .showStreamerToggleInDrawer, .showGhostToggleInTray, .showStreamerToggleInTray:
            return AyuGramSettingsSection.drawer.rawValue
        case .translationHeader, .translationProvider:
            return AyuGramSettingsSection.translation.rawValue
        case .webViewHeader, .spoofWebviewAsAndroid, .increaseWebviewHeight, .increaseWebviewWidth:
            return AyuGramSettingsSection.webView.rawValue
        case .advancedHeader, .streamerModeEnabled, .crashReporting:
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
        case .messageShotHeader:
            return 150
        case .showMessageShot:
            return 151
        case .messageShotShowBackground:
            return 152
        case .messageShotShowDate:
            return 153
        case .messageShotShowReactions:
            return 154
        case .messageShotShowHeaderDecorations:
            return 155
        case .messageShotShowColorfulReplies:
            return 156
        case .messageShotRevealSpoilers:
            return 157
        case .messageShotEmbeddedTheme:
            return 158
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
        case .composerHeader:
            return 450
        case .showAttachButtonInMessageField:
            return 451
        case .showCommandsButtonInMessageField:
            return 452
        case .showEmojiButtonInMessageField:
            return 453
        case .showMicrophoneButtonInMessageField:
            return 454
        case .showAutoDeleteButtonInMessageField:
            return 455
        case .showGiftButtonInMessageField:
            return 456
        case .showAiEditorButtonInMessageField:
            return 457
        case .showAttachPopup:
            return 458
        case .showEmojiPopup:
            return 459
        case .drawerHeader:
            return 470
        case .showMyProfileInDrawer:
            return 471
        case .showBotsInDrawer:
            return 472
        case .showNewGroupInDrawer:
            return 473
        case .showNewChannelInDrawer:
            return 474
        case .showContactsInDrawer:
            return 475
        case .showCallsInDrawer:
            return 476
        case .showSavedMessagesInDrawer:
            return 477
        case .showLReadToggleInDrawer:
            return 478
        case .showSReadToggleInDrawer:
            return 479
        case .showNightModeToggleInDrawer:
            return 480
        case .showGhostToggleInDrawer:
            return 481
        case .showStreamerToggleInDrawer:
            return 482
        case .showGhostToggleInTray:
            return 483
        case .showStreamerToggleInTray:
            return 484
        case .translationHeader:
            return 500
        case .translationProvider:
            return 501
        case .webViewHeader:
            return 520
        case .spoofWebviewAsAndroid:
            return 521
        case .increaseWebviewHeight:
            return 522
        case .increaseWebviewWidth:
            return 523
        case .advancedHeader:
            return 600
        case .streamerModeEnabled:
            return 601
        case .crashReporting:
            return 602
        }
    }

    static func <(lhs: AyuGramSettingsControllerEntry, rhs: AyuGramSettingsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramSettingsControllerArguments
        let localized: (String) -> String = { value in
            return ayuGramLocalized(value, languageCode: presentationData.strings.baseLanguageCode)
        }
        switch self {
        case .ghostModeHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("GHOST MODE"), sectionId: self.section)
        case let .useGlobalGhostMode(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Use Global Ghost Mode", value: value, section: self.section, arguments: arguments, keyPath: \.useGlobalGhostMode)
        case let .globalSendReadMessages(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: localized("Send Read Messages"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { settings in
                    var settings = settings
                    settings.globalGhostSettings.sendReadMessages = value
                    return settings
                }
            })

        case .messageHistoryHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("MESSAGE HISTORY"), sectionId: self.section)
        case let .saveDeletedMessages(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Save Deleted Messages", value: value, section: self.section, arguments: arguments, keyPath: \.saveDeletedMessages)
        case let .saveMessagesHistory(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Save Message Edit History", value: value, section: self.section, arguments: arguments, keyPath: \.saveMessagesHistory)

        case .messageShotHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("MESSAGE SHOT"), sectionId: self.section)
        case let .showMessageShot(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Show Message Shot", value: value, section: self.section, arguments: arguments, keyPath: \.showMessageShot)
        case let .messageShotShowBackground(value):
            return ayuGramMessageShotSwitchItem(presentationData: presentationData, title: "Background", value: value, section: self.section, arguments: arguments, keyPath: \.showBackground)
        case let .messageShotShowDate(value):
            return ayuGramMessageShotSwitchItem(presentationData: presentationData, title: "Date", value: value, section: self.section, arguments: arguments, keyPath: \.showDate)
        case let .messageShotShowReactions(value):
            return ayuGramMessageShotSwitchItem(presentationData: presentationData, title: "Reactions", value: value, section: self.section, arguments: arguments, keyPath: \.showReactions)
        case let .messageShotShowHeaderDecorations(value):
            return ayuGramMessageShotSwitchItem(presentationData: presentationData, title: "Header Decorations", value: value, section: self.section, arguments: arguments, keyPath: \.showHeaderDecorations)
        case let .messageShotShowColorfulReplies(value):
            return ayuGramMessageShotSwitchItem(presentationData: presentationData, title: "Colorful Replies", value: value, section: self.section, arguments: arguments, keyPath: \.showColorfulReplies)
        case let .messageShotRevealSpoilers(value):
            return ayuGramMessageShotSwitchItem(presentationData: presentationData, title: "Reveal Spoilers", value: value, section: self.section, arguments: arguments, keyPath: \.revealSpoilers)
        case let .messageShotEmbeddedTheme(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: localized("Embedded Theme"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { settings in
                    var settings = settings
                    settings.messageShotSettings.embeddedThemeType = value ? 0 : -1
                    return settings
                }
            })

        case .filtersHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("FILTERS"), sectionId: self.section)
        case let .filtersEnabled(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Enable Filters", value: value, section: self.section, arguments: arguments, keyPath: \.filtersEnabled)
        case let .filtersEnabledInChats(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Apply Filters in Chats", value: value, section: self.section, arguments: arguments, keyPath: \.filtersEnabledInChats)
        case .filtersList:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: localized("Filters"), label: "", sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openFilters()
            })

        case .appearanceHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("APPEARANCE"), sectionId: self.section)
        case let .semiTransparentDeletedMessages(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Semi-Transparent Deleted Messages", value: value, section: self.section, arguments: arguments, keyPath: \.semiTransparentDeletedMessages)
        case let .messageBubbleRadius(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: localized("Message Bubble Radius"), label: "\(value)", sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.updateSettings { settings in
                    var settings = settings
                    settings.messageBubbleRadius = nextValue(settings.messageBubbleRadius, values: [0, 4, 8, 12, 15, 16, 20, 24])
                    return settings
                }
            })
        case let .avatarCorners(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: localized("Avatar Corners"), label: "\(value)", sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
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
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("CHAT CONTROLS"), sectionId: self.section)
        case let .hideFastShare(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Hide Fast Share", value: value, section: self.section, arguments: arguments, keyPath: \.hideFastShare)
        case let .showPeerId(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: localized("Show Peer ID"), label: stringForPeerIdDisplay(value, languageCode: presentationData.strings.baseLanguageCode), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
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

        case .composerHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("COMPOSER"), sectionId: self.section)
        case let .showAttachButtonInMessageField(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Attach Button", value: value, section: self.section, arguments: arguments, keyPath: \.showAttachButtonInMessageField)
        case let .showCommandsButtonInMessageField(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Commands Button", value: value, section: self.section, arguments: arguments, keyPath: \.showCommandsButtonInMessageField)
        case let .showEmojiButtonInMessageField(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Emoji Button", value: value, section: self.section, arguments: arguments, keyPath: \.showEmojiButtonInMessageField)
        case let .showMicrophoneButtonInMessageField(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Microphone Button", value: value, section: self.section, arguments: arguments, keyPath: \.showMicrophoneButtonInMessageField)
        case let .showAutoDeleteButtonInMessageField(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Auto-Delete Button", value: value, section: self.section, arguments: arguments, keyPath: \.showAutoDeleteButtonInMessageField)
        case let .showGiftButtonInMessageField(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Gift Button", value: value, section: self.section, arguments: arguments, keyPath: \.showGiftButtonInMessageField)
        case let .showAiEditorButtonInMessageField(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "AI Editor Button", value: value, section: self.section, arguments: arguments, keyPath: \.showAiEditorButtonInMessageField)
        case let .showAttachPopup(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Attach Popup", value: value, section: self.section, arguments: arguments, keyPath: \.showAttachPopup)
        case let .showEmojiPopup(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Emoji Popup", value: value, section: self.section, arguments: arguments, keyPath: \.showEmojiPopup)

        case .drawerHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("DRAWER"), sectionId: self.section)
        case let .showMyProfileInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "My Profile", value: value, section: self.section, arguments: arguments, keyPath: \.showMyProfileInDrawer)
        case let .showBotsInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Bots", value: value, section: self.section, arguments: arguments, keyPath: \.showBotsInDrawer)
        case let .showNewGroupInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "New Group", value: value, section: self.section, arguments: arguments, keyPath: \.showNewGroupInDrawer)
        case let .showNewChannelInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "New Channel", value: value, section: self.section, arguments: arguments, keyPath: \.showNewChannelInDrawer)
        case let .showContactsInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Contacts", value: value, section: self.section, arguments: arguments, keyPath: \.showContactsInDrawer)
        case let .showCallsInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Calls", value: value, section: self.section, arguments: arguments, keyPath: \.showCallsInDrawer)
        case let .showSavedMessagesInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Saved Messages", value: value, section: self.section, arguments: arguments, keyPath: \.showSavedMessagesInDrawer)
        case let .showLReadToggleInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Local Read Toggle", value: value, section: self.section, arguments: arguments, keyPath: \.showLReadToggleInDrawer)
        case let .showSReadToggleInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Server Read Toggle", value: value, section: self.section, arguments: arguments, keyPath: \.showSReadToggleInDrawer)
        case let .showNightModeToggleInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Night Mode Toggle", value: value, section: self.section, arguments: arguments, keyPath: \.showNightModeToggleInDrawer)
        case let .showGhostToggleInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Ghost Toggle", value: value, section: self.section, arguments: arguments, keyPath: \.showGhostToggleInDrawer)
        case let .showStreamerToggleInDrawer(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Streamer Toggle", value: value, section: self.section, arguments: arguments, keyPath: \.showStreamerToggleInDrawer)
        case let .showGhostToggleInTray(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Ghost Tray Toggle", value: value, section: self.section, arguments: arguments, keyPath: \.showGhostToggleInTray)
        case let .showStreamerToggleInTray(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Streamer Tray Toggle", value: value, section: self.section, arguments: arguments, keyPath: \.showStreamerToggleInTray)

        case .translationHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("TRANSLATION"), sectionId: self.section)
        case let .translationProvider(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: localized("Translation Provider"), label: stringForTranslationProvider(value, languageCode: presentationData.strings.baseLanguageCode), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                presentTranslationProviderSheet(presentationData: arguments.presentationData(), current: value, arguments: arguments)
            })

        case .webViewHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("WEB VIEW"), sectionId: self.section)
        case let .spoofWebviewAsAndroid(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Spoof as Android", value: value, section: self.section, arguments: arguments, keyPath: \.spoofWebviewAsAndroid)
        case let .increaseWebviewHeight(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Increase WebView Height", value: value, section: self.section, arguments: arguments, keyPath: \.increaseWebviewHeight)
        case let .increaseWebviewWidth(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Increase WebView Width", value: value, section: self.section, arguments: arguments, keyPath: \.increaseWebviewWidth)

        case .advancedHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: localized("ADVANCED"), sectionId: self.section)
        case let .streamerModeEnabled(value):
            return ayuGramSwitchItem(presentationData: presentationData, title: "Streamer Mode", value: value, section: self.section, arguments: arguments, keyPath: \.streamerModeEnabled)
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
    let localizedTitle = ayuGramLocalized(title, languageCode: presentationData.strings.baseLanguageCode)
    return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: localizedTitle, value: value, sectionId: section, style: .blocks, updated: { value in
        arguments.updateSettings { settings in
            var settings = settings
            settings[keyPath: keyPath] = value
            return settings
        }
    })
}

private func ayuGramMessageShotSwitchItem(
    presentationData: ItemListPresentationData,
    title: String,
    value: Bool,
    section: ItemListSectionId,
    arguments: AyuGramSettingsControllerArguments,
    keyPath: WritableKeyPath<AyuGramMessageShotSettings, Bool>
) -> ListViewItem {
    let localizedTitle = ayuGramLocalized(title, languageCode: presentationData.strings.baseLanguageCode)
    return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: localizedTitle, value: value, sectionId: section, style: .blocks, updated: { value in
        arguments.updateSettings { settings in
            var settings = settings
            settings.messageShotSettings[keyPath: keyPath] = value
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

    entries.append(.messageShotHeader)
    entries.append(.showMessageShot(settings.showMessageShot))
    if settings.showMessageShot {
        entries.append(.messageShotShowBackground(settings.messageShotSettings.showBackground))
        entries.append(.messageShotShowDate(settings.messageShotSettings.showDate))
        entries.append(.messageShotShowReactions(settings.messageShotSettings.showReactions))
        entries.append(.messageShotShowHeaderDecorations(settings.messageShotSettings.showHeaderDecorations))
        entries.append(.messageShotShowColorfulReplies(settings.messageShotSettings.showColorfulReplies))
        entries.append(.messageShotRevealSpoilers(settings.messageShotSettings.revealSpoilers))
        entries.append(.messageShotEmbeddedTheme(settings.messageShotSettings.embeddedThemeType != -1))
    }

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

    entries.append(.composerHeader)
    entries.append(.showAttachButtonInMessageField(settings.showAttachButtonInMessageField))
    entries.append(.showCommandsButtonInMessageField(settings.showCommandsButtonInMessageField))
    entries.append(.showEmojiButtonInMessageField(settings.showEmojiButtonInMessageField))
    entries.append(.showMicrophoneButtonInMessageField(settings.showMicrophoneButtonInMessageField))
    entries.append(.showAutoDeleteButtonInMessageField(settings.showAutoDeleteButtonInMessageField))
    entries.append(.showGiftButtonInMessageField(settings.showGiftButtonInMessageField))
    entries.append(.showAiEditorButtonInMessageField(settings.showAiEditorButtonInMessageField))
    entries.append(.showAttachPopup(settings.showAttachPopup))
    entries.append(.showEmojiPopup(settings.showEmojiPopup))

    entries.append(.drawerHeader)
    entries.append(.showMyProfileInDrawer(settings.showMyProfileInDrawer))
    entries.append(.showBotsInDrawer(settings.showBotsInDrawer))
    entries.append(.showNewGroupInDrawer(settings.showNewGroupInDrawer))
    entries.append(.showNewChannelInDrawer(settings.showNewChannelInDrawer))
    entries.append(.showContactsInDrawer(settings.showContactsInDrawer))
    entries.append(.showCallsInDrawer(settings.showCallsInDrawer))
    entries.append(.showSavedMessagesInDrawer(settings.showSavedMessagesInDrawer))
    entries.append(.showLReadToggleInDrawer(settings.showLReadToggleInDrawer))
    entries.append(.showSReadToggleInDrawer(settings.showSReadToggleInDrawer))
    entries.append(.showNightModeToggleInDrawer(settings.showNightModeToggleInDrawer))
    entries.append(.showGhostToggleInDrawer(settings.showGhostToggleInDrawer))
    entries.append(.showStreamerToggleInDrawer(settings.showStreamerToggleInDrawer))
    entries.append(.showGhostToggleInTray(settings.showGhostToggleInTray))
    entries.append(.showStreamerToggleInTray(settings.showStreamerToggleInTray))

    entries.append(.translationHeader)
    entries.append(.translationProvider(settings.translationProvider))

    entries.append(.webViewHeader)
    entries.append(.spoofWebviewAsAndroid(settings.spoofWebviewAsAndroid))
    entries.append(.increaseWebviewHeight(settings.increaseWebviewHeight))
    entries.append(.increaseWebviewWidth(settings.increaseWebviewWidth))

    entries.append(.advancedHeader)
    entries.append(.streamerModeEnabled(settings.streamerModeEnabled))
    entries.append(.crashReporting(settings.crashReporting))

    return entries
}

private func stringForPeerIdDisplay(_ value: AyuPeerIdDisplay, languageCode: String) -> String {
    switch value {
    case .hidden:
        return ayuGramLocalized("Hidden", languageCode: languageCode)
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

private func stringForTranslationProvider(_ value: AyuTranslationProvider, languageCode: String) -> String {
    switch value {
    case .telegram:
        return "Telegram"
    case .google:
        return "Google"
    case .yandex:
        return "Yandex"
    case .native:
        return ayuGramLocalized("Native", languageCode: languageCode)
    }
}

private func presentTranslationProviderSheet(presentationData: PresentationData, current: AyuTranslationProvider, arguments: AyuGramSettingsControllerArguments) {
    let languageCode = presentationData.strings.baseLanguageCode
    let localized: (String) -> String = { value in
        return ayuGramLocalized(value, languageCode: languageCode)
    }
    let actionSheet = ActionSheetController(presentationData: presentationData)
    let dismissAction: () -> Void = { [weak actionSheet] in
        actionSheet?.dismissAnimated()
    }
    let selectProvider: (AyuTranslationProvider) -> Void = { provider in
        let apply: () -> Void = {
            arguments.updateSettings { settings in
                var settings = settings
                settings.translationProvider = provider
                return settings
            }
        }
        if provider == .google || provider == .yandex {
            let warningSheet = ActionSheetController(presentationData: presentationData)
            let dismissWarning: () -> Void = { [weak warningSheet] in
                warningSheet?.dismissAnimated()
            }
            warningSheet.setItemGroups([
                ActionSheetItemGroup(items: [
                    ActionSheetTextItem(title: ayuGramIsChineseLanguage(languageCode) ? "\(stringForTranslationProvider(provider, languageCode: languageCode)) 翻译会把文本发送给第三方服务。文本离开 Telegram 后，Telegram 无法再保护这些内容。" : "\(stringForTranslationProvider(provider, languageCode: languageCode)) translations send text to a third-party service. Telegram cannot protect that text once it leaves Telegram."),
                    ActionSheetButtonItem(title: ayuGramIsChineseLanguage(languageCode) ? "使用 \(stringForTranslationProvider(provider, languageCode: languageCode))" : "Use \(stringForTranslationProvider(provider, languageCode: languageCode))", color: .accent, action: {
                        dismissWarning()
                        apply()
                    })
                ]),
                ActionSheetItemGroup(items: [
                    ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: {
                        dismissWarning()
                    })
                ])
            ])
            arguments.presentController(warningSheet, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
        } else {
            apply()
        }
    }

    let providers: [AyuTranslationProvider] = [.telegram, .google, .yandex, .native]
    actionSheet.setItemGroups([
        ActionSheetItemGroup(items: providers.map { provider in
            ActionSheetButtonItem(title: current == provider ? "\(stringForTranslationProvider(provider, languageCode: languageCode)) (\(localized("current")))" : stringForTranslationProvider(provider, languageCode: languageCode), color: .accent, action: {
                dismissAction()
                selectProvider(provider)
            })
        }),
        ActionSheetItemGroup(items: [
            ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: {
                dismissAction()
            })
        ])
    ])
    arguments.presentController(actionSheet, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
}

public func ayuGramSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let currentPresentationData = Atomic<PresentationData?>(value: nil)
    let arguments = AyuGramSettingsControllerArguments(updateSettings: { f in
        let _ = updateAyuGramSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }, openFilters: {
        pushControllerImpl?(ayuGramFiltersController(context: context))
    }, presentationData: {
        return currentPresentationData.with { $0 } ?? context.sharedContext.currentPresentationData.with { $0 }
    }, presentController: { controller, arguments in
        presentControllerImpl?(controller, arguments)
    })

    let signal = combineLatest(
        context.sharedContext.presentationData,
        context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.ayuGramSettings])
    )
    |> deliverOnMainQueue
    |> map { presentationData, sharedData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let _ = currentPresentationData.swap(presentationData)
        let settings = ayuGramSettings(sharedData: sharedData)

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(ayuGramLocalized("AyuGram", languageCode: presentationData.strings.baseLanguageCode)),
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
    presentControllerImpl = { [weak controller] controllerToPresent, arguments in
        controller?.present(controllerToPresent, in: .window(.root), with: arguments)
    }
    return controller
}
