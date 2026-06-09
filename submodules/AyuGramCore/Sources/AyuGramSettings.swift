public struct AyuGramMessageShotSettings: Codable, Equatable {
    public var showBackground: Bool
    public var showDate: Bool
    public var showReactions: Bool
    public var showHeaderDecorations: Bool
    public var showColorfulReplies: Bool
    public var revealSpoilers: Bool
    public var embeddedThemeType: Int32
    public var embeddedThemeAccentColor: Int32
    public var cloudThemeId: Int64
    public var cloudThemeAccessHash: Int64
    public var cloudThemeDocumentId: Int64
    public var cloudThemeTitle: String
    public var cloudThemeAccountId: Int64

    public static let defaultSettings = AyuGramMessageShotSettings()

    public init(
        showBackground: Bool = true,
        showDate: Bool = false,
        showReactions: Bool = false,
        showHeaderDecorations: Bool = true,
        showColorfulReplies: Bool = true,
        revealSpoilers: Bool = true,
        embeddedThemeType: Int32 = -1,
        embeddedThemeAccentColor: Int32 = 0,
        cloudThemeId: Int64 = 0,
        cloudThemeAccessHash: Int64 = 0,
        cloudThemeDocumentId: Int64 = 0,
        cloudThemeTitle: String = "",
        cloudThemeAccountId: Int64 = 0
    ) {
        self.showBackground = showBackground
        self.showDate = showDate
        self.showReactions = showReactions
        self.showHeaderDecorations = showHeaderDecorations
        self.showColorfulReplies = showColorfulReplies
        self.revealSpoilers = revealSpoilers
        self.embeddedThemeType = embeddedThemeType
        self.embeddedThemeAccentColor = embeddedThemeAccentColor
        self.cloudThemeId = cloudThemeId
        self.cloudThemeAccessHash = cloudThemeAccessHash
        self.cloudThemeDocumentId = cloudThemeDocumentId
        self.cloudThemeTitle = cloudThemeTitle
        self.cloudThemeAccountId = cloudThemeAccountId
    }

    private enum CodingKeys: String, CodingKey {
        case showBackground
        case showDate
        case showReactions
        case showHeaderDecorations
        case showColorfulReplies
        case revealSpoilers
        case embeddedThemeType
        case embeddedThemeAccentColor
        case cloudThemeId
        case cloudThemeAccessHash
        case cloudThemeDocumentId
        case cloudThemeTitle
        case cloudThemeAccountId
    }

    public init(from decoder: Decoder) throws {
        let defaults = Self.defaultSettings
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.showBackground = container.decodeIfPresent(Bool.self, forKey: .showBackground, fallback: defaults.showBackground)
        self.showDate = container.decodeIfPresent(Bool.self, forKey: .showDate, fallback: defaults.showDate)
        self.showReactions = container.decodeIfPresent(Bool.self, forKey: .showReactions, fallback: defaults.showReactions)
        self.showHeaderDecorations = container.decodeIfPresent(Bool.self, forKey: .showHeaderDecorations, fallback: defaults.showHeaderDecorations)
        self.showColorfulReplies = container.decodeIfPresent(Bool.self, forKey: .showColorfulReplies, fallback: defaults.showColorfulReplies)
        self.revealSpoilers = container.decodeIfPresent(Bool.self, forKey: .revealSpoilers, fallback: defaults.revealSpoilers)
        self.embeddedThemeType = container.decodeIfPresent(Int32.self, forKey: .embeddedThemeType, fallback: defaults.embeddedThemeType)
        self.embeddedThemeAccentColor = container.decodeIfPresent(Int32.self, forKey: .embeddedThemeAccentColor, fallback: defaults.embeddedThemeAccentColor)
        self.cloudThemeId = container.decodeIfPresent(Int64.self, forKey: .cloudThemeId, fallback: defaults.cloudThemeId)
        self.cloudThemeAccessHash = container.decodeIfPresent(Int64.self, forKey: .cloudThemeAccessHash, fallback: defaults.cloudThemeAccessHash)
        self.cloudThemeDocumentId = container.decodeIfPresent(Int64.self, forKey: .cloudThemeDocumentId, fallback: defaults.cloudThemeDocumentId)
        self.cloudThemeTitle = container.decodeIfPresent(String.self, forKey: .cloudThemeTitle, fallback: defaults.cloudThemeTitle)
        self.cloudThemeAccountId = container.decodeIfPresent(Int64.self, forKey: .cloudThemeAccountId, fallback: defaults.cloudThemeAccountId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.showBackground, forKey: .showBackground)
        try container.encode(self.showDate, forKey: .showDate)
        try container.encode(self.showReactions, forKey: .showReactions)
        try container.encode(self.showHeaderDecorations, forKey: .showHeaderDecorations)
        try container.encode(self.showColorfulReplies, forKey: .showColorfulReplies)
        try container.encode(self.revealSpoilers, forKey: .revealSpoilers)
        try container.encode(self.embeddedThemeType, forKey: .embeddedThemeType)
        try container.encode(self.embeddedThemeAccentColor, forKey: .embeddedThemeAccentColor)
        try container.encode(self.cloudThemeId, forKey: .cloudThemeId)
        try container.encode(self.cloudThemeAccessHash, forKey: .cloudThemeAccessHash)
        try container.encode(self.cloudThemeDocumentId, forKey: .cloudThemeDocumentId)
        try container.encode(self.cloudThemeTitle, forKey: .cloudThemeTitle)
        try container.encode(self.cloudThemeAccountId, forKey: .cloudThemeAccountId)
    }
}

private struct AyuGramGhostAccountSettingsEntry: Codable, Equatable {
    var accountId: Int64
    var settings: AyuGramGhostSettings

    init(accountId: Int64, settings: AyuGramGhostSettings) {
        self.accountId = accountId
        self.settings = settings
    }

