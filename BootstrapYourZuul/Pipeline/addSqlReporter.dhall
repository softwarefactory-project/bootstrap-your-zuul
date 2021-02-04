let Zuul = (../../imports.dhall).Zuul

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

in  addSqlReporter
