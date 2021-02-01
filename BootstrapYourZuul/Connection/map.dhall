--| Helper function to map over a list connection for Pipeline definition
let Prelude = (../../imports.dhall).Prelude

let Connection = { Type = ./Type.dhall, getName = ./getName.dhall }

let map
    : forall (type : Type) ->
      forall (f : Connection.Type -> type) ->
      forall (xs : List Connection.Type) ->
        List { mapKey : Text, mapValue : type }
    = \(valueType : Type) ->
      \(f : Connection.Type -> valueType) ->
        Prelude.List.map
          Connection.Type
          { mapKey : Text, mapValue : valueType }
          ( \(conn : Connection.Type) ->
              { mapKey = Connection.getName conn, mapValue = f conn }
          )

in  map
