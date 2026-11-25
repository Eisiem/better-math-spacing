#let seq = $a+b$.body.func()
#let glyph = $a$.body.func()
#let blank = [ ].func()
#let align-point = $&$.body.func()
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

#let atom(n, index, c, previous, groups, expose-node: true, continuation: false) = {
  let kind = n.func()
  let role = if c == "vary" {
    if previous in ("normal", "alphabetic", "closing", "fence") { "binary" } else { "unary" }
  } else if c in ("binary", "unary") { c }
  let a = (node: n, index: index, class: c, role: role)
  if continuation { a.spacing-role = "binary" }
  let names = ()
  let before = none
  let after = none
  for (name, g) in groups {
    let matches = g.members == ()
    for m in g.members {
      if m == c or m == kind or (kind == glyph and type(m) == symbol and n.text == str(m)) {
        matches = true
        break
      }
    }
    if matches and (g.test == none or (g.test)(a)) {
      names.push(name)
      if g.before != none { before = g.before }
      if g.after != none { after = g.after }
    }
  }
  let face = if role == "binary" { "binary" } else { c }
  let l = face
  let r = face
  if kind == math.lr {
    let body = n.body
    if body.func() != seq or body.children.len() == 0 {
      l = none
      r = none
    } else {
      let kids = body.children
      if base-class(kids.first()) in delimiters { l = "opening" }
      if base-class(kids.last()) in delimiters { r = "closing" }
    }
  } else if kind in (math.mat, math.vec) {
    let delimiters = n.at("delim", default: if kind == math.mat { math.mat.delim } else { math.vec.delim })
    if delimiters.first() != none { l = "opening" }
    if delimiters.last() != none { r = "closing" }
  }
  // Static rules only need the element function for the binary pin guard.
  // Dropping the occurrence here lets identical class patterns share an edit plan.
  if not expose-node { a.node = kind }
  a + (groups: names, before: before, after: after, l: l, r: r)
}

// Typst can put transparent sequences inside sequences, e.g. f(x) in a
// numerator. Their edges participate in the same run as the surrounding atoms.
#let flatten(kids) = {
  let flat = ()
  let reserved = ()
  let start = 0
  for (i, kid) in kids.enumerate() {
    if kid.func() != seq { continue }
    if kid.has("label") { return none }
    let nested = flatten(kid.children)
    if nested == none { return none }
    flat += kids.slice(start, i) + nested.flat
    reserved += (kid,) + nested.reserved
    start = i + 1
  }
  (flat: if start == 0 { kids } else { flat + kids.slice(start) }, reserved: reserved)
}

// Alignment markers can escape a nested fence into its parent layout. A
// native or external expansion with unknown markers makes the parity unsafe.
#let known-layout(n) = {
  let f = n.func()
  if f == seq { return n.children.all(known-layout) }
  if f in (math.lr, math.class) { return known-layout(n.body) }
  f in (glyph, blank, text, h, math.primes, math.attach, math.frac, math.root,
    math.mat, math.vec, math.op)
}

// Map the original left atom to the marker. Only the right-aligned half of
// a column pair can absorb a gap without indenting the next column's term.
#let alignment-plan(kids, continuation, collect-attachment) = {
  let anchors = (:)
  let binary = (:)
  if not kids.any(k => k.func() == align-point) { return none }
  let items = kids.enumerate().filter(((_, k)) => k.func() != blank)
  let first-break = items.position(((_, k)) => k.func() == linebreak)
  if (first-break != none and items.slice(first-break + 1).any(((_, k)) => base-class(k) != none)
    and kids.all(k => k.func() in (linebreak, align-point) or known-layout(k))) {
    let row = 0
    let odd = false
    for (i, item) in items.enumerate() {
      let (marker, k) = item
      if k.func() == linebreak { row += 1; odd = false; continue }
      if k.func() != align-point { continue }
      odd = not odd
      if not odd or i == 0 or i + 1 == items.len() { continue }
      let (index, op) = items.at(i - 1)
      if op.func() != glyph { continue }
      let (term-index, term) = items.at(i + 1)
      let attached = term.func() == math.attach
      let base = if attached { term.base } else { term }
      if base.func() not in (glyph, text) { continue }
      let class = base-class(op)
      if (class not in ("vary", "binary", "unary", "relation", "large")
        or base-class(term) not in ("alphabetic", "normal")) { continue }
      // An opaque script can exclude the attachment from the editable runs.
      // Left scripts can offset the base from the column anchor.
      if attached and (term.has("tl") or term.has("bl") or collect-attachment(term, term-index) == none) {
        continue
      }
      anchors.insert(str(index), marker)
      if (continuation != none and class == "vary" and i >= 2
        and items.at(i - 2).last().func() == linebreak
        and continuation((node: op, class: class, role: "unary", index: index, row-index: row))) {
        binary.insert(str(index), true)
      }
    }
  }
  (anchors: anchors, binary: binary)
}

