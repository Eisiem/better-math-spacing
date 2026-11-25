#import "../../lib.typ": spacing, rule, group

#let edited = sys.inputs.at("profile", default: "native") == "scoped"
#let signs = (
  binary: group("vary", test: a => a.role == "binary", before: 3pt, after: 4pt),
  unary: group("vary", test: a => a.role == "unary", after: 7pt),
)
// Apply only to the outer display equation. The inline math in the box is
// a separate equation, and must not inherit any selectors from its sibling.
#show math.equation.where(block: true): eq => if edited { spacing(eq, groups: signs) } else { eq }
$ a &+ b \ -c+d $
$ a #h(10%) + b $
$ frac(a+b,c) = #box[$a+b$] + z+w $
$ a+b "when" c+d $
$ a+b bold(c+d) -z+w $
#{
  show $z$.body.func().where(text: "z"): _ => $a+b$.body
  $ frac(a+b,c) = z $
}

#{
  set math.frac(style: "horizontal")
  let eq = $frac(a+b,c) = (a+b)/c$
  let scoped = rule(e => {
    if e.path == () or e.path.last().field != "num" { return auto }
    if e.path.first().index == 0 { 2pt } else { 7pt }
  })
  if edited {
    show math.equation: spacing.with(rules: (scoped,))
    eq
  } else { eq }
}
