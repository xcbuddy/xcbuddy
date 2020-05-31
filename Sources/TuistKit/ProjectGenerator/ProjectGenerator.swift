import Foundation
import TSCBasic
import TuistCore
import TuistGenerator
import TuistLoader
import TuistSupport

protocol ProjectGenerating {
    @discardableResult
    func generate(path: AbsolutePath, projectOnly: Bool) throws -> AbsolutePath
    func generateWithGraph(path: AbsolutePath, projectOnly: Bool) throws -> (AbsolutePath, Graph)
}

class ProjectGenerator: ProjectGenerating {
    private let recursiveManifestLoader: RecursiveManifestLoading
    private let converter: ManifestModelConverting
    private let manifestLinter: ManifestLinting = ManifestLinter()
    private let graphLinter: GraphLinting = GraphLinter()
    private let environmentLinter: EnvironmentLinting = EnvironmentLinter()
    private let generator: DescriptorGenerating = DescriptorGenerator()
    private let writer: XcodeProjWriting = XcodeProjWriter()
    private let cocoapodsInteractor: CocoaPodsInteracting = CocoaPodsInteractor()
    private let swiftPackageManagerInteractor: SwiftPackageManagerInteracting = SwiftPackageManagerInteractor()
    private let modelLoader: GeneratorModelLoading
    private let graphLoader: GraphLoading
    private let sideEffectDescriptorExecutor: SideEffectDescriptorExecuting
    private let projectMapper: ProjectMapping
    private let graphMapperProvider: GraphMapperProviding
    private let manifestLoader: ManifestLoading

    init(graphMapperProvider: GraphMapperProviding = GraphMapperProvider(useCache: false),
         manifestLoaderFactory: ManifestLoaderFactory = ManifestLoaderFactory()) {
        let manifestLoader = manifestLoaderFactory.createManifestLoader()
        recursiveManifestLoader = RecursiveManifestLoader(manifestLoader: manifestLoader)
        let modelLoader = GeneratorModelLoader(manifestLoader: manifestLoader,
                                               manifestLinter: manifestLinter)
        converter = modelLoader
        graphLoader = GraphLoader(modelLoader: modelLoader)
        sideEffectDescriptorExecutor = SideEffectDescriptorExecutor()
        self.modelLoader = modelLoader
        self.graphMapperProvider = graphMapperProvider
        projectMapper = SequentialProjectMapper(mappers: [])
        self.manifestLoader = manifestLoader
    }

    func generate(path: AbsolutePath, projectOnly: Bool) throws -> AbsolutePath {
        let (generatedPath, _) = try generateWithGraph(path: path, projectOnly: projectOnly)
        return generatedPath
    }

    func generateWithGraph(path: AbsolutePath, projectOnly: Bool) throws -> (AbsolutePath, Graph) {
        let manifests = manifestLoader.manifests(at: path)

        if projectOnly {
            return try generateProject(path: path)
        } else if manifests.contains(.workspace) {
            return try generateWorkspace(path: path)
        } else if manifests.contains(.project) {
            return try generateProjectWorkspace(path: path)
        } else {
            throw ManifestLoaderError.manifestNotFound(path)
        }
    }

    private func generateProject(path: AbsolutePath) throws -> (AbsolutePath, Graph) {
        // Load
        let (project, graph, sideEffects) = try loadProject(path: path)

        // Lint
        try lint(graph: graph)

        // Generate
        let projectDescriptor = try generator.generateProject(project: project, graph: graph)

        // Write
        try writer.write(project: projectDescriptor)

        // Mapper side effects
        try sideEffectDescriptorExecutor.execute(sideEffects: sideEffects)

        // Post Generate Actions
        try postGenerationActions(for: graph, workspaceName: projectDescriptor.xcodeprojPath.basename)

        return (projectDescriptor.xcodeprojPath, graph)
    }

    private func generateWorkspace(path: AbsolutePath) throws -> (AbsolutePath, Graph) {
        // Load
        let (workspace, graph, sideEffects) = try loadWorkspace(path: path)

        // Lint
        try lint(graph: graph)

        // Generate
        let updatedWorkspace = workspace.merging(projects: Array(graph.projects.map { $0.path }))
        let workspaceDescriptor = try generator.generateWorkspace(workspace: updatedWorkspace,
                                                                  graph: graph)

        // Write
        try writer.write(workspace: workspaceDescriptor)

        // Mapper side effects
        try sideEffectDescriptorExecutor.execute(sideEffects: sideEffects)

        // Post Generate Actions
        try postGenerationActions(for: graph, workspaceName: workspaceDescriptor.xcworkspacePath.basename)

        return (workspaceDescriptor.xcworkspacePath, graph)
    }

