public struct AyuGramGhostSettings: Codable, Equatable {
    public var sendReadMessages: Bool
    public var sendReadStories: Bool
    public var sendOnlinePackets: Bool
    public var sendUploadProgress: Bool
    public var sendOfflinePacketAfterOnline: Bool
    public var markReadAfterAction: Bool
    public var useScheduledMessages: Bool
    public var sendWithoutSound: AyuSendWithoutSoundOption
    public var suggestGhostModeBeforeViewingStory: Bool
    public var sendReadMessagesLocked: Bool
    public var sendReadStoriesLocked: Bool
    public var sendOnlinePacketsLocked: Bool
    public var sendUploadProgressLocked: Bool
    public var sendOfflinePacketAfterOnlineLocked: Bool

    public static let defaultSettings = AyuGramGhostSettings()

    public init(
        sendReadMessages: Bool = true,
        sendReadStories: Bool = true,
        sendOnlinePackets: Bool = true,
        sendUploadProgress: Bool = true,
        sendOfflinePacketAfterOnline: Bool = false,
        markReadAfterAction: Bool = true,
        useScheduledMessages: Bool = false,
        sendWithoutSound: AyuSendWithoutSoundOption = .never,
        suggestGhostModeBeforeViewingStory: Bool = true,
        sendReadMessagesLocked: Bool = false,
        sendReadStoriesLocked: Bool = false,
        sendOnlinePacketsLocked: Bool = false,
        sendUploadProgressLocked: Bool = false,
        sendOfflinePacketAfterOnlineLocked: Bool = false
    ) {
        self.sendReadMessages = sendReadMessages
        self.sendReadStories = sendReadStories
        self.sendOnlinePackets = sendOnlinePackets
        self.sendUploadProgress = sendUploadProgress
        self.sendOfflinePacketAfterOnline = sendOfflinePacketAfterOnline
        self.markReadAfterAction = markReadAfterAction
        self.useScheduledMessages = useScheduledMessages
        self.sendWithoutSound = sendWithoutSound
        self.suggestGhostModeBeforeViewingStory = suggestGhostModeBeforeViewingStory
        self.sendReadMessagesLocked = sendReadMessagesLocked
        self.sendReadStoriesLocked = sendReadStoriesLocked
        self.sendOnlinePacketsLocked = sendOnlinePacketsLocked
        self.sendUploadProgressLocked = sendUploadProgressLocked
        self.sendOfflinePacketAfterOnlineLocked = sendOfflinePacketAfterOnlineLocked
    }

    private enum CodingKeys: String, CodingKey {
        case sendReadMessages
        case sendReadStories
        case sendOnlinePackets
        case sendUploadProgress
        case sendOfflinePacketAfterOnline
        case markReadAfterAction
        case useScheduledMessages
        case sendWithoutSound
        case suggestGhostModeBeforeViewingStory
        case sendReadMessagesLocked
        case sendReadStoriesLocked
        case sendOnlinePacketsLocked
        case sendUploadProgressLocked
        case sendOfflinePacketAfterOnlineLocked
    }

    public init(from decoder: Decoder) throws {
        let defaults = Self.defaultSettings
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.sendReadMessages = container.decodeIfPresent(Bool.self, forKey: .sendReadMessages, fallback: defaults.sendReadMessages)
        self.sendReadStories = container.decodeIfPresent(Bool.self, forKey: .sendReadStories, fallback: defaults.sendReadStories)
        self.sendOnlinePackets = container.decodeIfPresent(Bool.self, forKey: .sendOnlinePackets, fallback: defaults.sendOnlinePackets)
        self.sendUploadProgress = container.decodeIfPresent(Bool.self, forKey: .sendUploadProgress, fallback: defaults.sendUploadProgress)
        self.sendOfflinePacketAfterOnline = container.decodeIfPresent(Bool.self, forKey: .sendOfflinePacketAfterOnline, fallback: defaults.sendOfflinePacketAfterOnline)
        self.markReadAfterAction = container.decodeIfPresent(Bool.self, forKey: .markReadAfterAction, fallback: defaults.markReadAfterAction)
        self.useScheduledMessages = container.decodeIfPresent(Bool.self, forKey: .useScheduledMessages, fallback: defaults.useScheduledMessages)
        self.sendWithoutSound = container.decodeRawValueEnum(AyuSendWithoutSoundOption.self, forKey: .sendWithoutSound, fallback: defaults.sendWithoutSound)
        self.suggestGhostModeBeforeViewingStory = container.decodeIfPresent(Bool.self, forKey: .suggestGhostModeBeforeViewingStory, fallback: defaults.suggestGhostModeBeforeViewingStory)
        self.sendReadMessagesLocked = container.decodeIfPresent(Bool.self, forKey: .sendReadMessagesLocked, fallback: defaults.sendReadMessagesLocked)
        self.sendReadStoriesLocked = container.decodeIfPresent(Bool.self, forKey: .sendReadStoriesLocked, fallback: defaults.sendReadStoriesLocked)
        self.sendOnlinePacketsLocked = container.decodeIfPresent(Bool.self, forKey: .sendOnlinePacketsLocked, fallback: defaults.sendOnlinePacketsLocked)
        self.sendUploadProgressLocked = container.decodeIfPresent(Bool.self, forKey: .sendUploadProgressLocked, fallback: defaults.sendUploadProgressLocked)
        self.sendOfflinePacketAfterOnlineLocked = container.decodeIfPresent(Bool.self, forKey: .sendOfflinePacketAfterOnlineLocked, fallback: defaults.sendOfflinePacketAfterOnlineLocked)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.sendReadMessages, forKey: .sendReadMessages)
        try container.encode(self.sendReadStories, forKey: .sendReadStories)
        try container.encode(self.sendOnlinePackets, forKey: .sendOnlinePackets)
        try container.encode(self.sendUploadProgress, forKey: .sendUploadProgress)
        try container.encode(self.sendOfflinePacketAfterOnline, forKey: .sendOfflinePacketAfterOnline)
        try container.encode(self.markReadAfterAction, forKey: .markReadAfterAction)
        try container.encode(self.useScheduledMessages, forKey: .useScheduledMessages)
        try container.encode(self.sendWithoutSound.rawValue, forKey: .sendWithoutSound)
        try container.encode(self.suggestGhostModeBeforeViewingStory, forKey: .suggestGhostModeBeforeViewingStory)
        try container.encode(self.sendReadMessagesLocked, forKey: .sendReadMessagesLocked)
        try container.encode(self.sendReadStoriesLocked, forKey: .sendReadStoriesLocked)
        try container.encode(self.sendOnlinePacketsLocked, forKey: .sendOnlinePacketsLocked)
        try container.encode(self.sendUploadProgressLocked, forKey: .sendUploadProgressLocked)
        try container.encode(self.sendOfflinePacketAfterOnlineLocked, forKey: .sendOfflinePacketAfterOnlineLocked)
    }

    public var isGhostModeActive: Bool {
        return (self.sendReadMessagesLocked || !self.sendReadMessages)
            && (self.sendReadStoriesLocked || !self.sendReadStories)
            && (self.sendOnlinePacketsLocked || !self.sendOnlinePackets)
            && (self.sendUploadProgressLocked || !self.sendUploadProgress)
            && (self.sendOfflinePacketAfterOnlineLocked || self.sendOfflinePacketAfterOnline)
    }

    public var shouldSendWithoutSound: Bool {
        switch self.sendWithoutSound {
        case .never:
            return false
        case .inGhostMode:
            return self.isGhostModeActive
        case .always:
            return true
        }
    }
}
