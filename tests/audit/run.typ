#import "corpus.typ": corpus
#import "../../lib.typ": rule, spacing
#import "../../examples/profiles.typ": profiles

#let mode = sys.inputs.at("profile", default: "native")
#let case = sys.inputs.at("case", default: "")
#let count = int(sys.inputs.at("count", default: "0"))
#let unique = sys.inputs.at("unique", default: "false") == "true"
#let check-width = mode == "estimate"
#let apply(eq) = {
  let config = if mode == "admit" {
    (rules: _ => panic("AUDIT: analyzed"),)
  } else if check-width {
    (rules: (rule(e => {
      if e.native == 0pt { auto } else { e.native }
    }),),)
  } else { profiles.at(mode) }
  spacing(eq, ..config)
}
#let workload = sys.inputs.at("workload", default: "false") == "true"
#let format(eq) = {
  if mode == "native" { return eq }
  show math.equation: apply
  eq
}

#set text(size: 12pt)
#set page(width: 240mm, height: 240mm, margin: 11mm)
#let items = if workload { corpus.pairs().filter(pair => pair.first() != "fraction-style") } else if case == "" { corpus.pairs() } else { ((case, corpus.at(case)),) }
#if count > 0 {
  for i in range(count) {
    let eq = items.at(calc.rem(i, items.len())).last()
    if unique { eq = math.equation(eq.body + $(#i)$.body, block: eq.block) }
    format(eq)
    parbreak()
  }
} else {
  for (id, eq) in items {
    if check-width {
      context metadata((id: id, delta: (measure(format(eq)).width - measure(eq).width).pt()))
    }
    [#format(eq)#label("audit-" + id)]
    parbreak()
  }
}