    private enum CodingKeys: String, CodingKey {
        case accountId
        case settings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let accountId = try? container.decode(Int64.self, forKey: .accountId) else {
            throw DecodingError.keyNotFound(
                CodingKeys.accountId,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing ghost account id"
                )
            )
        }

        self.accountId = accountId
        self.settings = container.decodeIfPresent(AyuGramGhostSettings.self, forKey: .settings, fallback: .defaultSettings)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.accountId, forKey: .accountId)
        try container.encode(self.settings, forKey: .settings)
    }
}

public struct AyuGramSettings: Codable, Equatable {
    public var saveDeletedMessages: Bool
    public var saveMessagesHistory: Bool
    public var saveForBots: Bool
    public var shadowBanIds: Set<Int64>
    public var filtersEnabled: Bool
    public var filtersEnabledInChats: Bool
    public var hideFromBlocked: Bool
    public var semiTransparentDeletedMessages: Bool
    public var disableAds: Bool
    public var disableStories: Bool
    public var disableCustomBackgrounds: Bool
    public var showOnlyAddedEmojisAndStickers: Bool
    public var collapseSimilarChannels: Bool
    public var hideSimilarChannels: Bool
    public var messageBubbleRadius: Int32
    public var disableOpenLinkWarning: Bool
    public var wideMultiplier: Double
    public var spoofWebviewAsAndroid: Bool
    public var increaseWebviewHeight: Bool
    public var increaseWebviewWidth: Bool
    public var materialSwitches: Bool
    public var removeMessageTail: Bool
    public var disableNotificationsDelay: Bool
    public var localPremium: Bool
    public var showChannelReactions: Bool
    public var showGroupReactions: Bool
    public var showPrivateChatReactions: Bool
    public var appIcon: String
    public var simpleQuotesAndReplies: Bool
    public var hideFastShare: Bool
    public var replaceBottomInfoWithIcons: Bool
    public var deletedMark: String
    public var editedMark: String
    public var recentStickersCount: Int32
    public var showReactionsPanelInContextMenu: AyuContextMenuVisibility
    public var showViewsPanelInContextMenu: AyuContextMenuVisibility
    public var showHideMessageInContextMenu: AyuContextMenuVisibility
    public var showUserMessagesInContextMenu: AyuContextMenuVisibility
    public var showMessageDetailsInContextMenu: AyuContextMenuVisibility
    public var showRepeatMessageInContextMenu: AyuContextMenuVisibility
    public var showAddFilterInContextMenu: AyuContextMenuVisibility
    public var showAttachButtonInMessageField: Bool
    public var showCommandsButtonInMessageField: Bool
    public var showEmojiButtonInMessageField: Bool
    public var showMicrophoneButtonInMessageField: Bool
    public var showAutoDeleteButtonInMessageField: Bool
    public var showGiftButtonInMessageField: Bool
    public var showAiEditorButtonInMessageField: Bool
    public var showAttachPopup: Bool
    public var showEmojiPopup: Bool
    public var showMyProfileInDrawer: Bool
    public var showBotsInDrawer: Bool
    public var showNewGroupInDrawer: Bool
    public var showNewChannelInDrawer: Bool
    public var showContactsInDrawer: Bool
    public var showCallsInDrawer: Bool
    public var showSavedMessagesInDrawer: Bool
    public var showLReadToggleInDrawer: Bool
    public var showSReadToggleInDrawer: Bool
    public var showNightModeToggleInDrawer: Bool
    public var showGhostToggleInDrawer: Bool
    public var showStreamerToggleInDrawer: Bool
    public var showGhostToggleInTray: Bool
    public var showStreamerToggleInTray: Bool
    public var hidePremiumStatuses: Bool
    public var monoFont: String
    public var hideNotificationCounters: Bool
    public var hideNotificationBadge: Bool
    public var hideAllChatsFolder: Bool
    public var channelBottomButton: AyuChannelBottomButton
    public var quickAdminShortcuts: Bool
    public var showPeerId: AyuPeerIdDisplay
    public var showMessageSeconds: Bool
    public var showMessageShot: Bool
    public var filterZalgo: Bool
    public var stickerConfirmation: Bool
    public var gifConfirmation: Bool
    public var voiceConfirmation: Bool
    public var translationProvider: AyuTranslationProvider
    public var adaptiveCoverColor: Bool
    public var improveLinkPreviews: Bool
    public var crashReporting: Bool
    public var avatarCorners: Int32
    public var singleCornerRadius: Bool
    public var useGlobalGhostMode: Bool
    public var globalGhostSettings: AyuGramGhostSettings
    public var ghostAccounts: [Int64: AyuGramGhostSettings]
    public var messageShotSettings: AyuGramMessageShotSettings

    public static let defaultSettings = AyuGramSettings()

