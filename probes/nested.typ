// ¿Puede una condición exterior y una misma transformación alcanzar dos niveles?
#import "edges.typ": sequence, space-node, glyph, describe
#set text(size: 12pt)
// Sólo se prueban el arbitraje inicial y la composición después del filtrado.
#let transform(after, before, rules) = {
  let initial = if before != none { before } else if after != none { after } else { auto }
  rules.fold(initial, (w, r) => {
    if type(r) == function { r((width: w, left-after: after, right-before: before)) }
    else { r }
  })
}
#let twice(e) = if e.width == auto { auto } else { 2 * e.width }
#let add(e) = e.width + 1pt
#assert.eq(transform(7pt, none, (3pt, add, twice)), 8pt)
#assert.eq(transform(7pt, none, (3pt, twice, add)), 7pt)
#assert.eq(transform(2pt, 3pt, ()), 3pt)
#assert.eq(transform(2pt, 3pt, (e => e.left-after + e.right-before,)), 5pt)
#assert.eq(transform(none, none, (twice,)), auto)

#let enabled = sys.inputs.at("spaced", default: "no") == "yes"
#let nested(eq) = {
  let cells = eq.body.children.filter(it => it.func() != space-node)
  // En estas dos muestras el cuarto átomo es siempre un grupo delimitado.
  let prefix = cells.slice(0, 3).map(it => describe(it, none))
  if prefix.map(it => it.kind) != ("large", "relation", "large") { return eq }
  let rules = (twice,)
  let outer = transform(5em / 18, none, rules)
  let inner = transform(4em / 18, none, rules)
  let group = cells.at(3).body
  show glyph.where(text: prefix.at(1).ch): op => h(outer) + op + h(outer)
  show sequence.where(children: group.children): s => {
    let (open, x, op, y, close) = s.children
    (open, x, h(inner), math.class("binary", op), h(inner), y, close).join()
  }
  eq
}
#let formula = $sum_i^n = product_j^m (a+b)$
#let negative = $a = product_j^m (a+b)$
#context {
  let changed = { show math.equation: nested; formula }
  // En texto, dos huecos de relación y dos de binario suman exactamente 1 em.
  assert(calc.abs(measure(changed).width - measure(formula).width - 12pt) < 0.001pt)
  assert.eq(nested(negative), negative)
}
#show math.equation: eq => if enabled { nested(eq) } else { eq }
#formula

#negative
