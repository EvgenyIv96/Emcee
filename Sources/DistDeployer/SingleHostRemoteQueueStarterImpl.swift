import Deployer
import EmceeLogging
import Foundation
import PathLib
import ProcessController
import QueueModels
import Tmp
import UniqueIdentifierGenerator

public final class SingleHostRemoteQueueStarterImpl: SingleHostRemoteQueueStarter {
    private let logger: ContextualLogger
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        logger: ContextualLogger,
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.logger = logger
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func deployAndStart(
        deploymentId: DeploymentId,
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        queueServerConfigurationLocation: QueueServerConfigurationLocation
    ) throws {
        let deployablesGenerator = DeployablesGenerator(
            emceeVersion: emceeVersion,
            remoteEmceeBinaryName: "EmceeQueueServer"
        )
        try deploy(
            deploymentId: deploymentId,
            deploymentDestination: deploymentDestination,
            deployableItems: try deployablesGenerator.deployables(),
            emceeBinaryDeployableItem: try deployablesGenerator.runnerTool(),
            emceeVersion: emceeVersion,
            logger: logger,
            queueServerConfigurationLocation: queueServerConfigurationLocation
        )
    }
    
    private func deploy(
        deploymentId: DeploymentId,
        deploymentDestination: DeploymentDestination,
        deployableItems: [DeployableItem],
        emceeBinaryDeployableItem: DeployableItem,
        emceeVersion: Version,
        logger: ContextualLogger,
        queueServerConfigurationLocation: QueueServerConfigurationLocation
    ) throws {
        let launchdPlistTargetPath = "queue_server_launchd.plist"
        let launchdPlist = RemoteQueueLaunchdPlist(
            deploymentId: deploymentId,
            deploymentDestination: deploymentDestination,
            emceeDeployableItem: emceeBinaryDeployableItem,
            emceeVersion: emceeVersion,
            queueServerConfigurationLocation: queueServerConfigurationLocation
        )
        let launchdPlistDeployableItem = DeployableItem(
            name: "queue_server_launchd_plist",
            files: [
                DeployableFile(
                    source: try tempFolder.createFile(
                        filename: launchdPlistTargetPath,
                        contents: try launchdPlist.plistData()
                    ),
                    destination: RelativePath(launchdPlistTargetPath)
                )
            ]
        )
        let launchctlDeployableCommands = LaunchctlDeployableCommands(
            launchdPlistDeployableItem: launchdPlistDeployableItem,
            plistFilename: launchdPlistTargetPath
        )

        let deployer = DistDeployer(
            deploymentId: deploymentId,
            deploymentDestination: deploymentDestination,
            deployableItems: deployableItems + [launchdPlistDeployableItem],
            deployableCommands: [
                launchctlDeployableCommands.forceUnloadFromBackgroundCommand(),
                launchctlDeployableCommands.forceLoadInBackgroundCommand()
            ],
            logger: logger,
            processControllerProvider: processControllerProvider,
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        try deployer.deploy()
    }
}
