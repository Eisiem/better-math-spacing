#import "../lib.typ": group, rule, spacing

#let logical = (sym.and, sym.or)
#let implications = (sym.arrow.r.double, sym.arrow.l.double, sym.arrow.l.r.double)
#let reserved = (logical + implications).map(str)
#let spacing-role(atom) = atom.at("spacing-role", default: atom.role)
#let heavy(atom) = {
  let node = atom.node
  while node.func() == math.attach { node = node.base }
  node.func() == math.mat or node in ($sum$.body, $product$.body)
}

#let row-profile(minimum: 2pt, multiplier: 2, continuation: none) = {
  let ranks = ("arithmetic", "relations", "logic", "implications")
  let groups = (
    arithmetic: group(sym.plus, sym.minus, sym.times, sym.dot.op, sym.ast.op, sym.div,
      sym.plus.minus, sym.minus.plus, sym.union, sym.inter, sym.without,
      test: a => spacing-role(a) != "unary"),
    relations: group("relation", test: a => a.node.at("text", default: none) not in reserved),
    logic: group(..logical),
    implications: group(..implications),
  )
  let scaled(edge) = {
    // Leave delimiters and punctuation under native spacing rules.
    let guarded = ("opening", "closing", "fence", "punctuation")
    if (edge.left-class in guarded or edge.right-class in guarded
      or "unary" in (spacing-role(edge.left), spacing-role(edge.right))) { return auto }
    let adjacent = edge.left.groups + edge.right.groups
    let rank = ranks.rev().find(name => name in adjacent)
    if rank == none { return auto }
    let present = ranks.filter(name => edge.row.atoms.any(a => name in a.groups))
    let level = present.position(name => name == rank)
    minimum * calc.pow(multiplier, level + int(edge.row.atoms.any(heavy)))
  }
  spacing.with(groups: groups, rules: (rule(scaled),), rows: "aligned", continuation: continuation)
}