// Collect all selectable lists, including occurrences with an empty edit plan.
// The outer sequence can isolate each compound child in its own show scope.
#let collect(n, path, size, groups, context-needed, rows, singleton: true, across-align: false, continuation: none) = {
  let f = n.func()
  let lists = ()
  if f == seq {
    let runs = ()
    let breaks = ()
    let run = ()
    let fenced = path.len() > 0 and path.last().parent == math.lr
    let flattened = flatten(n.children)
    if flattened == none { return none }
    let plan = if across-align {
      alignment-plan(flattened.flat, continuation, (term, i) =>
        collect(term, path + ((parent: f, field: "children", index: i),), size,
          groups, context-needed, rows, singleton: false))
    }
    if path != () {
      for child in flattened.reserved {
        lists.push((node: child, path: path + ("nested sequence",), size: size, runs: ()))
      }
    }
    let previous = none
    for (i, child) in flattened.flat.enumerate() {
      let kind = child.func()
      if kind == blank { continue }
      let c = if kind == glyph { class-by-glyph.at(child.text, default: none) } else { base-class(child) }
      // Leaves cannot contain a sequence matched by a sibling's recipe.
      // In a deeper compound, abandon the branch if an opaque node could.
      if kind != glyph and kind not in (text, math.primes, h, linebreak, align-point) {
        let nested = collect(child, path + ((parent: f, field: "children", index: i),), size,
          groups, context-needed, rows, singleton: false)
        if nested == none {
          if path != () { return none }
          c = none
        } else { lists += nested }
      }
      if c == none or (previous == auto and c == "vary") {
        if run.len() > 0 { runs.push(run); run = () }
        // Alignment and a nonzero percentage gap are invisible to the
        // native role resolver. A top-level row break starts a new row.
        if rows and kind == linebreak { breaks.push(runs.len()) }
        if kind == align-point or (kind == h and type(child.amount) == ratio and child.amount != 0%) {
          continue
        }
        previous = if (kind == h and type(child.amount) == length) or (kind == linebreak and path == ()) {
          none
        } else if c == "vary" { c } else { auto }
        continue
      }
      let a = atom(child, i, c, previous, groups, expose-node: context-needed,
        continuation: plan != none and plan.binary != (:) and c == "vary" and str(i) in plan.binary)
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
      previous = a.class
    }
    if run.len() > 0 { runs.push(run) }
    // An entirely inaccessible root keeps the original delegation contract.
    if path == () and runs == () and flattened.flat.any(k =>
      k.func() != blank and (k.func() != h or type(k.amount) != length)) { return none }
    let list = (node: n, path: path, size: size, runs: runs)
    if breaks != () { list.breaks = breaks }
    // An extra child in the MathML cell can change the exported operator form.
    if plan != none and plan.anchors != (:) and target() == "paged" { list.anchors = plan.anchors }
    return (list,) + lists
  }
  let c = base-class(n)
  if singleton and context-needed and c != none {
    lists.push((node: n, path: path, size: size, runs: ((atom(n, 0, c, none, groups),),)))
  }
  if f in (glyph, text, math.primes) {
    return if c == none and path == () { none } else { lists }
  }
  let slots = ()
  if f in (math.mat, math.vec) {
    let cells-by-row = if f == math.mat { n.rows } else { n.children.map(x => (x,)) }
    for (row, cells) in cells-by-row.enumerate() {
      for (col, cell) in cells.enumerate() {
        let field = if f == math.mat { "rows" } else { "children" }
        let nested = collect(cell, path + ((parent: f, field: field, row: row, col: col),),
          calc.min(size + 1, 2), groups, context-needed, rows)
        if nested == none { return none }
        lists += nested
      }
    }
  } else if f == math.attach { slots = ("base", "t", "b", "tr", "br", "tl", "bl") }
  else if f == math.frac { slots = ("num", "denom") }
  else if f == math.root { slots = ("radicand", "index") }
  else if f in (math.lr, math.class) { slots = ("body",) }
  else if f == math.mid and n.body.func() == glyph { return if path == () { none } else { () } }
  else if f == math.op and n.text.func() == text { /* Atomic text operator. */ }
  else { return none }
  if f == math.attach and c == none { return none }
  for field in slots {
    let child = n.at(field, default: none)
    if type(child) != content { continue }
    let level = size
    if f == math.attach and field != "base" or field == "index" { level = 2 }
    if f == math.frac {
      level = if n.at("style", default: math.frac.style) == "horizontal" { size }
        else { calc.min(size + 1, 2) }
    }
    let nested = collect(child, path + ((parent: f, field: field),), level, groups, context-needed, rows)
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

#let edits(list, equation, rules, row: none, across: none, initial: auto) = {
  let result = (:)
  if row == auto {
    row = (index: 0, atoms: if list.runs.len() == 1 { list.runs.first() } else { list.runs.join(default: ()) })
  }
  for run in list.runs {
    for (i, pair) in run.windows(2).enumerate() {
      let (l, r) = pair
      let width = if r.before != none { r.before } else if l.after != none { l.after } else { initial }
      if width == auto and rules.len() == 0 { continue }
      let base = if rules != () { native(l.r, r.l, list.size >= 2) }
      let edge = if equation != none {
        (left: l, right: r, index: i, path: list.path, run: run, equation: equation,
          left-class: l.r, right-class: r.l, left-after: l.after, right-before: r.before, native: base)
      }
      if row != none {
        edge.row = row
        edge.aligned = across != none
        if across != none { edge.run = across; edge.index = across.len() - 1 }
      }
      for spec in rules {
        if spec.left != none and spec.left not in l.groups { continue }
        if spec.right != none and spec.right not in r.groups { continue }
        let value = spec.value
        if spec.when != none or type(value) == function {
          edge.width = width
          if spec.when != none and not (spec.when)(edge) { continue }
          if type(value) == function { value = value(edge) }
        }
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
          and (if "fenced" in list { list.fenced } else { list.path != () and list.path.last().parent == math.lr })
      ) { continue }
      let pin = r.class == "vary" and r.role == "binary"
      if pin and (if equation == none { r.node } else { r.node.func() }) != glyph { continue }
      result.insert(str(r.index), (width, pin))
    }
  }
  result
}

