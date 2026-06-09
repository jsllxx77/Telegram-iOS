import Foundation

public struct AyuGramFilter: Codable, Equatable, Identifiable {
    public var id: String
    public var text: String
    public var enabled: Bool
    public var reversed: Bool
    public var caseInsensitive: Bool
    public var dialogId: Int64?
    public var exclusions: Set<Int64>

    private enum CodingKeys: String, CodingKey {
        case id
        case text
        case enabled
        case reversed
        case caseInsensitive
        case dialogId
        case exclusions
    }

    public init(
        id: String = UUID().uuidString,
        text: String,
        enabled: Bool = true,
        reversed: Bool = false,
        caseInsensitive: Bool = true,
        dialogId: Int64? = nil,
        exclusions: Set<Int64> = Set()
    ) {
        self.id = id
        self.text = text
        self.enabled = enabled
        self.reversed = reversed
        self.caseInsensitive = caseInsensitive
        self.dialogId = dialogId
        self.exclusions = exclusions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = container.decodeIfPresent(String.self, forKey: .id, fallback: UUID().uuidString)
        self.text = container.decodeIfPresent(String.self, forKey: .text, fallback: "")
        self.enabled = container.decodeIfPresent(Bool.self, forKey: .enabled, fallback: true)
        self.reversed = container.decodeIfPresent(Bool.self, forKey: .reversed, fallback: false)
        self.caseInsensitive = container.decodeIfPresent(Bool.self, forKey: .caseInsensitive, fallback: true)
        self.dialogId = try? container.decodeIfPresent(Int64.self, forKey: .dialogId)
        self.exclusions = container.decodeIfPresent(Set<Int64>.self, forKey: .exclusions, fallback: Set())
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.text, forKey: .text)
        try container.encode(self.enabled, forKey: .enabled)
        try container.encode(self.reversed, forKey: .reversed)
        try container.encode(self.caseInsensitive, forKey: .caseInsensitive)
        try container.encodeIfPresent(self.dialogId, forKey: .dialogId)
        try container.encode(self.exclusions, forKey: .exclusions)
    }
}

public struct AyuGramFilterStore: Codable, Equatable {
    public private(set) var filters: [AyuGramFilter]

    public static let empty = AyuGramFilterStore()

    private enum CodingKeys: String, CodingKey {
        case filters
    }

    public init(filters: [AyuGramFilter] = []) {
        self.filters = filters
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.filters = container.decodeIfPresent([AyuGramFilter].self, forKey: .filters, fallback: [])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.filters, forKey: .filters)
    }

    public mutating func upsert(_ filter: AyuGramFilter) {
        if let index = self.filters.firstIndex(where: { $0.id == filter.id }) {
            self.filters[index] = filter
        } else {
            self.filters.append(filter)
        }
        self.filters.sort(by: Self.areFiltersInDisplayOrder)
    }

    @discardableResult
    public mutating func delete(id: String) -> Bool {
        guard let index = self.filters.firstIndex(where: { $0.id == id }) else {
            return false
        }
        self.filters.remove(at: index)
        return true
    }

    public mutating func replaceAll(_ filters: [AyuGramFilter]) {
        var seenIds = Set<String>()
        var normalized: [AyuGramFilter] = []
        for filter in filters {
            var filter = filter
            if filter.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || seenIds.contains(filter.id) {
                filter.id = UUID().uuidString
            }
            seenIds.insert(filter.id)
            normalized.append(filter)
        }
        self.filters = normalized.sorted(by: Self.areFiltersInDisplayOrder)
    }

    public func exportedJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    public static func imported(from data: Data) throws -> AyuGramFilterStore {
        let decoder = JSONDecoder()
        var store = try decoder.decode(AyuGramFilterStore.self, from: data)
        store.replaceAll(store.filters)
        return store
    }

    private static func areFiltersInDisplayOrder(_ lhs: AyuGramFilter, _ rhs: AyuGramFilter) -> Bool {
        if lhs.dialogId != rhs.dialogId {
            switch (lhs.dialogId, rhs.dialogId) {
            case (.none, .some):
                return true
            case (.some, .none):
                return false
            case let (.some(lhsValue), .some(rhsValue)):
                if lhsValue != rhsValue {
                    return lhsValue < rhsValue
                }
            case (.none, .none):
                break
            }
        }
        if lhs.text != rhs.text {
            return lhs.text.localizedCaseInsensitiveCompare(rhs.text) == .orderedAscending
        }
        return lhs.id < rhs.id
    }
}
