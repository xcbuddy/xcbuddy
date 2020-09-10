import ArgumentParser
import Foundation
import GraphViz
import TSCBasic
import TuistGenerator
import TuistLoader
import TuistSupport

/// Command that generates and exports a dot graph from the workspace or project in the current directory.
struct GraphCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "graph",
                             abstract: "Generates a graph from the workspace or project in the current directory")
    }

    @Flag(
        name: [.customShort("t"), .long],
        help: "Skip Test targets during graph rendering."
    )
    var skipTestTargets: Bool = false

    @Flag(
        name: [.customShort("d"), .long],
        help: "Skip external dependencies."
    )
    var skipExternalDependencies: Bool = false

    @Option(
        name: [.customShort("f"), .long],
        help: "Available formats: dot, png"
    )
    var format: GraphFormat = .dot

    @Option(
        name: [.customShort("a"), .customLong("algorithm")],
        help: "Available formats: dot, neato, twopi, circo, fdp, sfddp, patchwork"
    )
    var layoutAlgorithm: GraphViz.LayoutAlgorithm = .dot

    @Flag(
        name: [.customShort("s"), .customLong("simple")],
        help: "Simple graph: disable different shapes and colors"
    )
    var disableStyling: Bool = false

    @Option(
        name: .shortAndLong,
        help: "The path where the graph will be generated."
    )
    var path: String?

    func run() throws {
        try GraphService().run(format: format,
                               layoutAlgorithm: layoutAlgorithm,
                               skipTestTargets: skipTestTargets,
                               skipExternalDependencies: skipExternalDependencies,
                               path: path,
                               disableStyling: disableStyling)
    }
}

enum GraphFormat: String, ExpressibleByArgument {
    case dot, png
}

extension GraphViz.LayoutAlgorithm: ExpressibleByArgument {}
