import Foundation
import RxSwift
import TSCBasic
import TuistCache
import TuistCore
import TuistSupportTesting

public final class MockFrameworkBuilder: ArtifactBuilding {
    public init() {}

    public var invokedCacheOutputTypeGetter = false
    public var invokedCacheOutputTypeGetterCount = 0
    public var stubbedCacheOutputType: CacheOutputType!

    public var cacheOutputType: CacheOutputType {
        invokedCacheOutputTypeGetter = true
        invokedCacheOutputTypeGetterCount += 1
        return stubbedCacheOutputType
    }

    public var invokedBuildWorkspacePath = false
    public var invokedBuildWorkspacePathCount = 0
    public var invokedBuildWorkspacePathParameters: (workspacePath: AbsolutePath, target: Target)?
    public var invokedBuildWorkspacePathParametersList = [(workspacePath: AbsolutePath, target: Target)]()
    public var stubbedBuildWorkspacePathError: Error?
    public var stubbedBuildWorkspacePathResult: ((AbsolutePath, Target) -> Result<[AbsolutePath], Error>)?

    public func build(workspacePath: AbsolutePath, target: Target) throws -> Observable<[AbsolutePath]> {
        invokedBuildWorkspacePath = true
        invokedBuildWorkspacePathCount += 1
        invokedBuildWorkspacePathParameters = (workspacePath, target)
        invokedBuildWorkspacePathParametersList.append((workspacePath, target))
        if let error = stubbedBuildWorkspacePathError {
            throw error
        }
        if let stubbedBuildWorkspacePathResult = stubbedBuildWorkspacePathResult {
            switch stubbedBuildWorkspacePathResult(workspacePath, target) {
            case let .success(paths): return .just(paths)
            case let .failure(error): return .error(error)
            }
        } else {
            return .error(TestError("Call to non-stubbed method build"))
        }
    }

    public var invokedBuildProjectPath = false
    public var invokedBuildProjectPathCount = 0
    public var invokedBuildProjectPathParameters: (projectPath: AbsolutePath, target: Target)?
    public var invokedBuildProjectPathParametersList = [(projectPath: AbsolutePath, target: Target)]()
    public var stubbedBuildProjectPathError: Error?
    public var stubbedBuildProjectPathResult: Observable<[AbsolutePath]>!

    public func build(projectPath: AbsolutePath, target: Target) throws -> Observable<[AbsolutePath]> {
        invokedBuildProjectPath = true
        invokedBuildProjectPathCount += 1
        invokedBuildProjectPathParameters = (projectPath, target)
        invokedBuildProjectPathParametersList.append((projectPath, target))
        if let error = stubbedBuildProjectPathError {
            throw error
        }
        return stubbedBuildProjectPathResult
    }
}
