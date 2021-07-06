import Foundation
import QueueModels
import SocketModels

public protocol RemoteQueueLocator {
    func locateRunningQueueInstance(
        emceeVersion: Version,
        hosts: [String]
    ) -> Set<SocketAddress>
}
