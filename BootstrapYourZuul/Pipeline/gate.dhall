let Zuul = (../../imports.dhall).Zuul

let Connection = ../Connection/package.dhall

let TODO = Zuul.Pipeline.Reporter.sql

let --| Best practice check reporter
    successReporter =
      \(connection : Connection.Type) ->
        merge
          { Gerrit =
              \(name : Text) ->
                Zuul.Pipeline.Reporter.gerrit
                  [ Zuul.Pipeline.Reporter.Gerrit.vote "Verified" +2
                  , Zuul.Pipeline.Reporter.Gerrit.submit
                  ]
          , Pagure = \(name : Text) -> TODO
          , GitHub = \(app : Text) -> TODO
          }
          connection

let gate =
      \(connections : List Connection.Type) ->
        let reporter = Connection.map Zuul.Pipeline.Reporter.Type

        in  Zuul.Pipeline::{
            , name = "gate"
            , manager = Zuul.Pipeline.Manager.dependent
            , precedence = Some Zuul.Pipeline.Precedence.high
            , success = Some (reporter successReporter connections)
            }

in  gate
