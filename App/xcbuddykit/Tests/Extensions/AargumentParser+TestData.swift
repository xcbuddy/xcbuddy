import Foundation
@testable import Utility

extension ArgumentParser {
    static func test(usage: String = "test",
                     overview: String = "overview") -> ArgumentParser {
        return ArgumentParser(usage: usage, overview: overview)
    }
}
