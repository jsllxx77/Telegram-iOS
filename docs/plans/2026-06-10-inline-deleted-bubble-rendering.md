# Inline Deleted Bubble Rendering Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Display locally saved AyuGram deleted-message snapshots as inline chat bubbles, with v1 support for text and media summaries.

**Architecture:** Generate deterministic synthetic local `Message` objects from `AyuGramMessageSnapshot` and merge them into `chatHistoryEntriesForView(...)`. Keep snapshots in AyuGram preferences, not Postbox history, and mark synthetic entries so message UI/context actions can treat them as local deleted records.

**Tech Stack:** Swift, Telegram-iOS Bazel modules, `AyuGramCore`, `AyuGramUI`, `TelegramUI`, `Postbox`, `SwiftSignalKit`, GitHub Actions/Xcode 26.x for build verification.

---

## Task 1: Add Deleted Snapshot Rendering Helpers

**Files:**
- Create: `submodules/AyuGramCore/Sources/AyuGramDeletedBubbleRendering.swift`
- Modify: `submodules/AyuGramCore/BUILD`
- Test: `submodules/AyuGramCore/Tests/AyuGramDeletedBubbleRenderingTests.swift`

**Step 1: Write failing tests**

Add tests for deterministic synthetic IDs and per-thread filtering inputs:

```swift
func testSyntheticLocalMessageIdIsDeterministic() {
    let snapshot = AyuGramMessageSnapshot(
        accountPeerId: 1,
        peerId: 2,
        threadId: nil,
        messageNamespace: 0,
        messageId: 123,
        stableId: 456,
        authorPeerId: 3,
        timestamp: 1000,
        editTimestamp: nil,
        text: "hello",
        entitiesData: nil,
        views: nil,
        forwardInfoData: nil,
        mediaSummary: nil,
        createdAt: 1001
    )

    XCTAssertEqual(
        ayuGramDeletedBubbleLocalMessageId(snapshot),
        ayuGramDeletedBubbleLocalMessageId(snapshot)
    )
    XCTAssertLessThan(ayuGramDeletedBubbleLocalMessageId(snapshot), 0)
}
```

**Step 2: Run test to verify it fails**

Run on macOS/GitHub Actions:

```bash
bazel test //submodules/AyuGramCore/Tests:all
```

Expected: FAIL because the helper does not exist yet.

**Step 3: Implement minimal helpers**

Add pure functions only:

```swift
public func ayuGramDeletedBubbleLocalMessageId(_ snapshot: AyuGramMessageSnapshot) -> Int32
public func ayuGramDeletedBubbleStableId(_ snapshot: AyuGramMessageSnapshot) -> UInt32
public func ayuGramDeletedBubbleDisplayText(snapshot: AyuGramMessageSnapshot, deletedMark: String, fallbackDeletedMark: String) -> String
```

Implementation notes:
- Use a deterministic hash over `accountPeerId`, `peerId`, `threadId`, `messageNamespace`, and `messageId`.
- Force local message IDs into a negative range reserved for AyuGram deleted bubbles.
- Use `stableId` when available, but map it away from existing service-message constants.
- For v1, append `mediaSummary` as a localized summary line when `text` is empty or when both text and media exist.

**Step 4: Run tests again**

Run:

```bash
bazel test //submodules/AyuGramCore/Tests:all
```

Expected: PASS.

**Step 5: Commit**

```bash
git add submodules/AyuGramCore/Sources/AyuGramDeletedBubbleRendering.swift submodules/AyuGramCore/BUILD submodules/AyuGramCore/Tests/AyuGramDeletedBubbleRenderingTests.swift
git commit
```

Use a Lore-style commit message explaining that deterministic IDs prevent UI-transition instability.

## Task 2: Pass Deleted Snapshot Store Into Chat History Rendering

**Files:**
- Modify: `submodules/TelegramUI/Sources/ChatHistoryListNode.swift`
- Modify: `submodules/TelegramUI/Sources/ChatHistoryEntriesForView.swift`

