// Two equal public numerators in different siblings. A local recipe on each
// original sibling keeps its private fraction data and delimits its selectors.
#let selector = $a+b$.body.func()
#let formula = $frac(style: "horizontal", a+b, c-d) = (a+b)/(c-d)$
#let with-gap(node, width) = {
  show selector.where(children: $a+b$.body.children): s => {
    let (a, op, b) = s.children
    (a, h(width), math.class("binary", op), h(width), b).join()
  }
  node
}
#formula
#{
  show selector.where(children: formula.body.children): s => {
    let children = s.children
    children.at(0) = with-gap(children.first(), 2pt)
    children.at(-1) = with-gap(children.last(), 7pt)
    children.join()
  }
  formula
}
// A barrier splits neighbors. Only emit the two edits at the safe left sum.
#let mixed = $ a+b & = bold(a+b) \ "when" (-x) #box[$a+b$] $
#mixed
#{
  show selector.where(children: mixed.body.children): s => {
    let kids = s.children
    (kids.first(), h(3pt), math.class("binary", kids.at(1)), h(3pt), ..kids.slice(2)).join()
  }
  mixed
}
