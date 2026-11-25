#import "../lib.typ": group, rule, spacing
#import "../examples/row-profile.typ": row-profile

#set page(width: 340pt, height: auto, margin: 16pt)
#set text(size: 16pt)
#let kind = $x$.body.func()
#show kind.where(text: "b"): set text(fill: rgb("#236ba3"))
#show kind.where(text: "c"): set text(fill: rgb("#a3236b"))
#show kind.where(text: "p"): set text(fill: rgb("#178459"))
#show kind.where(text: "q"): set text(fill: rgb("#a35f23"))
#show kind.where(text: "+"): set text(fill: rgb("#5f23a3"))

#let samples = (
  leading: $ a = &b \ + &c + d $,
  prefix: $ a = &b \ &+c + d $,
  columns: $ a = &b & a = &p \ + &c & + &q $,
  even: $ a = &b + &p \ d = &c + &q $,
  double: $ a = &&b \ + &&c $,
  explicit: $ a = &b \ + #h(3pt) &c + d $,
  explicit-right: $ a = &b \ + & #h(3pt) c + d $,
  opaque: $ a = &b + #box[?] \ + &c + d $,
  single: $ a + &b $,
  trailing: $ a + &b \ $,
  compound: $ a = &b \ + &frac(c, d) $,
  fenced: $ a = &b \ (c & d) + &c $,
)
#let leading(sign) = {
  assert.eq(sign.row-index, 1)
  assert.eq(sign.role, "unary")
  sign.node == $+$.body
}
#let effective(a) = a.at("spacing-role", default: a.role)
#let mode = sys.inputs.at("profile", default: "native")
#let case = sys.inputs.at("case", default: "leading")
#if case == "nested-width" {
  context {
    let profile(eq) = {
      show math.equation: row-profile()
      eq
    }
    let a = measure(profile($(a+b,c+d)=z$)).width
    let b = measure($(a#h(2pt)class("binary", +)#h(2pt)b,c#h(2pt)class("binary", +)#h(2pt)d)=#h(2pt)z$).width
    assert(calc.abs(a - b) < 0.001pt, message: repr((a, b)))
  }
} else if case == "contexts" {
  assert.eq($xor$.body, $plus.o$.body)
  let probe(e) = {
    assert(e.run in e.equation.runs)
    assert.eq(e.run.at(e.index), e.left)
    if e.path == () {
      if e.row.index == 0 {
        assert(e.row.atoms.len() > e.run.len())
        assert(e.row.atoms.any(a => a.node == $=>$.body))
      } else {
        assert.eq(e.row.index, 1)
        assert(not e.row.atoms.any(a => a.node == $=>$.body))
      }
    } else {
      assert.eq(e.row.index, 0)
      assert(not e.row.atoms.any(a => a.node == $=>$.body))
    }
    if e.aligned {
      if e.left.node == $+$.body {
        assert.eq((e.left.class, e.left.role, e.left.spacing-role), ("vary", "unary", "binary"))
        assert.eq((e.left-class, e.native, e.width), ("vary", 0pt, math.med.amount))
      }
      assert.eq(e.index, e.run.len() - 1)
      assert(e.right not in e.run)
    } else {
      assert.eq(e.run.at(e.index + 1), e.right)
    }
    auto
  }
  let context-only = mode == "context-only"
  show math.equation: spacing.with(rows: if context-only { "context" } else { "aligned" },
    continuation: if not context-only { leading },
    rules: (rule(e => {
      if context-only { assert(not e.aligned); assert.eq(e.left.role, effective(e.left)) }
      probe(e)
    }),))
  $ (a+b, c+d) = &b #h(3pt) c => d \ + &c + d $
} else if case == "rank-geometry" {
  let actual = $ a + b #h(3pt) c = &p => q \ a = &p $
  let reference = $ a #h(2pt) class("binary", +) #h(2pt) b #h(3pt) c #h(4pt) = #h(4pt) &p
    #h(8pt) => #h(8pt) q \ a #h(2pt) = #h(2pt) &p $
  if mode == "reference" { reference } else {
    show math.equation: row-profile()
    actual
  }
} else if case == "corpus" {
  import "audit/corpus.typ": corpus
  for eq in corpus.values() {
    eq
    parbreak()
    { show math.equation: row-profile(); eq }
    parbreak()
  }
} else if case == "profile" {
  show math.equation: it => if mode == "native-control" { it } else { row-profile()(it) }
  $ (a+b, c+d) = &b #h(3pt) c => d \ a + &c + d $
  $ mat(a,b;c,d) + sum_i x_i + product_j y_j = z $
  $ a = b => c quad a and b $
  $ x y + (-z) $
  $ a union b in C and p => q $
  $ frac(a + b = c, d => e) $
  $ a xor b plus.o c $
  $ x + y = (a and b => c) $
} else {
  let eq = samples.at(case)
  if mode == "native" { eq }
  else {
    let signs = (binary: group("vary", after: 9pt, test: a => effective(a) == "binary"),)
    let cross = rule(9pt, when: e => e.aligned and e.left.node == $+$.body
      and (effective(e.left) == "binary" or case != "leading"))
    let selected = mode in ("binary", "groups", "role-only", "cancel", "scale", "large-gap")
    let rules = if mode == "legacy" { (rule(e => {
      assert(e.run in e.equation.runs)
      assert.eq(type(e.left.node), content)
      assert.eq(e.run.at(e.index + 1), e.right)
      assert("row" not in e and "aligned" not in e and "spacing-role" not in e.left)
      auto
    }),) }
      else if mode in ("groups", "role-only") { () }
      else if mode == "cancel" { (rule(auto, when: e => e.aligned),) }
      else if mode == "large-gap" { (rule(40pt, when: e => e.aligned and effective(e.left) != e.left.role),) }
      else if mode == "scale" { (rule(150%, when: e => e.aligned and effective(e.left) != e.left.role),) }
      else { (cross,) }
    show math.equation: spacing.with(
      rows: if mode != "legacy" { "aligned" },
      continuation: if selected { leading },
      groups: if mode == "groups" { signs } else { (:) },
      rules: rules,
    )
    eq
  }
}
