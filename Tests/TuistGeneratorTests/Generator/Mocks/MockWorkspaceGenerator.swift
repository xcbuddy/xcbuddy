import Basic
import Foundation
import TuistCore
import TuistCoreTesting
import TuistSupport
@testable import TuistGenerator

final class MockWorkspaceGenerator: WorkspaceGenerating {
    var generateWorkspaces: [Workspace] = []
    var generateStub: ((Workspace, AbsolutePath, Graphing) throws -> AbsolutePath)?

    func generate(workspace: Workspace,
                  path: AbsolutePath,
                  graph: Graphing) throws -> AbsolutePath {
        generateWorkspaces.append(workspace)
        return (try generateStub?(workspace, path, graph)) ?? AbsolutePath("/test")
    }

    func generateDescriptor(workspace _: Workspace, path _: AbsolutePath, graph _: Graphing) throws -> GeneratedWorkspaceDescriptor {
        fatalError("Not yet implemented")
    }
}
