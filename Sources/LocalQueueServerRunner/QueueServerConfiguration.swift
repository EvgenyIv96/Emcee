import AutomaticTermination
import Deployer
import DistWorkerModels
import Foundation
import MetricsExtensions
import LoggingSetup
import QueueModels

public struct QueueServerConfiguration: Decodable {
    public let globalAnalyticsConfiguration: AnalyticsConfiguration
    public let checkAgainTimeInterval: TimeInterval
    public let queueServerDeploymentDestinations: [DeploymentDestination]
    public let queueServerTerminationPolicy: AutomaticTerminationPolicy
    public let workerDeploymentDestinations: [DeploymentDestination]
    public let workerSpecificConfigurations: [WorkerId: WorkerSpecificConfiguration]

    public init(
        globalAnalyticsConfiguration: AnalyticsConfiguration,
        checkAgainTimeInterval: TimeInterval,
        queueServerDeploymentDestinations: [DeploymentDestination],
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        workerDeploymentDestinations: [DeploymentDestination],
        workerSpecificConfigurations: [WorkerId: WorkerSpecificConfiguration]
    ) {
        self.globalAnalyticsConfiguration = globalAnalyticsConfiguration
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.queueServerDeploymentDestinations = queueServerDeploymentDestinations
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.workerDeploymentDestinations = workerDeploymentDestinations
        self.workerSpecificConfigurations = workerSpecificConfigurations
    }
    
    private enum CodingKeys: String, CodingKey {
        case globalAnalyticsConfiguration
        case checkAgainTimeInterval
        case queueServerDeploymentDestination  // old style
        case queueServerDeploymentDestinations
        case queueServerTerminationPolicy
        case workerDeploymentDestinations
        case workerSpecificConfigurations
    }
     
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let globalAnalyticsConfiguration = try container.decode(AnalyticsConfiguration.self, forKey: .globalAnalyticsConfiguration)
        let checkAgainTimeInterval = try container.decode(TimeInterval.self, forKey: .checkAgainTimeInterval)
        
        let queueServerDeploymentDestinations = try container.decodeIfPresent([DeploymentDestination].self, forKey: .queueServerDeploymentDestinations)
        ?? [try container.decode(DeploymentDestination.self, forKey: .queueServerDeploymentDestination)]
        
        let queueServerTerminationPolicy = try container.decode(AutomaticTerminationPolicy.self, forKey: .queueServerTerminationPolicy)
        let workerDeploymentDestinations = try container.decode([DeploymentDestination].self, forKey: .workerDeploymentDestinations)
        let workerSpecificConfigurations = Dictionary(
            uniqueKeysWithValues: try container.decode(
                [String: WorkerSpecificConfiguration].self,
                forKey: .workerSpecificConfigurations
            ).map { key, value in
                (WorkerId(key), value)
            }
        )
        
        self.init(
            globalAnalyticsConfiguration: globalAnalyticsConfiguration,
            checkAgainTimeInterval: checkAgainTimeInterval,
            queueServerDeploymentDestinations: queueServerDeploymentDestinations,
            queueServerTerminationPolicy: queueServerTerminationPolicy,
            workerDeploymentDestinations: workerDeploymentDestinations,
            workerSpecificConfigurations: workerSpecificConfigurations
        )
    }
    
    public func workerConfiguration(
        workerSpecificConfiguration: WorkerSpecificConfiguration,
        payloadSignature: PayloadSignature
    ) -> WorkerConfiguration {
        return WorkerConfiguration(
            globalAnalyticsConfiguration: globalAnalyticsConfiguration,
            numberOfSimulators: workerSpecificConfiguration.numberOfSimulators,
            payloadSignature: payloadSignature
        )
    }
}
