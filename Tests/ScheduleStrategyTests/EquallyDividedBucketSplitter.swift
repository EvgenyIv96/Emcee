import Foundation
import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerTestHelpers
import ScheduleStrategy
import XCTest

final class EquallyDividedBucketSplitterTests: XCTestCase {
    let equallyDividedSplitter = EquallyDividedBucketSplitter()
    let testEntries = [
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod1"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod2"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod3"),
        TestEntryFixtures.testEntry(className: "class", methodName: "testMethod4")
    ]
    lazy var testEntryConfigurations = TestEntryConfigurationFixtures().add(testEntries: testEntries).testEntryConfigurations()
    
    func test_equally_divided_splitter__splits_to_buckets_with_equal_size() {
        let expected = testEntryConfigurations.splitToChunks(withSize: 1)
        
        let actual = equallyDividedSplitter.split(
            testEntryConfigurations: testEntryConfigurations,
            bucketSplitInfo: BucketSplitInfo(numberOfWorkers: 2, numberOfParallelBuckets: 4)
        )
        
        XCTAssertEqual(actual, expected)
    }
    
    func test_equally_divided_splitter__respects_number_of_destinations() {
        let expected = testEntryConfigurations.splitToChunks(withSize: 1)
        
        let actual = equallyDividedSplitter.split(
            testEntryConfigurations: testEntryConfigurations,
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(testEntries.count),
                numberOfParallelBuckets: UInt(testEntries.count)
            )
        )
        
        XCTAssertEqual(actual, expected)
    }
}

