# Inline Deleted Bubble Rendering Design - 2026-06-10

## Goal

Render AyuGram deleted-message snapshots directly in the chat history as local-only deleted bubbles. The first version intentionally supports text and media summaries only, because the current snapshot model stores `text`, serialized text metadata, and `mediaSummary`, but not full media resource references.

## Current State

- `Save Deleted Messages` is already persisted as `AyuGramSettings.saveDeletedMessages`.
- Delete snapshots are captured before TelegramCore delete operations and stored in `PreferencesKeys.ayuGramMessageHistoryStore()`.
- `AyuGramMessageHistoryStore` can list deleted snapshots by account, peer, and thread.
- `AyuGramDeletedMessagesController` can display the saved snapshots in a separate history screen.
- `ChatHistoryEntriesForView.swift` already imports `AyuGramCore`, receives AyuGram settings, and can construct local `Message` values with `Namespaces.Message.Local` for existing service/header entries.
- `ChatHistoryEntry` sorting uses `Message.index`, then `stableId`, so synthetic messages can be inserted into the same transition pipeline if they use deterministic local IDs and timestamps.

## Recommended Approach

Use synthetic local `Message` entries generated from `AyuGramMessageSnapshot` and merge them into `chatHistoryEntriesForView(...)` before the transition is prepared.

This keeps the feature local to the UI projection layer. It does not write deleted messages back into Postbox history, so it avoids corrupting Telegram sync state, unread counts, holes, search indexing, or server-backed message identity.

## Alternatives Considered

### A. Synthetic local `Message` entries

This is the preferred path. It reuses Telegram's existing `ChatMessageItemImpl` bubble rendering, date headers, insertion animations, selection plumbing, and message grouping behavior. It requires careful deterministic ID generation and a small amount of AyuGram metadata so the UI can mark messages as deleted.

Tradeoff: the first version is limited to text and media-summary rendering unless the snapshot model is extended later.

### B. New `ChatHistoryEntry.deletedSnapshot` case

This would make deleted snapshots explicit and avoid pretending they are real messages. It also means building or adapting a custom list item, context menu behavior, transitions, hit testing, accessibility labels, and theme behavior.

Tradeoff: more correct conceptually, but a larger and riskier first implementation.

### C. Insert deleted messages into Postbox

This is not recommended. It would make deleted snapshots look like real local history, but it risks breaking Telegram history consistency, search, holes, read state, sync replay, and pending-message logic.

Tradeoff: high blast radius for little v1 benefit.

## Data Flow

1. TelegramCore captures a snapshot before a message deletion and writes it to `PreferencesKeys.ayuGramMessageHistoryStore()`.
2. `ChatHistoryListNode` subscribes to the same preference in the existing chat-history combined signal.
3. For the current chat location, the node filters deleted snapshots by account, peer, and thread.
4. `chatHistoryEntriesForView(...)` receives the filtered snapshots together with `ayuGramSettings`.
5. If `saveDeletedMessages` is enabled, the function converts snapshots to deterministic synthetic local `Message` objects.
6. The synthetic entries are merged with normal chat entries and sorted by `ChatHistoryEntry` ordering.
7. The list transition renders them as local-only deleted bubbles.

## Synthetic Message Shape

Each deleted snapshot becomes a `Message` with:

- `id.peerId`: current chat peer.
- `id.namespace`: `Namespaces.Message.Local`.
- `id.id`: deterministic negative ID derived from original namespace and ID.
- `stableId`: deterministic high-range value derived from the snapshot identity.
- `threadId`: snapshot thread ID converted back to the local thread representation where applicable.
- `timestamp`: original message timestamp.
- `flags`: incoming when the original author is not the current account, outgoing otherwise.
- `author`: resolved from `view.additionalData` when available; otherwise omitted.
- `text`: original text plus an optional localized deleted marker.
- `media`: empty for text-only v1, or a `TelegramMediaAction.customText` / summary text when the snapshot has only `mediaSummary`.

The exact ID conversion should live in one helper so collisions can be unit-tested and later migrated.

## UI Behavior

- Deleted bubbles appear in chronological chat position, not only in a separate history list.
- A localized deleted marker is shown, using the existing AyuGram setting `deletedMark` when present, otherwise a built-in Chinese/English fallback.
- `semiTransparentDeletedMessages` applies only to these synthetic deleted entries.
- Context menus for synthetic deleted entries are restricted to local-safe actions: copy text, message details, open deleted history, and remove/clear local deleted records.
- Forward, reply, edit, reactions, read receipts, and server actions are hidden or disabled for synthetic deleted entries.
- Search remains a later task; v1 focuses on normal chat scroll rendering.

## Media Roadmap

The current model can only render a text summary such as `[Photo]` or `[Video]` because `AyuGramMessageSnapshot` does not preserve resource identity or local cache references.

Real image/video previews are possible later if capture is extended before deletion to persist enough metadata:

- media kind, dimensions, duration, file name, mime type;
- Telegram media ID / file reference where safe and useful;
- local MediaBox resource IDs for thumbnails and files;
- a cache-presence flag so UI can avoid showing broken previews.

If the client never received or cached the media before deletion, it cannot reconstruct the original image/video locally.

## Liquid Glass Assessment

This repository already contains substantial glass UI support:

- `GlassBackgroundComponent` and `GlassControls` provide reusable glass surfaces.
- `LegacyGlassView` uses private backdrop-layer behavior and guards newer mesh transforms with `#available(iOS 17.0, *)`.
- `LiquidLensView` already checks `#available(iOS 26.0, *)` and uses `NSClassFromString("_UILiquidLensView")` to adopt Apple's newest Liquid Lens/Liquid Glass internals when present.
- Debug settings expose `fakeGlass` and `forceClearGlass`, but AyuGram settings do not yet expose them.

The practical v1 path is to expose a user-facing AyuGram appearance setting for the existing glass style: system/default, clear glass, and compatibility/fake glass. True iOS 26 Liquid Glass support should remain guarded by availability checks and runtime class lookup, because unguarded SDK symbols would break older build targets or CI when Apple changes names.

## Risks

- ID collisions with existing local service messages if the deterministic range is not isolated.
- Duplicate display if the server message still exists locally and a stale deleted snapshot is present.
- Context menus may expose server actions unless the synthetic entry is marked clearly.
- Thread filtering must match forums, reply threads, and normal chats.
- Large stores could make chat-history recomputation expensive without per-chat filtering before entry generation.

## Acceptance Criteria

- A newly deleted text message appears inline after the chat refreshes.
- A newly deleted media message without cached resource metadata appears inline with a clear media summary.
- Toggling `Save Deleted Messages` off prevents inline rendering while preserving already saved history records.
- Toggling `Semi-Transparent Deleted Messages` changes only synthetic deleted bubbles.
- Contacts/Calls tab behavior is not affected.
- The app builds in GitHub Actions with Xcode 26.x.
