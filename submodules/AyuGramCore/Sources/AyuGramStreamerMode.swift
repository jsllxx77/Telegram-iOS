import Foundation

public struct AyuGramStreamerModePolicy: Equatable {
    public var isEnabled: Bool
    public var hidePeerTitles: Bool
    public var hideMessagePreviews: Bool
    public var redactSensitiveText: Bool

    public init(
        isEnabled: Bool,
        hidePeerTitles: Bool = true,
        hideMessagePreviews: Bool = true,
        redactSensitiveText: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.hidePeerTitles = hidePeerTitles
        self.hideMessagePreviews = hideMessagePreviews
        self.redactSensitiveText = redactSensitiveText
    }

    public static var disabled: AyuGramStreamerModePolicy {
        return AyuGramStreamerModePolicy(isEnabled: false)
    }
}

public enum AyuGramStreamerRedaction {
    public static let hiddenPeerTitle = "Hidden Chat"
    public static let hiddenUserTitle = "Hidden User"
    public static let hiddenMessagePreview = "[Hidden message]"
    public static let hiddenValue = "Hidden"

    public static func peerTitle(_ title: String, policy: AyuGramStreamerModePolicy) -> String {
        guard policy.isEnabled && policy.hidePeerTitles else {
            return title
        }
        return hiddenPeerTitle
    }

    public static func userTitle(_ title: String, policy: AyuGramStreamerModePolicy) -> String {
        guard policy.isEnabled && policy.hidePeerTitles else {
            return title
        }
        return hiddenUserTitle
    }

    public static func messagePreview(_ text: String, policy: AyuGramStreamerModePolicy) -> String {
        guard policy.isEnabled else {
            return text
        }
        if policy.hideMessagePreviews {
            return hiddenMessagePreview
        }
        return sensitiveText(text, policy: policy)
    }

    public static func sensitiveText(_ text: String, policy: AyuGramStreamerModePolicy) -> String {
        guard policy.isEnabled && policy.redactSensitiveText else {
            return text
        }

        var result = text
        let patterns = [
            "(?i)(https?://)?(t\\.me|telegram\\.me|telegram\\.dog)/[^\\s]+",
            "(?<![A-Za-z0-9_])@[A-Za-z0-9_]{3,32}",
            "\\+?[0-9][0-9\\s()\\-.]{6,}[0-9]",
            "\\b-?[0-9]{7,}\\b"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                continue
            }
            let range = NSRange(location: 0, length: (result as NSString).length)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: hiddenValue)
        }
        return result
    }
}
