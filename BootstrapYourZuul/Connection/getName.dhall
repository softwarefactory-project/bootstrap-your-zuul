let Connection = { Type = ./Type.dhall }

let getName
    : Connection.Type -> Text
    = \(conn : Connection.Type) ->
        merge
          { Gerrit = \(name : Text) -> name
          , Pagure = \(name : Text) -> name
          , GitHub = \(app : Text) -> "github.com"
          }
          conn

in  getName