    public init(
        saveDeletedMessages: Bool = true,
        saveMessagesHistory: Bool = true,
        saveForBots: Bool = false,
        shadowBanIds: Set<Int64> = Set(),
        filtersEnabled: Bool = false,
        filtersEnabledInChats: Bool = false,
        hideFromBlocked: Bool = false,
        semiTransparentDeletedMessages: Bool = false,
        disableAds: Bool = true,
        disableStories: Bool = false,
        disableCustomBackgrounds: Bool = false,
        showOnlyAddedEmojisAndStickers: Bool = false,
        collapseSimilarChannels: Bool = true,
        hideSimilarChannels: Bool = false,
        messageBubbleRadius: Int32 = 16,
        disableOpenLinkWarning: Bool = false,
        wideMultiplier: Double = 1.0,
        spoofWebviewAsAndroid: Bool = false,
        increaseWebviewHeight: Bool = false,
        increaseWebviewWidth: Bool = false,
        materialSwitches: Bool = true,
        removeMessageTail: Bool = false,
        disableNotificationsDelay: Bool = false,
        localPremium: Bool = false,
        showChannelReactions: Bool = true,
        showGroupReactions: Bool = true,
        showPrivateChatReactions: Bool = true,
        appIcon: String = "",
        simpleQuotesAndReplies: Bool = false,
        hideFastShare: Bool = false,
        replaceBottomInfoWithIcons: Bool = true,
        deletedMark: String = "",
        editedMark: String = "",
        recentStickersCount: Int32 = 100,
        showReactionsPanelInContextMenu: AyuContextMenuVisibility = .visible,
        showViewsPanelInContextMenu: AyuContextMenuVisibility = .visible,
        showHideMessageInContextMenu: AyuContextMenuVisibility = .hidden,
        showUserMessagesInContextMenu: AyuContextMenuVisibility = .visibleWithModifier,
        showMessageDetailsInContextMenu: AyuContextMenuVisibility = .visibleWithModifier,
        showRepeatMessageInContextMenu: AyuContextMenuVisibility = .hidden,
        showAddFilterInContextMenu: AyuContextMenuVisibility = .visible,
        showAttachButtonInMessageField: Bool = true,
        showCommandsButtonInMessageField: Bool = true,
        showEmojiButtonInMessageField: Bool = true,
        showMicrophoneButtonInMessageField: Bool = true,
        showAutoDeleteButtonInMessageField: Bool = true,
        showGiftButtonInMessageField: Bool = true,
        showAiEditorButtonInMessageField: Bool = true,
        showAttachPopup: Bool = true,
        showEmojiPopup: Bool = true,
        showMyProfileInDrawer: Bool = true,
        showBotsInDrawer: Bool = true,
        showNewGroupInDrawer: Bool = true,
        showNewChannelInDrawer: Bool = true,
        showContactsInDrawer: Bool = true,
        showCallsInDrawer: Bool = true,
        showSavedMessagesInDrawer: Bool = true,
        showLReadToggleInDrawer: Bool = false,
        showSReadToggleInDrawer: Bool = true,
        showNightModeToggleInDrawer: Bool = true,
        showGhostToggleInDrawer: Bool = true,
        showStreamerToggleInDrawer: Bool = false,
        showGhostToggleInTray: Bool = true,
        showStreamerToggleInTray: Bool = false,
        hidePremiumStatuses: Bool = false,
        monoFont: String = "",
        hideNotificationCounters: Bool = false,
        hideNotificationBadge: Bool = false,
        hideAllChatsFolder: Bool = false,
        channelBottomButton: AyuChannelBottomButton = .discussWithFallback,
        quickAdminShortcuts: Bool = true,
        showPeerId: AyuPeerIdDisplay = .botApi,
        showMessageSeconds: Bool = false,
        showMessageShot: Bool = true,
        filterZalgo: Bool = false,
        stickerConfirmation: Bool = false,
        gifConfirmation: Bool = false,
        voiceConfirmation: Bool = false,
        translationProvider: AyuTranslationProvider = .telegram,
        adaptiveCoverColor: Bool = true,
        improveLinkPreviews: Bool = false,
        crashReporting: Bool = true,
        avatarCorners: Int32 = 23,
        singleCornerRadius: Bool = false,
        useGlobalGhostMode: Bool = true,
        globalGhostSettings: AyuGramGhostSettings = .defaultSettings,
        ghostAccounts: [Int64: AyuGramGhostSettings] = [:],
        messageShotSettings: AyuGramMessageShotSettings = .defaultSettings
    ) {
        self.saveDeletedMessages = saveDeletedMessages
        self.saveMessagesHistory = saveMessagesHistory
        self.saveForBots = saveForBots
        self.shadowBanIds = shadowBanIds
        self.filtersEnabled = filtersEnabled
        self.filtersEnabledInChats = filtersEnabledInChats
        self.hideFromBlocked = hideFromBlocked
        self.semiTransparentDeletedMessages = semiTransparentDeletedMessages
        self.disableAds = disableAds
        self.disableStories = disableStories
        self.disableCustomBackgrounds = disableCustomBackgrounds
        self.showOnlyAddedEmojisAndStickers = showOnlyAddedEmojisAndStickers
        self.collapseSimilarChannels = collapseSimilarChannels
        self.hideSimilarChannels = hideSimilarChannels
        self.messageBubbleRadius = messageBubbleRadius
        self.disableOpenLinkWarning = disableOpenLinkWarning
        self.wideMultiplier = wideMultiplier
        self.spoofWebviewAsAndroid = spoofWebviewAsAndroid
        self.increaseWebviewHeight = increaseWebviewHeight
        self.increaseWebviewWidth = increaseWebviewWidth
        self.materialSwitches = materialSwitches
        self.removeMessageTail = removeMessageTail
        self.disableNotificationsDelay = disableNotificationsDelay
        self.localPremium = localPremium
        self.showChannelReactions = showChannelReactions
        self.showGroupReactions = showGroupReactions
        self.showPrivateChatReactions = showPrivateChatReactions
        self.appIcon = appIcon
        self.simpleQuotesAndReplies = simpleQuotesAndReplies
        self.hideFastShare = hideFastShare
        self.replaceBottomInfoWithIcons = replaceBottomInfoWithIcons
        self.deletedMark = deletedMark
        self.editedMark = editedMark
        self.recentStickersCount = recentStickersCount
        self.showReactionsPanelInContextMenu = showReactionsPanelInContextMenu
        self.showViewsPanelInContextMenu = showViewsPanelInContextMenu
        self.showHideMessageInContextMenu = showHideMessageInContextMenu
        self.showUserMessagesInContextMenu = showUserMessagesInContextMenu
        self.showMessageDetailsInContextMenu = showMessageDetailsInContextMenu
        self.showRepeatMessageInContextMenu = showRepeatMessageInContextMenu
        self.showAddFilterInContextMenu = showAddFilterInContextMenu
        self.showAttachButtonInMessageField = showAttachButtonInMessageField
        self.showCommandsButtonInMessageField = showCommandsButtonInMessageField
        self.showEmojiButtonInMessageField = showEmojiButtonInMessageField
        self.showMicrophoneButtonInMessageField = showMicrophoneButtonInMessageField
        self.showAutoDeleteButtonInMessageField = showAutoDeleteButtonInMessageField
        self.showGiftButtonInMessageField = showGiftButtonInMessageField
        self.showAiEditorButtonInMessageField = showAiEditorButtonInMessageField
        self.showAttachPopup = showAttachPopup
        self.showEmojiPopup = showEmojiPopup
        self.showMyProfileInDrawer = showMyProfileInDrawer
        self.showBotsInDrawer = showBotsInDrawer
        self.showNewGroupInDrawer = showNewGroupInDrawer
        self.showNewChannelInDrawer = showNewChannelInDrawer
        self.showContactsInDrawer = showContactsInDrawer
        self.showCallsInDrawer = showCallsInDrawer
        self.showSavedMessagesInDrawer = showSavedMessagesInDrawer
        self.showLReadToggleInDrawer = showLReadToggleInDrawer
        self.showSReadToggleInDrawer = showSReadToggleInDrawer
        self.showNightModeToggleInDrawer = showNightModeToggleInDrawer
        self.showGhostToggleInDrawer = showGhostToggleInDrawer
        self.showStreamerToggleInDrawer = showStreamerToggleInDrawer
        self.showGhostToggleInTray = showGhostToggleInTray
        self.showStreamerToggleInTray = showStreamerToggleInTray
        self.hidePremiumStatuses = hidePremiumStatuses
        self.monoFont = monoFont
        self.hideNotificationCounters = hideNotificationCounters
        self.hideNotificationBadge = hideNotificationBadge
        self.hideAllChatsFolder = hideAllChatsFolder
        self.channelBottomButton = channelBottomButton
        self.quickAdminShortcuts = quickAdminShortcuts
        self.showPeerId = showPeerId
        self.showMessageSeconds = showMessageSeconds
        self.showMessageShot = showMessageShot
        self.filterZalgo = filterZalgo
        self.stickerConfirmation = stickerConfirmation
        self.gifConfirmation = gifConfirmation
        self.voiceConfirmation = voiceConfirmation
        self.translationProvider = translationProvider
        self.adaptiveCoverColor = adaptiveCoverColor
        self.improveLinkPreviews = improveLinkPreviews
        self.crashReporting = crashReporting
        self.avatarCorners = avatarCorners
        self.singleCornerRadius = singleCornerRadius
        self.useGlobalGhostMode = useGlobalGhostMode
        self.globalGhostSettings = globalGhostSettings
        self.ghostAccounts = ghostAccounts
        self.messageShotSettings = messageShotSettings
    }

