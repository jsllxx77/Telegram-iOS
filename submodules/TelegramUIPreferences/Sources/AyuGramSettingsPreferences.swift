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

public func updateAyuGramLiquidGlassStyleInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, style: AyuLiquidGlassStyle) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.ayuGramSettings, { entry in
            var currentSettings = entry?.get(AyuGramSettings.self) ?? AyuGramSettings.defaultSettings
            currentSettings.liquidGlassStyle = style
            return SharedPreferencesEntry(currentSettings)
        })
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.experimentalUISettings, { entry in
            var currentSettings = entry?.get(ExperimentalUISettings.self) ?? ExperimentalUISettings.defaultSettings
            switch style {
            case .system:
                currentSettings.fakeGlass = false
                currentSettings.forceClearGlass = false
            case .clear:
                currentSettings.fakeGlass = false
                currentSettings.forceClearGlass = true
            case .compatibility:
                currentSettings.fakeGlass = true
                currentSettings.forceClearGlass = false
            }
            return SharedPreferencesEntry(currentSettings)
        })
    }
}
