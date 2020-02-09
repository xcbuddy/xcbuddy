import Basic
import Foundation
import TuistCore

protocol StaticProductsGraphLinting {
    func lint(graph: Graphing) -> [LintingIssue]
}

class StaticProductsGraphLinter: StaticProductsGraphLinting {
    func lint(graph: Graphing) -> [LintingIssue] {
        let nodes = graph.entryNodes
        return warnings(in: nodes)
            .sorted()
            .map(lintIssue)
    }

    private func warnings(in nodes: [GraphNode]) -> Set<StaticDependencyWarning> {
        var warnings = Set<StaticDependencyWarning>()
        let cache = Cache()
        nodes.forEach { node in
            // Skip already evaluated nodes
            guard cache.results(for: node) == nil else {
                return
            }
            let results = buildStaticProductsMap(visiting: node,
                                                 cache: cache)
            warnings.formUnion(results.linked.flatMap(staticDependencyWarning))
        }
        return warnings
    }

    private func staticDependencyWarning(staticProduct: GraphNode, linkedBy: Set<TargetNode>) -> [StaticDependencyWarning] {
        // Common dependencies between test bundles and their host apps are automatically omitted
        // during generation - as such those shouldn't be flagged
        //
        // reference: https://github.com/tuist/tuist/pull/664
        let apps: Set<GraphNode> = linkedBy.filter { $0.target.product == .app }
        let hostedTestBundles = linkedBy
            .filter { $0.target.product.testsBundle }
            .filter { $0.dependencies.contains(where: { apps.contains($0) }) }

        let links = linkedBy.subtracting(hostedTestBundles)

        guard links.count > 1 else {
            return []
        }

        let sortedLinks = links.sorted(by: { $0.name < $1.name })
        return [
            .init(staticProduct: staticProduct,
                  linkingNodes: sortedLinks),
        ]
    }

    private func buildStaticProductsMap(visiting node: GraphNode,
                                        cache: Cache) -> StaticProducts {
        if let cachedResult = cache.results(for: node) {
            return cachedResult
        }

        // Collect dependency results traversing the graph (dfs)
        var results = dependencies(for: node).reduce(StaticProducts()) { results, node in
            buildStaticProductsMap(visiting: node, cache: cache).merged(with: results)
        }

        // Static node case
        if nodeIsStaticProduct(node) {
            results.unlinked.insert(node)
            cache.cache(results: results, for: node)
            return results
        }

        // Linking node case
        guard let linkingNode = node as? TargetNode,
            linkingNode.target.canLinkStaticProducts() else {
            return results
        }

        while let staticProduct = results.unlinked.popFirst() {
            results.linked[staticProduct, default: Set()].insert(linkingNode)
        }

        cache.cache(results: results,
                    for: node)

        return results
    }

    private func dependencies(for node: GraphNode) -> [GraphNode] {
        (node as? TargetNode)?.dependencies ?? []
    }

    private func nodeIsStaticProduct(_ node: GraphNode) -> Bool {
        switch node {
        case is PackageProductNode:
            // Swift package products are currently assumed to be static
            return true
        case is LibraryNode:
            return true
        case let targetNode as TargetNode where targetNode.target.product.isStatic:
            return true
        default:
            return false
        }
    }

    private func lintIssue(from warning: StaticDependencyWarning) -> LintingIssue {
        let staticProduct = nodeDescription(warning.staticProduct)
        let names = warning.linkingNodes.map(\.name)
        return LintingIssue(reason: "\(staticProduct) has been linked against \(names), it is a static product so may introduce unwanted side effects.",
                            severity: .warning)
    }

    private func nodeDescription(_ node: GraphNode) -> String {
        switch node {
        case is PackageProductNode:
            return "Package \"\(node.name)\""
        case is LibraryNode:
            return "Library \"\(node.name)\""
        case is TargetNode:
            return "Target \"\(node.name)\""
        default:
            return node.name
        }
    }
}

// MARK: - Helper Types

extension StaticProductsGraphLinter {
    private struct StaticDependencyWarning: Hashable, Comparable, CustomStringConvertible {
        var staticProduct: GraphNode
        var linkingNodes: [TargetNode]

        var description: String {
            "\(staticProduct.name) > \(linkingNodes.map(\.name))"
        }

        static func < (lhs: StaticProductsGraphLinter.StaticDependencyWarning, rhs: StaticProductsGraphLinter.StaticDependencyWarning) -> Bool {
            lhs.description < rhs.description
        }
    }

    private struct StaticProducts {
        var unlinked: Set<GraphNode> = Set()
        var linked: [GraphNode: Set<TargetNode>] = [:]

        func merged(with other: StaticProducts) -> StaticProducts {
            StaticProducts(unlinked: unlinked.union(other.unlinked),
                           linked: linked.merging(other.linked, uniquingKeysWith: { $0.union($1) }))
        }
    }

    private class Cache {
        private var cachedResults: [GraphNode: StaticProducts] = [:]

        func results(for node: GraphNode) -> StaticProducts? {
            cachedResults[node]
        }

        func cache(results: StaticProducts,
                   for node: GraphNode) {
            cachedResults[node] = results
        }
    }
}
