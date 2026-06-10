# Liquid Glass Support Audit - 2026-06-10

## Summary

The current Telegram-iOS base already contains modern glass UI infrastructure and an iOS 26 guarded Liquid Lens path. AyuGram does not yet expose these controls as user-facing settings, but the codebase has enough hooks to support a first AyuGram "Liquid Glass" preference without adding a new rendering stack.

## Existing Glass Infrastructure

- `submodules/TelegramUI/Components/GlassBackgroundComponent/Sources/GlassBackgroundComponent.swift` defines reusable glass background containers and tint behavior.
- `submodules/TelegramUI/Components/GlassBackgroundComponent/Sources/LegacyGlassView.swift` creates a backdrop layer dynamically and applies blur/color-matrix filters. It guards advanced mesh behavior with `#available(iOS 17.0, *)`.
- `submodules/TelegramUI/Components/GlassControls/Sources/` provides glass control panels/groups used by newer UI surfaces.
- `submodules/Display/Source/NavigationBar.swift` and `NavigationBarImpl` support `.glass` navigation bars and `NavigationBar.GlassStyle` variants.
- `submodules/TelegramUI/Sources/ChatController.swift` already selects `NavigationBarPresentationData(... style: .glass, glassStyle: .default)` and switches to `.clear` when chat presentation asks for clear glass.

## iOS 26 / Latest System Support

`submodules/TelegramUI/Components/LiquidLens/Sources/LiquidLensView.swift` contains the strongest evidence of latest-system support:

```swift
if #available(iOS 26.0, *) {
    if let viewClass = NSClassFromString("_UILiquidLensView") as AnyObject as? NSObjectProtocol {
        ...
    }
}
```

This means the app can adopt the new system-backed Liquid Lens/Liquid Glass behavior when running on iOS 26, while avoiding compile/runtime failure on older systems. The implementation uses runtime class lookup rather than direct SDK symbol references, which is consistent with a compatibility-first app that still targets older iOS versions.

## Current Settings Exposure

Glass-related switches exist only in debug settings:

- `ExperimentalUISettings.fakeGlass`
- `ExperimentalUISettings.forceClearGlass`

They are surfaced in `DebugSettingsUI/Sources/DebugController.swift`, not in AyuGram settings. Normal users therefore cannot choose the glass behavior from the AyuGram page today.

## Recommended AyuGram Setting

Add an Appearance setting named `Liquid Glass Style` with three options:

- `System`: keep Telegram's default behavior and allow iOS 26 guarded paths to activate where the app already supports them.
- `Clear Glass`: prefer clear glass styling for supported navigation/chat surfaces.
- `Compatibility Glass`: prefer existing fake/legacy glass behavior for devices or sideload environments where the newest system effect is unstable.

This should be stored in `AyuGramSettings`, not directly in debug-only `ExperimentalUISettings`, so it can be exported/imported with the rest of AyuGram configuration later.

## Implementation Boundaries

- Do not add unguarded iOS 26 API references. Use `#available(iOS 26.0, *)` and runtime lookup where needed.
- Do not depend on private class names outside the existing pattern unless a CI build confirms the symbols are safe.
- Start by wiring existing `NavigationBar.GlassStyle`, `preferredGlassType`, `fakeGlass`, and `forceClearGlass` behavior.
- Treat the user setting as a preference overlay. If a surface does not support glass yet, it should fall back to the existing Telegram appearance rather than forcing a partial effect.

## Acceptance Criteria

- AyuGram settings exposes a localized Liquid Glass style row.
- `System` preserves current behavior.
- `Clear Glass` visibly affects chat/navigation surfaces that already support clear glass.
- `Compatibility Glass` uses the existing compatibility/fake glass path where available.
- iOS 26 builds continue to pass in GitHub Actions.
- Older deployment targets do not receive unguarded iOS 26 symbol references.
