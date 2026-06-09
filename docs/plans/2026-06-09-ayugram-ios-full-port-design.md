# AyuGram iOS Full Port Design

## Goal

Port the AyuGram Desktop feature set into the `jsllxx77/Telegram-iOS` fork as an iOS-native AyuGram layer, preserving AyuGram behavior where it is technically and ethically appropriate while keeping Telegram-iOS maintainable against upstream changes.

This is not a C++ to Swift copy. AyuGram Desktop is a Qt/C++ fork of Telegram Desktop. Telegram-iOS is Swift, Bazel, Postbox, TelegramCore, TelegramEngine, and AsyncDisplayKit-based UI. The port must recreate behavior through iOS-native models, storage, engine facades, and UI integration points.

## Source Inventory

Primary AyuGram Desktop sources:

- `AyuGramDesktop/README.md`: public feature summary.
- `AyuGramDesktop/Telegram/SourceFiles/ayu/`: AyuGram-specific implementation.
- `AyuGramDesktop/Telegram/SourceFiles/ayu/ayu_settings.h`: full settings surface and defaults.
- `AyuGramDesktop/Telegram/SourceFiles/ayu/data/messages_storage.*`: edited/deleted message persistence API.
- `AyuGramDesktop/Telegram/SourceFiles/ayu/data/ayu_database.*`: local database access for history and filters.
- `AyuGramDesktop/Telegram/SourceFiles/ayu/features/filters/`: regex filters and shadow ban.
- `AyuGramDesktop/Telegram/SourceFiles/ayu/features/translator/`: Telegram/Google/Yandex/native translation provider abstraction.
- `AyuGramDesktop/Telegram/SourceFiles/ayu/ui/context_menu/context_menu.cpp`: AyuGram message and chat context menu entry points.

Primary Telegram-iOS integration points:

- `submodules/TelegramUIPreferences/Sources/PostboxKeys.swift`: app-specific preference keys.
- `submodules/TelegramUIPreferences/Sources/*.swift`: Codable settings patterns.
- `submodules/SettingsUI/Sources/`: settings controller patterns.
- `submodules/TelegramUI/Sources/ChatHistoryListNode.swift`: automatic read-history management.
- `submodules/TelegramUI/Sources/AccountContext.swift`: read index application facade.
- `submodules/TelegramCore/Sources/State/AccountStateManagementUtils.swift`: incoming edit/delete update processing.
- `submodules/TelegramCore/Sources/State/SynchronizePeerReadState.swift`: read-history network sync.
- `submodules/TelegramCore/Sources/State/ManagedSynchronizeConsumeMessageContentsOperations.swift`: read-content network sync.
- `submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift`: message context menu.
- `submodules/TelegramUI/Sources/ChatControllerLoadDisplayNode.swift`: interaction wiring.

## Architecture

### New Ayu Modules

Create two repo-native submodules:

- `submodules/AyuGramCore`
- `submodules/AyuGramUI`

`AyuGramCore` owns:

- Settings models and update helpers.
- Ghost-mode policy evaluation.
- Anti-recall persistence models.
- Message filter models and matching.
- Translation provider abstraction.
- Small utility functions such as Zalgo filtering and ID formatting.

`AyuGramUI` owns:

- AyuGram settings screens.
- Edited/deleted message history screens.
- Filter management screens.
- Message details screen.
- Context menu action builders.
- Presentation helpers for Ayu-specific labels and badges.

Keep core logic outside `TelegramUI` as much as possible. Telegram-iOS files should become integration points, not the home of AyuGram business logic.

### Storage Strategy

Use existing Telegram-iOS storage primitives instead of adding SQLite:

- Shared/account preferences for settings through `TelegramUIPreferences`.
- Postbox item cache collections or account-specific preferences for structured Ayu data.
- Local-only message history records with stable Codable/PostboxCoding schemas.

This avoids a new database dependency and keeps data lifecycle aligned with account storage.

### Settings Strategy

Create `AyuGramSettings` and `AyuGramGhostAccountSettings` as Codable/Equatable models in `AyuGramCore`, with defaults matching AyuGram Desktop where appropriate:

- `saveDeletedMessages = true`
- `saveMessagesHistory = true`
- `saveForBots = false`
- `disableAds = true`
- `collapseSimilarChannels = true`
- `messageBubbleRadius = 16`
- `materialSwitches = true`
- `replaceBottomInfoWithIcons = true`
- `recentStickersCount = 100`
- `showSReadToggleInDrawer = true`
- `showNightModeToggleInDrawer = true`
- `showGhostToggleInDrawer = true`
- `channelBottomButton = discussWithFallback`
- `quickAdminShortcuts = true`
- `showPeerId = botApi`
- `showMessageShot = true`
- `translationProvider = telegram`
- `adaptiveCoverColor = true`
- `crashReporting = true`
- `avatarCorners = 23`
- `useGlobalGhostMode = true`

