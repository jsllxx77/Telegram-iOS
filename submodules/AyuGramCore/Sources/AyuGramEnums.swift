public enum AyuPeerIdDisplay: Int32, Codable, Equatable {
    case hidden = 0
    case telegramApi = 1
    case botApi = 2
}

public enum AyuChannelBottomButton: Int32, Codable, Equatable {
    case hidden = 0
    case muteUnmute = 1
    case discussWithFallback = 2
}

public enum AyuContextMenuVisibility: Int32, Codable, Equatable {
    case hidden = 0
    case visible = 1
    case visibleWithModifier = 2
}

public enum AyuTranslationProvider: String, Codable, Equatable {
    case telegram
    case google
    case yandex
    case native
}

public enum AyuSendWithoutSoundOption: Int32, Codable, Equatable {
    case never = 0
    case inGhostMode = 1
    case always = 2
}
