import Foundation
import Postbox

public final class AyuGramDeletedMessageAttribute: MessageAttribute {
    public let originalNamespace: Int32
    public let originalId: Int32
    public let threadId: Int64?
    public let createdAt: Int32

    public init(originalNamespace: Int32, originalId: Int32, threadId: Int64?, createdAt: Int32) {
        self.originalNamespace = originalNamespace
        self.originalId = originalId
        self.threadId = threadId
        self.createdAt = createdAt
    }

    public init(decoder: PostboxDecoder) {
        self.originalNamespace = decoder.decodeInt32ForKey("n", orElse: 0)
        self.originalId = decoder.decodeInt32ForKey("i", orElse: 0)
        self.threadId = decoder.decodeOptionalInt64ForKey("t")
        self.createdAt = decoder.decodeInt32ForKey("c", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.originalNamespace, forKey: "n")
        encoder.encodeInt32(self.originalId, forKey: "i")
        if let threadId = self.threadId {
            encoder.encodeInt64(threadId, forKey: "t")
        }
        encoder.encodeInt32(self.createdAt, forKey: "c")
    }
}

public func ayuGramMessageIsDeletedBubble(_ message: Message) -> Bool {
    return message.attributes.contains(where: { $0 is AyuGramDeletedMessageAttribute })
}
