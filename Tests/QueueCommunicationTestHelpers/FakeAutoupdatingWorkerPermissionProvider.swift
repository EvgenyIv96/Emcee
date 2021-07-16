import QueueCommunication
import QueueCommunicationModels
import QueueModels
import SocketModels

public class FakeAutoupdatingWorkerPermissionProvider: AutoupdatingWorkerPermissionProvider {
    public init() {}
    
    public var startUpdatingCalled = false
    public func startUpdating() {
        startUpdatingCalled = true
    }
    
    public var stopUpdatingCalled = false
    public func stopUpdatingAndRestoreDefaultConfig() {
        stopUpdatingCalled = true
    }
    
    public func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission {
        return .allowedToUtilize
    }
}
