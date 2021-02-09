--| A function to generate a patchset matching comment like `recheck`
\(name : Text) ->
  "(?i)^(Patch Set [0-9]+:)?( [\\w\\\\+-]*)*(\\n\\n)?\\s*${name}"
