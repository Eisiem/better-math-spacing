#import "../lib.typ": group, rule, spacing

#let signs = (groups: (signs: group(sym.plus, sym.minus, before: 4mm, after: 4mm)),)
#let roles = (
  binary: group(test: a => a.role == "binary"),
  unary: group(test: a => a.role == "unary"),
)
#let consecutive = (groups: roles, rules: (rule(0.65em, left: "binary", right: "unary"),))
#let doubled = (
  groups: (trigger: group(sym.eq),),
  rules: eq => {
    let surrounded(run) = run.windows(3).any(t =>
      t.first().class == "large" and "trigger" in t.at(1).groups and t.last().class == "large")
    if eq.runs.any(surrounded) { (rule(200%),) } else { () }
  },
)
#let hierarchy = (
  groups: (eq: group(sym.eq), arrow: group(sym.arrow.r.double)),
  rules: (rule(216%, when: e =>
    ("arrow" in e.left.groups or "arrow" in e.right.groups)
      and e.run.any(a => "eq" in a.groups)),),
)
#let commas = (groups: (
  plus: group(sym.plus, before: 0.12em, after: 0.12em),
  comma: group(sym.comma, after: 0.75em),
),)
#let asymmetric = (groups: roles, rules: (
  rule(0.35em, left: "binary"), rule(0.35em, right: "binary"), rule(0.08em, left: "unary"),
))
// Rank depends on the distinct lower-ranked families present in this run.
#let ranks = ("sum", "equal", "implies")
#let ranked = (
  groups: (sum: group(sym.plus), equal: group(sym.eq), implies: group(sym.arrow.r.double)),
  rules: (rule(e => {
    let neighbors = e.left.groups + e.right.groups
    let present = e.run.map(a => a.groups).flatten()
    let rank = ranks.rev().find(name => name in neighbors)
    if rank == none { return auto }
    let lower = ranks.slice(0, ranks.position(name => name == rank))
    100% + 45% * lower.filter(name => name in present).len()
  }),),
)
#let samples = (
  ("Signos a 4 mm", $a + b - c$, signs),
  ("Encuentro de operadores", $a + -b$, consecutive),
  ("Sin el precedente grande", $a = product_j^m x => y$, doubled),
  ("Igualdad entre grandes", $sum_i^n = product_j^m x => y$, doubled),
  ("Implicación aislada", $a => b$, hierarchy),
  ("Jerarquía local", $a = b => c$, hierarchy),
  ("Tupla de sumas", $(a + b, c + d)$, commas),
  ("Prefijo y resta", $-a - b$, asymmetric),
  ("Cociente incremental", $f'(x) = lim_(h -> 0) (f(x+h) - f(x))/h$, asymmetric),
  ("Sistema lineal", $A x = mat(a+b, -c; d, e-f) vec(x_1, x_2)$, asymmetric),
  ("Tres niveles presentes", $a + b = c => c > 0$, ranked),
  ("Media ponderada", $mu = (sum_(i=1)^n w_i x_i)/(sum_(i=1)^n w_i)$, (rules: (rule(165%),),)),
)
#set page(width: 215mm, height: auto, margin: 12mm, fill: white)
#set text(font: "Libertinus Serif", size: 11pt, lang: "es", fill: rgb("#173742"))
#text(size: 22pt, weight: "bold")[Espaciado matemático]
#v(3pt)
#text[Una misma fórmula, dos composiciones · Typst 0.15.1]
#v(8pt)
#let adjusted(eq, config) = {
  show math.equation: spacing.with(..config)
  eq
}
#table(columns: (1fr, 1.45fr, 1.5fr), stroke: none, inset: 7pt,
  align: left + horizon, fill: (_, y) => if y == 0 {rgb("#d8e8e9")} else if calc.odd(y) {rgb("#f4f7f7")},
  table.header([*Configuración*], [*Nativo*], [*Con el paquete*]),
  ..samples.map(((label, eq, config)) => (label, eq, adjusted(eq, config))).flatten(),
)
