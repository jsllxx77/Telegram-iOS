# AyuGram iOS Full Port Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an iOS-native AyuGram feature layer in the `Telegram-iOS` fork, covering the complete AyuGram Desktop feature families through phased, verifiable migration.

**Architecture:** Add `AyuGramCore` for settings, storage, ghost policy, anti-recall records, filters, translation, and utility logic. Add `AyuGramUI` for settings screens, message history screens, filter management, and context menu actions. Keep Telegram-iOS changes as narrow integration hooks into preferences, chat read management, state update processing, rendering, and context menus.

**Tech Stack:** Swift, Bazel, Telegram-iOS submodules, Postbox, TelegramCore, TelegramEngine, SwiftSignalKit, SettingsUI, ItemListUI, ContextUI, AsyncDisplayKit/Display.

---

## Execution Rules

- Implement one phase at a time.
- Keep risky behavior behind explicit settings.
- Do not add third-party dependencies.
- Do not bypass server-side Telegram Premium or other server entitlements.
- Prefer pure model tests for AyuGramCore even though the repository has limited existing test coverage.
- Run a targeted build after each wiring task and a full build after each phase.

Build command from repository guidance:

```bash
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --continueOnError --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64
```

Expected: build succeeds, or reports compile errors limited to the files changed in the current task.

## Phase 0: Ayu Foundation

### Task 1: Create AyuGramCore Module Skeleton

**Files:**
- Create: `submodules/AyuGramCore/BUILD`
- Create: `submodules/AyuGramCore/Sources/AyuGramSettings.swift`
- Create: `submodules/AyuGramCore/Sources/AyuGramGhostSettings.swift`
- Create: `submodules/AyuGramCore/Sources/AyuGramEnums.swift`
- Modify: root or module Bazel files as required by the existing submodule pattern

**Step 1: Inspect nearby module BUILD patterns**

Run:

```bash
find submodules/TelegramUIPreferences submodules/ChatInterfaceState -maxdepth 2 -name BUILD -print
sed -n '1,160p' submodules/TelegramUIPreferences/BUILD
```

Expected: identify the local Swift library rule and dependency syntax.

**Step 2: Add enum models**

Define Swift enums matching AyuGram Desktop:

```swift
public enum AyuPeerIdDisplay: Int32, Codable {
    case hidden = 0
    case telegramApi = 1
    case botApi = 2
}

public enum AyuChannelBottomButton: Int32, Codable {
    case hidden = 0
    case muteUnmute = 1
    case discussWithFallback = 2
}

public enum AyuContextMenuVisibility: Int32, Codable {
    case hidden = 0
    case visible = 1
    case visibleWithModifier = 2
}

public enum AyuTranslationProvider: String, Codable {
    case telegram
    case google
    case yandex
    case native
}

public enum AyuSendWithoutSoundOption: Int32, Codable {
    case never = 0
    case inGhostMode = 1
    case always = 2
}
```

**Step 3: Add ghost settings model**

Implement `AyuGramGhostSettings` with Desktop defaults:

```swift
public struct AyuGramGhostSettings: Codable, Equatable {
    public var sendReadMessages: Bool
    public var sendReadStories: Bool
    public var sendOnlinePackets: Bool
    public var sendUploadProgress: Bool
    public var sendOfflinePacketAfterOnline: Bool
    public var markReadAfterAction: Bool
    public var useScheduledMessages: Bool
    public var sendWithoutSound: AyuSendWithoutSoundOption
    public var suggestGhostModeBeforeViewingStory: Bool
    public var sendReadMessagesLocked: Bool
    public var sendReadStoriesLocked: Bool
    public var sendOnlinePacketsLocked: Bool
    public var sendUploadProgressLocked: Bool
    public var sendOfflinePacketAfterOnlineLocked: Bool
}
```

Add computed properties:

```swift
public var isGhostModeActive: Bool {
    return (sendReadMessagesLocked || !sendReadMessages)
        && (sendReadStoriesLocked || !sendReadStories)
        && (sendOnlinePacketsLocked || !sendOnlinePackets)
        && (sendUploadProgressLocked || !sendUploadProgress)
        && (sendOfflinePacketAfterOnlineLocked || sendOfflinePacketAfterOnline)
}
```

