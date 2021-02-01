let Zuul = (../../imports.dhall).Zuul

let Connection = ../Connection/package.dhall

let emptyReporter = Zuul.Pipeline.Reporter.sql

let --| Best practice check reporter
    successReporter =
      \(connection : Connection.Type) ->
        merge
          { Gerrit =
              \(name : Text) ->
                Zuul.Pipeline.Reporter.gerrit
                  [ Zuul.Pipeline.Reporter.Gerrit.vote "Verified" +1 ]
          , Pagure = \(name : Text) -> emptyReporter
          , GitHub = \(app : Text) -> emptyReporter
          }
          connection

let check =
      \(connections : List Connection.Type) ->
        let reporter = Connection.map Zuul.Pipeline.Reporter.Type

        in  Zuul.Pipeline::{
            , name = "check"
            , manager = Zuul.Pipeline.Manager.independent
            , success = Some (reporter successReporter connections)
            }

in  check
