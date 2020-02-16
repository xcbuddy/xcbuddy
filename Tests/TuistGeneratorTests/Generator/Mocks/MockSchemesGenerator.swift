import Basic
import Foundation
import TuistCore
import TuistCoreTesting
@testable import TuistGenerator

final class MockSchemesGenerator: SchemesGenerating {
    var generateWorkspaceSchemeArgs: [(workspace: Workspace, xcworkspacePath: AbsolutePath, generatedProjects: [AbsolutePath: GeneratedProject], graph: Graphing)] = []

    var generateProjectSchemeArgs: [(project: Project, xcprojectPath: AbsolutePath, generatedProject: GeneratedProject, graph: Graphing)] = []

    var wipeSchemeArgs: [AbsolutePath] = []

    func generateWorkspaceSchemes(workspace: Workspace,
                                  xcworkspacePath: AbsolutePath,
                                  generatedProjects: [AbsolutePath: GeneratedProject],
                                  graph: Graphing) throws {
        generateWorkspaceSchemeArgs.append((workspace: workspace, xcworkspacePath: xcworkspacePath, generatedProjects: generatedProjects, graph: graph))
    }

    func generateProjectSchemes(project: Project, xcprojectPath: AbsolutePath, generatedProject: GeneratedProject, graph: Graphing) throws {
        generateProjectSchemeArgs.append((project: project, xcprojectPath: xcprojectPath, generatedProject: generatedProject, graph: graph))
    }

    func generateProjectSchemeDescriptors(project _: Project, xcprojectPath _: AbsolutePath, generatedProject _: GeneratedProject, graph _: Graphing) throws -> [GeneratedSchemeDescriptor] {
        []
    }

    func generateWorkspaceSchemesDescriptors(workspace _: Workspace, xcworkspacePath _: AbsolutePath, generatedProjects _: [AbsolutePath: GeneratedProject], graph _: Graphing) throws -> [GeneratedSchemeDescriptor] {
        []
    }

    func wipeSchemes(at: AbsolutePath) throws {
        wipeSchemeArgs.append(at)
    }
}
