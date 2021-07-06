import EmceeLogging
import Deployer
import DI
import DistDeployer
import Foundation
import QueueModels

public final class DefaultRemoteQueueStarterProvider: RemoteQueueStarterProvider {
    private let di: DI
    
    public init(di: DI) {
        self.di = di
    }
    
    public func create(
        deploymentId: DeploymentId,
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        queueServerConfigurationLocation: QueueServerConfigurationLocation
    ) throws -> RemoteQueueStarter {
        RemoteQueueStarter(
            processControllerProvider: try di.get(),
            queueServerConfigurationLocation: queueServerConfigurationLocation,
            tempFolder: try di.get(),
            uniqueIdentifierGenerator: try di.get()
        )
    }
}