**Step 4: Add root settings model**

Implement `AyuGramSettings` with all fields from the design document feature matrix. Include `defaultSettings`.

**Step 5: Build**

Run the full build command.

Expected: any errors are limited to missing Bazel wiring and fixed before moving on.

**Step 6: Commit**

Use a Lore commit message:

```bash
git add submodules/AyuGramCore
git commit -m "Create the AyuGram settings foundation for iOS

The port needs a Swift-native settings model before any Telegram-iOS
behavior can be gated. This mirrors the AyuGram Desktop setting surface
without wiring behavior yet.

Constraint: AyuGram Desktop is C++/Qt and cannot be reused directly
Rejected: Store settings in a standalone JSON file | Telegram-iOS already has account/shared preference storage
Confidence: high
Scope-risk: narrow
Tested: Bazel build for debug simulator
Not-tested: Runtime settings UI because no UI exists yet"
```

### Task 2: Persist Ayu Settings

**Files:**
- Modify: `submodules/TelegramUIPreferences/Sources/PostboxKeys.swift`
- Create: `submodules/TelegramUIPreferences/Sources/AyuGramSettingsPreferences.swift`
- Modify: `submodules/TelegramUIPreferences/BUILD`
- Test: pure Codable round-trip test if existing test target supports it

**Step 1: Add preference key**

Add a new value to the relevant app-specific shared data or preferences key enum. Prefer account-manager shared settings if the UI should apply across accounts; use account-specific storage for per-account ghost overrides.

**Step 2: Add update helper**

Pattern after `TranslationSettings.swift`:

```swift
public func updateAyuGramSettingsInteractively(
    accountManager: AccountManager<TelegramAccountManagerTypes>,
    _ f: @escaping (AyuGramSettings) -> AyuGramSettings
) -> Signal<Void, NoError>
```

**Step 3: Add getter helpers**

Expose default-safe reads for shared data consumers.

**Step 4: Build and commit**

Run build command and commit with `Tested: Bazel build for debug simulator`.

### Task 3: Add Ayu Settings Entry

**Files:**
- Create: `submodules/AyuGramUI/BUILD`
- Create: `submodules/AyuGramUI/Sources/AyuGramSettingsController.swift`
- Modify: appropriate main settings controller in `submodules/SettingsUI/Sources`
- Modify: localization files for English labels

**Step 1: Inspect SettingsUI entry patterns**

Run:

```bash
rg -n "ItemListDisclosureItem|Settings_" submodules/SettingsUI/Sources -g '*.swift' | head -80
```

Expected: identify where top-level settings entries are constructed.

**Step 2: Build first settings screen**

Create an AyuGram settings controller with sections:

- Ghost Mode
- Message History
- Filters
- Appearance
- Chat Controls
- Translation
- Advanced

Initial rows should render values and allow toggling persisted settings, even if behavior is not wired yet.

**Step 3: Smoke test in simulator**

Run the app, open Settings, enter AyuGram, toggle a setting, leave and return.

Expected: setting persists.

**Step 4: Commit**

Commit settings UI separately from behavior changes.

## Phase 1: Ghost Mode Core

### Task 4: Gate Automatic Read History

**Files:**
- Modify: `submodules/TelegramUI/Sources/ChatHistoryListNode.swift:2488`
- Modify: `submodules/TelegramUI/Sources/AccountContext.swift`
- Modify/Create: `submodules/AyuGramCore/Sources/AyuGramGhostPolicy.swift`

**Step 1: Write ghost policy**

Add:

```swift
public struct AyuGramGhostPolicy: Equatable {
    public var sendReadMessages: Bool

    public var shouldApplyAutomaticReadHistory: Bool {
        return self.sendReadMessages
    }
}
```

Expand later as more ghost features are wired.

**Step 2: Read settings into AccountContext or ChatHistoryListNode**

Use existing shared data observation patterns. Avoid synchronous storage reads in hot paths.

**Step 3: Gate automatic read**

In `beginReadHistoryManagement`, change the automatic `applyMaxReadIndex` path so it requires both Telegram's existing conditions and Ayu ghost policy allowing read messages.

**Step 4: Manual verification**

Use a test account:

