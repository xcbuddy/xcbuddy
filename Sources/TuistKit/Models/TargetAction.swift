import Basic
import Foundation
import TuistCore

/// It represents a target script build phase
public struct TargetAction: GraphJSONInitiatable {
    /// Order when the action gets executed.
    ///
    /// - pre: Before the sources and resources build phase.
    /// - post: After the sources and resources build phase.
    enum Order: String {
        case pre
        case post
    }

    /// Name of the build phase when the project gets generated.
    let name: String

    /// Name of the tool to execute. Tuist will look up the tool on the environment's PATH.
    let tool: String?

    /// Path to the script to execute.
    let path: AbsolutePath?

    /// Target action order.
    let order: Order

    /// Arguments that to be passed.
    let arguments: [String]

    // MARK: - GraphJSONInitiatable

    init(json: JSON, projectPath: AbsolutePath, fileHandler _: FileHandling) throws {
        name = try json.get("name")
        order = Order(rawValue: try json.get("order"))!
        arguments = try json.get("arguments")
        if let path: String = try? json.get("path") {
            self.path = AbsolutePath(path, relativeTo: projectPath)
        } else {
            path = nil
        }
        tool = try? json.get("tool")
    }

    /// Returns the shell script that should be used in the target build phase.
    ///
    /// - Parameters:
    ///   - sourceRootPath: Path to the directory where the Xcode project is generated.
    ///   - system: System instance used to obtain the absolute path of the tool.
    /// - Returns: Shell script that should be used in the target build phase.
    /// - Throws: An error if the tool absolute path cannot be obtained.
    func shellScript(sourceRootPath: AbsolutePath,
                     system: Systeming = System()) throws -> String {
        if let path = path {
            return "\(path.relative(to: sourceRootPath).asString) \(arguments.joined(separator: " "))"
        } else {
            return try "\(system.which(tool!).chomp().chuzzle()!) \(arguments.joined(separator: " "))"
        }
    }
}

extension Array where Element == TargetAction {
    var preActions: [TargetAction] {
        return filter({ $0.order == .pre })
    }

    var postActions: [TargetAction] {
        return filter({ $0.order == .post })
    }
}
