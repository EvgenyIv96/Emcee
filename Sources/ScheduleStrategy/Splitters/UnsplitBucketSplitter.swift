import Foundation
import QueueModels
import UniqueIdentifierGenerator

public struct UnsplitBucketSplitter: TestSplitter {
    public init() {}
    
    public func split(
        testEntryConfigurations: [TestEntryConfiguration],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[TestEntryConfiguration]] {
        return [testEntryConfigurations]
    }
}
