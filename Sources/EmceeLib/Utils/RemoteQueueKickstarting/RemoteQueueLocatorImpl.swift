import Deployer
import EmceeLogging
import Foundation
import QueueCommunication
import QueueModels
import SocketModels

public final class RemoteQueueLocatorImpl: RemoteQueueLocator {
    private let logger: ContextualLogger
    private let remoteQueueDetectorProvider: RemoteQueueDetectorProvider
    
    public init(
        logger: ContextualLogger,
        remoteQueueDetectorProvider: RemoteQueueDetectorProvider
    ) {
        self.logger = logger
        self.remoteQueueDetectorProvider = remoteQueueDetectorProvider
    }
    
    public func locateRunningQueueInstance(
        emceeVersion: Version,
        hosts: [String]
    ) -> Set<SocketAddress> {
        for host in hosts {
            do {
                logger.info("Searching for queue server on \(host) with queue version \(emceeVersion)")
                let remoteQueueDetector = remoteQueueDetectorProvider.createRemoteQueueDetector(
                    emceeVersion: emceeVersion,
                    host: host
                )
                let suitablePorts = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts(timeout: 10)
                if !suitablePorts.isEmpty {
                    let addresses = Set(suitablePorts.map {
                        SocketAddress(host: host, port: $0)
                    })
                    logger.info("Found \(suitablePorts.count) queue server(s) at: '\(addresses)'")
                    return addresses
                }
            } catch {
                logger.warning("Error locating queue server at \(host): \(error). This error will be ignored.")
            }
        }
        logger.debug("Did not locate any running queues after scanning \(hosts.count) hosts")
        return []
    }
}