    private enum CodingKeys: String, CodingKey {
        case saveDeletedMessages
        case saveMessagesHistory
        case saveForBots
        case shadowBanIds
        case filtersEnabled
        case filtersEnabledInChats
        case hideFromBlocked
        case semiTransparentDeletedMessages
        case disableAds
        case disableStories
        case disableCustomBackgrounds
        case showOnlyAddedEmojisAndStickers
        case collapseSimilarChannels
        case hideSimilarChannels
        case messageBubbleRadius
        case disableOpenLinkWarning
        case wideMultiplier
        case spoofWebviewAsAndroid
        case increaseWebviewHeight
        case increaseWebviewWidth
        case materialSwitches
        case removeMessageTail
        case disableNotificationsDelay
        case localPremium
        case showChannelReactions
        case showGroupReactions
        case showPrivateChatReactions
        case appIcon
        case simpleQuotesAndReplies
        case hideFastShare
        case replaceBottomInfoWithIcons
        case deletedMark
        case editedMark
        case recentStickersCount
        case showReactionsPanelInContextMenu
        case showViewsPanelInContextMenu
        case showHideMessageInContextMenu
        case showUserMessagesInContextMenu
        case showMessageDetailsInContextMenu
        case showRepeatMessageInContextMenu
        case showAddFilterInContextMenu
        case showAttachButtonInMessageField
        case showCommandsButtonInMessageField
        case showEmojiButtonInMessageField
        case showMicrophoneButtonInMessageField
        case showAutoDeleteButtonInMessageField
        case showGiftButtonInMessageField
        case showAiEditorButtonInMessageField
        case showAttachPopup
        case showEmojiPopup
        case showMyProfileInDrawer
        case showBotsInDrawer
        case showNewGroupInDrawer
        case showNewChannelInDrawer
        case showContactsInDrawer
        case showCallsInDrawer
        case showSavedMessagesInDrawer
        case showLReadToggleInDrawer
        case showSReadToggleInDrawer
        case showNightModeToggleInDrawer
        case showGhostToggleInDrawer
        case showStreamerToggleInDrawer
        case showGhostToggleInTray
        case showStreamerToggleInTray
        case hidePremiumStatuses
        case monoFont
        case hideNotificationCounters
        case hideNotificationBadge
        case hideAllChatsFolder
        case channelBottomButton
        case quickAdminShortcuts
        case showPeerId
        case showMessageSeconds
        case showMessageShot
        case filterZalgo
        case stickerConfirmation
        case gifConfirmation
        case voiceConfirmation
        case translationProvider
        case adaptiveCoverColor
        case improveLinkPreviews
        case crashReporting
        case avatarCorners
        case singleCornerRadius
        case useGlobalGhostMode
        case globalGhostSettings
        case ghostAccounts
        case messageShotSettings
    }

