import Foundation
import TSCBasic

public struct Scheme: Equatable {
    // MARK: - Attributes

    public let name: String
    public let shared: Bool
    public let buildAction: BuildAction?
    public let testAction: TestAction?
    public let runAction: RunAction?
    public let archiveAction: ArchiveAction?
    public let profileAction: ProfileAction?
    public let analyzeAction: AnalyzeAction?

    // MARK: - Init

    public init(name: String,
                shared: Bool = false,
                buildAction: BuildAction? = nil,
                testAction: TestAction? = nil,
                runAction: RunAction? = nil,
                archiveAction: ArchiveAction? = nil,
                profileAction: ProfileAction? = nil,
                analyzeAction: AnalyzeAction? = nil) {
        self.name = name
        self.shared = shared
        self.buildAction = buildAction
        self.testAction = testAction
        self.runAction = runAction
        self.archiveAction = archiveAction
        self.profileAction = profileAction
        self.analyzeAction = analyzeAction
    }

    public func targetDependencies() -> [TargetReference] {
        let targetSources: [[TargetReference]?] = [
            buildAction?.targets,
            buildAction?.preActions.compactMap(\.target),
            buildAction?.postActions.compactMap(\.target),
            testAction?.targets.map(\.target),
            testAction?.codeCoverageTargets,
            testAction?.preActions.compactMap(\.target),
            testAction?.postActions.compactMap(\.target),
            runAction?.executable.map { [$0] },
            archiveAction?.preActions.compactMap(\.target),
            archiveAction?.postActions.compactMap(\.target),
            profileAction?.executable.map { [$0] },
        ]

        let targets = targetSources.compactMap { $0 }.flatMap { $0 }.uniqued()
        return targets.sorted { ($0.name < $1.name) }
    }
}
