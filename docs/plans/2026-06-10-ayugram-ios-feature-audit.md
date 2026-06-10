# AyuGram iOS Feature Audit - 2026-06-10

This audit records the current iOS port behavior after the first successful sideloaded device build. It focuses on user-reported settings that looked ineffective and on AyuGram settings that are still only partially wired.

## User-Reported Findings

### Save Deleted Messages

Status: partially implemented, but not inline.

- The setting is persisted through `AyuGramSettings.saveDeletedMessages`.
- `AccountContext` maps it into `AccountMessageHistoryPolicy` and passes it into TelegramCore state replay.
- TelegramCore captures snapshots before delete operations in `AccountStateManagementUtils.swift` for global-id deletes, message-id deletes, and min-available-message range deletes.
- The saved records are shown in `AyuGramDeletedMessagesController`, opened from the AyuGram message context-menu item `Deleted Messages`.

Important behavior gap: deleted messages are not reinserted into the chat bubble list. The current port stores future deletion snapshots in a local history view. It cannot show deletions that happened before the setting was enabled or before the original message existed in the local Postbox cache.

### Contacts / Calls Drawer Switches

Status: wired to iOS root tabs and settings items.

- `ApplicationContext` watches `ApplicationSpecificSharedDataKeys.ayuGramSettings` and recalculates `(showCallsTab, showContactsTab)`.
- `TelegramRootController.addRootControllers` and `updateRootControllers` include or remove Contacts/Calls controllers according to those values.
- `PeerInfoSettingsItems` also uses `showCallsInDrawer` for the settings-list calls entry.

Runtime note: the provided screenshot shows `Contacts` still enabled and `Calls` disabled. If Contacts remains visible after disabling the switch, retest with the switch visibly off, then leave and re-enter the root tab surface. The code path is present, but device verification is still required because this workspace cannot run iOS UI.

## Current Implementation Matrix

| Area | Setting / Feature | Current status | Notes |
|---|---|---|---|
| Localization | AyuGram settings page | Implemented in this pass | Uses `PresentationStrings.baseLanguageCode`; Chinese is selected for `zh`, `zh-*`, `zh_*`. |
| Localization | AyuGram context menu and history/detail screens | Implemented in this pass | Covers deleted/edit history, message details, message action labels, and history field labels. |
| Message history | Save deleted messages | Partial | Captures future delete snapshots and shows them in a history screen; no inline deleted bubbles. |
| Message history | Save edit history | Partial | Captures previous incoming text when edit update arrives; accessed via context menu only when edited history exists. |
| Message history | Save for bots | Wired | Used by TelegramCore snapshot policy, but not exposed in the current settings UI. |
| Message history | Semi-transparent deleted messages | UI-only / blocked | No inline deleted-message rendering exists yet, so the visual opacity setting has no consumer. |
| Drawer / tabs | Contacts | Wired | Controls root Contacts tab through root tab signal. |
| Drawer / tabs | Calls | Wired | Controls root Calls tab and settings-list call entry. |
| Drawer / settings | My Profile, Bots, Saved Messages | Wired | Consumed in peer info/settings items. |
| Drawer / compose | New Group, New Channel | Wired | Consumed in compose controller. |
| Drawer toggles | Local read, server read, night mode, ghost, streamer drawer/tray toggles | Not implemented | Settings exist and are copied into context, but no drawer/tray UI surface consumes them yet. |
| Composer | Attach, commands, emoji, microphone, auto-delete, gift, AI editor, attach/emoji popup | Mostly wired | Consumed by chat input/context code paths; needs device layout QA. |
| Chat controls | Hide fast share, show message seconds, hide similar channels, disable open-link warning, ads/stories, premium badges, notification counters/badge, all-chats folder | Wired or partially wired | Many are consumed by chat/chat-list paths; visual QA still needed. |
| Appearance | Bubble radius, avatar corners, single radius, remove tail, bottom info icons | Partially wired | Some rendering hooks exist from earlier tasks, but require screenshot QA across themes. |
| Filters | Filter engine/list/edit and chat filtering | Partial | Regex hiding is implemented; blocked-user integration and filtered-message reveal/marker remain open. |
| Context menu | Details, user messages, repeat, read until, hide locally, add filter | Partial | Core actions exist; some placeholders remain for shadow-ban/admin-style follow-ups. |
| Message Shot | Text-rendered image | Partial | First slice is not a live Telegram bubble capture. |
| Translation | Telegram/Google/Yandex/native provider selector | Partial | Provider setting is wired; non-Telegram providers need network/privacy device testing. |
| WebView | Android spoof, height/width increase | Partial | Context values exist and earlier hooks were added; WebApp runtime QA still required. |
| Streamer Mode | Local privacy mode | Partial | Redacts several AyuGram surfaces; deep chat bubble redaction remains follow-up. |
| Crash reporting | Toggle | UI-only / not audited | Needs a concrete crash-reporting backend gate before claiming effectiveness. |
| Local Premium | Setting model only | Not exposed / not implemented | Must remain local UI-only and must not bypass server-side Telegram Premium. |

## Next Fix Targets

1. Add an obvious, localized entry for `Deleted Messages` outside long-press context menus, or document the long-press access pattern in release notes.
2. Implement inline deleted-message rendering before enabling `Semi-Transparent Deleted Messages` as a real setting.
3. Add real consumers for drawer/tray toggles: local/server read, night mode, ghost mode, streamer mode.
4. Run a device test matrix for Contacts/Calls tab removal because local Linux cannot execute the iOS UI.
