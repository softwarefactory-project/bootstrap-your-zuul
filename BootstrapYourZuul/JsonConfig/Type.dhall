{ name : Text
, sql : Text
, connections :
    { gerrit : Optional (List Text)
    , pagure : Optional (List Text)
    , github : Optional (List Text)
    }
}
