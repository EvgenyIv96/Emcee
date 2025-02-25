import BuildArtifacts
import DateProvider
import DeveloperDirLocator
import EmceeLogging
import SimulatorPoolModels
import Tmp
import RunnerModels
import Foundation
import PathLib

public final class FailureReportingTestRunnerProxy: TestRunner {
    private let dateProvider: DateProvider
    private let testRunner: TestRunner
    
    public init(
        dateProvider: DateProvider,
        testRunner: TestRunner
    ) {
        self.dateProvider = dateProvider
        self.testRunner = testRunner
    }
    
    public func prepareTestRun(
        buildArtifacts: IosBuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        logger: ContextualLogger,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream
    ) throws -> TestRunnerInvocation {
        do {
            return try testRunner.prepareTestRun(
                buildArtifacts: buildArtifacts,
                developerDirLocator: developerDirLocator,
                entriesToRun: entriesToRun,
                logger: logger,
                testContext: testContext,
                testRunnerStream: testRunnerStream
            )
        } catch {
            return generateFailureResults(
                entriesToRun: entriesToRun,
                runnerError: error,
                testRunnerStream: testRunnerStream
            )
        }
    }
    
    public func additionalEnvironment(testRunnerWorkingDirectory: AbsolutePath) -> [String: String] {
        return testRunner.additionalEnvironment(testRunnerWorkingDirectory: testRunnerWorkingDirectory)
    }
    
    private func generateFailureResults(
        entriesToRun: [TestEntry],
        runnerError: Error,
        testRunnerStream: TestRunnerStream
    ) -> TestRunnerInvocation {
        testRunnerStream.openStream()
        for testEntry in entriesToRun {
            testRunnerStream.testStarted(testName: testEntry.testName)
            testRunnerStream.testStopped(
                testStoppedEvent: TestStoppedEvent(
                    testName: testEntry.testName,
                    result: .lost,
                    testDuration: 0,
                    testExceptions: [
                        RunnerConstants.failedToStartTestRunner(runnerError).testException
                    ],
                    logs: [],
                    testStartTimestamp: dateProvider.dateSince1970ReferenceDate()
                )
            )
        }
        testRunnerStream.closeStream()
        return NoOpTestRunnerInvocation()
    }
}

private class NoOpTestRunnerInvocation: TestRunnerInvocation {
    private class NoOpTestRunnerRunningInvocation: TestRunnerRunningInvocation {
        init() {}
        let pidInfo = PidInfo(pid: 0, name: "no-op process")
        func cancel() {}
        func wait() {}
    }
    
    init() {}
    
    func startExecutingTests() -> TestRunnerRunningInvocation { NoOpTestRunnerRunningInvocation() }
}
