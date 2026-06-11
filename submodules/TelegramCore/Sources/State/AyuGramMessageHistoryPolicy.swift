import Foundation

public struct AccountMessageHistoryPolicy: Equatable {
    public var saveDeletedMessages: Bool
    public var saveMessagesHistory: Bool
    public var deletedMessagesStorageLimit: Int32
    public var saveForBots: Bool

    public static let defaultValue = AccountMessageHistoryPolicy(
        saveDeletedMessages: false,
        saveMessagesHistory: false,
        deletedMessagesStorageLimit: 5000,
        saveForBots: false
    )

    public init(saveDeletedMessages: Bool, saveMessagesHistory: Bool, deletedMessagesStorageLimit: Int32, saveForBots: Bool) {
        self.saveDeletedMessages = saveDeletedMessages
        self.saveMessagesHistory = saveMessagesHistory
        self.deletedMessagesStorageLimit = deletedMessagesStorageLimit
        self.saveForBots = saveForBots
    }
}
