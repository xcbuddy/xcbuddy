import Foundation
import TSCBasic
import TuistCore
import TuistDependencies
import TuistLoader
import TuistSupport

final class DependenciesUpdateService {
    private let dependenciesController: DependenciesControlling
    private let manifestLoader: ManifestLoading

    init(dependenciesController: DependenciesControlling = DependenciesController(),
         manifestLoader: ManifestLoading = ManifestLoader()) {
        self.dependenciesController = dependenciesController
        self.manifestLoader = manifestLoader
    }

    func run(path: String?) throws {
        logger.notice("Start updating dependencies.")
        
        let path = self.path(path)
        
        let dependencies = try manifestLoader.loadDependencies(at: path).dependencies
        try dependenciesController.install(at: path, method: .update, dependencies: dependencies)
        
        logger.notice("Successfully updated dependencies.", metadata: .success)
    }

    // MARK: - Helpers

    private func path(_ path: String?) -> AbsolutePath {
        if let path = path {
            return AbsolutePath(path, relativeTo: FileHandler.shared.currentPath)
        } else {
            return FileHandler.shared.currentPath
        }
    }
}
