{{>head}}

{{#self}}
# {{{ name }}} {{ kind }}

{{>source_link}}
{{>categorization}}
{{>feature_set}}
{{/self}}

{{#library}}
{{>documentation}}
{{/library}}

{{#library.hasPublicClasses}}
## Classes

{{#library.publicClassesSorted}}
{{>container}}

{{/library.publicClassesSorted}}
{{/library.hasPublicClasses}}

{{#library.hasPublicMixins}}
## Mixins

{{#library.publicMixinsSorted}}
{{>container}}

{{/library.publicMixinsSorted}}
{{/library.hasPublicMixins}}

{{#library.hasPublicExtensions}}
## Extensions

{{#library.publicExtensionsSorted}}
{{>extension}}

{{/library.publicExtensionsSorted}}
{{/library.hasPublicExtensions}}

{{#library.hasPublicConstants}}
## Constants

{{#library.publicConstantsSorted}}
{{>constant}}

{{/library.publicConstantsSorted}}
{{/library.hasPublicConstants}}

{{#library.hasPublicProperties}}
## Properties

{{#library.publicPropertiesSorted}}
{{>property}}

{{/library.publicPropertiesSorted}}
{{/library.hasPublicProperties}}

{{#library.hasPublicFunctions}}
## Functions

{{#library.publicFunctionsSorted}}
{{>callable}}

{{/library.publicFunctionsSorted}}
{{/library.hasPublicFunctions}}

{{#library.hasPublicEnums}}
## Enums

{{#library.publicEnumsSorted}}
{{>container}}

{{/library.publicEnumsSorted}}
{{/library.hasPublicEnums}}

{{#library.hasPublicTypedefs}}
## Typedefs

{{#library.publicTypedefsSorted}}
{{>typedef}}

{{/library.publicTypedefsSorted}}
{{/library.hasPublicTypedefs}}

{{#library.hasPublicExceptions}}
## Exceptions / Errors

{{#library.publicExceptionsSorted}}
{{>container}}

{{/library.publicExceptionsSorted}}
{{/library.hasPublicExceptions}}

{{>footer}}
