import Foundation

public struct AyuGramMessageSnapshot: Codable, Equatable {
    public var accountPeerId: Int64
    public var peerId: Int64
    public var threadId: Int64?
    public var messageNamespace: Int32
    public var messageId: Int32
    public var stableId: Int64?
    public var authorPeerId: Int64?
    public var timestamp: Int32
    public var editTimestamp: Int32?
    public var text: String
    public var entitiesData: Data?
    public var views: Int32?
    public var forwardInfoData: Data?
    public var mediaSummary: String?
    public var createdAt: Int32

    private enum CodingKeys: String, CodingKey {
        case accountPeerId
        case peerId
        case threadId
        case messageNamespace
        case messageId
        case stableId
        case authorPeerId
        case timestamp
        case editTimestamp
        case text
        case entitiesData
        case views
        case forwardInfoData
        case mediaSummary
        case createdAt
    }

    public init(
        accountPeerId: Int64,
        peerId: Int64,
        threadId: Int64?,
        messageNamespace: Int32,
        messageId: Int32,
        stableId: Int64?,
        authorPeerId: Int64?,
        timestamp: Int32,
        editTimestamp: Int32?,
        text: String,
        entitiesData: Data?,
        views: Int32?,
        forwardInfoData: Data?,
        mediaSummary: String?,
        createdAt: Int32
    ) {
        self.accountPeerId = accountPeerId
        self.peerId = peerId
        self.threadId = threadId
        self.messageNamespace = messageNamespace
        self.messageId = messageId
        self.stableId = stableId
        self.authorPeerId = authorPeerId
        self.timestamp = timestamp
        self.editTimestamp = editTimestamp
        self.text = text
        self.entitiesData = entitiesData
        self.views = views
        self.forwardInfoData = forwardInfoData
        self.mediaSummary = mediaSummary
        self.createdAt = createdAt
    }

    public func hasMessageIdentity(
        accountPeerId: Int64,
        peerId: Int64,
        messageNamespace: Int32,
        messageId: Int32
    ) -> Bool {
        return self.accountPeerId == accountPeerId
            && self.peerId == peerId
            && self.messageNamespace == messageNamespace
            && self.messageId == messageId
    }

    public func hasSameMessageIdentity(as other: AyuGramMessageSnapshot) -> Bool {
        return self.hasMessageIdentity(
            accountPeerId: other.accountPeerId,
            peerId: other.peerId,
            messageNamespace: other.messageNamespace,
            messageId: other.messageId
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.accountPeerId = container.decodeIfPresent(Int64.self, forKey: .accountPeerId, fallback: 0)
        self.peerId = container.decodeIfPresent(Int64.self, forKey: .peerId, fallback: 0)
        self.threadId = try? container.decodeIfPresent(Int64.self, forKey: .threadId)
        self.messageNamespace = container.decodeIfPresent(Int32.self, forKey: .messageNamespace, fallback: 0)
        self.messageId = container.decodeIfPresent(Int32.self, forKey: .messageId, fallback: 0)
        self.stableId = try? container.decodeIfPresent(Int64.self, forKey: .stableId)
        self.authorPeerId = try? container.decodeIfPresent(Int64.self, forKey: .authorPeerId)
        self.timestamp = container.decodeIfPresent(Int32.self, forKey: .timestamp, fallback: 0)
        self.editTimestamp = try? container.decodeIfPresent(Int32.self, forKey: .editTimestamp)
        self.text = container.decodeIfPresent(String.self, forKey: .text, fallback: "")
        self.entitiesData = try? container.decodeIfPresent(Data.self, forKey: .entitiesData)
        self.views = try? container.decodeIfPresent(Int32.self, forKey: .views)
        self.forwardInfoData = try? container.decodeIfPresent(Data.self, forKey: .forwardInfoData)
        self.mediaSummary = try? container.decodeIfPresent(String.self, forKey: .mediaSummary)
        self.createdAt = container.decodeIfPresent(Int32.self, forKey: .createdAt, fallback: self.timestamp)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.accountPeerId, forKey: .accountPeerId)
        try container.encode(self.peerId, forKey: .peerId)
        try container.encodeIfPresent(self.threadId, forKey: .threadId)
        try container.encode(self.messageNamespace, forKey: .messageNamespace)
        try container.encode(self.messageId, forKey: .messageId)
        try container.encodeIfPresent(self.stableId, forKey: .stableId)
        try container.encodeIfPresent(self.authorPeerId, forKey: .authorPeerId)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encodeIfPresent(self.editTimestamp, forKey: .editTimestamp)
        try container.encode(self.text, forKey: .text)
        try container.encodeIfPresent(self.entitiesData, forKey: .entitiesData)
        try container.encodeIfPresent(self.views, forKey: .views)
        try container.encodeIfPresent(self.forwardInfoData, forKey: .forwardInfoData)
        try container.encodeIfPresent(self.mediaSummary, forKey: .mediaSummary)
        try container.encode(self.createdAt, forKey: .createdAt)
    }
}