- Disable Ayu send read messages.
- Open an unread chat.
- Confirm the remote account still sees messages as unread.
- Use explicit read action later to mark read.

**Step 5: Commit**

Commit only the automatic read gate.

### Task 5: Add Manual Read Until

**Files:**
- Modify: `submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift`
- Modify: `submodules/TelegramUI/Sources/ChatControllerLoadDisplayNode.swift`
- Reuse: `AccountContext.applyMaxReadIndex`

**Step 1: Add context menu item**

Show "Read Until" for incoming, non-local, unread-eligible messages when ghost suppresses automatic reads.

**Step 2: Bypass ghost policy intentionally**

Call the existing read index application path explicitly.

**Step 3: Verify**

Open a chat with ghost enabled, long-press an older unread message, choose Read Until.

Expected: messages up to that point become read remotely.

**Step 4: Commit**

Commit as a separate behavior slice.

### Task 6: Expand Ghost State Surfaces

**Files:**
- Inventory first: story read modules, presence modules, upload progress modules
- Modify only after inventory is documented

**Step 1: Inventory**

Run:

```bash
rg -n "readStories|readStory|story.*read|updateReadStories|presence|online|offline|uploadProgress|sendProgress|typing" submodules -g '*.swift'
```

**Step 2: Classify call sites**

Classify each as:

- Safe UI-only gate
- Network request gate
- State-machine critical
- Not applicable on iOS

**Step 3: Implement one surface per commit**

Order:

1. Story read gate
2. Send without sound while ghost active
3. Upload progress gate
4. Online/offline packet gate

**Step 4: Verify**

Use two accounts and check remote-visible effects.

## Phase 2: Anti-Recall Core

### Task 7: Create Anti-Recall Storage Models

**Files:**
- Create: `submodules/AyuGramCore/Sources/AyuGramMessageSnapshot.swift`
- Create: `submodules/AyuGramCore/Sources/AyuGramMessageHistoryStore.swift`
- Modify: `submodules/AyuGramCore/BUILD`

**Step 1: Define snapshot**

Fields should cover the Desktop model's first pass:

```swift
public struct AyuGramMessageSnapshot: Codable, Equatable {
    public var accountPeerId: Int64
    public var peerId: Int64
    public var threadId: Int64?
    public var messageNamespace: Int32
    public var messageId: Int32
    public var stableId: Int64?
    public var authorPeerId: Int64?
    public var timestamp: Int32
    public var editTimestamp: Int32?
    public var text: String
    public var entitiesData: Data?
    public var views: Int32?
    public var forwardInfoData: Data?
    public var mediaSummary: String?
    public var createdAt: Int32
}
```

**Step 2: Store text-only first**

Do not store media bytes in this task. Store media metadata/resource references only after the text path is stable.

**Step 3: Add query APIs**

Implement:

- add edited snapshot
- add deleted snapshot
- list edited snapshots by message id
- list deleted snapshots by peer/thread/search
- clear deleted snapshots by peer/thread

**Step 4: Build and commit**

Commit storage model separately.

### Task 8: Capture Edited Messages

**Files:**
- Modify: `submodules/TelegramCore/Sources/State/AccountStateManagementUtils.swift`
- Modify: `submodules/AyuGramCore/Sources/AyuGramMessageHistoryStore.swift`

**Step 1: Locate previous message before update**

In the `.EditMessage` path, capture `previousMessage` before `transaction.updateMessage` mutates it.

**Step 2: Store only when enabled**

Read current Ayu settings and store previous text snapshot when `saveMessagesHistory` is true, message is incoming or allowed by settings, and text is non-empty.

**Step 3: Verify**

Edit a message from another account.

Expected: local current message changes, previous text appears in local edited history query.

**Step 4: Commit**

### Task 9: Capture Deleted Messages

**Files:**
- Modify: `submodules/TelegramCore/Sources/State/AccountStateManagementUtils.swift`
- Modify: delete helper paths if needed

**Step 1: Capture before delete**

Before `_internal_deleteMessages` or `transaction.deleteMessages*` removes records, fetch each message from transaction and store snapshot.

**Step 2: Preserve existing delete behavior**

Do not prevent Telegram's local delete. Store local copy only.

**Step 3: Verify**