**Step 1: Add a store signal**

In `ChatHistoryListNode.swift`, near the existing AyuGram settings/filter store signals, subscribe to:

```swift
TelegramEngine.EngineData.Item.Configuration.ApplicationSpecificPreference(
    key: PreferencesKeys.ayuGramMessageHistoryStore()
)
```

Map the preference to `AyuGramMessageHistoryStore.empty` when absent and apply `distinctUntilChanged`.

**Step 2: Combine it with existing AyuGram inputs**

Change `ayuGramFiltering` into an AyuGram chat projection tuple containing:

```swift
(settings: AyuGramSettings, filters: AyuGramFilterStore, historyStore: AyuGramMessageHistoryStore)
```

Update the `promises` tuple consumers accordingly.

**Step 3: Extend `chatHistoryEntriesForView(...)`**

Add a new parameter:

```swift
ayuGramMessageHistoryStore: AyuGramMessageHistoryStore
```

Pass it at the call site.

**Step 4: Verify compilation syntax locally if possible**

Run:

```bash
git diff --check
```

Expected: no whitespace errors. Full Swift compilation is expected to run in GitHub Actions.

**Step 5: Commit**

```bash
git add submodules/TelegramUI/Sources/ChatHistoryListNode.swift submodules/TelegramUI/Sources/ChatHistoryEntriesForView.swift
git commit
```

## Task 3: Convert Snapshots To Synthetic Local Messages

**Files:**
- Modify: `submodules/TelegramUI/Sources/ChatHistoryEntriesForView.swift`

**Step 1: Add snapshot filtering in `chatHistoryEntriesForView(...)`**

When `ayuGramSettings.saveDeletedMessages` is true and `location.peerId` exists:

- Use `context.account.peerId.toInt64()` as account ID.
- Use `location.peerId.toInt64()` as peer ID.
- Use `listDeletedSnapshotsInThread` when `location.threadId` exists.
- Use `listDeletedSnapshotsWithoutThread` for normal chat history.

**Step 2: Build `Message` values**

Create a small private function in the same file:

```swift
private func ayuGramDeletedSnapshotMessage(
    snapshot: AyuGramMessageSnapshot,
    peerId: PeerId,
    accountPeerId: PeerId,
    presentationData: ChatPresentationData,
    peerLookup: [PeerId: Peer],
    settings: AyuGramSettings
) -> Message
```

Use `Namespaces.Message.Local`, deterministic ID/stable ID helpers, snapshot timestamp, and display text from `ayuGramDeletedBubbleDisplayText(...)`.

**Step 3: Resolve author when possible**

Build `peerLookup` from `view.additionalData` entries and the message peers available in `view.entries`. If `snapshot.authorPeerId` resolves, set it as `author`; otherwise keep `author` nil.

**Step 4: Insert entries and sort**

Append `.MessageEntry` for each synthetic message with default `ChatMessageEntryAttributes`, then call `entries.sort()` before unread-entry/date-header logic that depends on sorted entries.

**Step 5: Verify no obvious duplicate rendering**

Skip a snapshot if `view.entries` still contains the original `(messageNamespace, messageId, peerId)`. This handles race windows where a snapshot exists but the message has not disappeared from the visible history yet.

**Step 6: Commit**

```bash
git add submodules/TelegramUI/Sources/ChatHistoryEntriesForView.swift
git commit
```

## Task 4: Mark Synthetic Deleted Messages For UI Policy

**Files:**
- Create or modify: `submodules/AyuGramCore/Sources/AyuGramDeletedMessageAttribute.swift`
- Modify: `submodules/AyuGramCore/BUILD`
- Modify: `submodules/TelegramUI/Sources/ChatHistoryEntriesForView.swift`
- Modify as needed: `submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift`

**Step 1: Add a local message attribute**

Create a lightweight attribute to identify synthetic deleted bubbles:

