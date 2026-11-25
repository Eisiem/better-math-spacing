#import "../lib.typ": group, spacing

#show math.equation: spacing.with(groups: (
  signs: group(sym.plus, sym.minus, before: 4mm, after: 4mm),
))

$a + b - c$
