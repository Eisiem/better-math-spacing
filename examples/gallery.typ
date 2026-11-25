#import "../lib.typ": spacing
#import "profiles.typ": profiles

#let columns = (
  ("native", "Nativo"),
  ("compact", "Compacto"),
  ("hierarchical", "Jerárquico"),
  ("adaptive", "Adaptativo"),
  ("wide", "Amplio"),
)
#let samples = (
  ("Signos y precedencia", $-a + b - (-c)$),
  ("Tupla de sumas", $(a+b, c+d, e-f)$),
  ("Implicación", $a+b = c => c > 0$),
  ("Matriz por vector", $A x = mat(a+b,-c;d,e-f) vec(x_1,x_2)$),
  ("Identidad del paralelogramo", $norm(u+v)^2 + norm(u-v)^2 = 2 norm(u)^2 + 2 norm(v)^2$),
  ("Cociente incremental", $f'(x) = lim_(h -> 0) (f(x+h)-f(x))/h$),
  ("Serie geométrica", $sum_(k=0)^n r^k = (1-r^(n+1))/(1-r)$),
  ("Suma de Riemann", $S_n = (b-a)/n sum_(i=1)^n f(a + i (b-a)/n)$),
)
#let ink = rgb("#1a3039")
#let muted = rgb("#4f646c")
#let teal = rgb("#cce5e4")
#set page(width: 397mm, height: auto, margin: (x: 13mm, y: 9mm), fill: white)
#set text(font: "Libertinus Serif", size: 10pt, fill: ink, lang: "es")

#text(size: 23pt, weight: "bold")[Cinco perfiles de espaciado matemático]
#v(2pt)
#text(fill: muted)[La misma ecuación se repite en cada fila para comparar los cambios entre operadores.]
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
  table.header([*Ecuación*], ..columns.map(it => strong(it.last()))),
  ..samples.map(((title, eq)) => (
    table.cell(align: left + horizon, text(weight: "semibold", title)),
    ..columns.map(it => adjusted(eq, it.first())),
  )).flatten(),
)
#v(7pt)
#text(size: 9pt, fill: muted)[
  Compacto aplica 65 % del espacio estimado. Jerárquico amplía los operadores según las familias presentes.
  Adaptativo responde a la densidad, los separadores y la profundidad. Amplio aplica 160 %.
]
