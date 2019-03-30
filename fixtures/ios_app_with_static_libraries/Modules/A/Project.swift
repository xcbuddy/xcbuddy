import ProjectDescription

let project = Project(name: "A",
                      targets: [
                          Target(name: "A",
                                 platform: .iOS,
                                 product: .staticLibrary,
                                 bundleId: "io.tuist.A",
                                 infoPlist: "Info.plist",
                                 sources: "Sources/**",
                                 dependencies: [
                                     .project(target: "B", path: "../B"),
                                     .library(path: "../prebuilt/C/libC.a",
                                             publicHeaders: "../prebuilt/C",
                                             swiftModuleMap: "../prebuilt/C/C.swiftmodule")
                          ]),
                          Target(name: "ATests",
                                 platform: .iOS,
                                 product: .unitTests,
                                 bundleId: "io.tuist.ATests",
                                 infoPlist: "Tests.plist",
                                 sources: "Tests/**",
                                 dependencies: [
                                     .target(name: "A"),
                          ]),
])
