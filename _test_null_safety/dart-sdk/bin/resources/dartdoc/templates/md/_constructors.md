{{ #hasPublicConstructors }}
## Constructors

{{ #publicConstructorsSorted }}
{{{ linkedName }}} ({{{ linkedParams }}})

{{{ oneLineDoc }}}  {{ !two spaces intentional }}
{{ #isConst }}_const_{{ /isConst }} {{ #isFactory }}_factory_{{ /isFactory }}

{{ /publicConstructorsSorted }}
{{ /hasPublicConstructors }}