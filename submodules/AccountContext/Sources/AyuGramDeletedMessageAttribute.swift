import Foundation
import Postbox

public final class AyuGramDeletedMessageAttribute: MessageAttribute {
    public let originalNamespace: Int32
    public let originalId: Int32
    public let threadId: Int64?
    public let createdAt: Int32
    public let mediaKind: String?
    public let mediaMimeType: String?
    public let mediaFileName: String?
    public let mediaDuration: Double?
    public let mediaDimensions: String?
    public let mediaPreviewResourceId: String?
    public let mediaPreviewResourceRole: String?
    public let mediaPreviewPath: String?
    public let mediaPrimaryResourceId: String?
    public let mediaPrimaryPath: String?
    public let mediaThumbnailResourceId: String?
    public let mediaThumbnailPath: String?

    public init(
        originalNamespace: Int32,
        originalId: Int32,
        threadId: Int64?,
        createdAt: Int32,
        mediaKind: String? = nil,
        mediaMimeType: String? = nil,
        mediaFileName: String? = nil,
        mediaDuration: Double? = nil,
        mediaDimensions: String? = nil,
        mediaPreviewResourceId: String? = nil,
        mediaPreviewResourceRole: String? = nil,
        mediaPreviewPath: String? = nil,
        mediaPrimaryResourceId: String? = nil,
        mediaPrimaryPath: String? = nil,
        mediaThumbnailResourceId: String? = nil,
        mediaThumbnailPath: String? = nil
    ) {
        self.originalNamespace = originalNamespace
        self.originalId = originalId
        self.threadId = threadId
        self.createdAt = createdAt
        self.mediaKind = mediaKind
        self.mediaMimeType = mediaMimeType
        self.mediaFileName = mediaFileName
        self.mediaDuration = mediaDuration
        self.mediaDimensions = mediaDimensions
        self.mediaPreviewResourceId = mediaPreviewResourceId
        self.mediaPreviewResourceRole = mediaPreviewResourceRole
        self.mediaPreviewPath = mediaPreviewPath
        self.mediaPrimaryResourceId = mediaPrimaryResourceId
        self.mediaPrimaryPath = mediaPrimaryPath
        self.mediaThumbnailResourceId = mediaThumbnailResourceId
        self.mediaThumbnailPath = mediaThumbnailPath
    }

    public init(decoder: PostboxDecoder) {
        self.originalNamespace = decoder.decodeInt32ForKey("n", orElse: 0)
        self.originalId = decoder.decodeInt32ForKey("i", orElse: 0)
        self.threadId = decoder.decodeOptionalInt64ForKey("t")
        self.createdAt = decoder.decodeInt32ForKey("c", orElse: 0)
        self.mediaKind = decoder.decodeOptionalStringForKey("mk")
        self.mediaMimeType = decoder.decodeOptionalStringForKey("mm")
        self.mediaFileName = decoder.decodeOptionalStringForKey("mf")
        self.mediaDuration = decoder.decodeOptionalDoubleForKey("md")
        self.mediaDimensions = decoder.decodeOptionalStringForKey("ms")
        self.mediaPreviewResourceId = decoder.decodeOptionalStringForKey("pr")
        self.mediaPreviewResourceRole = decoder.decodeOptionalStringForKey("pt")
        self.mediaPreviewPath = decoder.decodeOptionalStringForKey("pp")
        self.mediaPrimaryResourceId = decoder.decodeOptionalStringForKey("ppr")
        self.mediaPrimaryPath = decoder.decodeOptionalStringForKey("ppp")
        self.mediaThumbnailResourceId = decoder.decodeOptionalStringForKey("ptr")
        self.mediaThumbnailPath = decoder.decodeOptionalStringForKey("ptp")
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.originalNamespace, forKey: "n")
        encoder.encodeInt32(self.originalId, forKey: "i")
        if let threadId = self.threadId {
            encoder.encodeInt64(threadId, forKey: "t")
        }
        encoder.encodeInt32(self.createdAt, forKey: "c")
        if let mediaKind = self.mediaKind {
            encoder.encodeString(mediaKind, forKey: "mk")
        }
        if let mediaMimeType = self.mediaMimeType {
            encoder.encodeString(mediaMimeType, forKey: "mm")
        }
        if let mediaFileName = self.mediaFileName {
            encoder.encodeString(mediaFileName, forKey: "mf")
        }
        if let mediaDuration = self.mediaDuration {
            encoder.encodeDouble(mediaDuration, forKey: "md")
        }
        if let mediaDimensions = self.mediaDimensions {
            encoder.encodeString(mediaDimensions, forKey: "ms")
        }
        if let mediaPreviewResourceId = self.mediaPreviewResourceId {
            encoder.encodeString(mediaPreviewResourceId, forKey: "pr")
        }
        if let mediaPreviewResourceRole = self.mediaPreviewResourceRole {
            encoder.encodeString(mediaPreviewResourceRole, forKey: "pt")
        }
        if let mediaPreviewPath = self.mediaPreviewPath {
            encoder.encodeString(mediaPreviewPath, forKey: "pp")
        }
        if let mediaPrimaryResourceId = self.mediaPrimaryResourceId {
            encoder.encodeString(mediaPrimaryResourceId, forKey: "ppr")
        }
        if let mediaPrimaryPath = self.mediaPrimaryPath {
            encoder.encodeString(mediaPrimaryPath, forKey: "ppp")
        }
        if let mediaThumbnailResourceId = self.mediaThumbnailResourceId {
            encoder.encodeString(mediaThumbnailResourceId, forKey: "ptr")
        }
        if let mediaThumbnailPath = self.mediaThumbnailPath {
            encoder.encodeString(mediaThumbnailPath, forKey: "ptp")
        }
    }
}

public func ayuGramMessageIsDeletedBubble(_ message: Message) -> Bool {
    return message.attributes.contains(where: { $0 is AyuGramDeletedMessageAttribute })
}