    public init(from decoder: Decoder) throws {
        let defaults = Self.defaultSettings
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.saveDeletedMessages = container.decodeIfPresent(Bool.self, forKey: .saveDeletedMessages, fallback: defaults.saveDeletedMessages)
        self.saveMessagesHistory = container.decodeIfPresent(Bool.self, forKey: .saveMessagesHistory, fallback: defaults.saveMessagesHistory)
        self.saveForBots = container.decodeIfPresent(Bool.self, forKey: .saveForBots, fallback: defaults.saveForBots)
        self.shadowBanIds = container.decodeIfPresent(Set<Int64>.self, forKey: .shadowBanIds, fallback: defaults.shadowBanIds)
        self.filtersEnabled = container.decodeIfPresent(Bool.self, forKey: .filtersEnabled, fallback: defaults.filtersEnabled)
        self.filtersEnabledInChats = container.decodeIfPresent(Bool.self, forKey: .filtersEnabledInChats, fallback: defaults.filtersEnabledInChats)
        self.hideFromBlocked = container.decodeIfPresent(Bool.self, forKey: .hideFromBlocked, fallback: defaults.hideFromBlocked)
        self.semiTransparentDeletedMessages = container.decodeIfPresent(Bool.self, forKey: .semiTransparentDeletedMessages, fallback: defaults.semiTransparentDeletedMessages)
        self.disableAds = container.decodeIfPresent(Bool.self, forKey: .disableAds, fallback: defaults.disableAds)
        self.disableStories = container.decodeIfPresent(Bool.self, forKey: .disableStories, fallback: defaults.disableStories)
        self.disableCustomBackgrounds = container.decodeIfPresent(Bool.self, forKey: .disableCustomBackgrounds, fallback: defaults.disableCustomBackgrounds)
        self.showOnlyAddedEmojisAndStickers = container.decodeIfPresent(Bool.self, forKey: .showOnlyAddedEmojisAndStickers, fallback: defaults.showOnlyAddedEmojisAndStickers)
        self.collapseSimilarChannels = container.decodeIfPresent(Bool.self, forKey: .collapseSimilarChannels, fallback: defaults.collapseSimilarChannels)
        self.hideSimilarChannels = container.decodeIfPresent(Bool.self, forKey: .hideSimilarChannels, fallback: defaults.hideSimilarChannels)
        self.messageBubbleRadius = container.decodeIfPresent(Int32.self, forKey: .messageBubbleRadius, fallback: defaults.messageBubbleRadius)
        self.disableOpenLinkWarning = container.decodeIfPresent(Bool.self, forKey: .disableOpenLinkWarning, fallback: defaults.disableOpenLinkWarning)
        self.wideMultiplier = container.decodeIfPresent(Double.self, forKey: .wideMultiplier, fallback: defaults.wideMultiplier)
        self.spoofWebviewAsAndroid = container.decodeIfPresent(Bool.self, forKey: .spoofWebviewAsAndroid, fallback: defaults.spoofWebviewAsAndroid)
        self.increaseWebviewHeight = container.decodeIfPresent(Bool.self, forKey: .increaseWebviewHeight, fallback: defaults.increaseWebviewHeight)
        self.increaseWebviewWidth = container.decodeIfPresent(Bool.self, forKey: .increaseWebviewWidth, fallback: defaults.increaseWebviewWidth)
        self.materialSwitches = container.decodeIfPresent(Bool.self, forKey: .materialSwitches, fallback: defaults.materialSwitches)
        self.removeMessageTail = container.decodeIfPresent(Bool.self, forKey: .removeMessageTail, fallback: defaults.removeMessageTail)
        self.disableNotificationsDelay = container.decodeIfPresent(Bool.self, forKey: .disableNotificationsDelay, fallback: defaults.disableNotificationsDelay)
        self.localPremium = container.decodeIfPresent(Bool.self, forKey: .localPremium, fallback: defaults.localPremium)
        self.showChannelReactions = container.decodeIfPresent(Bool.self, forKey: .showChannelReactions, fallback: defaults.showChannelReactions)
        self.showGroupReactions = container.decodeIfPresent(Bool.self, forKey: .showGroupReactions, fallback: defaults.showGroupReactions)
        self.showPrivateChatReactions = container.decodeIfPresent(Bool.self, forKey: .showPrivateChatReactions, fallback: defaults.showPrivateChatReactions)
        self.appIcon = container.decodeIfPresent(String.self, forKey: .appIcon, fallback: defaults.appIcon)
        self.simpleQuotesAndReplies = container.decodeIfPresent(Bool.self, forKey: .simpleQuotesAndReplies, fallback: defaults.simpleQuotesAndReplies)
        self.hideFastShare = container.decodeIfPresent(Bool.self, forKey: .hideFastShare, fallback: defaults.hideFastShare)
        self.replaceBottomInfoWithIcons = container.decodeIfPresent(Bool.self, forKey: .replaceBottomInfoWithIcons, fallback: defaults.replaceBottomInfoWithIcons)
        self.deletedMark = container.decodeIfPresent(String.self, forKey: .deletedMark, fallback: defaults.deletedMark)
        self.editedMark = container.decodeIfPresent(String.self, forKey: .editedMark, fallback: defaults.editedMark)
        self.recentStickersCount = container.decodeIfPresent(Int32.self, forKey: .recentStickersCount, fallback: defaults.recentStickersCount)
        self.showReactionsPanelInContextMenu = container.decodeRawValueEnum(AyuContextMenuVisibility.self, forKey: .showReactionsPanelInContextMenu, fallback: defaults.showReactionsPanelInContextMenu)
        self.showViewsPanelInContextMenu = container.decodeRawValueEnum(AyuContextMenuVisibility.self, forKey: .showViewsPanelInContextMenu, fallback: defaults.showViewsPanelInContextMenu)
        self.showHideMessageInContextMenu = container.decodeRawValueEnum(AyuContextMenuVisibility.self, forKey: .showHideMessageInContextMenu, fallback: defaults.showHideMessageInContextMenu)
        self.showUserMessagesInContextMenu = container.decodeRawValueEnum(AyuContextMenuVisibility.self, forKey: .showUserMessagesInContextMenu, fallback: defaults.showUserMessagesInContextMenu)
        self.showMessageDetailsInContextMenu = container.decodeRawValueEnum(AyuContextMenuVisibility.self, forKey: .showMessageDetailsInContextMenu, fallback: defaults.showMessageDetailsInContextMenu)
        self.showRepeatMessageInContextMenu = container.decodeRawValueEnum(AyuContextMenuVisibility.self, forKey: .showRepeatMessageInContextMenu, fallback: defaults.showRepeatMessageInContextMenu)
        self.showAddFilterInContextMenu = container.decodeRawValueEnum(AyuContextMenuVisibility.self, forKey: .showAddFilterInContextMenu, fallback: defaults.showAddFilterInContextMenu)
        self.showAttachButtonInMessageField = container.decodeIfPresent(Bool.self, forKey: .showAttachButtonInMessageField, fallback: defaults.showAttachButtonInMessageField)
        self.showCommandsButtonInMessageField = container.decodeIfPresent(Bool.self, forKey: .showCommandsButtonInMessageField, fallback: defaults.showCommandsButtonInMessageField)
        self.showEmojiButtonInMessageField = container.decodeIfPresent(Bool.self, forKey: .showEmojiButtonInMessageField, fallback: defaults.showEmojiButtonInMessageField)
        self.showMicrophoneButtonInMessageField = container.decodeIfPresent(Bool.self, forKey: .showMicrophoneButtonInMessageField, fallback: defaults.showMicrophoneButtonInMessageField)
        self.showAutoDeleteButtonInMessageField = container.decodeIfPresent(Bool.self, forKey: .showAutoDeleteButtonInMessageField, fallback: defaults.showAutoDeleteButtonInMessageField)
        self.showGiftButtonInMessageField = container.decodeIfPresent(Bool.self, forKey: .showGiftButtonInMessageField, fallback: defaults.showGiftButtonInMessageField)
        self.showAiEditorButtonInMessageField = container.decodeIfPresent(Bool.self, forKey: .showAiEditorButtonInMessageField, fallback: defaults.showAiEditorButtonInMessageField)
        self.showAttachPopup = container.decodeIfPresent(Bool.self, forKey: .showAttachPopup, fallback: defaults.showAttachPopup)
        self.showEmojiPopup = container.decodeIfPresent(Bool.self, forKey: .showEmojiPopup, fallback: defaults.showEmojiPopup)
        self.showMyProfileInDrawer = container.decodeIfPresent(Bool.self, forKey: .showMyProfileInDrawer, fallback: defaults.showMyProfileInDrawer)
        self.showBotsInDrawer = container.decodeIfPresent(Bool.self, forKey: .showBotsInDrawer, fallback: defaults.showBotsInDrawer)
        self.showNewGroupInDrawer = container.decodeIfPresent(Bool.self, forKey: .showNewGroupInDrawer, fallback: defaults.showNewGroupInDrawer)
        self.showNewChannelInDrawer = container.decodeIfPresent(Bool.self, forKey: .showNewChannelInDrawer, fallback: defaults.showNewChannelInDrawer)
        self.showContactsInDrawer = container.decodeIfPresent(Bool.self, forKey: .showContactsInDrawer, fallback: defaults.showContactsInDrawer)
        self.showCallsInDrawer = container.decodeIfPresent(Bool.self, forKey: .showCallsInDrawer, fallback: defaults.showCallsInDrawer)
        self.showSavedMessagesInDrawer = container.decodeIfPresent(Bool.self, forKey: .showSavedMessagesInDrawer, fallback: defaults.showSavedMessagesInDrawer)
        self.showLReadToggleInDrawer = container.decodeIfPresent(Bool.self, forKey: .showLReadToggleInDrawer, fallback: defaults.showLReadToggleInDrawer)
        self.showSReadToggleInDrawer = container.decodeIfPresent(Bool.self, forKey: .showSReadToggleInDrawer, fallback: defaults.showSReadToggleInDrawer)
        self.showNightModeToggleInDrawer = container.decodeIfPresent(Bool.self, forKey: .showNightModeToggleInDrawer, fallback: defaults.showNightModeToggleInDrawer)
        self.showGhostToggleInDrawer = container.decodeIfPresent(Bool.self, forKey: .showGhostToggleInDrawer, fallback: defaults.showGhostToggleInDrawer)
        self.showStreamerToggleInDrawer = container.decodeIfPresent(Bool.self, forKey: .showStreamerToggleInDrawer, fallback: defaults.showStreamerToggleInDrawer)
        self.showGhostToggleInTray = container.decodeIfPresent(Bool.self, forKey: .showGhostToggleInTray, fallback: defaults.showGhostToggleInTray)
        self.showStreamerToggleInTray = container.decodeIfPresent(Bool.self, forKey: .showStreamerToggleInTray, fallback: defaults.showStreamerToggleInTray)
        self.hidePremiumStatuses = container.decodeIfPresent(Bool.self, forKey: .hidePremiumStatuses, fallback: defaults.hidePremiumStatuses)
        self.monoFont = container.decodeIfPresent(String.self, forKey: .monoFont, fallback: defaults.monoFont)
        self.hideNotificationCounters = container.decodeIfPresent(Bool.self, forKey: .hideNotificationCounters, fallback: defaults.hideNotificationCounters)
        self.hideNotificationBadge = container.decodeIfPresent(Bool.self, forKey: .hideNotificationBadge, fallback: defaults.hideNotificationBadge)
        self.hideAllChatsFolder = container.decodeIfPresent(Bool.self, forKey: .hideAllChatsFolder, fallback: defaults.hideAllChatsFolder)
        self.channelBottomButton = container.decodeRawValueEnum(AyuChannelBottomButton.self, forKey: .channelBottomButton, fallback: defaults.channelBottomButton)
        self.quickAdminShortcuts = container.decodeIfPresent(Bool.self, forKey: .quickAdminShortcuts, fallback: defaults.quickAdminShortcuts)
        self.showPeerId = container.decodeRawValueEnum(AyuPeerIdDisplay.self, forKey: .showPeerId, fallback: defaults.showPeerId)
        self.showMessageSeconds = container.decodeIfPresent(Bool.self, forKey: .showMessageSeconds, fallback: defaults.showMessageSeconds)
        self.showMessageShot = container.decodeIfPresent(Bool.self, forKey: .showMessageShot, fallback: defaults.showMessageShot)
        self.filterZalgo = container.decodeIfPresent(Bool.self, forKey: .filterZalgo, fallback: defaults.filterZalgo)
        self.stickerConfirmation = container.decodeIfPresent(Bool.self, forKey: .stickerConfirmation, fallback: defaults.stickerConfirmation)
        self.gifConfirmation = container.decodeIfPresent(Bool.self, forKey: .gifConfirmation, fallback: defaults.gifConfirmation)
        self.voiceConfirmation = container.decodeIfPresent(Bool.self, forKey: .voiceConfirmation, fallback: defaults.voiceConfirmation)
        self.translationProvider = container.decodeRawValueEnum(AyuTranslationProvider.self, forKey: .translationProvider, fallback: defaults.translationProvider)
        self.adaptiveCoverColor = container.decodeIfPresent(Bool.self, forKey: .adaptiveCoverColor, fallback: defaults.adaptiveCoverColor)
        self.improveLinkPreviews = container.decodeIfPresent(Bool.self, forKey: .improveLinkPreviews, fallback: defaults.improveLinkPreviews)
        self.crashReporting = container.decodeIfPresent(Bool.self, forKey: .crashReporting, fallback: defaults.crashReporting)
        self.avatarCorners = container.decodeIfPresent(Int32.self, forKey: .avatarCorners, fallback: defaults.avatarCorners)
        self.singleCornerRadius = container.decodeIfPresent(Bool.self, forKey: .singleCornerRadius, fallback: defaults.singleCornerRadius)
        self.useGlobalGhostMode = container.decodeIfPresent(Bool.self, forKey: .useGlobalGhostMode, fallback: defaults.useGlobalGhostMode)
        self.globalGhostSettings = container.decodeIfPresent(AyuGramGhostSettings.self, forKey: .globalGhostSettings, fallback: defaults.globalGhostSettings)
        if let ghostAccountEntries = try? container.decodeIfPresent([AyuGramGhostAccountSettingsEntry].self, forKey: .ghostAccounts) {
            var ghostAccounts: [Int64: AyuGramGhostSettings] = [:]
            for entry in ghostAccountEntries {
                ghostAccounts[entry.accountId] = entry.settings
            }
            self.ghostAccounts = ghostAccounts
        } else {
            self.ghostAccounts = defaults.ghostAccounts
        }
        self.messageShotSettings = container.decodeIfPresent(AyuGramMessageShotSettings.self, forKey: .messageShotSettings, fallback: defaults.messageShotSettings)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.saveDeletedMessages, forKey: .saveDeletedMessages)
        try container.encode(self.saveMessagesHistory, forKey: .saveMessagesHistory)
        try container.encode(self.saveForBots, forKey: .saveForBots)
        try container.encode(self.shadowBanIds, forKey: .shadowBanIds)
        try container.encode(self.filtersEnabled, forKey: .filtersEnabled)
        try container.encode(self.filtersEnabledInChats, forKey: .filtersEnabledInChats)
        try container.encode(self.hideFromBlocked, forKey: .hideFromBlocked)
        try container.encode(self.semiTransparentDeletedMessages, forKey: .semiTransparentDeletedMessages)
        try container.encode(self.disableAds, forKey: .disableAds)
        try container.encode(self.disableStories, forKey: .disableStories)
        try container.encode(self.disableCustomBackgrounds, forKey: .disableCustomBackgrounds)
        try container.encode(self.showOnlyAddedEmojisAndStickers, forKey: .showOnlyAddedEmojisAndStickers)
        try container.encode(self.collapseSimilarChannels, forKey: .collapseSimilarChannels)
        try container.encode(self.hideSimilarChannels, forKey: .hideSimilarChannels)
        try container.encode(self.messageBubbleRadius, forKey: .messageBubbleRadius)
        try container.encode(self.disableOpenLinkWarning, forKey: .disableOpenLinkWarning)
        try container.encode(self.wideMultiplier, forKey: .wideMultiplier)
        try container.encode(self.spoofWebviewAsAndroid, forKey: .spoofWebviewAsAndroid)
        try container.encode(self.increaseWebviewHeight, forKey: .increaseWebviewHeight)
        try container.encode(self.increaseWebviewWidth, forKey: .increaseWebviewWidth)
        try container.encode(self.materialSwitches, forKey: .materialSwitches)
        try container.encode(self.removeMessageTail, forKey: .removeMessageTail)
        try container.encode(self.disableNotificationsDelay, forKey: .disableNotificationsDelay)
        try container.encode(self.localPremium, forKey: .localPremium)
        try container.encode(self.showChannelReactions, forKey: .showChannelReactions)
        try container.encode(self.showGroupReactions, forKey: .showGroupReactions)
        try container.encode(self.showPrivateChatReactions, forKey: .showPrivateChatReactions)
        try container.encode(self.appIcon, forKey: .appIcon)
        try container.encode(self.simpleQuotesAndReplies, forKey: .simpleQuotesAndReplies)
        try container.encode(self.hideFastShare, forKey: .hideFastShare)
        try container.encode(self.replaceBottomInfoWithIcons, forKey: .replaceBottomInfoWithIcons)
        try container.encode(self.deletedMark, forKey: .deletedMark)
        try container.encode(self.editedMark, forKey: .editedMark)
        try container.encode(self.recentStickersCount, forKey: .recentStickersCount)
        try container.encode(self.showReactionsPanelInContextMenu.rawValue, forKey: .showReactionsPanelInContextMenu)
        try container.encode(self.showViewsPanelInContextMenu.rawValue, forKey: .showViewsPanelInContextMenu)
        try container.encode(self.showHideMessageInContextMenu.rawValue, forKey: .showHideMessageInContextMenu)
        try container.encode(self.showUserMessagesInContextMenu.rawValue, forKey: .showUserMessagesInContextMenu)
        try container.encode(self.showMessageDetailsInContextMenu.rawValue, forKey: .showMessageDetailsInContextMenu)
        try container.encode(self.showRepeatMessageInContextMenu.rawValue, forKey: .showRepeatMessageInContextMenu)
        try container.encode(self.showAddFilterInContextMenu.rawValue, forKey: .showAddFilterInContextMenu)
        try container.encode(self.showAttachButtonInMessageField, forKey: .showAttachButtonInMessageField)
        try container.encode(self.showCommandsButtonInMessageField, forKey: .showCommandsButtonInMessageField)
        try container.encode(self.showEmojiButtonInMessageField, forKey: .showEmojiButtonInMessageField)
        try container.encode(self.showMicrophoneButtonInMessageField, forKey: .showMicrophoneButtonInMessageField)
        try container.encode(self.showAutoDeleteButtonInMessageField, forKey: .showAutoDeleteButtonInMessageField)
        try container.encode(self.showGiftButtonInMessageField, forKey: .showGiftButtonInMessageField)
        try container.encode(self.showAiEditorButtonInMessageField, forKey: .showAiEditorButtonInMessageField)
        try container.encode(self.showAttachPopup, forKey: .showAttachPopup)
        try container.encode(self.showEmojiPopup, forKey: .showEmojiPopup)
        try container.encode(self.showMyProfileInDrawer, forKey: .showMyProfileInDrawer)
        try container.encode(self.showBotsInDrawer, forKey: .showBotsInDrawer)
        try container.encode(self.showNewGroupInDrawer, forKey: .showNewGroupInDrawer)
        try container.encode(self.showNewChannelInDrawer, forKey: .showNewChannelInDrawer)
        try container.encode(self.showContactsInDrawer, forKey: .showContactsInDrawer)
        try container.encode(self.showCallsInDrawer, forKey: .showCallsInDrawer)
        try container.encode(self.showSavedMessagesInDrawer, forKey: .showSavedMessagesInDrawer)
        try container.encode(self.showLReadToggleInDrawer, forKey: .showLReadToggleInDrawer)
        try container.encode(self.showSReadToggleInDrawer, forKey: .showSReadToggleInDrawer)
        try container.encode(self.showNightModeToggleInDrawer, forKey: .showNightModeToggleInDrawer)
        try container.encode(self.showGhostToggleInDrawer, forKey: .showGhostToggleInDrawer)
        try container.encode(self.showStreamerToggleInDrawer, forKey: .showStreamerToggleInDrawer)
        try container.encode(self.showGhostToggleInTray, forKey: .showGhostToggleInTray)
        try container.encode(self.showStreamerToggleInTray, forKey: .showStreamerToggleInTray)
        try container.encode(self.hidePremiumStatuses, forKey: .hidePremiumStatuses)
        try container.encode(self.monoFont, forKey: .monoFont)
        try container.encode(self.hideNotificationCounters, forKey: .hideNotificationCounters)
        try container.encode(self.hideNotificationBadge, forKey: .hideNotificationBadge)
        try container.encode(self.hideAllChatsFolder, forKey: .hideAllChatsFolder)
        try container.encode(self.channelBottomButton.rawValue, forKey: .channelBottomButton)
        try container.encode(self.quickAdminShortcuts, forKey: .quickAdminShortcuts)
        try container.encode(self.showPeerId.rawValue, forKey: .showPeerId)
        try container.encode(self.showMessageSeconds, forKey: .showMessageSeconds)
        try container.encode(self.showMessageShot, forKey: .showMessageShot)
        try container.encode(self.filterZalgo, forKey: .filterZalgo)
        try container.encode(self.stickerConfirmation, forKey: .stickerConfirmation)
        try container.encode(self.gifConfirmation, forKey: .gifConfirmation)
        try container.encode(self.voiceConfirmation, forKey: .voiceConfirmation)
        try container.encode(self.translationProvider.rawValue, forKey: .translationProvider)
        try container.encode(self.adaptiveCoverColor, forKey: .adaptiveCoverColor)
        try container.encode(self.improveLinkPreviews, forKey: .improveLinkPreviews)
        try container.encode(self.crashReporting, forKey: .crashReporting)
        try container.encode(self.avatarCorners, forKey: .avatarCorners)
        try container.encode(self.singleCornerRadius, forKey: .singleCornerRadius)
        try container.encode(self.useGlobalGhostMode, forKey: .useGlobalGhostMode)
        try container.encode(self.globalGhostSettings, forKey: .globalGhostSettings)
        let ghostAccountEntries = self.ghostAccounts.keys.sorted().map { accountId in
            AyuGramGhostAccountSettingsEntry(
                accountId: accountId,
                settings: self.ghostAccounts[accountId] ?? .defaultSettings
            )
        }
        try container.encode(ghostAccountEntries, forKey: .ghostAccounts)
        try container.encode(self.messageShotSettings, forKey: .messageShotSettings)
    }
}
