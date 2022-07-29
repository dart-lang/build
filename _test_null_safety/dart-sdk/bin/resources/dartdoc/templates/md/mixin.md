{{>head}}

{{#self}}
# {{{nameWithGenerics}}} {{kind}}

{{>source_link}}
{{>categorization}}
{{>feature_set}}
{{/self}}

{{#mixin}}
{{>documentation}}

{{#hasModifiers}}
{{#hasPublicSuperclassConstraints}}
**Superclass Constraints**

{{#publicSuperclassConstraints}}
- {{{linkedName}}}
{{/publicSuperclassConstraints}}
{{/hasPublicSuperclassConstraints}}

{{ >super_chain }}
{{ >interfaces }}

{{#hasPublicImplementors}}
**Mixin Applications**

{{#publicImplementorsSorted}}
- {{{linkedName}}}
{{/publicImplementorsSorted}}
{{/hasPublicImplementors}}

{{ >annotations }}
{{/hasModifiers}}

{{#hasPublicInstanceFields}}
## Properties

{{#publicInstanceFieldsSorted}}
{{>property}}

{{/publicInstanceFieldsSorted}}
{{/hasPublicInstanceFields}}

{{> instance_methods }}

{{ >instance_operators }}

{{ >static_properties }}

{{ >static_methods }}

{{ >static_constants }}
{{/mixin}}

{{>footer}}
