import Foundation
import TuistCore
import TuistGenerator
import TuistLoader
import TuistSigning
import TuistSupport

/// It defines an interface for providing the project mappers to be used for a specific configuration.
protocol ProjectMapperProviding {
    /// Returns a list of mappers to be used for a specific configuration.
    /// - Parameter config: Project's configuration.
    func mapper(config: Config) -> ProjectMapping
}

final class ProjectMapperProvider: ProjectMapperProviding {
    func mapper(config: Config) -> ProjectMapping {
        var mappers: [ProjectMapping] = []

        // Auto-generation of schemes
        if !config.generationOptions.contains(.disableAutogeneratedSchemes) {
            mappers.append(AutogeneratedSchemesProjectMapper())
        }

        // Delete current derived
        mappers.append(DeleteDerivedDirectoryProjectMapper())

        // Namespace generator
        if !config.generationOptions.contains(.disableSynthesizedResourceAccessors) {
            mappers.append(SynthesizedResourceInterfaceProjectMapper())
        }

        // Logfile noise suppression
        if config.generationOptions.contains(.disableShowEnvironmentVarsInScriptPhases) {
            mappers.append(
                TargetProjectMapper(mapper: TargetActionEnvironmentMapper(false))
            )
        }

        // Support for resources in libraries
        mappers.append(ResourcesProjectMapper())

        // Info Plist
        mappers.append(GenerateInfoPlistProjectMapper())

        // Project name and organization
        mappers.append(ProjectNameAndOrganizationMapper(config: config))
        
        // Development region
        mappers.append(ProjectDevelopmentRegionMapper(config: config))

        // Signing
        mappers.append(SigningMapper())

        return SequentialProjectMapper(mappers: mappers)
    }
}
