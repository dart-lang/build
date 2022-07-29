{{>head}}

{{#self}}
# {{{nameWithGenerics}}} {{kind}}

{{>source_link}}
{{>categorization}}
{{>feature_set}}
{{/self}}

{{#clazz}}
{{>documentation}}

{{#hasModifiers}}
{{ >super_chain }}
{{ >interfaces }}
{{ >mixed_in_types }}

{{#hasPublicImplementors}}
**Implementers**

{{#publicImplementorsSorted}}
- {{{linkedName}}}
{{/publicImplementorsSorted}}
{{/hasPublicImplementors}}

{{#hasPotentiallyApplicableExtensions}}
**Available Extensions**

{{#potentiallyApplicableExtensions}}
- {{{linkedName}}}
{{/potentiallyApplicableExtensions}}
{{/hasPotentiallyApplicableExtensions}}

{{ >annotations }}
{{/hasModifiers}}

{{ >constructors }}

{{#hasPublicInstanceFields}}
## Properties

{{#publicInstanceFieldsSorted}}
{{>property}}

{{/publicInstanceFieldsSorted}}
{{/hasPublicInstanceFields}}

{{ >instance_methods }}

{{ >instance_operators }}

{{ >static_properties }}

{{ >static_methods }}

{{ >static_constants }}
{{/clazz}}

{{>footer}}
