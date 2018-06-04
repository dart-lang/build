# Build.yaml format

A `build.yaml` file is decribed by the [BuildConfig](#buildconfig) object.

This is a more technical doc of the exact build.yaml format, if you would like
to see examples or goal oriented docs you may want to look at the
[build_config/README.md](../build_config/README.md).

## BuildConfig

key | value | default
--- | --- | ---
targets | Map<[TargetKey](#targetkey), [BuildTarget](#buildtarget)> | a single target with the same name as the package
builders | Map<[BuilderKey](#builderkey), [BuilderDefinition](#builderdefinition)> | empty
post_process_builders | Map<[BuilderKey](#builderkey), [PostProcessBuilderDefinition](#postprocessbuilderdefinition)> | empty

## BuildTarget

key | value | default
--- | --- | ---
builders | Map<[BuilderKey](#builderkey), [TargetBuilderConfig](#targetbuilderconfig)> | empty
dependencies | List<[TargetKey](#targetkey)> | all default targets from all dependencies in your pubspec
sources | [InputSet](#inputset) | all whitelisted directories

## BuilderDefinition

key | value | default
--- | --- | ---
builder_factories | List<String> | none
import | String | none
build_extensions | Map<String, List<String>> | none
auto_apply | [AutoApply](#autoapply) | `AutoApply.none`
required_inputs | List<String> | none
runs_before | List<[BuilderKey](#builderkey)> | none
applies_builders | List<[BuilderKey](#builderkey)> | none
is_optional | bool | false
build_to | [BuildTo](#buildto) | `BuildTo.cache`
defaults | [TargetBuilderConfigDefaults](#targetbuilderconfigdefaults) | none

## PostProcessBuilderDefinition

key | value | default
--- | --- | ---
builder_factory | String | none
import | String | none
input_extensions | List<String> | none
defaults | [TargetBuilderConfigDefaults](#targetbuilderconfigdefaults) | none

## InputSet

Note that in addition to the following structure, you can provide a
`List<String>` and that will be inferred to mean the `include` key below.

key | value | default
--- | --- | ---
include | List<String> | `**`
exclude | List<String> | none

## TargetBuilderConfig

key | value | default
--- | --- | ---
enabled | bool | true
generate_for | [InputSet](#inputset) | `**`
options | [BuilderOptions](#builderoptions) | none
dev_options | [BuilderOptions](#builderoptions) | none
release_options | [BuilderOptions](#builderoptions) | none

## TargetBuilderConfigDefaults

key | value | default
--- | --- | ---
generate_for | [InputSet](#inputset) | `**`
options | [BuilderOptions](#builderoptions) | none
dev_options | [BuilderOptions](#builderoptions) | none
release_options | [BuilderOptions](#builderoptions) | none

## AutoApply

value | meaning
--- | ---
none | Doesn't apply by default to any package, must be explicitly enabled.
dependents | Applies to all packages with a direct dependency on this package.
allPackages | Applies to all packages in the graph.
rootPackage | Applies to only the root (application) package.

## BuildTo

value | meaning
--- | ---
cache | Writes all files to the cache directory
source | Writes all files directly to the source directory


## TargetKey

An identifier for a `target`. A target key has two parts, a `package` and a
`name`.

To construct a key, you join the package and name with a `:`, so for instance
the `bar` target in the `foo` package would be referenced like this `foo:bar`.

When referring to targets in the current package, you can omit the package and
start with a `:` instead, so the above example could be shorted to `:bar`.

Additionally, for any target you can omit the target name, and it will be
defaulted to the package name, so `foo` would become `foo:foo`.

There is one additional shorthand, which is the `:$default` target. This refers
to the default target in the current package (which has the same name as the
package).

## BuilderKey

An identifier for a `builder`. A builder has two parts, a `package` and a
`name`.

To construct a key, you join the package and name with a `|`, so for instance
the `bar` builder in the `foo` package would be referenced like this `foo:bar`.

When referring to builders in the current package, you can omit the package and
start with a `|` instead, so the above example could be shorted to `|bar`.

Additionally, for any builder you can omit the target name, and it will be
defaulted to the package name, so `foo` would become `foo|foo`.
