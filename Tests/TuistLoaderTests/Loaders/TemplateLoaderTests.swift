import TSCBasic
import TuistCore
import TuistSupport
import XCTest

@testable import ProjectDescription
@testable import TuistLoader
@testable import TuistLoaderTesting
@testable import TuistSupportTesting

final class TemplateLoaderTests: TuistUnitTestCase {
    var subject: TemplateLoader!
    var manifestLoader: MockManifestLoader!

    override func setUp() {
        super.setUp()
        manifestLoader = MockManifestLoader()
        subject = TemplateLoader(manifestLoader: manifestLoader)
    }

    override func tearDown() {
        manifestLoader = nil
        subject = nil
        super.tearDown()
    }

    func test_loadTemplate_when_not_found() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        manifestLoader.loadTemplateStub = { path, _ in
            throw ManifestLoaderError.manifestNotFound(path)
        }

        // Then
        XCTAssertThrowsSpecific(try subject.loadTemplate(at: temporaryPath, plugins: .none),
                                ManifestLoaderError.manifestNotFound(temporaryPath))
    }

    func test_loadTemplate_files() throws {
        // Given
        let temporaryPath = try self.temporaryPath()
        manifestLoader.loadTemplateStub = { _, _ in
            ProjectDescription.Template(description: "desc",
                                        files: [ProjectDescription.Template.File(path: "generateOne",
                                                                                 contents: .file("fileOne"))])
        }

        // When
        let got = try subject.loadTemplate(at: temporaryPath, plugins: .none)

        // Then
        XCTAssertEqual(got, TuistCore.Template(description: "desc",
                                               files: [Template.File(path: RelativePath("generateOne"),
                                                                     contents: .file(temporaryPath.appending(component: "fileOne")))]))
    }
}
