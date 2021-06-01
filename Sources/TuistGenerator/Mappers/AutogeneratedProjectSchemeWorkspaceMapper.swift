import Foundation
import TuistCore
import TuistGraph

/// Mapper that generates a new scheme `ProjectName-Project` that includes all targets
/// From a given workspace
public final class AutogeneratedProjectSchemeWorkspaceMapper: WorkspaceMapping { // swiftlint:disable:this type_name
    private let enableCodeCoverage: Bool

    // MARK: - Init

    public init(enableCodeCoverage: Bool) {
        self.enableCodeCoverage = enableCodeCoverage
    }

    public func map(workspace: WorkspaceWithProjects) throws -> (WorkspaceWithProjects, [SideEffectDescriptor]) {
        guard let project = workspace.projects.first else { return (workspace, []) }

        let platforms = Set(
            workspace.projects
                .flatMap {
                    $0.targets.map(\.platform)
                }
        )

        let schemes: [Scheme]

        if platforms.count == 1, let platform = platforms.first {
            schemes = [
                scheme(
                    name: "\(workspace.workspace.name)-Project",
                    platform: platform,
                    project: project,
                    workspace: workspace,
                    codeCoverage: enableCodeCoverage
                ),
            ]
        } else {
            schemes = platforms.map { platform in
                scheme(
                    name: "\(workspace.workspace.name)-Project-\(platform.caseValue)",
                    platform: platform,
                    project: project,
                    workspace: workspace,
                    codeCoverage: enableCodeCoverage
                )
            }
        }

        var workspace = workspace
        workspace.workspace.schemes.append(contentsOf: schemes)
        return (workspace, [])
    }

    // MAARK: - Helpers

    private func scheme(
        name: String,
        platform: Platform,
        project: Project,
        workspace: WorkspaceWithProjects,
        codeCoverage: Bool
    ) -> Scheme {
        var (targets, testableTargets): ([TargetReference], [TestableTarget]) = workspace.projects
            .reduce(([], [])) { result, project in
                let targets = project.targets
                    .filter { $0.platform == platform }
                    .map { TargetReference(projectPath: project.path, name: $0.name) }
                let testableTargets = project.targets
                    .filter { $0.platform == platform }
                    .filter(\.product.testsBundle)
                    .map { TargetReference(projectPath: project.path, name: $0.name) }
                    .map { TestableTarget(target: $0) }

                return (result.0 + targets, result.1 + testableTargets)
            }

        targets = targets.sorted(by: { $0.name < $1.name })
        testableTargets = testableTargets.sorted(by: { $0.target.name < $1.target.name })

        return Scheme(
            name: name,
            shared: true,
            buildAction: BuildAction(targets: targets),
            testAction: TestAction(
                targets: testableTargets,
                arguments: nil,
                configurationName: project.defaultDebugBuildConfigurationName,
                coverage: codeCoverage,
                codeCoverageTargets: [],
                expandVariableFromTarget: nil,
                preActions: [],
                postActions: [],
                diagnosticsOptions: [.mainThreadChecker]
            )
        )
    }
}
