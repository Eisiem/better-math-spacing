// Sonda de emisión. En esta fórmula cada + es binario y el único − es prefijo.
#let glyph = $+$.body.func()
#let mode = sys.inputs.at("spaced", default: "no")
#set math.equation(numbering: "(1)", supplement: [Fórmula])
#show math.frac: set text(fill: blue)
#show math.equation: set text(fill: red)

#show glyph.where(text: "z"): it => $q$.body

#show math.equation: eq => {
  if mode == "no" { return eq }
  show glyph.where(text: "+"): op => h(4mm) + (
    if mode == "guard" { math.class("binary", op) } else { op }
  ) + h(4mm)
  show glyph.where(text: "−"): sign => sign + h(4mm)
  eq
}

#math.equation(block: true, alt: "Ejercicio de estructura", $frac(x + y,z) = mat(a + b, sum_(i=1)^n;c_(u + v)^(-w), d)$.body) <estruct>
#context {
  let equations = query(math.equation).filter(it => it.block)
  assert.eq(equations.len(), 1)
  assert.eq(query(<estruct>).len(), 1)
  assert.eq(counter(math.equation).at(<estruct>), (1,))
  assert.eq(equations.first().alt, "Ejercicio de estructura")
}
Referencia @estruct.
