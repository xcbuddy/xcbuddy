import Foundation
import RxBlocking
import RxSwift
import TSCBasic
import TuistCache
import TuistCore
import TuistGenerator
import TuistLoader
import TuistSupport

protocol FocusServiceProjectGeneratorProviding {
    func generator(cache: Bool) -> ProjectGenerating
}

final class FocusServiceProjectGeneratorProvider: FocusServiceProjectGeneratorProviding {
    func generator(cache: Bool) -> ProjectGenerating {
        ProjectGenerator(graphMapperProvider: GraphMapperProvider(cache: cache))
    }
}

enum FocusServiceError: FatalError {
    case cacheWorkspaceNonSupported
    var description: String {
        switch self {
        case .cacheWorkspaceNonSupported:
            return "Caching is only supported when focusing on a project. Please, run the command in a directory that contains a Project.swift file."
        }
    }

    var type: ErrorType {
        switch self {
        case .cacheWorkspaceNonSupported:
            return .abort
        }
    }
}

final class FocusService {
    private let opener: Opening
    private let generatorProvider: FocusServiceProjectGeneratorProviding
    private let manifestLoader: ManifestLoading

    init(manifestLoader: ManifestLoading = ManifestLoader(),
         opener: Opening = Opener(),
         generatorProvider: FocusServiceProjectGeneratorProviding = FocusServiceProjectGeneratorProvider()) {
        self.manifestLoader = manifestLoader
        self.opener = opener
        self.generatorProvider = generatorProvider
    }

    func run(cache: Bool) throws {
        let path = FileHandler.shared.currentPath
        if isWorkspace(path: path), cache {
            throw FocusServiceError.cacheWorkspaceNonSupported
        }
        let generator = generatorProvider.generator(cache: cache)
        let workspacePath = try generator.generate(path: path, projectOnly: false)
        try opener.open(path: workspacePath)
    }

    func isWorkspace(path: AbsolutePath) -> Bool {
        manifestLoader.manifests(at: path).contains(.workspace)
    }
}