Delete a message from another account.

Expected: message disappears from normal chat, appears in Ayu deleted history query.

**Step 4: Commit**

### Task 10: Build History UI

**Files:**
- Create: `submodules/AyuGramUI/Sources/AyuGramEditedHistoryController.swift`
- Create: `submodules/AyuGramUI/Sources/AyuGramDeletedMessagesController.swift`
- Modify: `submodules/AyuGramUI/BUILD`

**Step 1: Create list UI**

Use existing ItemList/ListView patterns. Show text, author, date, edit date, message id.

**Step 2: Add search for deleted history**

Support local text search.

**Step 3: Add clear action**

Clear deleted records by peer/thread.

**Step 4: Commit**

## Phase 3: Context Menu And Message Details

### Task 11: Add Ayu Context Menu Builder

**Files:**
- Create: `submodules/AyuGramUI/Sources/AyuGramMessageContextMenu.swift`
- Modify: `submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift`

**Step 1: Build pure action descriptors**

Return descriptors for:

- View edited history
- View deleted messages
- Message details
- User messages
- Repeat message
- Read until
- Hide message locally
- Add filter
- Shadow ban

**Step 2: Gate by settings**

Use `AyuContextMenuVisibility`.

**Step 3: Wire actions**

Keep action handlers in TelegramUI integration, delegate logic to AyuGramUI/Core.

**Step 4: Commit**

### Task 12: Message Details Screen

**Files:**
- Create: `submodules/AyuGramUI/Sources/AyuGramMessageDetailsController.swift`

**Step 1: Show safe metadata**

Display:

- peer id
- message id
- author id
- date
- edit date
- views/forwards where available
- entity count
- media type summary
- thread id

**Step 2: Add copy actions**

Allow copying IDs and text fields.

**Step 3: Commit**

## Phase 4: Filters And Shadow Ban

### Task 13: Implement Filter Models And Matching

**Files:**
- Create: `submodules/AyuGramCore/Sources/AyuGramFilter.swift`
- Create: `submodules/AyuGramCore/Sources/AyuGramFilterEngine.swift`

**Step 1: Define models**

Mirror Desktop:

- id
- text
- enabled
- reversed
- caseInsensitive
- dialogId
- exclusions

**Step 2: Implement matching**

Use `NSRegularExpression`.

**Step 3: Add tests**

Cover normal, reversed, case-insensitive, disabled, per-dialog, and exclusion cases.

**Step 4: Commit**

### Task 14: Add Filter Storage And UI

**Files:**
- Create: `submodules/AyuGramUI/Sources/AyuGramFiltersController.swift`
- Create: `submodules/AyuGramUI/Sources/AyuGramFilterEditController.swift`

**Step 1: Persist filter list**

Use account-specific storage.

**Step 2: Add UI**

List filters, add/edit/delete, enable/disable, import/export JSON.

**Step 3: Commit**

### Task 15: Apply Filters To Chat History

**Files:**
- Modify: chat history transition or entry mapping modules identified by inventory

**Step 1: Inventory entry mapping**

Run:

```bash
rg -n "mappedChatHistoryViewListTransition|ChatHistoryEntry|filteredEntries" submodules/TelegramUI/Sources -g '*.swift'
```

**Step 2: Add local hidden/filtered state**

Prefer marking entries hidden before rendering, with a setting to show filtered records.

**Step 3: Verify grouped messages**

Ensure filtering one grouped message does not corrupt layout.

**Step 4: Commit**

## Phase 5: Appearance And UI Controls

### Task 16: Appearance Settings

**Files:**
- Modify: `submodules/TelegramUIPreferences/Sources/PresentationThemeSettings.swift`
- Modify: bubble/avatar rendering modules identified by inventory
- Modify: `submodules/AyuGramUI/Sources/AyuGramSettingsController.swift`

**Step 1: Implement low-risk display toggles**

Start with:

- show message seconds
- show peer id
- hide fast share
- hide similar channels
- disable open link warning

**Step 2: Implement rendering changes**

Then:

- bubble radius
- avatar corners
- remove message tail
- bottom info icons

**Step 3: Commit each display family separately**

### Task 17: Stories, Ads, Premium Status, Chat List Controls

