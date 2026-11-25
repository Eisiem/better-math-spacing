#let seq = $a+b$.body.func()
#let glyph = $a$.body.func()
#let blank = [ ].func()
#let classes = json("math-classes.json")
#let class-by-glyph = {
  let lookup = (:)
  for (class, chars) in classes {
    for ch in chars.codepoints() { lookup.insert(ch, class) }
  }
  lookup
}
#let delimiters = ("opening", "closing", "fence")
#let number = regex("^(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)$")

#let group(..members, before: none, after: none, test: none) = {
  assert(members.named().len() == 0, message: "Unknown group option")
  for m in members.pos() {
    assert(type(m) in (symbol, function) or (type(m) == str and m in classes),
      message: "Expected a symbol, element function, or math class: " + repr(m))
  }
  for width in (before, after) {
    assert(width == none or type(width) == length, message: "Expected a length in pt, mm or em")
  }
  assert(test == none or type(test) == function)
  (members: members.pos(), before: before, after: after, test: test)
}

#let rule(value, left: none, right: none, when: none) = {
  assert(value == auto or type(value) in (length, ratio, function), message: "Invalid spacing rule")
  assert(when == none or type(when) == function)
  (value: value, left: left, right: right, when: when)
}

#let base-class(n) = {
  let f = n.func()
  if f == glyph {
    return class-by-glyph.at(n.text, default: none)
  }
  if f == math.attach { return base-class(n.base) }
  if f == math.class { return n.class }
  if f == math.op { return "large" }
  if f == text and n.text.match(number) != none { return "normal" }
  if f in (math.lr, math.frac, math.mat, math.vec, math.root, math.primes) { return "normal" }
  none
}

#let atom(n, index, previous, groups) = {
  let c = base-class(n)
  let role = if c == "vary" {
    if previous in ("normal", "alphabetic", "closing", "fence") { "binary" } else { "unary" }
  } else if c in ("binary", "unary") { c }
  let a = (node: n, index: index, class: c, role: role)
  let names = ()
  let before = none
  let after = none
  for (name, g) in groups {
    let matches = g.members.len() == 0 or g.members.any(m => {
      if type(m) == symbol { n.func() == glyph and n.text == str(m) }
      else { m == c or m == n.func() }
    })
    if matches and (g.test == none or (g.test)(a)) {
      names.push(name)
      if g.before != none { before = g.before }
      if g.after != none { after = g.after }
    }
  }
  let face = if role == "binary" { "binary" } else { c }
  let l = face
  let r = face
  if n.func() == math.lr {
    let body = n.body
    if body.func() != seq or body.children.len() == 0 {
      l = none
      r = none
    } else {
      let kids = body.children
      if base-class(kids.first()) in delimiters { l = "opening" }
      if base-class(kids.last()) in delimiters { r = "closing" }
    }
  } else if n.func() in (math.mat, math.vec) {
    let delimiters = n.at("delim", default: if n.func() == math.mat { math.mat.delim } else { math.vec.delim })
    if delimiters.first() != none { l = "opening" }
    if delimiters.last() != none { r = "closing" }
  }
  a + (groups: names, before: before, after: after, l: l, r: r)
}

// Typst can put transparent sequences inside sequences, e.g. f(x) in a
// numerator. Their edges participate in the same run as the surrounding atoms.
#let flatten(kids) = {
  let flat = ()
  let reserved = ()
  for kid in kids {
    if kid.func() == seq {
      if kid.has("label") { return none }
      let nested = flatten(kid.children)
      if nested == none { return none }
      flat += nested.flat
      reserved += (kid,) + nested.reserved
    } else { flat.push(kid) }
  }
  (flat: flat, reserved: reserved)
}

// Collect all selectable lists, including occurrences with an empty edit plan.
// An opaque subtree might contain an equal sequence, so abstain for that equation.
#let collect(n, path, size, groups, singleton: true) = {
  let f = n.func()
  let lists = ()
  let descend(child, field, level, ..position) = collect(child,
    path + ((parent: f, field: field, ..position.named()),), level, groups,
    singleton: f != seq)
  if f == seq {
    let runs = ()
    let run = ()
    let fenced = path.len() > 0 and path.last().parent == math.lr
    let flattened = flatten(n.children)
    if flattened == none { return none }
    for child in flattened.reserved {
      lists.push((node: child, path: path + ("nested sequence",), size: size, runs: ()))
    }
    for (i, child) in flattened.flat.enumerate() {
      if child.func() == blank { continue }
      if child.func() == h {
        if type(child.amount) != length { return none }
        if run.len() > 0 { runs.push(run) }
        run = ()
        continue
      }
      let prev = if run.len() > 0 { run.last().class }
      let a = atom(child, i, prev, groups)
      // Typst treats a delimiter at the start of lr as opening even if its
      // glyph is normally closing (e.g. a reversed bracket).
      if fenced and a.class in delimiters {
        if i == 0 {
          a.class = "opening"
          a.r = "opening"
        } else if i == flattened.flat.len() - 1 {
          a.l = "closing"
        }
      }
      run.push(a)
      let nested = descend(child, "children", size, index: i)
      if nested == none { return none }
      lists += nested
    }
    if run.len() > 0 { runs.push(run) }
    return ((node: n, path: path, size: size, runs: runs),) + lists
  }
  if singleton {
    lists.push((node: n, path: path, size: size, runs: ((atom(n, 0, none, groups),),)))
  }
  let slots = ()
  if f in (math.mat, math.vec) {
    let rows = if f == math.mat { n.rows } else { n.children.map(x => (x,)) }
    for (row, cells) in rows.enumerate() {
      for (col, cell) in cells.enumerate() {
        let field = if f == math.mat { "rows" } else { "children" }
        let nested = descend(cell, field, calc.min(size + 1, 2), row: row, col: col)
        if nested == none { return none }
        lists += nested
      }
    }
  } else if f == math.attach { slots = ("base", "t", "b", "tr", "br", "tl", "bl") }
  else if f == math.frac { slots = ("num", "denom") }
  else if f == math.root { slots = ("radicand", "index") }
  else if f in (math.lr, math.class) { slots = ("body",) }
  else if f == math.op and n.text.func() == text { /* Atomic text operator. */ }
  else if f not in (glyph, text, math.primes) { return none }
  if f in (glyph, text, math.attach) and base-class(n) == none { return none }
  for field in slots {
    let child = n.at(field, default: none)
    if type(child) != content { continue }
    let level = size
    if f == math.attach and field != "base" or field == "index" { level = 2 }
    if f == math.frac {
      level = if n.at("style", default: math.frac.style) == "horizontal" { size }
        else { calc.min(size + 1, 2) }
    }
    let nested = descend(child, field, level)
    if nested == none { return none }
    lists += nested
  }
  lists
}

