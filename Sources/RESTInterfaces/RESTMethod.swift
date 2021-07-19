import Foundation

public enum RESTMethod: String, RESTPath {
    case bucketResult
    case workerIds
    case disableWorker
    case enableWorker
    case getBucket
    case queueVersion
    case registerWorker
    case reportAlive
    case scheduleTests
    case toggleWorkersSharing
    case workerStatus
    case workersToUtilize
    
    public var pathWithLeadingSlash: String {
        return "/\(self.rawValue)"
    }
}
