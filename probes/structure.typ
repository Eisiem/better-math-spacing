// Typst 0.15.1 probe that inserts or removes a known marker in a fixed fixture.
// The original equations contain no author-supplied h(3pt).
#let seq = $x+y$.body.func()
#let sign = $+$.body
#let mark = h(3pt)

#let change(node, undo: false) = {
  let f = node.func()
  let fields = node.fields()
  let original-label = fields.remove("label", default: none)
  let visit(child) = change(child, undo: undo)
  let out = if f == seq {
    let children = ()
    for child in node.children {
      if undo and child == mark { continue }
      if not undo and child == sign { children.push(mark) }
      children.push(visit(child))
    }
    seq(children)
  } else if f == math.frac {
    let num = fields.remove("num")
    let denom = fields.remove("denom")
    math.frac(visit(num), visit(denom), ..fields)
  } else if f == math.mat {
    let rows = fields.remove("rows")
    math.mat(..rows.map(row => row.map(visit)), ..fields)
  } else if f == math.attach {
    let base = fields.remove("base")
    let scripts = (:)
    for (pos, value) in fields {
      scripts.insert(pos, if type(value) == content {visit(value)} else {value})
    }
    math.attach(visit(base), ..scripts)
  } else if f == math.lr {
    let body = fields.remove("body")
    math.lr(visit(body), ..fields)
  } else {
    return node
  }
  if original-label != none { [#out#original-label] } else { out }
}

#let with-label = [#math.frac($a+b$.body, $a-b$.body)<part>]
#let samples = (
  $(a+b)/(c-d)$,
  $frac(style: "skewed", a+b, c-d)$,
  $mat(delim: "[", augment: #1, a+b, c; d, e+f)$,
  $sum_(i=1)^(n+1) x_(i+1)^2$,
  $attach(x, t: a+b, b: i+j, tl: c+d, tr: e+f, bl: g+h, br: k+l)$,
  $lr(size: #130%, ((a+b,c+d), (e+f)/(g+h)))$,
  $a+#with-label$,
  $a #h(1em) + b \ c & = d$,
  $"x+y" + #text(fill: red)[$a+b$]$,
)

#for sample in samples {
  let edited = change(sample.body)
  assert.ne(edited, sample.body)
  assert.eq(change(edited, undo: true), sample.body)
  sample
  h(1em)
  math.equation(edited)
  parbreak()
}

#assert.eq($=>$.body, $⇒$.body)
#assert.eq($-$.body.text, "−")
#assert.ne(sign.func(), symbol)
#assert.ne(sign.func(), $"+"$.body.func())
#assert.eq($12+13$.body.children.first().func(), text)
#assert.eq($a b$.body.children.at(1).func(), [ ].func())
#assert.eq($a^(-b)$.body.t.func(), seq)
#assert.eq($(a+b)/(c-d)$.body, $frac(a+b,c-d)$.body)
#assert.eq(change(with-label).label, <part>)
