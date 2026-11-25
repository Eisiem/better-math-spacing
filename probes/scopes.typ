// Two trees with the same public fields, rendered horizontally.
#let slash = $(a+b)/(c-d)$
#let call = $frac(a+b,c-d)$
#assert.eq(slash.body, call.body)
#set math.frac(style: "horizontal")
#let seq = $x+y$.body.func()
#let widen(s) = {
  let (x, op, y) = s.children
  (x, h(3pt), math.class("binary", op), h(3pt), y).join()
}
#let mode = sys.inputs.at("scope", default: "original")
#show math.equation: eq => {
  if mode == "original" { return eq }
  let f = eq.body
  // The numerator selector also matches an equal denominator.
  if f.num == f.denom {
    show seq.where(children: f.num.children): widen
    eq
  } else {
    show seq.where(children: f.num.children): widen
    show seq.where(children: f.denom.children): widen
    eq
  }
}
#slash

#call

#math.equation(math.frac(slash.body.num, slash.body.denom))

#set math.frac(style: "vertical")
$(a+b)/(a+b)$
