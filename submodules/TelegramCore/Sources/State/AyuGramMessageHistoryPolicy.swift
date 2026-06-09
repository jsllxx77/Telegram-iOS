import Foundation

public struct AccountMessageHistoryPolicy: Equatable {
    public var saveMessagesHistory: Bool
    public var saveForBots: Bool

    public static let defaultValue = AccountMessageHistoryPolicy(
        saveMessagesHistory: false,
        saveForBots: false
    )

    public init(saveMessagesHistory: Bool, saveForBots: Bool) {
        self.saveMessagesHistory = saveMessagesHistory
        self.saveForBots = saveForBots
    }
}
