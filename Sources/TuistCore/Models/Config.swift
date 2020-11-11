import Foundation
import TSCBasic
import TuistSupport

/// This model allows to configure Tuist.
public struct Config: Equatable, Hashable {
    /// Contains options related to the project generation.
    ///
    /// - xcodeProjectName: Name used for the Xcode project
    public enum GenerationOption: Hashable, Equatable {
        case xcodeProjectName(String)
        case organizationName(String)
        case developmentRegion(String)
        case disableAutogeneratedSchemes
        case disableSynthesizedResourceAccessors
        case disableShowEnvironmentVarsInScriptPhases
        case enableCodeCoverage
    }

    /// Generation options.
    public let generationOptions: [GenerationOption]

    /// List of Xcode versions the project or set of projects is compatible with.
    public let compatibleXcodeVersions: CompatibleXcodeVersions

    /// Cloud configuration.
    public let cloud: Cloud?

    /// List of `Plugin`s used to extend Tuist.
    public let plugins: [PluginLocation]

    /// The path of the config file.
    public let path: AbsolutePath?

    /// Returns the default Tuist configuration.
    public static var `default`: Config {
        Config(compatibleXcodeVersions: .all, cloud: nil, plugins: [], generationOptions: [], path: nil)
    }

    /// Initializes the tuist cofiguration.
    ///
    /// - Parameters:
    ///   - compatibleXcodeVersions: List of Xcode versions the project or set of projects is compatible with.
    ///   - cloud: Cloud configuration.
    ///   - plugins: The locations of plugins to use to extend Tuist.
    ///   - generationOptions: Generation options.
    ///   - path: The path of the config file.
    public init(
        compatibleXcodeVersions: CompatibleXcodeVersions,
        cloud: Cloud?,
        plugins: [PluginLocation],
        generationOptions: [GenerationOption],
        path: AbsolutePath?
    ) {
        self.compatibleXcodeVersions = compatibleXcodeVersions
        self.cloud = cloud
        self.plugins = plugins
        self.generationOptions = generationOptions
        self.path = path
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(generationOptions)
        hasher.combine(cloud)
        hasher.combine(plugins)
        hasher.combine(compatibleXcodeVersions)
    }
}
