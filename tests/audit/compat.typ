#import "../../lib.typ": group, rule, spacing

#let owner = $+$.body.func()
#let fixed(eq) = spacing(eq, rules: (rule(4pt, when: e => e.index == 0),))
#let setting = sys.inputs.at("case", default: "base")
#set text(size: 12pt)
#let math-sample = $a+b$
#let restyled = {
  show owner.where(text: "+"): op => math.class("relation", op)
  if setting == "external-class" { show math.equation: fixed; math-sample }
  else { $a #h(4pt) + b$ }
}
#let stacked = {
  show math.equation: spacing.with(rules: (rule(0.5em),))
  show math.equation: spacing.with(rules: (rule(200%),))
  math-sample
}
#let swapped = {
  show math.equation: spacing.with(rules: (rule(200%),))
  show math.equation: spacing.with(rules: (rule(0.5em),))
  math-sample
}
#let combined = {
  show math.equation: spacing.with(rules: (rule(0.5em), rule(200%)))
  math-sample
}
#let weak = {
  set h(weak: true)
  show math.equation: spacing.with(groups: (open: group("opening", after: 4pt),))
  $(a+b)$
}
#context metadata((
  external: measure(restyled).width.pt(),
  stacked: measure(stacked).width.pt(),
  swapped: measure(swapped).width.pt(),
  combined: measure(combined).width.pt(),
  weak: measure(weak).width.pt(),
  weak-target: measure($(#h(4pt, weak: false)a+b)$).width.pt(),
))
#restyled
