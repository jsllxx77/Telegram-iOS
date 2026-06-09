import Foundation

public struct AccountMessageHistoryPolicy: Equatable {
    public var saveDeletedMessages: Bool
    public var saveMessagesHistory: Bool
    public var saveForBots: Bool

    public static let defaultValue = AccountMessageHistoryPolicy(
        saveDeletedMessages: false,
        saveMessagesHistory: false,
        saveForBots: false
    )

    public init(saveDeletedMessages: Bool, saveMessagesHistory: Bool, saveForBots: Bool) {
        self.saveDeletedMessages = saveDeletedMessages
        self.saveMessagesHistory = saveMessagesHistory
        self.saveForBots = saveForBots
    }
}
