import Foundation

private let ayuGramDeletedBubbleLocalIdBase: UInt64 = 1_000_000_000
private let ayuGramDeletedBubbleLocalIdRange: UInt64 = 900_000_000
private let ayuGramDeletedBubbleStableIdBase: UInt64 = 0x7000_0000
private let ayuGramDeletedBubbleStableIdRange: UInt64 = 0x0fff_ffff

public func ayuGramDeletedBubbleLocalMessageId(_ snapshot: AyuGramMessageSnapshot) -> Int32 {
    let value = ayuGramDeletedBubbleLocalIdBase + ayuGramDeletedBubbleHash(snapshot) % ayuGramDeletedBubbleLocalIdRange
    return -Int32(value)
}

public func ayuGramDeletedBubbleStableId(_ snapshot: AyuGramMessageSnapshot) -> UInt32 {
    let value = ayuGramDeletedBubbleStableIdBase + ayuGramDeletedBubbleHash(snapshot) % ayuGramDeletedBubbleStableIdRange
    return UInt32(value)
}

public func ayuGramDeletedBubbleDisplayText(
    snapshot: AyuGramMessageSnapshot,
    deletedMark: String,
    fallbackDeletedMark: String
) -> String {
    let marker = ayuGramNonEmptyTrimmedString(deletedMark) ?? ayuGramNonEmptyTrimmedString(fallbackDeletedMark) ?? "Deleted"
    var lines: [String] = [marker]

    if let text = ayuGramNonEmptyTrimmedString(snapshot.text) {
        lines.append(text)
    }

    if let mediaSummary = ayuGramNonEmptyTrimmedString(snapshot.mediaSummary) {
        if mediaSummary.hasPrefix("[") && mediaSummary.hasSuffix("]") {
            lines.append(mediaSummary)
        } else {
            lines.append("[\(mediaSummary)]")
        }
    }

    return lines.joined(separator: "\n")
}

private func ayuGramNonEmptyTrimmedString(_ value: String?) -> String? {
    guard let value = value else {
        return nil
    }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

private func ayuGramDeletedBubbleHash(_ snapshot: AyuGramMessageSnapshot) -> UInt64 {
    var hash: UInt64 = 0xcbf29ce484222325
    ayuGramDeletedBubbleHashCombine(&hash, UInt64(bitPattern: snapshot.accountPeerId))
    ayuGramDeletedBubbleHashCombine(&hash, UInt64(bitPattern: snapshot.peerId))
    ayuGramDeletedBubbleHashCombine(&hash, UInt64(bitPattern: snapshot.threadId ?? 0))
    ayuGramDeletedBubbleHashCombine(&hash, UInt64(UInt32(bitPattern: snapshot.messageNamespace)))
    ayuGramDeletedBubbleHashCombine(&hash, UInt64(UInt32(bitPattern: snapshot.messageId)))
    ayuGramDeletedBubbleHashCombine(&hash, UInt64(bitPattern: snapshot.stableId ?? 0))
    return hash
}

private func ayuGramDeletedBubbleHashCombine(_ hash: inout UInt64, _ value: UInt64) {
    var value = value
    for _ in 0 ..< 8 {
        hash ^= value & 0xff
        hash = hash &* 0x100000001b3
        value >>= 8
    }
}
