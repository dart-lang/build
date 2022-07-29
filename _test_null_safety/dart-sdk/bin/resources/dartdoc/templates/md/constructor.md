{{>head}}

{{#self}}
# {{{nameWithGenerics}}} {{kind}}

{{>source_link}}
{{>feature_set}}
{{/self}}

{{#constructor}}
{{#hasAnnotations}}
{{#annotations}}
- {{{linkedNameWithParameters}}}
{{/annotations}}
{{/hasAnnotations}}

{{#isConst}}const{{/isConst}}
{{{nameWithGenerics}}}({{#hasParameters}}{{{linkedParamsLines}}}{{/hasParameters}})

{{>documentation}}

{{>source_code}}

{{/constructor}}

{{>footer}}
