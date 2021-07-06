import Foundation
import Deployer
import QueueModels

public protocol SingleHostRemoteQueueStarter {
    func deployAndStart(
        deploymentId: DeploymentId,
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        queueServerConfigurationLocation: QueueServerConfigurationLocation
    ) throws
}
