import Deployer
import QueueModels

public class WorkersToUtilizePayload: Codable {
    public let workerIds: Set<WorkerId>
    public let queueInfo: QueueInfo
    
    public init(
        workerIds: Set<WorkerId>,
        queueInfo: QueueInfo
    ) {
        self.workerIds = workerIds
        self.queueInfo = queueInfo
    }
}