```swift
public final class AyuGramDeletedMessageAttribute: MessageAttribute {
    public let originalNamespace: Int32
    public let originalId: Int32
    public let createdAt: Int32
}
```

Follow existing `MessageAttribute` coding patterns in TelegramCore/Postbox modules.

**Step 2: Attach it to synthetic messages**

Add the attribute to `Message.attributes` when creating the deleted snapshot message.

**Step 3: Restrict context menu actions**

In `ChatInterfaceStateContextMenus.swift`, detect this attribute and avoid server actions such as reply, edit, forward, delete for everyone, reactions, and read-stat actions. Keep copy/details/local deleted history actions.

**Step 4: Commit**

```bash
git add submodules/AyuGramCore/Sources/AyuGramDeletedMessageAttribute.swift submodules/AyuGramCore/BUILD submodules/TelegramUI/Sources/ChatHistoryEntriesForView.swift submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift
git commit
```

## Task 5: Apply Semi-Transparent Deleted Bubble Styling

**Files:**
- Inspect/modify: `submodules/TelegramUI/Components/Chat/ChatMessageItem*/Sources/*.swift`
- Modify: whichever file computes message bubble alpha/background for `ChatMessageItemImpl`

**Step 1: Locate bubble alpha update code**

Run:

```bash
rg -n "alpha|opacity|backgroundColor|bubble" submodules/TelegramUI/Components/Chat -g '*.swift'
```

**Step 2: Add AyuGram deleted attribute detection**

When `message.attributes` contains `AyuGramDeletedMessageAttribute` and `associatedData.ayuGramData` or another passed setting says `semiTransparentDeletedMessages` is enabled, lower bubble/content opacity only for this message.

**Step 3: Pass the setting through associated data if needed**

If `ChatMessageItemAssociatedData.ayuGramData` lacks this flag, add it to the AyuGram data struct and populate it from `ChatHistoryListNode.swift`.

**Step 4: Commit**

```bash
git add <touched chat message item files>
git commit
```

## Task 6: Add Local Removal/Clear Actions For Deleted Bubbles

**Files:**
- Modify: `submodules/AyuGramCore/Sources/AyuGramMessageHistoryStore.swift`
- Modify: `submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift`
- Modify: `submodules/AyuGramUI/Sources/AyuGramMessageContextMenu.swift` if AyuGram menu descriptors need a new action

**Step 1: Add a single-record removal API**

Add:

```swift
public mutating func removeDeletedSnapshot(accountPeerId: Int64, peerId: Int64, messageNamespace: Int32, messageId: Int32) -> Bool
```

**Step 2: Add context action**

For synthetic deleted bubbles, add a localized action such as `Remove Local Deleted Record` / `移除本地删除记录`.

**Step 3: Update preference store on action**

Use `context.engine.preferences.update(id: PreferencesKeys.ayuGramMessageHistoryStore())` to remove the snapshot.

**Step 4: Commit**

```bash
git add submodules/AyuGramCore/Sources/AyuGramMessageHistoryStore.swift submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift submodules/AyuGramUI/Sources/AyuGramMessageContextMenu.swift
git commit
```

## Task 7: Liquid Glass Settings Exposure

**Files:**
- Modify: `submodules/AyuGramCore/Sources/AyuGramSettings.swift`
- Modify: `submodules/AyuGramCore/Sources/AyuGramEnums.swift`
- Modify: `submodules/AyuGramUI/Sources/AyuGramSettingsController.swift`
- Modify: `submodules/AyuGramUI/Sources/AyuGramLocalization.swift`
- Inspect/modify: chat/root controllers that read `ExperimentalUISettings.forceClearGlass` / `fakeGlass`

**Step 1: Add an AyuGram glass style enum**

Add values like:

```swift
public enum AyuLiquidGlassStyle: Int32, Codable, Equatable {
    case system
    case clear
    case compatibility
}
```

**Step 2: Add setting storage**

