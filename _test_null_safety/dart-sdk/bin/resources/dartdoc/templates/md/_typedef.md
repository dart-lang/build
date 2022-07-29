{{#isCallable}}
  {{#asCallable}}
    ##### {{{linkedName}}}{{{linkedGenericParameters}}} = {{{modelType.linkedName}}}
    {{>categorization}}

    {{{ oneLineDoc }}}  {{!two spaces intentional}}
    {{>features}}
  {{/asCallable}}
{{/isCallable}}
{{^isCallable}}
  {{>type}}
{{/isCallable}}
