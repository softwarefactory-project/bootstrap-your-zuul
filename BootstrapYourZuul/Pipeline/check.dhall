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
                  [ Zuul.Pipeline.Reporter.Gerrit.vote "Verified" +1 ]
          , Pagure = \(name : Text) -> TODO
          , GitHub = \(app : Text) -> TODO
          }
          connection

let failureReporter =
      \(connection : Connection.Type) ->
        merge
          { Gerrit =
              \(name : Text) ->
                Zuul.Pipeline.Reporter.gerrit
                  [ Zuul.Pipeline.Reporter.Gerrit.vote "Verified" -1 ]
          , Pagure = \(name : Text) -> TODO
          , GitHub = \(app : Text) -> TODO
          }
          connection

let startReporter =
      \(connection : Connection.Type) ->
        merge
          { Gerrit =
              \(name : Text) ->
                Zuul.Pipeline.Reporter.gerrit
                  [ Zuul.Pipeline.Reporter.Gerrit.vote "Verified" +0 ]
          , Pagure = \(name : Text) -> TODO
          , GitHub = \(app : Text) -> TODO
          }
          connection

let --| Best practice check require
    checkRequire =
      \(connection : Connection.Type) ->
        let TODO = Zuul.Pipeline.Require.git

        in  merge
              { Gerrit =
                  \(name : Text) ->
                    Zuul.Pipeline.Require.gerrit
                      Zuul.Pipeline.Require.Gerrit::{
                      , open = Some True
                      , current-patchset = Some True
                      }
              , Pagure = \(name : Text) -> TODO
              , GitHub = \(app : Text) -> TODO
              }
              connection

let checkTrigger =
      \(connection : Connection.Type) ->
        let TODO =
              Zuul.Pipeline.Trigger.git
                ([] : List Zuul.Pipeline.Trigger.Git.Type)

        let Trigger = Zuul.Pipeline.Trigger

        let Gerrit = Trigger.Gerrit

        in  merge
              { Gerrit =
                  \(name : Text) ->
                    Trigger.gerrit
                      [ Gerrit::{ event = [ Gerrit.Event.patchset-created ] }
                      , Gerrit::{ event = [ Gerrit.Event.change-restored ] }
                      , Gerrit::{
                        , event = [ Gerrit.Event.comment-added ]
                        , comment = Some
                          [ "(?i)^(Patch Set [0-9]+:)?( [\\w\\\\+-]*)*(\\n\\n)?\\s*(recheck|reverify)"
                          ]
                        }
                      ]
              , Pagure = \(name : Text) -> TODO
              , GitHub = \(app : Text) -> TODO
              }
              connection

let check =
      \(connections : List Connection.Type) ->
        let reporter = Connection.map Zuul.Pipeline.Reporter.Type

        in  Zuul.Pipeline::{
            , name = "check"
            , manager = Zuul.Pipeline.Manager.independent
            , require = Some
                ( Connection.map
                    Zuul.Pipeline.Require.Type
                    checkRequire
                    connections
                )
            , trigger = Some
                ( Connection.map
                    Zuul.Pipeline.Trigger.Type
                    checkTrigger
                    connections
                )
            , start = Some (reporter startReporter connections)
            , success = Some (reporter successReporter connections)
            , failure = Some (reporter failureReporter connections)
            }

in  check
