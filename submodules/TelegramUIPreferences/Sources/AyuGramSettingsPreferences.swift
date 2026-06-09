import Foundation
import TelegramCore
import SwiftSignalKit
import AyuGramCore

public func ayuGramSettings(sharedData: AccountSharedDataView<TelegramAccountManagerTypes>) -> AyuGramSettings {
    return sharedData.entries[ApplicationSpecificSharedDataKeys.ayuGramSettings]?.get(AyuGramSettings.self) ?? AyuGramSettings.defaultSettings
}

public func updateAyuGramSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (AyuGramSettings) -> AyuGramSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.ayuGramSettings, { entry in
            let currentSettings: AyuGramSettings
            if let entry = entry?.get(AyuGramSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = AyuGramSettings.defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}
