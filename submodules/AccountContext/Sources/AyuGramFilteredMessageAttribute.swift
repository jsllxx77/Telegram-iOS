import Foundation
import Postbox

public final class AyuGramFilteredMessageAttribute: MessageAttribute {
    public let reason: String
    public let originalText: String

    public init(reason: String, originalText: String) {
        self.reason = reason
        self.originalText = originalText
    }

    public init(decoder: PostboxDecoder) {
        self.reason = decoder.decodeStringForKey("r", orElse: "filter")
        self.originalText = decoder.decodeStringForKey("t", orElse: "")
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeString(self.reason, forKey: "r")
        encoder.encodeString(self.originalText, forKey: "t")
    }
}

public func ayuGramFilteredMessageAttribute(_ message: Message) -> AyuGramFilteredMessageAttribute? {
    return message.attributes.first(where: { $0 is AyuGramFilteredMessageAttribute }) as? AyuGramFilteredMessageAttribute
}
