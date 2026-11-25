#import "../../lib.typ": rule, spacing
#let estimate(eq) = {
  show math.equation: spacing.with(rules: (rule(e => if e.native == 0pt { auto } else { e.native }),))
  eq
}
#set text(size: 12pt)
#let terms = (
  fence-l: $(x,)$,
  fence-r: $lr(bracket.r a+z bracket.l)$,
  fence-swapped: $lr(bracket.r -x bracket.l)$,
  nested-lr: $sum lr(abs(x)) + x$,
  nested-after: $sum lr((a+b)) + x$,
  nested-mat: $sum mat(a,b;c,d)^2 + z$,
  integral-fence: $integral abs(x) d x$,
  optical: $cos x sin y$,
  adjacency: $x | y$,
  script-shift: $x^frac(2+1,a+b)$,
  explicit-style: $x+frac(style: "skewed",sum x,a+b)$,
  bare-symbol: $a ∗ b$,
  class-rel: $x class("relation", !) x$,
  horizontal-multi: $frac(style: "horizontal", a+b,c+d) = frac(style: "horizontal", c+d,a+b)$,
  frac-op: $sum frac(style: "horizontal",a,b) + y$,
)
#context metadata(terms.pairs().map(((k,x)) => {
  let a = measure(x)
  let b = measure(estimate(x))
  (id: k, w: (b.width - a.width).pt(), y: (b.height - a.height).pt())
}))

// A scope set on the equation itself must inform the fraction profile.
#show math.equation: set math.frac(style: "horizontal")
#context {
  let eq = $(a+b)/(c-d)$
  let before = measure(eq)
  let after = measure(estimate(eq))
  metadata((id: "show-set-horizontal", w: (after.width - before.width).pt(),
    y: (after.height - before.height).pt()))
}
