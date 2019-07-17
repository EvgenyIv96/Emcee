@testable import RuntimeDump
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import SimulatorPool
import SimulatorPoolTestHelpers
import TemporaryStuff
import TestingFakeFbxctest
import XCTest

final class RuntimeTestQuerierTests: XCTestCase {
    let eventBus = EventBus()
    let fbxctest = try! FakeFbxctestExecutableProducer.fakeFbxctestPath(runId: UUID().uuidString)
    let resourceLocationResolver = ResourceLocationResolver()
    let tempFolder = try! TemporaryFolder()
    
    lazy var simulatorPool = OnDemandSimulatorPool(
        resourceLocationResolver: resourceLocationResolver,
        simulatorControllerProvider: FakeSimulatorControllerProvider(result: { simulator -> SimulatorController in
            return FakeSimulatorController(
                simulator: simulator,
                simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
                developerDir: .current
            )
        }),
        tempFolder: tempFolder
    )
    
    func test__getting_available_tests__without_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [],
            applicationTestSupport: nil
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
    }
    
    func test__getting_available_tests_while_some_tests_are_missing__without_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))])
    }
    
    func test__when_JSON_file_is_missing_throws__without_application_test_support() throws {
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime(configuration: configuration))
    }
    
    func test__when_JSON_file_has_incorrect_format_throws__without_application_test_support() throws {
        try tempFolder.createFile(
            filename: RuntimeTestQuerierImpl.runtimeTestsJsonFilename,
            contents: "oopps".data(using: .utf8)!)
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime(configuration: configuration))
    }

    func test__getting_available_tests__with_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [],
            applicationTestSupport: buildApplicationTestSupport()
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
    }

    func test__getting_available_tests_while_some_tests_are_missing__with_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))])
    }

    func test__when_JSON_file_is_missing_throws__with_application_test_support() throws {
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime(configuration: configuration))
    }

    func test__when_JSON_file_has_incorrect_format_throws__with_application_test_support() throws {
        try tempFolder.createFile(
            filename: RuntimeTestQuerierImpl.runtimeTestsJsonFilename,
            contents: "oopps".data(using: .utf8)!)
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime(configuration: configuration))
    }
    
    private func prepareFakeRuntimeDumpOutputForTestQuerier(entries: [RuntimeTestEntry]) throws {
        let data = try JSONEncoder().encode(entries)
        try tempFolder.createFile(
            filename: RuntimeTestQuerierImpl.runtimeTestsJsonFilename,
            contents: data)
    }
    
    private func runtimeTestQuerier() -> RuntimeTestQuerier {
        return RuntimeTestQuerierImpl(
            eventBus: eventBus,
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: simulatorPool,
            tempFolder: tempFolder
        )
    }
    
    private func runtimeDumpConfiguration(
        testsToValidate: [TestToRun],
        applicationTestSupport: RuntimeDumpApplicationTestSupport?
    ) -> RuntimeDumpConfiguration {
        return RuntimeDumpConfiguration(
            fbxctest: FbxctestLocation(ResourceLocation.localFilePath(fbxctest)),
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(ResourceLocation.localFilePath("")),
                runtimeDumpKind: .logicTest
            ),
            applicationTestSupport: applicationTestSupport,
            testDestination: TestDestinationFixtures.testDestination,
            testsToValidate: testsToValidate,
            developerDir: DeveloperDir.current
        )
    }

    private func buildApplicationTestSupport() -> RuntimeDumpApplicationTestSupport {
        return RuntimeDumpApplicationTestSupport(
            appBundle: AppBundleLocation(.localFilePath("")),
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool
        )
    }
}

