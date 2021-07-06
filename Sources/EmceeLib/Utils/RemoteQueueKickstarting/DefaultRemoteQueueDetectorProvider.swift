import DI
import EmceeLogging
import Foundation
import QueueCommunication
import QueueModels
import RemotePortDeterminer
import RequestSender
import SocketModels

public final class DefaultRemoteQueueDetectorProvider: RemoteQueueDetectorProvider {
    private let logger: ContextualLogger
    private let portRange: ClosedRange<SocketModels.Port>
    private let requestSenderProvider: RequestSenderProvider
    
    public init(
        logger: ContextualLogger,
        portRange: ClosedRange<SocketModels.Port>,
        requestSenderProvider: RequestSenderProvider
    ) {
        self.logger = logger
        self.portRange = portRange
        self.requestSenderProvider = requestSenderProvider
    }
    
    public func createRemoteQueueDetector(
        emceeVersion: Version,
        host: String
    ) -> RemoteQueueDetector {
        DefaultRemoteQueueDetector(
            emceeVersion: emceeVersion,
            logger: logger,
            remotePortDeterminer: RemoteQueuePortScanner(
                host: host,
                logger: logger,
                portRange: portRange,
                requestSenderProvider: requestSenderProvider
            )
        )
    }
}