// Only sequences with explicit breaks or editable markers need this loop.
// The normal resolver also handles the two-atom bridge. Its output goes
// before the marker and its callback observes the original left run.
#let row-edits(list, rules, equation) = {
  let result = (:)
  let start = 0
  let anchors = list.at("anchors", default: (:))
  for (index, end) in (list.at("breaks", default: ()) + (list.runs.len(),)).enumerate() {
    let runs = list.runs.slice(start, end)
    start = end
    let row = if equation != none { (index: index, atoms: runs.join(default: ())) }
    if anchors == (:) {
      result += edits(list + (runs: runs), equation, rules, row: row)
      continue
    }
    for (j, run) in runs.enumerate() {
      result += edits(list + (runs: (run,)), equation, rules, row: row)
      let marker = anchors.at(str(run.last().index), default: none)
      if marker == none { continue }
      let term = runs.at(j + 1).first()
      let cross = edits(list + (runs: ((run.last(), term),)), equation, rules,
        row: row, across: run, initial: if "spacing-role" in run.last() { math.med.amount } else { auto })
      if cross != (:) { result.insert(str(marker), cross.at(str(term.index))) }
    }
  }
  result
}

// Changes follow the original indices in increasing order. Copy the intervening
// slices intact, including any opaque children or layout markers.
#let emit(kids, changes) = {
  if changes == (:) { return kids }
  let out = ()
  let start = 0
  for (key, change) in changes {
    let i = int(key)
    out += kids.slice(start, i)
    out.push(h(change.first(), weak: false))
    out.push(if change.last() { math.class("binary", kids.at(i)) } else { kids.at(i) })
    start = i + 1
  }
  out + kids.slice(start)
}

