#import "edges.typ": apply
#import "policies.typ": samples

#set page(width: 178mm, height: auto, margin: 11mm, fill: white)
#set text(font: "Libertinus Serif", size: 11pt, lang: "es", fill: rgb("#182b34"))
#set par(leading: 0.6em)
#text(size: 19pt, weight: "bold")[Espaciado entre átomos matemáticos]
#v(2pt)
#text(size: 10pt)[La misma ecuación con el espaciado de Typst y con una regla activa.]
#v(8pt)
#let adjusted(s) = {
  show math.equation: eq => apply(eq, s.policy)
  s.eq
}
#table(
  columns: (2.3fr, 1.35fr, 1.7fr), stroke: none,
  inset: (x: 5pt, y: 8pt), align: left + horizon,
  fill: (_, y) => if y == 0 { rgb("#dfedf0") } else if calc.odd(y) { rgb("#f4f7f7") },
  table.header([*Regla*], [*Nativo*], [*Con la regla*]),
  ..samples.map(s => (s.name, s.eq, adjusted(s))).flatten(),
)
