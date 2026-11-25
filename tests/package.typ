#import "../lib.typ": group, rule, spacing
#set text(size: 12pt)

#let mode = sys.inputs.at("case", default: "checks")
#let signs = (sign: group(sym.plus, sym.minus, before: 4mm, after: 4mm),)
#let render(eq, ..args) = {
  show math.equation: spacing.with(..args)
  eq
}
#let near(x, y) = assert(calc.abs(x - y) < 0.001pt, message: repr((x, y)))
#if mode == "collision" {
  render($frac(a+b,a+b)$, rules: (rule(4pt, when: e => e.path.last().field == "num"),))
} else if mode == "invalid" {
  render($a+b$, groups: (bad: group(sym.plus, after: 10%),))
} else {
  context {
    let width(eq, ..args) = measure(render(eq, ..args)).width
    near(width($a+b$, groups: signs), measure($a#h(4mm)class("binary", +)#h(4mm)b$).width)
    near(width($a+b$, rules: (rule(200%),)), measure($a+b$).width + 2 * math.med.amount.to-absolute())
    near(width($a+b$, rules: (rule(4mm, when: e => e.index == 0),)),
      measure($a#h(4mm)class("binary", +)b$).width)
    near(width($x_(a+b)$, rules: (rule(200%),)), measure($x_(a+b)$).width)
    near(width($a+b$, rules: (rule(3pt), rule(e => e.width + 1pt), rule(200%))),
      measure($a#h(8pt)class("binary", +)#h(8pt)b$).width)
    let sides = (lhs: group(sym.plus, after: 2pt), rhs: group(sym.minus, before: 3pt))
    near(width($a+-b$, groups: sides), measure($a+#h(3pt)-b$).width)
    near(width($a+-b$, groups: sides, rules: (rule(e => e.left-after + e.right-before,
      left: "lhs", right: "rhs"),)), measure($a+#h(5pt)-b$).width)
    near(width($a #h(3pt) + b$, groups: signs), measure($a #h(3pt) + #h(4mm) b$).width)
    let kinds = (compound: group(math.frac, math.mat, after: 5pt),)
    near(width($frac(a,b)x$, groups: kinds), measure($frac(a,b)#h(5pt)x$).width)
    // No editable boundary beside an unknown atom, or across a marker.
    for eq in ($a #box[?] + b$, $a &+ #box[?]$) {
      assert.eq(spacing(eq, groups: signs), eq)
    }
    for eq in ($#box[?] #box[!]$, $mid(|)$, $frac(a+b, #box[$a+b$])$) {
      assert.eq(spacing(eq, rules: _ => panic("opaque scope leaked")), eq)
    }
    near(width($a &+ b$, groups: signs), measure($a &+ #h(4mm)b$).width)
    near(width($a+b \ c$, groups: signs),
      measure($a#h(4mm)class("binary", +)#h(4mm)b \ c$).width)
  }
  set math.equation(numbering: "(1)", alt: "Control fraction")
  set math.frac(style: "horizontal")
  show math.equation: spacing.with(groups: signs)
  show "+": set text(fill: red)
  show $a$.body.func().where(text: "b"): _ => $z$.body
  [$ (a+b)/(a+b) $ <control>]
  [@control]
  context {
    assert.eq(query(math.equation).len(), 1)
    assert.eq(query(<control>).first().alt, "Control fraction")
    assert.eq(counter(math.equation).at(<control>), (1,))
  }
}