// The local selectors use the realized occurrence, including its private fields.
#let apply-plans(node, plans) = {
  let selectors = plans.map(p => seq.where(children: p.kids))
  show selectors.first().or(..selectors.slice(1)): it => {
    let plan = plans.find(p => it.children == p.kids)
    emit(flatten(it.children).flat, plan.changes).join()
  }
  node
}

// Static profiles can reuse a plan for an equal body. A contextual profile
// receives the original equation, including its label, numbering and location.
#let plan(source, block, groups, rules, rows, continuation, contextual) = {
  let body = if contextual { source.body } else { source }
  let lists = collect(body, (), if block { 0 } else { 1 }, groups, contextual, rows != none,
    across-align: rows == "aligned" and block, continuation: continuation)
  if lists == none { return ((:), (:)) }
  let equation = if contextual { (node: source, runs: lists.map(it => it.runs).join(default: ())) }
  if type(rules) == function { rules = rules(equation) }
  for spec in rules {
    for name in (spec.left, spec.right) {
      assert(name == none or name in groups, message: "Unknown spacing group: " + repr(name))
    }
  }
  let outer = body.func() == seq
  let root-edits = (:)
  let scopes = (:)
  for list in lists {
    if list.node.func() != seq { continue }
    let changes = if list.runs == () or (list.runs.len() == 1 and list.runs.first().len() == 1) {
      (:)
    } else if "breaks" in list or "anchors" in list {
      row-edits(list, rules, equation)
    } else {
      let view = if contextual { list } else {
        let fenced = list.runs != () and list.path != () and list.path.last().parent == math.lr
        (runs: list.runs, size: list.size, fenced: fenced)
      }
      edits(view, equation, rules, row: if rows != none and contextual { auto })
    }
    if outer and list.path == () { root-edits = changes; continue }
    let key = if outer { str(list.path.first().index) } else { "body" }
    let plans = scopes.at(key, default: ())
    let kids = list.node.children
    let prior = plans.find(p => p.kids == kids)
    if prior == none {
      plans.push((kids: kids, changes: changes, path: list.path))
      scopes.insert(key, plans)
    } else {
      assert(prior.changes == changes, message: "Conflicting spacing for equal sequences at "
        + repr(prior.path) + " and " + repr(list.path))
    }
  }
  for (key, plans) in scopes {
    let active = plans.filter(p => p.changes != (:))
    if active == () { let _ = scopes.remove(key); continue }
    if active.len() > 1 {
      for p in active {
        let output = emit(flatten(p.kids).flat, p.changes)
        assert(not active.any(other => output == other.kids),
          message: "Spacing replacement matches another active sequence at " + repr(p.path))
      }
    }
    scopes.insert(key, active)
  }
  (root-edits, scopes)
}

#let spacing(eq, groups: (:), rules: (), rows: none, continuation: none) = {
  assert(rows in (none, "context", "aligned"), message: "Expected none, context or aligned for rows")
  assert(continuation == none or (type(continuation) == function and rows == "aligned"),
    message: "continuation requires aligned rows and a predicate")
  if groups == (:) and rules == () and continuation == none { return eq }
  let contextual = type(rules) == function or rules.any(s => s.when != none or type(s.value) == function)
  let (root-edits, scopes) = plan(if contextual { eq } else { eq.body }, eq.block,
    groups, rules, rows, continuation, contextual)
  if root-edits == (:) and scopes == (:) { return eq }
  if eq.body.func() == seq {
    show seq.where(children: eq.body.children): it => {
      let kids = flatten(it.children).flat
      for (key, plans) in scopes {
        let i = int(key)
        kids.at(i) = apply-plans(kids.at(i), plans)
      }
      emit(kids, root-edits).join()
    }
    eq
  } else {
    apply-plans(eq, scopes.body)
  }
}