Some desktop defaults should be re-evaluated for iOS UX and risk before enabling in production, especially `disableAds`, `localPremium`, WebView spoofing, and non-Telegram translation providers.

### Build Strategy

Add Bazel targets for new modules and wire them into existing consumers with minimal deps:

- `AyuGramCore` should depend on Foundation, SwiftSignalKit, Postbox, TelegramCore only where necessary.
- `AyuGramUI` may depend on Display, ItemListUI, PresentationDataUtils, AccountContext, TelegramPresentationData, ContextUI, and TelegramUI-facing types.
- Avoid UIKit or Display deps in TelegramCore.

## Feature Matrix

### Foundation

| Feature | iOS Strategy | Primary Touchpoints | Risk |
|---|---|---|---|
| Ayu settings | Codable settings stored via TelegramUIPreferences | `PostboxKeys.swift`, new `AyuGramSettings.swift` | Low |
| Per-account ghost settings | Map account peer id to `AyuGramGhostAccountSettings` | `AccountContext`, `AyuGramCore` | Medium |
| Settings UI | New Settings entry and sectioned Ayu settings screen | `SettingsUI`, `AyuGramUI` | Medium |
| Localization | Add English strings first, then expand | `Telegram-iOS/en.lproj`, generated strings pipeline if needed | Medium |

### Ghost Mode

| Feature | iOS Strategy | Primary Touchpoints | Risk |
|---|---|---|---|
| Do not send read history | Gate automatic `applyMaxReadIndex` when ghost disables read messages | `ChatHistoryListNode.swift`, `AccountContext.swift` | Medium |
| Manual read until | Add explicit action that bypasses ghost gate | `ChatInterfaceStateContextMenus.swift`, `AccountContext.swift` | Medium |
| Do not read message contents | Gate consume-content operations for media/voice where possible | `ManagedSynchronizeConsumeMessageContentsOperations.swift`, chat action handlers | High |
| Do not send story read | Gate story read synchronization | Story state modules, to be inventoried in task | High |
| Do not send online packets | Gate presence/status updates without breaking auth/session | Account state/network presence modules, to be inventoried | High |
| Do not send upload progress | Gate upload progress notifications where API emits them | pending upload / send message modules | High |
| Send offline after online | Explicit state transition when disabling ghost | Account state/network presence modules | High |
| Send without sound in ghost | Apply send options in message enqueue path | `EnqueueMessage.swift`, chat send action UI | Medium |
| Suggest ghost before stories | Prompt before opening story UI | story UI modules | Medium |

### Anti-Recall And History

| Feature | iOS Strategy | Primary Touchpoints | Risk |
|---|---|---|---|
| Save edited messages | Before applying edit update, save previous message snapshot | `AccountStateManagementUtils.swift` `.EditMessage` path | Medium |
| Save deleted messages | Before deleting messages, save current message snapshots | `AccountStateManagementUtils.swift` delete paths | Medium |
| Edited history view | New local history screen keyed by message id | `AyuGramUI`, context menu | Medium |
| Deleted messages view | New chat-scoped local history screen with search/topic filtering | `AyuGramUI`, Postbox storage | Medium |
| Clear deleted messages | Delete local records by peer/thread | `AyuGramCore`, context menu | Low |
| Deleted/edited badges | Add presentation attributes or UI overlay logic | chat item rendering modules | High |
| Semi-transparent deleted messages | If records are rendered inline, style deleted records | chat history transition/rendering | High |
| Media snapshots | Start text-only; later store media references/resource IDs when stable | Postbox media/resource references | High |

### Filters And Shadow Ban

| Feature | iOS Strategy | Primary Touchpoints | Risk |
|---|---|---|---|
| Regex filters | Store filter records and compile `NSRegularExpression` | `AyuGramCore` | Medium |
| Global filters | Evaluate against message text and sender metadata | chat history mapping/rendering | High |
| Per-dialog filters | Filter set keyed by peer id | `AyuGramCore`, settings UI | Medium |
| Reverse/case-insensitive filters | Match AyuGram Desktop model | `AyuGramCore` | Low |
| Hide blocked users | Integrate with peer blocked state | chat history filtering | Medium |
| Shadow ban | Maintain local hidden peer id set | peer context menu, filter UI | Medium |
| Show/hide filtered messages | Add chat-level override and filtered-message marker | `ChatHistoryListNode` transition pipeline | High |
| Import/export filters | JSON-compatible import/export; avoid dpaste dependency by default | `AyuGramUI`, share sheet | Low |

