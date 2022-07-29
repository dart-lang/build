{{>head}}

{{#self}}
# {{name}} {{kind}}

{{>source_link}}
{{>feature_set}}
{{/self}}

{{#self}}
{{#hasNoGetterSetter}}
{{{ modelType.linkedName }}} {{>name_summary}}  {{!two spaces intentional}}
{{>features}}

{{>documentation}}

{{>source_code}}
{{/hasNoGetterSetter}}

{{#hasGetterOrSetter}}
{{#hasGetter}}
{{>accessor_getter}}
{{/hasGetter}}

{{#hasSetter}}
{{>accessor_setter}}
{{/hasSetter}}
{{/hasGetterOrSetter}}
{{/self}}

{{>footer}}
