import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistGraph
import TuistSupport

/// A component responsible for converting Manifests (`ProjectDescription`) to Models (`TuistCore`)
public protocol ManifestModelConverting {
    func convert(manifest: ProjectDescription.Workspace, path: AbsolutePath) throws -> TuistGraph.Workspace
    func convert(
        manifest: ProjectDescription.Project,
        path: AbsolutePath,
        plugins: Plugins,
        externalDependencies: [String: [TuistGraph.TargetDependency]]
    ) throws -> TuistGraph.Project
    func convert(manifest: ProjectDescription.DependenciesGraph, path: AbsolutePath) throws -> TuistGraph.DependenciesGraph
}

public final class ManifestModelConverter: ManifestModelConverting {
    private let manifestLoader: ManifestLoading
    private let resourceSynthesizerPathLocator: ResourceSynthesizerPathLocating

    public convenience init() {
        self.init(
            manifestLoader: ManifestLoader()
        )
    }

    public convenience init(
        manifestLoader: ManifestLoading
    ) {
        self.init(
            manifestLoader: manifestLoader,
            resourceSynthesizerPathLocator: ResourceSynthesizerPathLocator()
        )
    }

    init(
        manifestLoader: ManifestLoading,
        resourceSynthesizerPathLocator: ResourceSynthesizerPathLocating = ResourceSynthesizerPathLocator()
    ) {
        self.manifestLoader = manifestLoader
        self.resourceSynthesizerPathLocator = resourceSynthesizerPathLocator
    }

    public func convert(
        manifest: ProjectDescription.Project,
        path: AbsolutePath,
        plugins: Plugins,
        externalDependencies: [String: [TuistGraph.TargetDependency]]
    ) throws -> TuistGraph.Project {
        let generatorPaths = GeneratorPaths(manifestDirectory: path)
        return try TuistGraph.Project.from(
            manifest: manifest,
            generatorPaths: generatorPaths,
            plugins: plugins,
            externalDependencies: externalDependencies,
            resourceSynthesizerPathLocator: resourceSynthesizerPathLocator
        )
    }

    public func convert(
        manifest: ProjectDescription.Workspace,
        path: AbsolutePath
    ) throws -> TuistGraph.Workspace {
        let generatorPaths = GeneratorPaths(manifestDirectory: path)
        let workspace = try TuistGraph.Workspace.from(
            manifest: manifest,
            path: path,
            generatorPaths: generatorPaths,
            manifestLoader: manifestLoader
        )
        return workspace
    }

    public func convert(
        manifest: ProjectDescription.DependenciesGraph,
        path: AbsolutePath
    ) throws -> TuistGraph.DependenciesGraph {
        let externalDependencies = try manifest.externalDependencies.mapValues { targetDependencies in
            try targetDependencies.flatMap { targetDependencyManifest in
                try TuistGraph.TargetDependency.from(
                    manifest: targetDependencyManifest,
                    generatorPaths: GeneratorPaths(manifestDirectory: path),
                    externalDependencies: [:] // externalDependencies manifest can't contain other external dependencies
                )
            }
        }

        return .init(
            externalDependencies: externalDependencies,
            externalProjects: try Dictionary(uniqueKeysWithValues: manifest.externalProjects.map { project in
                (
                    AbsolutePath(project.key.pathString),
                    try convert(
                        manifest: project.value,
                        path: path,
                        plugins: .none,
                        externalDependencies: externalDependencies
                    )
                )

            })
        )
    }
}
