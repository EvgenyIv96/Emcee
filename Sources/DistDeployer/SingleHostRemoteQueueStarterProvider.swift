import Foundation

public protocol SingleHostRemoteQueueStarterProvider {
    func create() -> SingleHostRemoteQueueStarter
}