**Files:**
- Inventory first using `rg`
- Modify chat list, story, sponsored, and peer info modules

**Step 1: Inventory**

Run:

```bash
rg -n "sponsored|story|stories|premiumBadge|isPremium|similarChannels|chatListFilter" submodules -g '*.swift'
```

**Step 2: Implement local UI hiding**

Do not alter server requests unless necessary.

**Step 3: Commit by feature family**

### Task 18: Composer And Drawer Controls

**Files:**
- Inventory chat input modules
- Modify settings UI and input panel modules

**Step 1: Inventory**

Run:

```bash
rg -n "attach|emoji|microphone|gift|commands|inputPanel|compose" submodules/TelegramUI submodules/ChatInterfaceState -g '*.swift'
```

**Step 2: Add gates**

Hide configured buttons and popup entries.

**Step 3: Commit**

## Phase 6: Translation, WebView, Streamer, Message Shot

### Task 19: Translation Providers

**Files:**
- Create: `submodules/AyuGramCore/Sources/AyuGramTranslationProvider.swift`
- Create: `submodules/AyuGramCore/Sources/AyuGramGoogleTranslationProvider.swift`
- Create: `submodules/AyuGramCore/Sources/AyuGramYandexTranslationProvider.swift`
- Modify translation UI integration points

**Step 1: Keep Telegram provider as default**

Use existing Telegram-iOS translation behavior.

**Step 2: Add external providers opt-in**

Warn in UI that external providers send text to third-party services.

**Step 3: Add cache**

Implement in-memory LRU first.

**Step 4: Commit**

### Task 20: WebView Tweaks

**Files:**
- Inventory WebView/browser modules

**Step 1: Inventory**

```bash
rg -n "WKWebView|userAgent|webView|WebApp|Browser" submodules -g '*.swift'
```

**Step 2: Add settings gates**

Implement Android UA spoof and larger presentation dimensions only where Telegram-iOS owns the WebView.

**Step 3: Commit**

### Task 21: Streamer Mode

**Files:**
- Create: `submodules/AyuGramCore/Sources/AyuGramStreamerMode.swift`
- Modify selected presentation modules

**Step 1: Define redaction policy**

Hide phone numbers, usernames, peer IDs, invite links, and sensitive message previews where configured.

**Step 2: Apply to presentation only**

Do not mutate stored messages.

**Step 3: Commit**

### Task 22: Message Shot

**Files:**
- Create: `submodules/AyuGramUI/Sources/AyuGramMessageShotController.swift`
- Create: `submodules/AyuGramUI/Sources/AyuGramMessageShotRenderer.swift`

**Step 1: Implement selected-message renderer**

Render text-only message shots first.

**Step 2: Add options**

Support background, date, reactions, header decorations, colorful replies, spoiler reveal, embedded theme.

**Step 3: Add share/save flow**

Use iOS share sheet.

**Step 4: Commit**

## Phase 7: Full QA And Hardening

### Task 23: Feature Matrix Verification

**Files:**
- Create: `docs/plans/2026-06-09-ayugram-ios-verification-matrix.md`

**Step 1: Add matrix**

Columns:

- feature
- default setting
- implementation commit
- simulator tested
- device tested
- two-account tested
- residual risk

**Step 2: Fill after each phase**

Keep it current.

**Step 3: Commit**

### Task 24: Full Build And Runtime Smoke

**Step 1: Full build**

Run the build command.

Expected: success.

**Step 2: Simulator smoke**

Verify:

- app launches
- account loads
- settings opens
- AyuGram settings persist
- chat opens
- context menus open
- message send still works

**Step 3: Two-account smoke**

Verify:

- ghost read suppression
- manual read until
- edit history capture
- deleted message capture
- filter hiding

**Step 4: Commit final QA notes**

Commit verification matrix updates.

## Completion Criteria

- Every feature in the design matrix is either implemented, explicitly marked iOS-not-applicable, or documented as intentionally excluded.
- Risky features are off by default or guarded by explicit warnings.
- Full debug simulator build passes.
- At least one simulator smoke run is completed.
- Ghost and anti-recall are tested with two Telegram accounts.
- No new dependency is introduced.
- The final report lists changed files, simplifications, and remaining risks.
