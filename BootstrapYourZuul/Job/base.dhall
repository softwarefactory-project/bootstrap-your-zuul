let Zuul = (../../imports.dhall).Zuul

let base =
      \(zuul-jobs : Text) ->
        Zuul.Job::{
        , name = "base"
        , parent = Some "null"
        , description = Some "The base job."
        , pre-run = Some [ "playbooks/base/pre.yaml" ]
        , post-run = Some [ "playbooks/base/post.yaml" ]
        , roles = Some [ { zuul = zuul-jobs } ]
        , extra-vars = Some
            (Zuul.Vars.mapBool (toMap { zuul_use_fetch_output = True }))
        }

in  base
