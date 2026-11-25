#import "edges.typ": apply
#import "policies.typ": samples, four-mm, hierarchy

#set text(size: 12pt)
#show math.equation: set text(font: "New Computer Modern Math")
#let changed(eq, policy) = {
  show math.equation: it => apply(it, policy)
  eq
}
#let close(x, y) = assert(calc.abs(x - y) < 0.001pt, message: repr((x, y)))
#let width(body) = measure(body).width
#context {
  let w(i) = {
    let s = samples.at(i)
    width(changed(s.eq, s.policy))
  }
  // Testigos explícitos e independientes para cada posición afectada.
  close(w(0), width($a#h(4mm)class("binary", +)#h(4mm)b#h(4mm)class("binary", -)#h(4mm)c$))
  close(w(1), width($a + #h(0.65em) -b$))
  close(w(2), width(samples.at(2).eq))
  // Cuatro fronteras con relación (5/18 em) y una grande-ordinario (1/6 em).
  close(w(3) - width(samples.at(3).eq), 12pt * (4 * 5/18 + 1/6))
  close(w(4), width($a => b$))
  close(w(5), width($a = b #h(0.6em) => #h(0.6em) c$))
  close(w(6), width($(a#h(0.12em)class("binary", +)#h(0.12em)b,#h(0.75em)c#h(0.12em)class("binary", +)#h(0.12em)d)$))
  close(w(7), width($-#h(0.08em)a#h(0.35em)class("binary", -)#h(0.35em)b$))
  // La sonda plana se abstiene al encontrar una frontera explícita o caja.
  for eq in ($a #h(2mm) + b$, $a + #box[?]$, $a &+ b$, $a + b \ c$) {
    assert.eq(apply(eq, four-mm), eq)
  }
  assert.eq(apply($a => b$, hierarchy), $a => b$)
}

#set math.equation(numbering: "(1)", supplement: [Fórmula], alt: "Suma")
#show math.equation: eq => apply(eq, four-mm)
#show "+": set text(fill: red)
$ a + b $ <primera>
$ c + d $ <segunda>
@primera, @segunda.
#context {
  assert.eq(query(math.equation).len(), 2)
  for (i, lbl) in (<primera>, <segunda>).enumerate() {
    let hit = query(lbl)
    assert.eq(hit.len(), 1)
    assert.eq(hit.first().body, ($a + b$.body, $c + d$.body).at(i))
    assert.eq(hit.first().alt, "Suma")
    assert.eq(counter(math.equation).at(lbl), (i + 1,))
  }
}
