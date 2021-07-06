import Foundation
import EmceeLogging
import QueueModels
import Deployer
import DistDeployer
import SynchronousWaiter
import SocketModels

public protocol MultihostRemoteQueueStarter {
    func startNewQueueServerInstance(
        deploymentId: DeploymentId,
        emceeVersion: Version,
        queueServerConfigurationLocation: QueueServerConfigurationLocation,
        queueServerDeploymentDestinations: [DeploymentDestination]
    ) throws -> SocketAddress
}

public final class QueueShitterImpl: MultihostRemoteQueueStarter {
    private let logger: ContextualLogger
    private let waiter: Waiter
    private let remoteQueueStarterProvider: RemoteQueueStarterProvider
    private let remoteQueueLocator: RemoteQueueLocator
    
    public init(
        logger: ContextualLogger,
        waiter: Waiter,
        remoteQueueStarterProvider: RemoteQueueStarterProvider,
        remoteQueueLocator: RemoteQueueLocator
    ) {
        self.logger = logger
        self.waiter = waiter
        self.remoteQueueStarterProvider = remoteQueueStarterProvider
        self.remoteQueueLocator = remoteQueueLocator
    }
    
    public func startNewQueueServerInstance(
        deploymentId: DeploymentId,
        emceeVersion: Version,
        queueServerConfigurationLocation: QueueServerConfigurationLocation,
        queueServerDeploymentDestinations: [DeploymentDestination]
    ) throws -> SocketAddress {
        var collectedErrors = [(host: String, error: Error)]()
        for queueServerDeploymentDestination in queueServerDeploymentDestinations {
            do {
                try startNewInstanceOfRemoteQueueServerOnSpecificHost(
                    deploymentId: deploymentId,
                    queueServerDeploymentDestination: queueServerDeploymentDestination,
                    emceeVersion: emceeVersion,
                    queueServerConfigurationLocation: queueServerConfigurationLocation,
                    logger: logger
                )
                
                let socketAddresses = remoteQueueLocator.locateRunningQueueInstance(
                    emceeVersion: emceeVersion,
                    hosts: [queueServerDeploymentDestination.host]
                )
                logger.info("Found queue server at '\(socketAddresses)'")
                //  TODO
                return socketAddresses.first!
            } catch {
                logger.warning("Failed to start queue server on \(queueServerDeploymentDestination.host): \(error). This error will be ignored.")
                collectedErrors.append((host: queueServerDeploymentDestination.host, error: error))
            }
        }
        throw FailedToStartNewQueueInstance(errors: collectedErrors)
    }
    
    struct FailedToStartNewQueueInstance: Error, CustomStringConvertible {
        let errors: [(host: String, error: Error)]
        var description: String {
            let descriptiveErrors = errors.map { pair in
                "- Error starting queue server on \(pair.host): \(pair.error)"
            }.joined(separator: "\n")
            return "Failed to start new queue server instance after trying \(errors.count) hosts. Errors:\n\(descriptiveErrors)"
        }
    }
    
    private func startNewInstanceOfRemoteQueueServerOnSpecificHost(
        deploymentId: DeploymentId,
        queueServerDeploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        queueServerConfigurationLocation: QueueServerConfigurationLocation,
        logger: ContextualLogger
    ) throws {
        logger.info("No running queue server has been found. Will deploy and start remote queue.")
        let remoteQueueStarter = try remoteQueueStarterProvider.create(
            deploymentId: deploymentId,
            deploymentDestination: queueServerDeploymentDestination,
            emceeVersion: emceeVersion,
            queueServerConfigurationLocation: queueServerConfigurationLocation
        )
        try remoteQueueStarter.deployAndStart(
            deploymentId: deploymentId,
            deploymentDestination: queueServerDeploymentDestination,
            emceeVersion: emceeVersion,
            logger: logger
        )
    }
}
