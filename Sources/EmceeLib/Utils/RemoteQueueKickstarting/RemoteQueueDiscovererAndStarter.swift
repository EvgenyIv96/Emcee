import EmceeLogging
import Deployer
import DI
import DistDeployer
import Foundation
import QueueCommunication
import QueueModels
import RemotePortDeterminer
import SocketModels
import SynchronousWaiter

public class RemoteQueueDiscovererAndStarter {
    private let remoteQueueLocator: RemoteQueueLocator
    private let logger: ContextualLogger
    private let di: DI
    
    public init(
        logger: ContextualLogger,
        remoteQueueLocator: RemoteQueueLocator,
        di: DI
    ) {
        self.logger = logger
        self.remoteQueueLocator = remoteQueueLocator
        self.di = di
    }
    
    public func detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
        emceeVersion: Version,
        queueServerDeploymentDestinations: [DeploymentDestination],
        queueServerConfigurationLocation: QueueServerConfigurationLocation,
        deploymentId: DeploymentId
    ) throws -> SocketAddress {
        if let runningQueueAddress = remoteQueueLocator.locateRunningQueueInstance(
            emceeVersion: emceeVersion,
            hosts: queueServerDeploymentDestinations.map(\.host)
        ).sorted(by: { left, right in left.asString < right.asString }).last {
            return runningQueueAddress
        }
        
        logger.debug("Did not locate any running queue servers after scanning \(queueServerDeploymentDestinations.count) hosts. Will start a new queue server.")
        
        return try QueueShitterImpl(
            logger: logger,
            waiter: try di.get(),
            remoteQueueStarterProvider: DefaultRemoteQueueStarterProvider(di: di),
            remoteQueueLocator: remoteQueueLocator
        ).startNewQueueServerInstance(
            deploymentId: deploymentId,
            emceeVersion: emceeVersion,
            queueServerConfigurationLocation: queueServerConfigurationLocation,
            queueServerDeploymentDestinations: queueServerDeploymentDestinations
        )
    }
    
    private func selectPort(ports: Set<SocketModels.Port>) throws -> SocketModels.Port {
        struct NoRunningQueueFoundError: Error, CustomStringConvertible {
            var description: String { "No running queue server found" }
        }
        
        guard let port = ports.sorted().last else { throw NoRunningQueueFoundError() }
        return port
    }
}
