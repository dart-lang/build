{{>head}}

# {{ title }}

{{#defaultPackage}}
{{>documentation}}
{{/defaultPackage}}

{{#localPackages}}
{{#isFirstPackage}}
## Libraries
{{/isFirstPackage}}
{{^isFirstPackage}}
## {{name}}
{{/isFirstPackage}}

{{#defaultCategory.publicLibrariesSorted}}
{{>library}}
{{/defaultCategory.publicLibrariesSorted}}

{{#categoriesWithPublicLibraries}}
### Category {{{categoryLabel}}}

{{#publicLibrariesSorted}}
{{>library}}
{{/publicLibrariesSorted}}
{{/categoriesWithPublicLibraries}}
{{/localPackages}}

{{>footer}}
