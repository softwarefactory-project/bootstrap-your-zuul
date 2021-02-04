let Zuul = (../../imports.dhall).Zuul

let Connection = ../Connection/package.dhall

let --| Best practice post trigger
    postTrigger =
      \(connection : Connection.Type) ->
        merge
          { Gerrit =
              \(name : Text) ->
                Zuul.Pipeline.Trigger.gerrit
                  [ Zuul.Pipeline.Trigger.Gerrit::{
                    , event = [ Zuul.Pipeline.Trigger.Gerrit.Event.ref-updated ]
                    , ref = Some [ "^refs/heads/.*\$" ]
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

let post =
      \(connections : List Connection.Type) ->
        let trigger = Connection.map Zuul.Pipeline.Trigger.Type

        in  Zuul.Pipeline::{
            , name = "post"
            , description = Some
                "This pipeline runs jobs that operate after each change is merged."
            , manager = Zuul.Pipeline.Manager.supercedent
            , precedence = Some Zuul.Pipeline.high
            , post-review = Some True
            , trigger = Some (trigger postTrigger connections)
            }

in  post
