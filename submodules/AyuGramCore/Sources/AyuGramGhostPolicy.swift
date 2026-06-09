public struct AyuGramGhostPolicy: Equatable {
    public var sendReadMessages: Bool

    public var shouldApplyAutomaticReadHistory: Bool {
        return self.sendReadMessages
    }

    public init(sendReadMessages: Bool) {
        self.sendReadMessages = sendReadMessages
    }
}
