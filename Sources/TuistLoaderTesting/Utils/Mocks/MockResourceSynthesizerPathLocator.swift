import Foundation
import TSCBasic
import TuistGraph
@testable import TuistLoader

public final class MockResourceSynthesizerPathLocator: ResourceSynthesizerPathLocating {
    public init() {}

    public var templatePathStub: ((String, String, [ResourceSynthesizerPlugin]) throws -> AbsolutePath)?
    public func templatePath(
        for pluginName: String,
        resourceName: String,
        resourceSynthesizerPlugins: [ResourceSynthesizerPlugin]
    ) throws -> AbsolutePath {
        try templatePathStub?(pluginName, resourceName, resourceSynthesizerPlugins) ?? AbsolutePath("/test")
    }

    public var templatePathResourceStub: ((String, AbsolutePath) -> AbsolutePath?)?
    public func templatePath(
        for resourceName: String,
        path: AbsolutePath
    ) -> AbsolutePath? {
        templatePathResourceStub?(resourceName, path)
    }
}