Add `liquidGlassStyle` to `AyuGramSettings`, defaulting to `.system`, with backward-compatible decoding.

**Step 3: Add settings UI**

Add an Appearance row using localized labels:

- System / 跟随系统
- Clear Glass / 透明玻璃
- Compatibility Glass / 兼容玻璃

**Step 4: Wire to existing glass behavior**

Map:

- `.system`: existing Telegram behavior.
- `.clear`: prefer `NavigationBar.GlassStyle.clear` where the current code supports `preferredGlassType` or `forceClearGlass`.
- `.compatibility`: prefer existing fake/legacy glass paths without unguarded iOS 26 SDK symbols.

**Step 5: Keep iOS 26 API guarded**

Any new reference to system Liquid Glass must use `#available(iOS 26.0, *)` and runtime lookup where needed. Do not add direct private API calls beyond the existing runtime-lookup pattern.

**Step 6: Commit**

```bash
git add submodules/AyuGramCore/Sources/AyuGramSettings.swift submodules/AyuGramCore/Sources/AyuGramEnums.swift submodules/AyuGramUI/Sources/AyuGramSettingsController.swift submodules/AyuGramUI/Sources/AyuGramLocalization.swift <glass consumer files>
git commit
```

## Task 8: Media Preview Follow-Up Foundation

**Files:**
- Modify: `submodules/AyuGramCore/Sources/AyuGramMessageSnapshot.swift`
- Modify: `submodules/TelegramCore/Sources/State/AccountStateManagementUtils.swift`
- Test: `submodules/AyuGramCore/Tests/AyuGramMessageHistoryStoreTests.swift` or a new snapshot coding test

**Step 1: Add optional media metadata fields**

Add backward-compatible optional fields only:

```swift
public var mediaKind: String?
public var mediaResourceId: String?
public var mediaThumbnailResourceId: String?
public var mediaMimeType: String?
public var mediaFileName: String?
public var mediaDuration: Double?
public var mediaDimensions: String?
```

**Step 2: Extend snapshot capture**

When deleting a message, capture available media metadata from message media objects without forcing network download.

**Step 3: Do not render real previews yet**

Only persist enough data so a later task can look up cached MediaBox resources safely.

**Step 4: Commit**

```bash
git add submodules/AyuGramCore/Sources/AyuGramMessageSnapshot.swift submodules/TelegramCore/Sources/State/AccountStateManagementUtils.swift <tests>
git commit
```

## Task 9: GitHub Actions Verification

**Files:**
- Modify only if needed: `.github/workflows/build.yml`

**Step 1: Static checks on Linux**

Run:

```bash
git diff --check
git status --short
```

Expected: no whitespace errors; only intended files changed.

**Step 2: Push branch**

Run:

```bash
git push origin feature/ayugram-ios-full-port
```

**Step 3: Trigger CI**

Run:

```bash
gh workflow run build.yml --repo jsllxx77/Telegram-iOS --ref feature/ayugram-ios-full-port
```

**Step 4: Watch build**

Run:

```bash
gh run list --repo jsllxx77/Telegram-iOS --workflow build.yml --limit 3
gh run view <run-id> --repo jsllxx77/Telegram-iOS --json status,conclusion,jobs,url
```

Expected: build succeeds and release job can publish without rebuilding when permissions are correct.

## Implementation Order

1. Tasks 1-4 for v1 inline deleted text/media summary bubbles.
2. Task 5 for semi-transparent rendering.
3. Task 6 for local deleted-bubble management actions.
4. Task 7 for Liquid Glass user-facing setting.
5. Task 8 only after v1 is stable, because real media preview needs additional stored metadata.
6. Task 9 after each meaningful batch.

## Known Verification Limits

- This Linux workspace cannot run Swift, Bazel iOS builds, or device UI tests.
- GitHub Actions with Xcode 26.x is the build oracle.
- Device sideload testing is still required for chat scroll behavior, context menus, and visual opacity.
