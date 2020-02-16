import Basic
import Foundation
import TuistCore
import TuistSupport
import XcodeProj

protocol DerivedFileGenerating {
    /// Generates the derived files that are associated to the given project.
    ///
    /// - Parameters:
    ///   - graph: The dependencies graph.
    ///   - project: Project whose derived files will be generated.
    ///   - sourceRootPath: Path to the directory in which the Xcode project will be generated.
    /// - Throws: An error if the generation of the derived files errors.
    /// - Returns: A project that might have got mutated after the generation of derived files, and a
    ///     function to be called after the project generation to delete the derived files that are not necessary anymore.
    func generate(graph: Graphing, project: Project, sourceRootPath: AbsolutePath) throws -> (Project, () throws -> Void)
    func generateSideEffects(graph: Graphing, project: Project, sourceRootPath: AbsolutePath) throws -> (Project, [GeneratedSideEffect])
}

final class DerivedFileGenerator: DerivedFileGenerating {
    fileprivate static let derivedFolderName = "Derived"
    fileprivate static let infoPlistsFolderName = "InfoPlists"

    struct Transformation {
        var project: Project
        var sideEffects: [GeneratedSideEffect]
    }

    /// Info.plist content provider.
    let infoPlistContentProvider: InfoPlistContentProviding

    /// Initializes the generator with its attributes.
    ///
    /// - Parameters:
    ///   - infoPlistContentProvider: Info.plist content provider.
    init(infoPlistContentProvider: InfoPlistContentProviding = InfoPlistContentProvider()) {
        self.infoPlistContentProvider = infoPlistContentProvider
    }

    func generate(graph: Graphing, project: Project, sourceRootPath: AbsolutePath) throws -> (Project, () throws -> Void) {
        let transformation = try generateInfoPlists(graph: graph, project: project, sourceRootPath: sourceRootPath)
        let createFiles = transformation.sideEffects.filter(\.isCreateFile)
        let process = DerivedFileGenerator.process
        try createFiles.forEach(process)

        let deletions = transformation.sideEffects.filter(\.isDeleteFile)
        return (transformation.project, {
            try deletions.forEach(process)
        })
    }

    func generateSideEffects(graph: Graphing, project: Project, sourceRootPath: AbsolutePath) throws -> (Project, [GeneratedSideEffect]) {
        let transformation = try generateInfoPlists(graph: graph, project: project, sourceRootPath: sourceRootPath)

        return (transformation.project, transformation.sideEffects)
    }

    /// Genreates the Info.plist files.
    ///
    /// - Parameters:
    ///   - graph: The dependencies graph.
    ///   - project: Project that contains the targets whose Info.plist files will be generated.
    ///   - sourceRootPath: Path to the directory in which the project is getting generated.
    /// - Returns: A set with paths to the Info.plist files that are no longer necessary and therefore need to be removed.
    /// - Throws: An error if the encoding of the Info.plist content fails.
    func generateInfoPlists(graph: Graphing, project: Project, sourceRootPath: AbsolutePath) throws -> Transformation {
        let targetsWithGeneratableInfoPlists = project.targets.filter {
            if let infoPlist = $0.infoPlist, case InfoPlist.file = infoPlist {
                return false
            }
            return true
        }

        // Getting the Info.plist files that need to be deleted
        let glob = "\(DerivedFileGenerator.derivedFolderName)/\(DerivedFileGenerator.infoPlistsFolderName)/*.plist"
        let existing = FileHandler.shared.glob(sourceRootPath, glob: glob)
        let new: [AbsolutePath] = targetsWithGeneratableInfoPlists.map {
            DerivedFileGenerator.infoPlistPath(target: $0, sourceRootPath: sourceRootPath)
        }
        let toDelete = Set(existing).subtracting(new)

        let deletions = toDelete.map {
            GeneratedSideEffect.delete($0)
        }

        // Generate the Info.plist
        let transformation = try project.targets.map { (target) -> (Target, [GeneratedSideEffect]) in
            guard targetsWithGeneratableInfoPlists.contains(target),
                let infoPlist = target.infoPlist else {
                return (target, [])
            }

            guard let dictionary = infoPlistDictionary(infoPlist: infoPlist,
                                                       project: project,
                                                       target: target,
                                                       graph: graph) else {
                return (target, [])
            }

            let path = DerivedFileGenerator.infoPlistPath(target: target, sourceRootPath: sourceRootPath)

            let data = try PropertyListSerialization.data(fromPropertyList: dictionary,
                                                          format: .xml,
                                                          options: 0)

            let sideEffet = GeneratedSideEffect.file(GeneratedFile(path: path, contents: data))

            // Override the Info.plist value to point to te generated one
            return (target.with(infoPlist: InfoPlist.file(path: path)), [sideEffet])
        }

        return Transformation(project: project.with(targets: transformation.map { $0.0 }),
                              sideEffects: deletions + transformation.flatMap { $0.1 })
    }

    private func infoPlistDictionary(infoPlist: InfoPlist,
                                     project: Project,
                                     target: Target,
                                     graph: Graphing) -> [String: Any]? {
        switch infoPlist {
        case let .dictionary(content):
            return content.mapValues { $0.value }
        case let .extendingDefault(extended):
            if let content = infoPlistContentProvider.content(graph: graph,
                                                              project: project,
                                                              target: target,
                                                              extendedWith: extended) {
                return content
            }
            return nil
        default:
            return nil
        }
    }

    private static func process(sideEffect: GeneratedSideEffect) throws {
        switch sideEffect {
        case let .file(file):
            try FileHandler.shared.createFolder(file.path.parentDirectory)
            try file.contents.write(to: file.path.url)
        case let .delete(path):
            try FileHandler.shared.delete(path)
        default:
            break
        }
    }

    /// Returns the path to the directory that contains all the derived files.
    ///
    /// - Parameter sourceRootPath: Directory where the project will be generated.
    /// - Returns: Path to the directory that contains all the derived files.
    static func path(sourceRootPath: AbsolutePath) -> AbsolutePath {
        sourceRootPath
            .appending(component: DerivedFileGenerator.derivedFolderName)
    }

    /// Returns the path to the directory where all generated Info.plist files will be.
    ///
    /// - Parameter sourceRootPath: Directory where the Xcode project gets genreated.
    /// - Returns: The path to the directory where all the Info.plist files will be generated.
    static func infoPlistsPath(sourceRootPath: AbsolutePath) -> AbsolutePath {
        path(sourceRootPath: sourceRootPath)
            .appending(component: DerivedFileGenerator.infoPlistsFolderName)
    }

    /// Returns the path where the derived Info.plist is generated.
    ///
    /// - Parameters:
    ///   - target: The target the InfoPlist belongs to.
    ///   - sourceRootPath: The directory where the Xcode project will be generated.
    /// - Returns: The path where the derived Info.plist is generated.
    static func infoPlistPath(target: Target, sourceRootPath: AbsolutePath) -> AbsolutePath {
        infoPlistsPath(sourceRootPath: sourceRootPath)
            .appending(component: "\(target.name).plist")
    }
}

private extension GeneratedSideEffect {
    var isCreateFile: Bool {
        switch self {
        case .file: return true
        default: return false
        }
    }

    var isDeleteFile: Bool {
        switch self {
        case .delete: return true
        default: return false
        }
    }
}
