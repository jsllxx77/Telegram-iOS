import Foundation
import AccountContext
import AyuGramCore
import Postbox
import SwiftSignalKit
import TelegramCore

func ayuGramFilterStoreSignal(context: AccountContext) -> Signal<AyuGramFilterStore, NoError> {
    let storeKey = PreferencesKeys.ayuGramFilterStore()
    return context.engine.data.subscribe(
        TelegramEngine.EngineData.Item.Configuration.ApplicationSpecificPreference(key: storeKey)
    )
    |> map { entry -> AyuGramFilterStore in
        return entry?.get(AyuGramFilterStore.self) ?? .empty
    }
    |> distinctUntilChanged
}

func updateAyuGramFilterStore(
    context: AccountContext,
    _ f: @escaping (AyuGramFilterStore) -> AyuGramFilterStore
) -> Signal<Never, NoError> {
    let storeKey = PreferencesKeys.ayuGramFilterStore()
    return context.engine.preferences.update(id: storeKey) { entry -> EnginePreferencesEntry? in
        let current = entry?.get(AyuGramFilterStore.self) ?? .empty
        return EnginePreferencesEntry(f(current))
    }
}
