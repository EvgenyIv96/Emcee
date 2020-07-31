import ArgLib
import EmceeVersion
import Foundation
import Logging
import QueueClient
import QueueModels
import RequestSender
import SocketModels
import Types

public final class KickstartCommand: Command {
    public let name = "kickstart"
    public let description = "Attempts to restart the Emcee worker"
    public let arguments: Arguments = [
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asMultiple.asRequired,
    ]
    
    private let callbackQueue = DispatchQueue(label: "KickstartCommand.callbackQueue")
    private let processingQueue = DispatchQueue(label: "KickstartCommand.processingQueue", attributes: .concurrent, target: DispatchQueue.global(qos: .default))
    private let requestSenderProvider: RequestSenderProvider
    
    public init(
        requestSenderProvider: RequestSenderProvider
    ) {
        self.requestSenderProvider = requestSenderProvider
    }
    
    public func run(payload: CommandPayload) throws {
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerIds: [WorkerId] = try payload.nonEmptyCollectionOfValues(argumentName: ArgumentDescriptions.workerId.name)
        
        let kickstarter = WorkerKickstarterImpl(
            requestSender: requestSenderProvider.requestSender(
                socketAddress: queueServerAddress
            )
        )
        
        let waitingGroup = DispatchGroup()
        
        for workerId in workerIds {
            waitingGroup.enter()
            
            Logger.info("Attempting to kickstart \(workerId)")
            kickstarter.kickstart(workerId: workerId, callbackQueue: callbackQueue) { result in
                defer {
                    waitingGroup.leave()
                }
                do {
                    let workerId = try result.dematerialize()
                    Logger.info("Successfully kickstarted \(workerId)")
                } catch {
                    Logger.error("Failed to start worker \(workerId): \(error)")
                }
            }
        }

        waitingGroup.wait()
    }
}
