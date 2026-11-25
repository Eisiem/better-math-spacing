// Adjacency probe for a flat sequence or the body of an lr element.
// The policy receives the original run once and returns a function for each boundary.
#let sequence = $a+b$.body.func()
#let glyph = $+$.body.func()
#let space-node = [ ].func()
#let classes = (
  "+": "vary", "−": "vary", "=": "relation", "⇒": "relation",
  "∑": "large", "∏": "large", ",": "punctuation", "(": "opening", ")": "closing",
)

#let describe(node, previous) = {
  let base = if node.func() == math.attach { node.base } else { node }
  if base.func() != glyph { return none }
  let ch = base.text
  let kind = classes.at(ch, default: none)
  if kind == none and ch.match(regex("^[a-z]$")) != none { kind = "alphabetic" }
  if kind == none { return none }
  let role = if kind == "vary" {
    if previous != none and previous.kind in ("alphabetic", "closing") { "binary" } else { "unary" }
  } else { kind }
  (node: node, ch: ch, kind: kind, role: role)
}

#let apply(eq, policy) = {
  let body = eq.body
  if body.func() == math.lr { body = body.body }
  if body.func() != sequence { return eq }
  let atoms = ()
  for child in body.children {
    if child.func() == space-node { continue }
    let atom = describe(child, atoms.at(-1, default: none))
    if atom == none { return eq }
    atoms.push(atom)
  }
  let gap = policy(atoms)
  let output = ()
  let i = 0
  let edited = false
  for child in body.children {
    let current = child
    if child.func() != space-node {
      if i > 0 {
        let width = gap(atoms.at(i - 1), atoms.at(i))
        if width != auto {
          assert.eq(type(width), length)
          output.push(h(width))
          edited = true
          if atoms.at(i).kind == "vary" and atoms.at(i).role == "binary" {
            current = math.class("binary", child)
          }
        }
      }
      i += 1
    }
    output.push(current)
  }
  if not edited { return eq }
  show sequence.where(children: body.children): _ => output.join()
  eq
}
