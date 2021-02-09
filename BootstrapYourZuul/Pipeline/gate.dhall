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

let failureReporter =
      \(connection : Connection.Type) ->
        merge
          { Gerrit =
              \(name : Text) ->
                Zuul.Pipeline.Reporter.gerrit
                  [ Zuul.Pipeline.Reporter.Gerrit.vote "Verified" -2 ]
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
    gateRequire =
      \(connection : Connection.Type) ->
        let Require = Zuul.Pipeline.Require

        let TODO = Zuul.Pipeline.Require.git

        in  merge
              { Gerrit =
                  \(name : Text) ->
                    Require.gerrit
                      Require.Gerrit::{
                      , open = Some True
                      , current-patchset = Some True
                      , approval = Some
                        [ Require.Gerrit.Approval.vote "Workflow" +1 ]
                      }
              , Pagure = \(name : Text) -> TODO
              , GitHub = \(app : Text) -> TODO
              }
              connection

let gateTrigger =
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
                      [ Gerrit::{
                        , event = [ Gerrit.Event.comment-added ]
                        , approval = Some (toMap { Workflow = +1 })
                        }
                      , Gerrit::{
                        , event = [ Gerrit.Event.comment-added ]
                        , comment = Some [ ./patchsetComment.dhall "reverify" ]
                        }
                      ]
              , Pagure = \(name : Text) -> TODO
              , GitHub = \(app : Text) -> TODO
              }
              connection

let --| TODO: add clean-check toggle
    gate =
      \(connections : List Connection.Type) ->
        let reporter = Connection.map Zuul.Pipeline.Reporter.Type

        in  Zuul.Pipeline::{
            , name = "gate"
            , manager = Zuul.Pipeline.Manager.dependent
            , precedence = Some Zuul.Pipeline.Precedence.high
            , post-review = Some True
            , supercedes = Some "check"
            , require = Some
                ( Connection.map
                    Zuul.Pipeline.Require.Type
                    gateRequire
                    connections
                )
            , trigger = Some
                ( Connection.map
                    Zuul.Pipeline.Trigger.Type
                    gateTrigger
                    connections
                )
            , start = Some (reporter startReporter connections)
            , success = Some (reporter successReporter connections)
            , failure = Some (reporter failureReporter connections)
            }

in  gate
