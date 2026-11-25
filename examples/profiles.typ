#import "../lib.typ": group, rule

#let ranked = ("arithmetic", "relation", "logic")
#let hierarchy = (
  arithmetic: group("binary", "vary", test: a => a.role == "binary"),
  relation: group("relation", test: a => a.node not in ($=>$.body, $<=>$.body)),
  logic: group(sym.arrow.r.double, sym.arrow.l.r.double),
)
#let adaptive(eq) = {
  let dense = eq.runs.any(run => run.len() >= 11)
  let nested = eq.runs.len() > 3
  (
    rule(if dense { 78% } else { 108% }),
    rule(0.42em, left: "separator", when: e => e.path.len() <= 2),
    rule(113%, when: e => e.path.len() > 2 and nested and e.native != auto),
    rule(119%, when: e => e.right.role == "binary" and e.path.len() <= 2 and not dense),
  )
}
#let profiles = (
  native: (:),
  compact: (rules: (rule(65%),),),
  hierarchical: (groups: hierarchy, rules: (rule(e => {
    let touches = e.left.groups + e.right.groups
    let rank = ranked.rev().find(name => name in touches)
    if rank == none { return auto }
    let local = e.run.map(a => a.groups).flatten()
    let lower = ranked.slice(0, ranked.position(name => name == rank))
    100% + 45% * lower.filter(name => name in local).len()
  }),)),
  adaptive: (groups: (separator: group(sym.comma),), rules: adaptive),
  wide: (rules: (rule(160%),),),
  // Basic API case used by the audit alongside the contextual profiles.
  basic: (groups: (signs: group(sym.plus, sym.minus, before: 0.32em, after: 0.32em),),),
)
