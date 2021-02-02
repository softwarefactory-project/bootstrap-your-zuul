{ name : Text
, sql : Text
, zuul-jobs : Optional Text
, connections :
    { gerrit : Optional (List Text)
    , pagure : Optional (List Text)
    , github : Optional (List Text)
    }
}
