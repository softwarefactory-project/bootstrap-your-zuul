let Zuul = (../../imports.dhall).Zuul

let Connection = ../Connection/package.dhall

let --| Best practice promote trigger
    promoteTrigger =
      \(connection : Connection.Type) ->
        merge
          { Gerrit =
              \(name : Text) ->
                Zuul.Pipeline.Trigger.gerrit
                  [ Zuul.Pipeline.Trigger.Gerrit::{
                    , event =
                      [ Zuul.Pipeline.Trigger.Gerrit.Event.change-merged ]
                    }
                  ]
          , Pagure =
              \(name : Text) ->
                Zuul.Pipeline.Trigger.pagure
                  ([] : List Zuul.Pipeline.Trigger.Pagure.Type)
          , GitHub =
              \(app : Text) ->
                Zuul.Pipeline.Trigger.github
                  ([] : List Zuul.Pipeline.Trigger.GitHub.Type)
          }
          connection

let --| Best practice promote reporter
    promoteReporter =
      \(connection : Connection.Type) ->
        merge
          { Gerrit =
              \(name : Text) ->
                Zuul.Pipeline.Reporter.gerrit
                  ([] : Zuul.Pipeline.Reporter.Gerrit.Type)
          , Pagure =
              \(name : Text) ->
                Zuul.Pipeline.Reporter.pagure
                  Zuul.Pipeline.Reporter.Pagure.default
          , GitHub =
              \(app : Text) ->
                Zuul.Pipeline.Reporter.github
                  Zuul.Pipeline.Reporter.GitHub.default
          }
          connection

let promote =
      \(connections : List Connection.Type) ->
        let trigger = Connection.map Zuul.Pipeline.Trigger.Type

        let reporter = Connection.map Zuul.Pipeline.Reporter.Type

        in  Zuul.Pipeline::{
            , name = "promote"
            , description = Some
                ''
                This pipeline runs jobs that operate after each change is merged
                in order to promote artifacts generated in the gate
                pipeline.
                ''
            , manager = Zuul.Pipeline.Manager.supercedent
            , precedence = Some Zuul.Pipeline.high
            , post-review = Some True
            , trigger = Some (trigger promoteTrigger connections)
            , success = Some (reporter promoteReporter connections)
            , failure = Some (reporter promoteReporter connections)
            }

in  promote
