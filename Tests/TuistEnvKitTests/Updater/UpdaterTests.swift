import Foundation
import TuistCore
import XCTest

@testable import TuistCoreTesting
@testable import TuistEnvKit

final class UpdaterTests: XCTestCase {
    var context: MockContext!
    var githubClient: MockGitHubClient!
    var versionsController: MockVersionsController!
    var installer: MockInstaller!
    var envUpdater: MockEnvUpdater!
    var subject: Updater!

    override func setUp() {
        super.setUp()
        context = Context.mockSharedContext()

        githubClient = MockGitHubClient()
        versionsController = try! MockVersionsController()
        installer = MockInstaller()
        envUpdater = MockEnvUpdater()
        subject = Updater(githubClient: githubClient,
                          versionsController: versionsController,
                          installer: installer,
                          envUpdater: envUpdater)
    }

    func test_update_when_no_remote_releases() throws {
        githubClient.releasesStub = { [] }
        try subject.update(force: false)

        XCTAssertPrinterOutputContains(context, expected: "No remote versions found")
        XCTAssertEqual(envUpdater.updateCallCount, 1)
    }

    func test_update_when_force() throws {
        githubClient.releasesStub = { [Release.test(version: "3.2.1")] }
        var installArgs: [(version: String, force: Bool)] = []
        installer.installStub = { version, force in installArgs.append((version: version, force: force)) }

        try subject.update(force: true)

        XCTAssertPrinterOutputContains(context, expected: "Forcing the update of version 3.2.1")
        XCTAssertEqual(installArgs.count, 1)
        XCTAssertEqual(installArgs.first?.version, "3.2.1")
        XCTAssertEqual(installArgs.first?.force, true)
        XCTAssertEqual(envUpdater.updateCallCount, 1)
    }

    func test_update_when_there_are_no_updates() throws {
        versionsController.semverVersionsStub = ["3.2.1"]
        githubClient.releasesStub = { [Release.test(version: "3.2.1")] }

        try subject.update(force: false)

        XCTAssertPrinterOutputContains(context, expected: "There are no updates available")
        XCTAssertEqual(envUpdater.updateCallCount, 1)
    }

    func test_update_when_there_are_updates() throws {
        versionsController.semverVersionsStub = ["3.1.1"]
        githubClient.releasesStub = { [Release.test(version: "3.2.1")] }
        var installArgs: [(version: String, force: Bool)] = []
        installer.installStub = { version, force in installArgs.append((version: version, force: force)) }

        try subject.update(force: false)

        XCTAssertPrinterOutputContains(context, expected: "Installing new version available 3.2.1")
        XCTAssertEqual(installArgs.count, 1)
        XCTAssertEqual(installArgs.first?.version, "3.2.1")
        XCTAssertEqual(installArgs.first?.force, false)
        XCTAssertEqual(envUpdater.updateCallCount, 1)
    }

    func test_update_when_no_local_versions_available() throws {
        versionsController.semverVersionsStub = []
        githubClient.releasesStub = { [Release.test(version: "3.2.1")] }
        var installArgs: [(version: String, force: Bool)] = []
        installer.installStub = { version, force in installArgs.append((version: version, force: force)) }

        try subject.update(force: false)

        XCTAssertPrinterOutputContains(context, expected: "No local versions available. Installing the latest version 3.2.1")
        XCTAssertEqual(installArgs.count, 1)
        XCTAssertEqual(installArgs.first?.version, "3.2.1")
        XCTAssertEqual(installArgs.first?.force, false)
        XCTAssertEqual(envUpdater.updateCallCount, 1)
    }
}
