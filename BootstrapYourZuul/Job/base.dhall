let Prelude = (../../imports.dhall).Prelude

let Zuul = (../../imports.dhall).Zuul

let base =
      \(label : Optional Text) ->
      \(zuul-jobs : Text) ->
      \(secrets : List Text) ->
        Zuul.Job::{
        , name = "base"
        , parent = Some "null"
        , description = Some "The base job."
        , pre-run = Some [ "playbooks/base/pre.yaml" ]
        , post-run = Some [ "playbooks/base/post.yaml" ]
        , roles = Some [ { zuul = zuul-jobs } ]
        , nodeset =
            merge
              { None = None Zuul.Nodeset.Union
              , Some =
                  \(label : Text) ->
                    Some
                      ( Zuul.Nodeset.Inline
                          Zuul.Nodeset::{
                          , name = "default"
                          , nodes = [ { name = "worker", label } ]
                          }
                      )
              }
              label
        , timeout = Some 3600
        , secrets = Some
            ( Prelude.List.map
                Text
                Zuul.Job.Secret.Union
                (\(name : Text) -> Zuul.Job.Secret.Name name)
                secrets
            )
        , extra-vars = Some
            (Zuul.Vars.mapBool (toMap { zuul_use_fetch_output = True }))
        }

in  base
