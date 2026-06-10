load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AyuGramCore",
    module_name = "AyuGramCore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    visibility = [
        "//visibility:public",
    ],
)

swift_library(
    name = "AyuGramCoreTestsLib",
    testonly = True,
    module_name = "AyuGramCoreTests",
    srcs = glob([
        "Tests/**/*.swift",
    ]),
    deps = [
        ":AyuGramCore",
    ],
)

ios_unit_test(
    name = "AyuGramFilterEngineTests",
    bundle_id = "org.telegram.AyuGramFilterEngineTests",
    minimum_os_version = "13.0",
    deps = [
        ":AyuGramCoreTestsLib",
    ],
    visibility = [
        "//visibility:public",
    ],
)