### Privacy And Restrictions

| Feature | iOS Strategy | Primary Touchpoints | Risk |
|---|---|---|---|
| Disable sponsored messages | Hide sponsored UI locally; do not alter server behavior | sponsored message UI modules | Medium |
| Disable promo suggestions | Hide local promo suggestion entries | chat list/settings promo modules | Medium |
| Disable stories | Hide stories UI entry points and story rings | chat list, peer info, dialogs UI | Medium |
| Hide premium statuses | Suppress premium badge/status presentation locally | peer/message rendering | Medium |
| Hide similar channels | Hide similar channel sections | peer info modules | Low |
| No copy restrictions | Allow copy UI when Telegram content protection says no | context menu/copy guard sites | High |
| No download restrictions | Allow save/download UI where local content is available | media context menus/download guards | High |
| Disable open link warning | Gate warning presentation locally | URL/open link handlers | Low |
| Disable notification delay | iOS notification delivery is OS-managed; only app-side delay can be changed | notification pipeline | High |

### Appearance And Chat UI

| Feature | iOS Strategy | Primary Touchpoints | Risk |
|---|---|---|---|
| Bubble radius | Extend presentation theme/chat bubble settings | `TelegramUIPreferences`, bubble rendering | Medium |
| Avatar corners | Apply to avatar rendering where possible | avatar nodes/components | Medium |
| Single corner radius | Theme/presentation extension | bubble rendering | Medium |
| Remove message tail | Gate tail drawing | chat bubble rendering | Medium |
| Hide fast share | Hide quick share button/action | message item rendering/context actions | Medium |
| Replace bottom info with icons | Adjust message status/read views display | message status rendering | High |
| Show message seconds | Format timestamps with seconds | message/time formatting utilities | Medium |
| Show peer id | Add peer id rows in profile/sticker/peer info surfaces | peer info UI | Low |
| Filter Zalgo | Normalize displayed names/text in selected presentation paths | peer/message text formatting | Medium |
| Custom mono font | iOS font selection is more constrained; implement chat font override if feasible | theme/font settings | High |
| App icon | Map available iOS alternate icons | app icon settings | Low |
| Hide notification counters/badge | In-app counters low risk; app badge constrained by OS/push state | chat list/badge update | Medium |
| Hide all chats folder | Hide filter tab locally | chat list filter UI | Medium |
| Channel bottom button | Adjust channel bottom action button | chat controller bottom panel | Medium |

### Message Actions

| Feature | iOS Strategy | Primary Touchpoints | Risk |
|---|---|---|---|
| Message details | New screen with ids, dates, views, forwards, entities, media metadata | `AyuGramUI`, context menu | Low |
| User messages | Search/filter chat messages by sender | search/history query APIs | Medium |
| Repeat message | Re-send equivalent content where allowed | enqueue/forward helpers | Medium |
| Read until | Explicitly apply read up to selected message | `AccountContext.applyMaxReadIndex` | Medium |
| Burn/read media contents | Explicit content-read action for voice/video contents | consume-content operations | High |
| Message shot | Render selected messages into an image using iOS snapshot/composition | `AyuGramUI`, chat item rendering helpers | High |
| Quick admin shortcuts | Add selected-message admin actions to top bar/context menu | admin action menus | Medium |
| Context menu panel visibility | Gate existing and new context menu sections | `ChatInterfaceStateContextMenus.swift` | Low |
| Hide message locally | Add local hidden-message set/filter | Postbox item cache, history mapping | High |

### Input, Drawer, Tabs

| Feature | iOS Strategy | Primary Touchpoints | Risk |
|---|---|---|---|
| Hide composer buttons | Gate attach/commands/emoji/mic/auto-delete/gift/AI editor buttons | chat input panel modules | Medium |
| Hide attach/emoji popup entries | Filter menu entries | attachment and emoji menu modules | Medium |
| Drawer entries | iOS has different navigation; map to Settings/main tab actions where available | root/settings UI | Medium |
| Ghost/read/night toggles | Add Ayu action rows or toolbar actions | settings/root UI | Medium |
| Streamer toggle | Add local privacy presentation mode | `AyuGramCore`, UI presentation | High |

