import SocketModels

public protocol AutoupdatingWorkerPermissionProvider: WorkerPermissionProvider {
    func startUpdating()
    func stopUpdatingAndRestoreDefaultConfig()
}
