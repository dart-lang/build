{{#isCallable}}
  {{#asCallable}}
    {{#hasAnnotations}}
    {{#annotations}}
    - {{{linkedNameWithParameters}}}
    {{/annotations}}
    {{/hasAnnotations}}

    {{{modelType.returnType.linkedName}}} {{name}}{{{linkedGenericParameters}}} = {{{modelType.linkedName}}}
  {{/asCallable}}
{{/isCallable}}
{{^isCallable}}
  {{>type_multiline}}
{{/isCallable}}
