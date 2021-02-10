let Prelude = (../imports.dhall).Prelude

let Zuul = (../imports.dhall).Zuul

let Pipeline = ./Pipeline/package.dhall

let Job = ./Job/package.dhall

let Playbook = ./Playbook.dhall

let Config = ./Config/package.dhall

let --| TODO: define log settings in the Config
    log-secrets =
      [ "site_sflogs" ]

in  \(config : Config.Type) ->
      { tenant = [ { tenant.name = config.name } ]
      , jobs =
          Zuul.Job.wrap
            [ Job.base config.label (Config.getZuulJobs config) log-secrets ]
      , pipelines =
          let maybeAddReporter =
                merge
                  { None = \(xs : List Zuul.Pipeline.Type) -> xs
                  , Some =
                      \(sql : Text) ->
                        Prelude.List.map
                          Zuul.Pipeline.Type
                          Zuul.Pipeline.Type
                          (Pipeline.addSqlReporter sql)
                  }
                  config.sql

          in  Zuul.Pipeline.wrap
                ( maybeAddReporter
                    [ Pipeline.check config.connections
                    , Pipeline.gate config.connections
                    , Pipeline.post config.connections
                    , Pipeline.promote config.connections
                    ]
                )
      , playbook_pre = Playbook.pre
      , playbook_post = Playbook.post
      }
