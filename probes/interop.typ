// Emission probe. Each plus sign is binary and the minus sign is a prefix.
#let glyph = $+$.body.func()
#let mode = sys.inputs.at("spaced", default: "no")
#set math.equation(numbering: "(1)", supplement: [Equation])
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

#math.equation(block: true, alt: "Structure exercise", $frac(x + y,z) = mat(a + b, sum_(i=1)^n;c_(u + v)^(-w), d)$.body) <structure>
#context {
  let equations = query(math.equation).filter(it => it.block)
  assert.eq(equations.len(), 1)
  assert.eq(query(<structure>).len(), 1)
  assert.eq(counter(math.equation).at(<structure>), (1,))
  assert.eq(equations.first().alt, "Structure exercise")
}
Reference @structure.
