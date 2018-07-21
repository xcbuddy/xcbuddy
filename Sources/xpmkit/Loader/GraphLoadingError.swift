import Basic
import Foundation
import xpmcore

enum GraphLoadingError: FatalError, Equatable {
    case missingFile(AbsolutePath)
    case targetNotFound(String, AbsolutePath)
    case manifestNotFound(AbsolutePath)
    case circularDependency(GraphCircularDetectorNode, GraphCircularDetectorNode)
    case unexpected(String)

    static func == (lhs: GraphLoadingError, rhs: GraphLoadingError) -> Bool {
        switch (lhs, rhs) {
        case let (.missingFile(lhsPath), .missingFile(rhsPath)):
            return lhsPath == rhsPath
        case let (.targetNotFound(lhsName, lhsPath), .targetNotFound(rhsName, rhsPath)):
            return lhsPath == rhsPath && lhsName == rhsName
        case let (.manifestNotFound(lhsPath), .manifestNotFound(rhsPath)):
            return lhsPath == rhsPath
        case let (.unexpected(lhsMessage), .unexpected(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.circularDependency(lhsFrom, lhsTo), .circularDependency(rhsFrom, rhsTo)):
            return lhsFrom == rhsFrom && lhsTo == rhsTo
        default:
            return false
        }
    }

    var type: ErrorType {
        return .abort
    }

    var description: String {
        switch self {
        case let .manifestNotFound(path):
            return "Couldn't find manifest at path: '\(path.asString)'"
        case let .targetNotFound(targetName, path):
            return "Couldn't find target '\(targetName)' at '\(path.asString)'"
        case let .missingFile(path):
            return "Couldn't find file at path '\(path.asString)'"
        case let .unexpected(message):
            return message
        // swiftlint:disable:next identifier_name
        case let .circularDependency(from, to):
            var message = ""
            message.append("Found circular dependency between the target")
            message.append(" '\(from.name)' at '\(from.path.asString)'")
            message.append(" and the target '\(to.name)' at '\(to.path.asString)'")
            return message
        }
    }
}