### Translation, WebView, Extras

| Feature | iOS Strategy | Primary Touchpoints | Risk |
|---|---|---|---|
| Telegram translation provider | Use existing Telegram-iOS translation flow | translation settings/chat translate modules | Low |
| Google provider | Implement optional HTTP provider; default off | `AyuGramCore`, networking | Medium |
| Yandex provider | Implement optional HTTP provider; default off | `AyuGramCore`, networking | Medium |
| Native provider | Use platform APIs only if available and entitlement-safe | iOS translation APIs | High |
| Translation cache | In-memory LRU plus optional local cache | `AyuGramCore` | Low |
| Spoof WebView as Android | Change WebView UA only where app controls WebView | web app/browser modules | Medium |
| Increase WebView dimensions | Adjust presentation constraints | web app/browser UI | Medium |
| Improve link previews | Local presentation tweaks only | link preview rendering | Medium |
| Sticker/GIF/voice confirmations | Add send confirmation gates | input/media send paths | Medium |
| Adaptive cover color | Extract colors for media/player cover UI | media player UI | Medium |
| Crash reporting toggle | Gate local crash/reporting code if present | app delegate/crash reporting | Low |
| Local Premium | Local UI-only premium state. Do not bypass server-side Telegram Premium. | premium checks/presentation only | High |

## Risk And Ethics Boundaries

Do not implement server-side entitlement bypasses. `localPremium` may only affect local presentation and local UI gates that do not require Telegram server capabilities.

Restriction bypass features such as copy/save/download restriction changes must be isolated behind explicit settings and reviewed carefully. They may conflict with platform policy, user expectations, and upstream Telegram content-protection behavior.

Third-party translation providers must be opt-in because they send message text to external services.

Ghost mode changes must avoid corrupting Telegram read-state, notification, and sync invariants. The first implementation should gate only automatic UI read application, then expand after verification.

## Migration Phases

### Phase 0: Ayu Foundation

Create Ayu settings, storage keys, module targets, and a Settings entry. No behavior changes except showing and persisting settings.

### Phase 1: Ghost Mode Core

Gate automatic read-history sending, add manual read actions, and add per-account/global ghost configuration.

### Phase 2: Anti-Recall Core

Persist text snapshots of edited and deleted messages before Telegram-iOS mutates local state. Add history screens and context actions.

### Phase 3: Message Actions And Details

Add context menu actions: message details, edited history, deleted history, repeat message, user messages, read until, clear deleted messages.

### Phase 4: Filters And Shadow Ban

Implement regex filters, per-chat/global filter lists, hidden peer ids, filtered-message visibility overrides, and import/export.

### Phase 5: Appearance And UI Controls

Add message/chat appearance options, composer button gates, drawer/tab-related mappings, stories/ads/similar-channel hiding, and peer id display.

### Phase 6: Translation, WebView, Streamer, Message Shot

Implement optional translation providers, WebView tweaks, streamer mode, message shot generation, confirmations, and adaptive cover color.

### Phase 7: Full QA And Hardening

Run full build, simulator smoke tests, true-device smoke tests where possible, privacy review, settings migration checks, and upstream rebase conflict audit.

## Verification Strategy

Use layered verification:

- Pure model tests for settings defaults, Codable round trips, ghost policy, filter matching, and anti-recall record schemas.
- Compile checks for each module after wiring.
- Targeted smoke tests in simulator for settings, chat read behavior, context menus, and history views.
- Manual account-based tests for ghost mode and anti-recall behavior.
- Full Bazel build before claiming any phase complete.

The repository notes that no conventional unit tests are currently used, but new pure Swift tests are still valuable for AyuGramCore because the behavior is cross-cutting and easy to regress.

## Open Decisions

- Whether to default risky features off even when AyuGram Desktop defaults them on.
- Whether deleted messages should render inline or only in a separate local history screen.
- Whether filter hiding should alter the history list transition pipeline or use a lighter overlay/visibility model.
- Whether iOS alternate icons should use AyuGram Desktop icon art or a new iOS-specific icon set.
- Whether external translation providers should be included in initial release builds or kept behind a compile-time flag.

## Recommended First Slice

Start with Phase 0 and the safest part of Phase 1:

1. Add AyuGramCore settings models and persistence.
2. Add Settings UI entry and screen.
3. Add ghost policy read gate for automatic chat read history.
4. Verify settings persist and opening a chat with ghost read disabled does not call `applyMaxReadIndex`.

This proves the integration pattern before touching edit/delete state processing or deep network synchronization.
