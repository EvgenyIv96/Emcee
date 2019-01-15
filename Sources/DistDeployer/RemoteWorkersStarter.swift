import Deployer
import Foundation
import Logging
import Models
import TempFolder

/// Starts the remote workers on the given destinations that will poll jobs from the given queue
public final class RemoteWorkersStarter {
    private let deploymentId: String
    private let deploymentDestinations: [DeploymentDestination]
    private let pluginLocations: [PluginLocation]
    private let queueAddress: SocketAddress
    private let tempFolder: TempFolder

    public init(
        deploymentId: String,
        deploymentDestinations: [DeploymentDestination],
        pluginLocations: [PluginLocation],
        queueAddress: SocketAddress,
        tempFolder: TempFolder)
    {
        self.deploymentId = deploymentId
        self.deploymentDestinations = deploymentDestinations
        self.pluginLocations = pluginLocations
        self.queueAddress = queueAddress
        self.tempFolder = tempFolder
    }
    
    public func deployAndStartWorkers() throws {
        let deployablesGenerator = DeployablesGenerator(
            remoteAvitoRunnerPath: "EmceeWorker",
            pluginLocations: pluginLocations
        )
        try deployWorkers(
            deployableItems: try deployablesGenerator.deployables().values.flatMap { $0 }
        )
        try startDeployedWorkers(
            emceeBinaryDeployableItem: deployablesGenerator.runnerTool,
            queueAddress: queueAddress
        )
    }
    
    private func deployWorkers(deployableItems: [DeployableItem]) throws {
        let deployer = DistDeployer(
            deploymentId: deploymentId,
            deploymentDestinations: deploymentDestinations,
            deployableItems: deployableItems,
            deployableCommands: [],
            tempFolder: tempFolder
        )
        try deployer.deploy()
    }
    
    private func startDeployedWorkers(
        emceeBinaryDeployableItem: DeployableItem,
        queueAddress: SocketAddress)
        throws
    {
        let launchdPlistTargetPath = "launchd.plist"
        
        for destination in deploymentDestinations {
            let launchdPlist = RemoteWorkerLaunchdPlist(
                deploymentId: deploymentId,
                deploymentDestination: destination,
                executableDeployableItem: emceeBinaryDeployableItem,
                queueAddress: queueAddress
            )
            let filePath = try tempFolder.createFile(
                filename: launchdPlistTargetPath,
                contents: try launchdPlist.plistData()
            )
            
            let launchdDeployableItem = DeployableItem(
                name: "launchd_plist",
                files: [
                    DeployableFile(
                        source: filePath.asString,
                        destination: launchdPlistTargetPath
                    )
                ]
            )
            let launchctlDeployableCommands = LaunchctlDeployableCommands(
                launchdPlistDeployableItem: launchdDeployableItem,
                plistFilename: launchdPlistTargetPath
            )
            
            let deployer = DistDeployer(
                deploymentId: deploymentId,
                deploymentDestinations: [destination],
                deployableItems: [launchdDeployableItem],
                deployableCommands: [
                    launchctlDeployableCommands.forceUnloadFromBackgroundCommand(),
                    [
                        "sleep", "2"        // launchctl is async, so we have to wait :(
                    ],
                    launchctlDeployableCommands.forceLoadInBackgroundCommand()
                ],
                tempFolder: tempFolder
            )
            do {
                try deployer.deploy()
            } catch {
                Logger.warning("Failed to deploy launchd plist: \(error). This error will be ignored.")
            }
        }
    }
}
