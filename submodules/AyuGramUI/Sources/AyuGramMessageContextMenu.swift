import Foundation
import AyuGramCore

public enum AyuGramMessageContextMenuAction: Equatable {
    case viewEditedHistory
    case viewDeletedMessages
    case messageDetails
    case messageShot
    case userMessages
    case repeatMessage
    case readUntil
    case hideMessageLocally
    case addFilter
    case shadowBan(isShadowBanned: Bool)
}

public struct AyuGramMessageContextMenuDescriptor: Equatable {
    public let action: AyuGramMessageContextMenuAction
    public let title: String
    public let iconName: String
    public let isDestructive: Bool
    public let isPlaceholder: Bool

    public init(
        action: AyuGramMessageContextMenuAction,
        title: String,
        iconName: String,
        isDestructive: Bool = false,
        isPlaceholder: Bool = false
    ) {
        self.action = action
        self.title = title
        self.iconName = iconName
        self.isDestructive = isDestructive
        self.isPlaceholder = isPlaceholder
    }
}

public struct AyuGramMessageContextMenuInput {
    public let settings: AyuGramSettings
    public let hasEditedHistory: Bool
    public let canViewDeletedMessages: Bool
    public let canViewMessageDetails: Bool
    public let canCreateMessageShot: Bool
    public let canViewUserMessages: Bool
    public let canRepeatMessage: Bool
    public let canReadUntil: Bool
    public let canHideMessageLocally: Bool
    public let canAddFilter: Bool
    public let canShadowBan: Bool
    public let isShadowBanned: Bool
    public let isExtendedMenu: Bool
    public let editedHistoryVisibility: AyuContextMenuVisibility
    public let deletedMessagesVisibility: AyuContextMenuVisibility
    public let readUntilVisibility: AyuContextMenuVisibility
    public let shadowBanVisibility: AyuContextMenuVisibility
    public let languageCode: String

    public init(
        settings: AyuGramSettings,
        hasEditedHistory: Bool,
        canViewDeletedMessages: Bool,
        canViewMessageDetails: Bool,
        canCreateMessageShot: Bool,
        canViewUserMessages: Bool,
        canRepeatMessage: Bool,
        canReadUntil: Bool,
        canHideMessageLocally: Bool,
        canAddFilter: Bool,
        canShadowBan: Bool,
        isShadowBanned: Bool,
        isExtendedMenu: Bool = false,
        editedHistoryVisibility: AyuContextMenuVisibility = .visible,
        deletedMessagesVisibility: AyuContextMenuVisibility = .visible,
        readUntilVisibility: AyuContextMenuVisibility = .visible,
        shadowBanVisibility: AyuContextMenuVisibility = .visible,
        languageCode: String = "en"
    ) {
        self.settings = settings
        self.hasEditedHistory = hasEditedHistory
        self.canViewDeletedMessages = canViewDeletedMessages
        self.canViewMessageDetails = canViewMessageDetails
        self.canCreateMessageShot = canCreateMessageShot
        self.canViewUserMessages = canViewUserMessages
        self.canRepeatMessage = canRepeatMessage
        self.canReadUntil = canReadUntil
        self.canHideMessageLocally = canHideMessageLocally
        self.canAddFilter = canAddFilter
        self.canShadowBan = canShadowBan
        self.isShadowBanned = isShadowBanned
        self.isExtendedMenu = isExtendedMenu
        self.editedHistoryVisibility = editedHistoryVisibility
        self.deletedMessagesVisibility = deletedMessagesVisibility
        self.readUntilVisibility = readUntilVisibility
        self.shadowBanVisibility = shadowBanVisibility
        self.languageCode = languageCode
    }
}

public func ayuGramMessageContextMenuDescriptors(
    input: AyuGramMessageContextMenuInput
) -> [AyuGramMessageContextMenuDescriptor] {
    var descriptors: [AyuGramMessageContextMenuDescriptor] = []
    let settings = input.settings
    let localized: (String) -> String = { value in
        return ayuGramLocalized(value, languageCode: input.languageCode)
    }

    if input.hasEditedHistory && ayuGramShouldShowContextMenuItem(input.editedHistoryVisibility, isExtendedMenu: input.isExtendedMenu) {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .viewEditedHistory,
            title: localized("View Edit History"),
            iconName: "Chat/Context Menu/Edit"
        ))
    }

    if input.canViewDeletedMessages && settings.saveDeletedMessages && ayuGramShouldShowContextMenuItem(input.deletedMessagesVisibility, isExtendedMenu: input.isExtendedMenu) {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .viewDeletedMessages,
            title: localized("Deleted Messages"),
            iconName: "Chat/Context Menu/Delete"
        ))
    }

    if input.canViewMessageDetails && ayuGramShouldShowContextMenuItem(settings.showMessageDetailsInContextMenu, isExtendedMenu: input.isExtendedMenu) {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .messageDetails,
            title: localized("Message Details"),
            iconName: "Chat/Context Menu/Info"
        ))
    }

    if input.canCreateMessageShot && settings.showMessageShot {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .messageShot,
            title: localized("Message Shot"),
            iconName: "Chat/Context Menu/Share"
        ))
    }

    if input.canViewUserMessages && ayuGramShouldShowContextMenuItem(settings.showUserMessagesInContextMenu, isExtendedMenu: input.isExtendedMenu) {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .userMessages,
            title: localized("User Messages"),
            iconName: "Chat/Context Menu/User"
        ))
    }

    if input.canRepeatMessage && ayuGramShouldShowContextMenuItem(settings.showRepeatMessageInContextMenu, isExtendedMenu: input.isExtendedMenu) {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .repeatMessage,
            title: localized("Repeat Message"),
            iconName: "Chat/Context Menu/Resend"
        ))
    }

    if input.canReadUntil && ayuGramShouldShowContextMenuItem(input.readUntilVisibility, isExtendedMenu: input.isExtendedMenu) {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .readUntil,
            title: localized("Read Until"),
            iconName: "Chat/Context Menu/Read"
        ))
    }

    if input.canHideMessageLocally && ayuGramShouldShowContextMenuItem(settings.showHideMessageInContextMenu, isExtendedMenu: input.isExtendedMenu) {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .hideMessageLocally,
            title: localized("Hide Message Locally"),
            iconName: "Chat/Context Menu/Clear",
            isDestructive: true
        ))
    }

    if input.canAddFilter && settings.filtersEnabled && ayuGramShouldShowContextMenuItem(settings.showAddFilterInContextMenu, isExtendedMenu: input.isExtendedMenu) {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .addFilter,
            title: localized("Add Filter"),
            iconName: "Chat/Context Menu/AddToFolder"
        ))
    }

    if input.canShadowBan && settings.filtersEnabled && ayuGramShouldShowContextMenuItem(input.shadowBanVisibility, isExtendedMenu: input.isExtendedMenu) {
        descriptors.append(AyuGramMessageContextMenuDescriptor(
            action: .shadowBan(isShadowBanned: input.isShadowBanned),
            title: input.isShadowBanned ? localized("Remove Shadow Ban") : localized("Shadow Ban"),
            iconName: input.isShadowBanned ? "Chat/Context Menu/Read" : "Chat/Context Menu/Restrict",
            isDestructive: !input.isShadowBanned,
            isPlaceholder: true
        ))
    }

    return descriptors
}

public func ayuGramShouldShowContextMenuItem(
    _ visibility: AyuContextMenuVisibility,
    isExtendedMenu: Bool
) -> Bool {
    switch visibility {
    case .hidden:
        return false
    case .visible:
        return true
    case .visibleWithModifier:
        return isExtendedMenu
    }
}
