--| An helper function to convert weakly type JsonConfig to Config
-- The Connection.Type variant are too similar and json-to-dhall picks the first one that match
-- To workaround this limitation, the JsonConfig schema defines the connection type as a key,
-- and this function converts the JsonConfig into a Config:
--
-- From:
-- ```yaml
-- connections:
--   gerrit: ["local", "opendev.org"]
-- ```
--
-- To:
-- ```dhall
-- { connections = [Connection.gerrit "local", Connection.gerrit "opendev.org"] }
-- ```
let Prelude = (../../imports.dhall).Prelude

let JsonConfig = { Type = ./Type.dhall }

let Config = ../Config/package.dhall

let Connection = ../Connection/package.dhall

let cmap =
      \(f : Text -> Connection.Type) ->
      \(xs : Optional (List Text)) ->
        merge
          { None = [] : List Connection.Type
          , Some =
              \(xs : List Text) -> Prelude.List.map Text Connection.Type f xs
          }
          xs

let toConfig
    : JsonConfig.Type -> Config.Type
    = \(jsonConfig : JsonConfig.Type) ->
        Config::{
        , name = jsonConfig.name
        , sql = jsonConfig.sql
        , connections =
              cmap Connection.gerrit jsonConfig.connections.gerrit
            # cmap Connection.pagure jsonConfig.connections.pagure
            # cmap Connection.github jsonConfig.connections.github
        }

in  toConfig
