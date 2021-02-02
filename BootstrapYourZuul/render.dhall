let Prelude = (../imports.dhall).Prelude

let Zuul = (../imports.dhall).Zuul

let Pipeline = ./Pipeline/package.dhall

let addSqlReporter =
      \(reporter-name : Text) ->
      \(pipeline : Zuul.Pipeline.wrapped) ->
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

        let pipeline = pipeline.pipeline

        in  { pipeline =
                    pipeline
                //  { success = addReporter pipeline.success
                    , failure = addReporter pipeline.failure
                    }
            }

in  \(config : ./Config/Type.dhall) ->
      { tenant = [ { tenant.name = config.name } ]
      , pipelines =
          Prelude.List.map
            Zuul.Pipeline.wrapped
            Zuul.Pipeline.wrapped
            (addSqlReporter config.sql)
            [ { pipeline = Pipeline.check config.connections } ]
      }
