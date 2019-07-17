import EventBus
import Foundation
import Models
import Runner
import SimulatorPool

public class SchedulerConfiguration {
    public let testRunExecutionBehavior: TestRunExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let schedulerDataSource: SchedulerDataSource
    public let onDemandSimulatorPool: OnDemandSimulatorPool

    public init(
        testRunExecutionBehavior: TestRunExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        schedulerDataSource: SchedulerDataSource,
        onDemandSimulatorPool: OnDemandSimulatorPool
    ) {
        self.testRunExecutionBehavior = testRunExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.schedulerDataSource = schedulerDataSource
        self.onDemandSimulatorPool = onDemandSimulatorPool
    }
}
