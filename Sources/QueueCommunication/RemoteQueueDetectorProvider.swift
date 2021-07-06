import Foundation
import QueueModels

public protocol RemoteQueueDetectorProvider {
    func createRemoteQueueDetector(
        emceeVersion: Version,
        host: String
    ) -> RemoteQueueDetector
}