#let native(l, r, script) = {
  if none in (l, r) { return auto }
  if r == "punctuation" { return 0pt }
  if l == "punctuation" and not script { return math.thin.amount }
  if l == "opening" or r == "closing" or (l, r) == ("relation", "relation") { return 0pt }
  if "relation" in (l, r) and not script { return math.thick.amount }
  if "binary" in (l, r) and not script { return math.med.amount }
  if l == "large" and r in ("opening", "fence") { return 0pt }
  if "large" in (l, r) { return math.thin.amount }
  if "fence" in (l, r) { return auto }
  0pt
}

#let edits(list, equation, rules) = {
  let result = (:)
  for run in list.runs {
    for (i, pair) in run.windows(2).enumerate() {
      let (l, r) = pair
      let width = if r.before != none { r.before } else if l.after != none { l.after } else { auto }
      if width == auto and rules.len() == 0 { continue }
      let base = native(l.r, r.l, list.size >= 2)
      let edge = (left: l, right: r, index: i, path: list.path, run: run, equation: equation,
        left-class: l.r, right-class: r.l, left-after: l.after, right-before: r.before, native: base)
      for spec in rules {
        if spec.left != none and spec.left not in l.groups { continue }
        if spec.right != none and spec.right not in r.groups { continue }
        edge.width = width
        if spec.when != none and not (spec.when)(edge) { continue }
        let value = if type(spec.value) == function { (spec.value)(edge) } else { spec.value }
        if type(value) == ratio {
          let basis = if width == auto { base } else { width }
          if basis != auto and value != 100% and (width != auto or basis != 0pt) {
            width = basis * value
          }
        } else { width = value }
        assert(width == auto or type(width) == length, message: "Expected auto or a length from rule")
      }
      if width == auto { continue }
      // In MathML a space before the initial vary in a fenced expression
      // changes the exported operator form. Keep that boundary native.
      if (
        l.index == 0 and l.r == "opening" and r.class == "vary" and r.role == "unary"
          and list.path.len() > 0 and list.path.last().parent == math.lr
      ) { continue }
      let pin = r.class == "vary" and r.role == "binary"
      if pin and r.node.func() != glyph { continue }
      result.insert(str(r.index), (width, pin))
    }
  }
  result
}

#let emit(kids, changes) = {
  let out = ()
  for (i, child) in flatten(kids).flat.enumerate() {
    let change = changes.at(str(i), default: none)
    if change != none {
      out.push(h(change.first(), weak: false))
      if change.last() { child = math.class("binary", child) }
    }
    out.push(child)
  }
  out
}

#let spacing(eq, groups: (:), rules: ()) = {
  if groups == (:) and rules == () { return eq }
  let lists = collect(eq.body, (), if eq.block { 0 } else { 1 }, groups)
  if lists == none { return eq }
  let equation = (node: eq, runs: lists.map(it => it.runs).join(default: ()))
  if type(rules) == function { rules = rules(equation) }
  for spec in rules {
    for name in (spec.left, spec.right) {
      assert(name == none or name in groups, message: "Unknown spacing group: " + repr(name))
    }
  }
  let plans = ()
  for list in lists.filter(it => it.node.func() == seq) {
    let changes = edits(list, equation, rules)
    let kids = list.node.children
    let prior = plans.find(p => p.kids == kids)
    if prior == none {
      plans.push((kids: kids, changes: changes, path: list.path))
    } else {
      assert(prior.changes == changes, message: "Conflicting spacing for equal sequences at "
        + repr(prior.path) + " and " + repr(list.path))
    }
  }
  plans = plans.filter(p => p.changes.len() > 0)
  if plans.len() == 0 { return eq }
  // A replacement must not match another active selector (e.g. an author
  // used exactly the same explicit h in a second branch).
  if plans.len() > 1 {
    for p in plans {
      let output = emit(p.kids, p.changes)
      assert(not plans.any(other => output == other.kids),
        message: "Spacing replacement matches another active sequence at " + repr(p.path))
    }
  }
  let selectors = plans.map(p => seq.where(children: p.kids))
  show selectors.first().or(..selectors.slice(1)): it => {
    let p = plans.find(p => it.children == p.kids)
    emit(it.children, p.changes).join()
  }
  eq
}
