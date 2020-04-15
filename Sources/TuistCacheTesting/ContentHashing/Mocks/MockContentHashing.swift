import Foundation
import TuistCache
import Basic

public class MockContentHashing: ContentHashing {
    public init(){}

    public var hashStringStub = ""
    public var hashStringSpy: String?
    public var hashStringCallCount = 0
    public func hash(_ string: String) throws -> String {
        hashStringSpy = string
        hashStringCallCount += 1
        return hashStringStub
    }

    public var hashStringsStub = ""
    public var hashStringsSpy: [String]? = nil
    public var hashStringsCallCount = 0
    public func hash(_ strings: [String]) throws -> String {
        hashStringsSpy = strings
        hashStringsCallCount += 1
        return hashStringsStub
    }

    public var stubHashForPath: [AbsolutePath: String] = [:]
    public var hashFileAtPathCallCount = 0
    public func hash(fileAtPath filePath: AbsolutePath) throws -> String {
        hashFileAtPathCallCount += 1
        return stubHashForPath[filePath] ?? ""
    }
}

