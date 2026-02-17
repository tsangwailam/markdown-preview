import Foundation

public struct CacheKey: Hashable, Sendable {
    public let path: String
    public let modificationTime: Date
    public let byteSize: Int64

    public init(path: String, modificationTime: Date, byteSize: Int64) {
        self.path = path
        self.modificationTime = modificationTime
        self.byteSize = byteSize
    }
}

public actor PreviewCache {
    private let capacity: Int
    private var entries: [CacheKey: String] = [:]
    private var usageOrder: [CacheKey] = []

    public init(capacity: Int = 32) {
        self.capacity = max(1, capacity)
    }

    public func value(for key: CacheKey) -> String? {
        guard let value = entries[key] else { return nil }
        touch(key)
        return value
    }

    public func store(_ value: String, for key: CacheKey) {
        entries[key] = value
        touch(key)

        if entries.count > capacity, let oldest = usageOrder.first {
            usageOrder.removeFirst()
            entries.removeValue(forKey: oldest)
        }
    }

    private func touch(_ key: CacheKey) {
        usageOrder.removeAll { $0 == key }
        usageOrder.append(key)
    }
}
