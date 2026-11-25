#import "../lib.typ": spacing
#import "profiles.typ": profiles

#let columns = (
  ("native", "Native"),
  ("compact", "Compact"),
  ("hierarchical", "Hierarchical"),
  ("adaptive", "Adaptive"),
  ("wide", "Wide"),
)
#let samples = (
  ("Unary and binary signs", $-a + b - (-c)$),
  ("Tuple of sums", $(a+b, c+d, e-f)$),
  ("Implication", $a+b = c => c > 0$),
  ("Matrix–vector product", $A x = mat(a+b,-c;d,e-f) vec(x_1,x_2)$),
  ("Parallelogram identity", $norm(u+v)^2 + norm(u-v)^2 = 2 norm(u)^2 + 2 norm(v)^2$),
  ("Difference quotient", $f'(x) = lim_(h -> 0) (f(x+h)-f(x))/h$),
  ("Geometric series", $sum_(k=0)^n r^k = (1-r^(n+1))/(1-r)$),
  ("Riemann sum", $S_n = (b-a)/n sum_(i=1)^n f(a + i (b-a)/n)$),
)
#let ink = rgb("#1a3039")
#let muted = rgb("#4f646c")
#let teal = rgb("#cce5e4")
#set page(width: 397mm, height: auto, margin: (x: 13mm, y: 9mm), fill: white)
#set text(font: "Libertinus Serif", size: 10pt, fill: ink, lang: "en")

#text(size: 23pt, weight: "bold")[Five profiles for mathematical spacing]
#v(2pt)
#text(fill: muted)[Each row shows the same equation with five spacing policies.]
#v(10pt)
#let adjusted(eq, key) = {
  if key == "native" { return eq }
  show math.equation: spacing.with(..profiles.at(key))
  eq
}
#table(
  columns: (1fr,) + (2.15fr,) * columns.len(),
  stroke: none, inset: (x: 5pt, y: 9pt), align: center + horizon,
  fill: (x, y) => if y == 0 {teal} else if calc.odd(y) {rgb("#f0f5f6")},
  table.header([*Equation*], ..columns.map(it => strong(it.last()))),
  ..samples.map(((title, eq)) => (
    table.cell(align: left + horizon, text(weight: "semibold", title)),
    ..columns.map(it => adjusted(eq, it.first())),
  )).flatten(),
)
#v(7pt)
#text(size: 9pt, fill: muted)[
  Compact scales estimated native spacing to 65%. Hierarchical widens gaps according to the operator families present.
  Adaptive responds to density, separators and nesting depth. Wide scales estimated native spacing to 160%.
]
