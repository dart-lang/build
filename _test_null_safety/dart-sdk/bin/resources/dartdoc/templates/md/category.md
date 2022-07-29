{{>head}}

{{#self}}
# {{name}} {{kind}}

{{>documentation}}

{{#hasPublicLibraries}}
## Libraries

{{#publicLibrariesSorted}}
{{>library}}

{{/publicLibrariesSorted}}
{{/hasPublicLibraries}}

{{#hasPublicClasses}}
## Classes

{{#publicClassesSorted}}
{{>container}}

{{/publicClassesSorted}}
{{/hasPublicClasses}}

{{#hasPublicMixins}}
## Mixins

{{#publicMixinsSorted}}
{{>container}}

{{/publicMixinsSorted}}
{{/hasPublicMixins}}

{{#hasPublicExtensions}}
## Extensions

{{#publicExtensionsSorted}}
{{>extension}}

{{/publicExtensionsSorted}}
{{/hasPublicExtensions}}

{{#hasPublicConstants}}
## Constants

{{#publicConstantsSorted}}
{{>constant}}

{{/publicConstantsSorted}}
{{/hasPublicConstants}}

{{#hasPublicProperties}}
## Properties

{{#publicPropertiesSorted}}
{{>property}}

{{/publicPropertiesSorted}}
{{/hasPublicProperties}}

{{#hasPublicFunctions}}
## Functions

{{#publicFunctionsSorted}}
{{>callable}}

{{/publicFunctionsSorted}}
{{/hasPublicFunctions}}

{{#hasPublicEnums}}
## Enums

{{#publicEnumsSorted}}
{{>container}}

{{/publicEnumsSorted}}
{{/hasPublicEnums}}

{{#hasPublicTypedefs}}
## Typedefs

{{#publicTypedefsSorted}}
{{>typedef}}

{{/publicTypedefsSorted}}
{{/hasPublicTypedefs}}

{{#hasPublicExceptions}}
## Exceptions / Errors

{{#publicExceptionsSorted}}
{{>container}}

{{/publicExceptionsSorted}}
{{/hasPublicExceptions}}
{{/self}}

{{>footer}}
