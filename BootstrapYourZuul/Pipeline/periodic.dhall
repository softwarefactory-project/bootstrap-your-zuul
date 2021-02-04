let Zuul = (../../imports.dhall).Zuul

let Frequency = ./Frequency/package.dhall

let periodic =
      \(frequency : Frequency.Type) ->
      \(smtp-config : Zuul.Pipeline.Reporter.Smtp.Type) ->
        Zuul.Pipeline::{
        , name = "periodic-${Frequency.show frequency}"
        , manager = Zuul.Pipeline.independent
        , precedence = Some Zuul.Pipeline.low
        , post-review = Some True
        , description = Some
            "Jobs in this queue are triggered ${Frequency.show frequency}"
        , trigger = Some
            ( toMap
                { timer =
                    Zuul.Pipeline.Trigger.timer
                      [ { time = Frequency.time frequency } ]
                }
            )
        , failure = Some
            (toMap { smtp = Zuul.Pipeline.Reporter.smtp smtp-config })
        }

in  periodic
