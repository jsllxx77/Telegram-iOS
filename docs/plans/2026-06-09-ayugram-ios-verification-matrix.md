# AyuGram iOS Verification Matrix

Status as of Task 23 on `feature/ayugram-ios-full-port`.

This matrix records implementation coverage and the runtime verification that still needs to happen on macOS/GitHub Actions or physical iOS devices. The Linux workspace used for Tasks 1-23 does not have `swift`, `swiftc`, `bazel`, `bazelisk`, or `xcodebuild`, so simulator/device/two-account columns intentionally remain `Not run` until Task 24.

| Feature | Default setting | Implementation commit | Simulator tested | Device tested | Two-account tested | Residual risk |
|---|---|---|---|---|---|---|
| AyuGramCore module and settings schema | Enabled by app presence; defaults from `AyuGramSettings.defaultSettings` | `5d0f9eaa` | Not run | Not run | Not run | Codable migration should be checked against older installs. |
| Persist AyuGram settings in Telegram preferences | Enabled | `eb5d9072`, `9b20b09b` | Not run | Not run | Not run | Account/shared-data refresh timing needs runtime confirmation. |
| AyuGram settings screen entry | Visible in peer info advanced settings | `ff2ff5b6` | Not run | Not run | Not run | Navigation placement may need UX polish on small screens. |
| Global ghost mode | `useGlobalGhostMode = true` | `5d0f9eaa`, `9b20b09b` | Not run | Not run | Not run | Per-account override interactions need two-account testing. |
| Gate automatic read history | Ghost global read policy defaults to enabled read suppression when configured | `6c45714b`, `9b20b09b` | Not run | Not run | Not run | Must verify no accidental read receipts are sent during chat open/scroll. |
| Manual Read Until action | Context menu visibility controlled by Ayu context menu policy | `c7bd2fd8` | Not run | Not run | Not run | Needs two-account confirmation that explicit read bypasses ghost gate only when selected. |
| Ghost state surface inventory | Documentation only | `361bedcc` | Not run | Not run | Not run | Inventory may become stale as upstream Telegram-iOS changes. |
| Gate story read receipts | Controlled by ghost settings | `db19ec48` | Not run | Not run | Not run | Story surfaces are broad and need full runtime smoke. |
| Send without sound in ghost | Controlled by ghost settings | `80488a58` | Not run | Not run | Not run | Must verify scheduled/quick-reply paths inherit intended send options. |
| Suppress upload progress activities | Controlled by ghost settings | `df9faf97` | Not run | Not run | Not run | Upload progress has multiple media paths; large media should be tested. |
| Gate online presence packets | Controlled by ghost policy | `577565b4` | Not run | Not run | Not run | Presence behavior is network-visible and requires two-account testing. |
| Anti-recall history models | `saveDeletedMessages = true`, `saveMessagesHistory = true` | `61a93f2c` | Not run | Not run | Not run | Local storage size and pruning policy need longer-run testing. |
| Preserve edited-message history | `saveMessagesHistory = true` | `47f69e88` | Not run | Not run | Not run | Media/entity edits need runtime inspection beyond text snapshots. |
| Capture deleted messages | `saveDeletedMessages = true` | `c63e0cde` | Not run | Not run | Not run | Bulk delete and topic-scoped delete paths need coverage. |
| Edited/deleted history UI | Enabled when history features are enabled | `dae686b7` | Not run | Not run | Not run | Empty states, large histories, and search need simulator QA. |
| AyuGram message context menu builder | Controlled by individual visibility settings | `da495fa3` | Not run | Not run | Not run | Menu ordering and icon availability need visual QA. |
| Message details screen | `showMessageDetailsInContextMenu = visible` | `1b5368ad`, `bf3f7efc` | Not run | Not run | Not run | Streamer-mode redaction should be visually checked before demos. |
| Filter models and matching | `filtersEnabled = false`, `filtersEnabledInChats = true` | `80468abf` | Not run | Not run | Not run | Regex compatibility with AyuGram Desktop edge cases needs fixture expansion. |
| Filter storage and UI | Filter list available; filtering disabled by default | `80468abf` | Not run | Not run | Not run | Import/export and malformed pattern UX need runtime QA. |
| Apply filters to chat history | `filtersEnabled = false` | `927886d9` | Not run | Not run | Not run | History diffing can be sensitive; test with unread anchors and search. |
| Display privacy toggles | Defaults vary by setting; premium hiding defaults off | `66966f92`, `e58fe548` | Not run | Not run | Not run | Local-only hiding must not imply server-side capability changes. |
| Chat appearance controls | `messageBubbleRadius = 16`, `avatarCorners = 23`, bottom info icons enabled | `66966f92`, `fd9d2158` | Not run | Not run | Not run | Bubble/tail/avatar rendering needs screenshot comparison on multiple themes. |
| Hide ads and stories | `disableAds = true`, `disableStories = false` | `46e3f1be` | Not run | Not run | Not run | Sponsored/story entry points are spread across UI modules. |
| Hide premium statuses and notification/chat-list controls | Defaults vary; premium status hiding off | `e58fe548` | Not run | Not run | Not run | Badge and counter state should be checked after push notifications. |
| Composer button controls | Defaults mostly visible | `8fd7cce5` | Not run | Not run | Not run | Input panel layouts need small-device and orientation QA. |
| Drawer/tray controls | Ghost tray enabled; streamer tray disabled | `8fd7cce5` | Not run | Not run | Not run | iOS drawer differs from Desktop; expected mapping needs UX review. |
| Translation providers | `translationProvider = telegram` | `2a2362d8` | Not run | Not run | Not run | Non-Telegram provider behavior requires network and privacy review. |
| WebView Android user-agent spoof | `spoofWebviewAsAndroid = false`; height/width increases false | `7a7fe5d5` | Not run | Not run | Not run | Must verify WebApps still work and no Telegram API platform spoofing occurs. |
| Streamer Mode | `streamerModeEnabled = false` | `bf3f7efc` | Not run | Not run | Not run | Current slice redacts stable presentation surfaces; deep chat bubbles still need follow-up. |
| Message Shot | `showMessageShot = true`; background/header/colorful replies/spoiler reveal enabled, date/reactions disabled | `f09cac9a` | Not run | Not run | Not run | First slice is text-rendered image, not live bubble capture; visual and share-sheet QA required. |

## Task 24 Update Rules

When Task 24 runs, update each tested column with one of:

- `Pass (date / environment)`
- `Fail (issue link or note)`
- `Partial (scope)`
- `Not applicable`

Keep `residual risk` focused on what remains after the latest verification, not on already-fixed issues.
