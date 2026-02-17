import XCTest
@testable import CoreMarkdownPreview

final class PreviewCacheTests: XCTestCase {
    func testEvictionByCapacity() async {
        let cache = PreviewCache(capacity: 1)
        let key1 = CacheKey(path: "/tmp/a.md", modificationTime: .distantPast, byteSize: 1)
        let key2 = CacheKey(path: "/tmp/b.md", modificationTime: .distantFuture, byteSize: 2)

        await cache.store("A", for: key1)
        await cache.store("B", for: key2)

        let a = await cache.value(for: key1)
        let b = await cache.value(for: key2)

        XCTAssertNil(a)
        XCTAssertEqual(b, "B")
    }
}
