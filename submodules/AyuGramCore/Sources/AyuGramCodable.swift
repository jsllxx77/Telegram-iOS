extension KeyedDecodingContainer {
    func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key, fallback: T) -> T {
        return (try? self.decodeIfPresent(type, forKey: key)) ?? fallback
    }

    func decodeRawValueEnum<T: RawRepresentable>(_ type: T.Type, forKey key: Key, fallback: T) -> T where T.RawValue == Int32 {
        if let rawValue = try? self.decodeIfPresent(Int32.self, forKey: key), let value = T(rawValue: rawValue) {
            return value
        }
        return fallback
    }

    func decodeRawValueEnum<T: RawRepresentable>(_ type: T.Type, forKey key: Key, fallback: T) -> T where T.RawValue == String {
        if let rawValue = try? self.decodeIfPresent(String.self, forKey: key), let value = T(rawValue: rawValue) {
            return value
        }
        return fallback
    }
}
