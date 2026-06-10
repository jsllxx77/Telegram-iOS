import Foundation
import Postbox

final class AyuGramDeletedMessageAttribute: MessageAttribute {
    let originalNamespace: Int32
    let originalId: Int32
    let threadId: Int64?
    let createdAt: Int32

    init(originalNamespace: Int32, originalId: Int32, threadId: Int64?, createdAt: Int32) {
        self.originalNamespace = originalNamespace
        self.originalId = originalId
        self.threadId = threadId
        self.createdAt = createdAt
    }

    init(decoder: PostboxDecoder) {
        self.originalNamespace = decoder.decodeInt32ForKey("n", orElse: 0)
        self.originalId = decoder.decodeInt32ForKey("i", orElse: 0)
        self.threadId = decoder.decodeOptionalInt64ForKey("t")
        self.createdAt = decoder.decodeInt32ForKey("c", orElse: 0)
    }

    func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.originalNamespace, forKey: "n")
        encoder.encodeInt32(self.originalId, forKey: "i")
        if let threadId = self.threadId {
            encoder.encodeInt64(threadId, forKey: "t")
        }
        encoder.encodeInt32(self.createdAt, forKey: "c")
    }
}
