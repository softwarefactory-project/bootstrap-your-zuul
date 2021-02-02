let Prelude = (../imports.dhall).Prelude

let Zuul = (../imports.dhall).Zuul

let Pipeline = ./Pipeline/package.dhall

let Job = ./Job/package.dhall

let Playbook = ./Playbook.dhall

let Config = ./Config/package.dhall

let addSqlReporter =
      \(reporter-name : Text) ->
      \(pipeline : Zuul.Pipeline.Type) ->
        let reporter =
              [ { mapKey = reporter-name
                , mapValue = Zuul.Pipeline.Reporter.sql
                }
              ]

        let addReporter =
              \(reporters : Optional Zuul.Pipeline.Reporter.map) ->
                merge
                  { None = Some reporter
                  , Some =
                      \(reporters : Zuul.Pipeline.Reporter.map) ->
                        Some (reporter # reporters)
                  }
                  reporters

        in      pipeline
            //  { success = addReporter pipeline.success
                , failure = addReporter pipeline.failure
                }

in  \(config : Config.Type) ->
      { tenant = [ { tenant.name = config.name } ]
      , jobs = Zuul.Job.wrap [ Job.base (Config.getZuulJobs config) ]
      , pipelines =
          Zuul.Pipeline.wrap
            ( Prelude.List.map
                Zuul.Pipeline.Type
                Zuul.Pipeline.Type
                (addSqlReporter config.sql)
                [ Pipeline.check config.connections
                , Pipeline.gate config.connections
                ]
            )
      , playbook_pre = Playbook.pre
      , playbook_post = Playbook.post
      }
