{{ >head }}

{{ #self }}
# {{{ nameWithGenerics }}} {{ kind }}

{{ >source_link }}
{{ >feature_set }}
{{ /self}}

{{ #eNum }}
{{ >documentation }}

{{ #hasModifiers }}
{{ >super_chain }}
{{ >interfaces }}
{{ >mixed_in_types }}

{{ >annotations }}
{{ /hasModifiers }}

{{ >constructors }}

{{ #hasPublicEnumValues }}
## Values

{{ #publicEnumValues }}
{{ >constant }}

{{ /publicEnumValues }}
{{ /hasPublicEnumValues }}

{{ #hasPublicInstanceFields }}
## Properties

{{ #publicInstanceFieldsSorted }}
{{ >property }}

{{ /publicInstanceFieldsSorted }}
{{ /hasPublicInstanceFields }}

{{ >instance_methods }}

{{ >instance_operators }}

{{ >static_properties }}

{{ >static_methods }}

{{ >static_constants }}
{{ /eNum }}

{{ >footer }}
