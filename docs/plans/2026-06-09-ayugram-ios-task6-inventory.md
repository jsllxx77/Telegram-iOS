# AyuGram iOS Task 6 Ghost Surface Inventory

Date: 2026-06-09

## Story Reads

- UI thresholds call `environment.markAsSeen` from `StoryItemContentComponent.swift`; safe UI-only gate.
- `StoryChatContent.swift` forwards `markAsSeen` into `context.engine.messages.markStoryAsSeen`; network-visible gate.
- `TelegramEngine/Messages/Stories.swift` `_internal_markStoryAsSeen` queues `stories.readStories` and directly sends `stories.incrementStoryViews` for pinned stories; state-machine critical plus network request gate.
- `ManagedSynchronizeViewStoriesOperations.swift` sends queued `stories.readStories`; network request gate.

Implementation choice: gate at the Stories UI/content context before calling `markStoryAsSeen` so TelegramCore does not need an AyuGramCore dependency.

## Send Without Sound

- UI options such as `ChatSendMessageContextScreen.swift` and `ChatMessageDisplaySendMessageOptions.swift` only select silent-send mode.
- `ChatController.transformEnqueueMessages` adds `NotificationInfoMessageAttribute(flags: .muted)` for normal sends; state-machine critical.
- `ChatController.enqueueChatContextResult` and `OutgoingMessageWithChatContextResult.swift` cover inline/context result sends that bypass the normal transformer.
- `PendingMessageManager.swift` converts muted attributes into MTProto send flags; network request gate.

Implementation choice: set the muted message attribute in UI/state-machine send surfaces, not in PendingMessageManager.

## Upload Progress

- `PendingMessageManager.swift` derives upload activities for outgoing media; state-machine critical.
- `ManagedLocalInputActivities.swift` maps `PeerInputActivity.uploading*` to `messages.setTyping` upload actions; network request gate.
- Chat title and pending-message progress views are local UI only and should not be gated.

Implementation choice: gate outgoing uploading activities before `messages.setTyping`, while leaving actual media upload and local progress UI intact.

## Online/Offline Presence

- Most `presence` hits display other peers' status; safe UI-only or not applicable.
- `ManagedAccountPresence.swift` sends `account.updateStatus(offline: false)` and `account.updateStatus(offline: true)`; network request gate.

Implementation choice: gate status updates in the account presence manager, preserving local network/account state handling.
