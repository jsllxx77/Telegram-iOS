import Foundation
import UIKit
import AyuGramCore
import Display
import Postbox
import TelegramCore
import TelegramPresentationData

public enum AyuGramMessageShotRenderer {
    public static func render(
        message: Message,
        presentationData: PresentationData,
        settings: AyuGramMessageShotSettings,
        streamerPolicy: AyuGramStreamerModePolicy
    ) -> UIImage {
        let maxWidth: CGFloat = 760.0
        let horizontalInset: CGFloat = 32.0
        let verticalInset: CGFloat = 28.0
        let bubbleInset: CGFloat = 22.0
        let contentWidth = maxWidth - horizontalInset * 2.0 - bubbleInset * 2.0

        let titleFont = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        let metadataFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        let bodyFont = UIFont.systemFont(ofSize: 24.0, weight: .regular)
        let footerFont = UIFont.systemFont(ofSize: 13.0, weight: .medium)

        let theme = presentationData.theme
        let canvasColor = settings.showBackground ? theme.list.plainBackgroundColor : .clear
        let bubbleColor = theme.list.itemBlocksBackgroundColor
        let primaryColor = theme.list.itemPrimaryTextColor
        let secondaryColor = theme.list.itemSecondaryTextColor
        let accentColor = settings.embeddedThemeType == -1 ? theme.list.itemAccentColor : UIColor(rgb: UInt32(bitPattern: settings.embeddedThemeAccentColor))

        let peerTitle = AyuGramMessageShotRenderer.peerTitle(message: message, policy: streamerPolicy)
        let authorTitle = AyuGramMessageShotRenderer.authorTitle(message: message, policy: streamerPolicy)
        let bodyText = AyuGramMessageShotRenderer.bodyText(message: message, settings: settings, policy: streamerPolicy)
        let mediaSummary = AyuGramMessageShotRenderer.mediaSummary(message: message)
        let reactionCount = AyuGramMessageShotRenderer.reactionCount(message: message)

        var blocks: [(String, UIFont, UIColor)] = []
        if settings.showHeaderDecorations {
            blocks.append((peerTitle, titleFont, primaryColor))
            if !authorTitle.isEmpty && authorTitle != peerTitle {
                blocks.append((authorTitle, metadataFont, secondaryColor))
            }
        }
        if settings.showDate {
            blocks.append((AyuGramMessageShotRenderer.dateString(message.timestamp), metadataFont, secondaryColor))
        }
        blocks.append((bodyText, bodyFont, primaryColor))
        if !mediaSummary.isEmpty {
            blocks.append((mediaSummary, footerFont, secondaryColor))
        }
        if settings.showReactions && reactionCount > 0 {
            blocks.append(("Reactions: \(reactionCount)", footerFont, accentColor))
        }
        if settings.embeddedThemeType != -1 || !settings.cloudThemeTitle.isEmpty {
            let themeTitle = settings.cloudThemeTitle.isEmpty ? "Embedded theme" : settings.cloudThemeTitle
            blocks.append((themeTitle, footerFont, accentColor))
        }

        let paragraphSpacing: CGFloat = 10.0
        var totalTextHeight: CGFloat = 0.0
        var measuredBlocks: [(String, UIFont, UIColor, CGRect)] = []
        for (text, font, color) in blocks {
            let rect = (text as NSString).boundingRect(
                with: CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).integral
            measuredBlocks.append((text, font, color, rect))
            totalTextHeight += rect.height
        }
        totalTextHeight += paragraphSpacing * CGFloat(max(0, measuredBlocks.count - 1))

        let bubbleHeight = totalTextHeight + bubbleInset * 2.0
        let imageSize = CGSize(width: maxWidth, height: bubbleHeight + verticalInset * 2.0)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = settings.showBackground

        return UIGraphicsImageRenderer(size: imageSize, format: format).image { context in
            canvasColor.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: imageSize))

            let bubbleRect = CGRect(
                x: horizontalInset,
                y: verticalInset,
                width: imageSize.width - horizontalInset * 2.0,
                height: bubbleHeight
            )
            bubbleColor.setFill()
            UIBezierPath(roundedRect: bubbleRect, cornerRadius: 18.0).fill()

            if settings.showColorfulReplies {
                accentColor.setFill()
                UIBezierPath(roundedRect: CGRect(x: bubbleRect.minX, y: bubbleRect.minY, width: 5.0, height: bubbleRect.height), cornerRadius: 2.5).fill()
            }

            var y = bubbleRect.minY + bubbleInset
            for (text, font, color, rect) in measuredBlocks {
                (text as NSString).draw(
                    with: CGRect(x: bubbleRect.minX + bubbleInset, y: y, width: contentWidth, height: rect.height),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [
                        .font: font,
                        .foregroundColor: color
                    ],
                    context: nil
                )
                y += rect.height + paragraphSpacing
            }
        }
    }

    private static func peerTitle(message: Message, policy: AyuGramStreamerModePolicy) -> String {
        let title = message.peers[message.id.peerId].flatMap(EnginePeer.init)?.compactDisplayTitle ?? "Chat"
        return AyuGramStreamerRedaction.peerTitle(title, policy: policy)
    }

    private static func authorTitle(message: Message, policy: AyuGramStreamerModePolicy) -> String {
        let title = message.author.flatMap(EnginePeer.init)?.compactDisplayTitle ?? ""
        return AyuGramStreamerRedaction.userTitle(title, policy: policy)
    }

    private static func bodyText(message: Message, settings: AyuGramMessageShotSettings, policy: AyuGramStreamerModePolicy) -> String {
        var text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            text = "[No text]"
        }
        if !settings.revealSpoilers {
            text = AyuGramMessageShotRenderer.hideSpoilers(text: text, attributes: message.attributes)
        }
        return AyuGramStreamerRedaction.messagePreview(text, policy: policy)
    }

    private static func hideSpoilers(text: String, attributes: [MessageAttribute]) -> String {
        var spoilerRanges: [Range<String.Index>] = []
        for attribute in attributes {
            guard let textEntities = attribute as? TextEntitiesMessageAttribute else {
                continue
            }
            for entity in textEntities.entities {
                let nsRange = NSRange(location: entity.range.lowerBound, length: entity.range.count)
                if case .Spoiler = entity.type, let range = Range(nsRange, in: text) {
                    spoilerRanges.append(range)
                }
            }
        }
        guard !spoilerRanges.isEmpty else {
            return text
        }
        var result = text
        for range in spoilerRanges.sorted(by: { $0.lowerBound > $1.lowerBound }) {
            result.replaceSubrange(range, with: "Spoiler")
        }
        return result
    }

    private static func mediaSummary(message: Message) -> String {
        guard !message.media.isEmpty else {
            return ""
        }
        let count = message.media.count
        return count == 1 ? "Media attachment" : "\(count) media attachments"
    }

    private static func reactionCount(message: Message) -> Int32 {
        guard let attribute = message._asMessage().reactionsAttribute else {
            return 0
        }
        return attribute.reactions.reduce(0, { partialResult, reaction in
            return partialResult + reaction.count
        })
    }

    private static func dateString(_ timestamp: Int32) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