    private func generateProjectWorkspace(path: AbsolutePath) throws -> (AbsolutePath, Graph) {
        // Load
        let (project, graph, sideEffects) = try loadProject(path: path)

        // Lint
        try lint(graph: graph)

        // Generate
        let workspace = Workspace(path: path, name: project.name, projects: Array(graph.projects.map { $0.path }))
        let workspaceDescriptor = try generator.generateWorkspace(workspace: workspace, graph: graph)

        // Write
        try writer.write(workspace: workspaceDescriptor)

        // Mapper side effects
        try sideEffectDescriptorExecutor.execute(sideEffects: sideEffects)

        // Post Generate Actions
        try postGenerationActions(for: graph, workspaceName: workspaceDescriptor.xcworkspacePath.basename)

        return (workspaceDescriptor.xcworkspacePath, graph)
    }

    private func lint(graph: Graph) throws {
        let config = try graphLoader.loadConfig(path: graph.entryPath)

        try environmentLinter.lint(config: config).printAndThrowIfNeeded()
        try graphLinter.lint(graph: graph).printAndThrowIfNeeded()
    }

    private func postGenerationActions(for graph: Graph, workspaceName: String) throws {
        try swiftPackageManagerInteractor.install(graph: graph, workspaceName: workspaceName)
        try cocoapodsInteractor.install(graph: graph)
    }

    // MARK: -

    private func loadProject(path: AbsolutePath) throws -> (Project, Graph, [SideEffectDescriptor]) {
        // Load all manifests
        let manifests = try recursiveManifestLoader.loadProject(at: path)

        // Lint Manifests
        try manifests.projects.flatMap {
            manifestLinter.lint(project: $0.value)
        }.printAndThrowIfNeeded()

        // Convert to models
        let models = try convert(manifests: manifests)

        // Apply any registered model mappers
        let updatedModels = try models.map(projectMapper.map)
        let updatedProjects = updatedModels.map(\.0)
        let modelMapperSideEffects = updatedModels.flatMap { $0.1 }

        // Load Graph
        let cachedModelLoader = CachedModelLoader(projects: updatedProjects)
        let cachedGraphLoader = GraphLoader(modelLoader: cachedModelLoader)
        let (graph, project) = try cachedGraphLoader.loadProject(path: path)

        // Apply graph mappers
        let config = try graphLoader.loadConfig(path: graph.entryPath)
        let (updatedGraph, graphMapperSideEffects) = try graphMapperProvider.mapper(config: config).map(graph: graph)

        return (project, updatedGraph, modelMapperSideEffects + graphMapperSideEffects)
    }

    private func loadWorkspace(path: AbsolutePath) throws -> (Workspace, Graph, [SideEffectDescriptor]) {
        // Load all manifests
        let manifests = try recursiveManifestLoader.loadWorkspace(at: path)

        // Lint Manifests
        try manifests.projects.flatMap {
            manifestLinter.lint(project: $0.value)
        }.printAndThrowIfNeeded()

        // Convert to models
        let models = try convert(manifests: manifests)

        // Apply model mappers
        let updatedModels = try models.projects.map(projectMapper.map)
        let updatedProjects = updatedModels.map(\.0)
        let modelMapperSideEffects = updatedModels.flatMap { $0.1 }

        // Load Graph
        let cachedModelLoader = CachedModelLoader(workspace: [models.workspace], projects: updatedProjects)
        let cachedGraphLoader = GraphLoader(modelLoader: cachedModelLoader)
        let (graph, workspace) = try cachedGraphLoader.loadWorkspace(path: path)

        // Apply graph mappers
        let config = try graphLoader.loadConfig(path: graph.entryPath)
        let (updatedGraph, graphMapperSideEffects) = try graphMapperProvider.mapper(config: config).map(graph: graph)

        return (workspace, updatedGraph, modelMapperSideEffects + graphMapperSideEffects)
    }

    private func convert(manifests: LoadedProjects,
                         context: ExecutionContext = .concurrent) throws -> [TuistCore.Project] {
        let tuples = manifests.projects.map { (path: $0.key, manifest: $0.value) }
        return try tuples.map(context: context) {
            try converter.convert(manifest: $0.manifest, path: $0.path)
        }
    }

    private func convert(manifests: LoadedWorkspace,
                         context: ExecutionContext = .concurrent) throws -> (workspace: Workspace, projects: [TuistCore.Project]) {
        let workspace = try converter.convert(manifest: manifests.workspace, path: manifests.path)
        let tuples = manifests.projects.map { (path: $0.key, manifest: $0.value) }
        let projects = try tuples.map(context: context) {
            try converter.convert(manifest: $0.manifest, path: $0.path)
        }
        return (workspace, projects)
    }
}
