# Better math spacing

**Experimental 0.2.1 · Typst 0.15.1**

Adjust spacing between math atoms with a Typst show rule. You write the equation once and specify which boundaries to adjust. The original equation retains its numbering, labels and references. The package has no runtime dependencies.

## Install locally

Use a checkout of the [GitHub repository](https://github.com/Eisiem/better-math-spacing) with Typst 0.15.1. On Linux or macOS, run the installer with Python 3 available:

```sh
git clone --branch v0.2.1 https://github.com/Eisiem/better-math-spacing.git
cd better-math-spacing
./scripts/link-local.sh
```

The script links the checkout into `local/better-math-spacing/0.2.1` under Typst's package directory. It uses `TYPST_PACKAGE_PATH` when set. Otherwise, it uses `${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages` on Linux or `~/Library/Application Support/typst/packages` on macOS. The script prints the link path and can be run again for the same checkout. [Typst's local package documentation](https://github.com/typst/packages#local-packages)

Run `typst info` to locate a custom package directory. Pass that directory as the script's only argument, or set `TYPST_PACKAGE_PATH` for both the installer and the compiler. To install manually, place a symlink to the checkout at `<package-directory>/local/better-math-spacing/0.2.1`. On Windows, a directory junction also works. Keep the checkout at its linked location. To uninstall, remove the link.

## Quick start

In any project compiled with your local Typst CLI:

```typst
#import "@local/better-math-spacing:0.2.1": group, spacing

#show math.equation: spacing.with(groups: (
  signs: group(sym.plus, sym.minus, before: 4mm, after: 4mm),
))

$a + b - c$
```

## Gallery

![Five spacing profiles applied to eight equations, including a matrix product, a difference quotient and a Riemann sum](docs/gallery.svg)

Compact and wide scale estimated native spacing. Hierarchical draws attention to higher-ranking operators when other operator groups are present. Adaptive responds to density, separators and nesting depth. [Gallery source](examples/gallery.typ) · [Profile configurations](examples/profiles.typ)

## API reference

| Function | Behavior |
| --- | --- |
| `group(..members, before: none, after: none, test: none)` | Matches any listed symbol, math class name or element function. An optional `test(atom)` must also accept the atom. With an empty member list, the predicate alone determines membership. |
| `rule(value, left: none, right: none, when: none)` | Adjusts one boundary. When supplied, `left` and `right` name required groups on the respective sides. The optional `when(edge)` adds a condition. |
| `spacing(eq, groups: (:), rules: (), rows: none, continuation: none)` | Applies the configuration to a math equation. Bind the named arguments with `spacing.with(...)` in a show rule. `groups` maps names to groups. `rules` is an array or a function that accepts the equation view and returns an array. |

| `rows` | Boundary callbacks and edits |
| --- | --- |
| `none` (default) | Uses the original 0.1.1 callback fields and adjusts contiguous runs. |
| `"context"` | Adds `edge.row` and sets `edge.aligned` to `false`. Adjusts contiguous runs using context from the full row. |
| `"aligned"` | Adds the same row context and exposes eligible cross-marker boundaries in paged output with `edge.aligned == true`. Also enables the optional continuation predicate. |

`continuation` defaults to `none`. With `rows: "aligned"`, it can be a predicate called for a variable-class glyph at the start of a row after an explicit line break, directly before an eligible `&` and its term. Returning `true` opts that occurrence into binary spacing and adds `spacing-role: "binary"` to its atom record. The native `role`, facing classes and `edge.native` keep describing Typst's classification.

Group predicates classify individual atoms before the row is assembled. Put a margin that depends on other atoms in a boundary rule, where the completed row and its group memberships are available.

A group can set each side independently using lengths in pt, mm, em or a combination. On each atom, the last matching group that supplies a length for that side wins. At a boundary, the right atom's `before` takes precedence over the left atom's `after`. If neither is supplied, the starting value is `auto`. The crossed boundary of a selected continuation starts at Typst’s medium binary spacing.

Rules run in declaration order. A length replaces the current value. `auto` returns the boundary to native spacing. A ratio such as `150%` scales the current length, or scales the native estimate when the current value is `auto` and an estimate exists. A callback can return any of these values.

| Callback | Fields |
| --- | --- |
| Group predicate | `node` is the original content, `index` is its position in the flattened sequence, `class` is the math class, and `role` is `"unary"`, `"binary"` or `none`. A selected continuation adds a `spacing-role` override. Use `a.at("spacing-role", default: a.role)` for the effective typographic role. Attachments inherit the class of their base. Symbol members match direct glyphs. |
| Boundary predicate or value callback | `left` and `right` include the atom fields plus `groups`, `before`, `after`, and facing classes `l` and `r`. `left-class` and `right-class` name the opposing classes. `left-after` and `right-before` expose the group requests. `width` is the current value and `native` is the native estimate or `auto`. |
| Boundary position | `run` contains the contiguous atoms and `index` is the zero-based position of the left atom within it. `path` leads from the equation body to the sequence. Each step supplies `parent` and `field`, with `index`, `row` or `col` where applicable. |
| Row context (opt-in) | `row.index` counts explicit row breaks from zero in the current sequence. Typst can suppress a break inside a table cell. `row.atoms` contains its accessible direct atoms in source order, across alignment points, explicit spaces and opaque barriers. A nested sequence (e.g. a denominator or matrix cell) has its own rows and `path`. A compound counts as one atom in its parent. |
| Aligned boundary (row modes) | `aligned` is true for an eligible operator–term pair across one `&` when `rows: "aligned"`. Here `run` is the **left** editable run, `index` its last position, and `right` the first atom of the next run. For ordinary boundaries, `right == run.at(index + 1)`. |
| Continuation predicate | `node`, `index`, `class` and native `role` describe the candidate sign. `row-index` counts explicit row breaks from zero in the equation body. |
| Equation callback | The equation view exposes the original `node` and accessible `runs`. The same view is available as `edge.equation` in boundary callbacks. Use this view to decide once per equation which rules to apply. |

## Examples

These examples use the same local import as above, with `rule` added to the import list.

### Set an exception for two adjacent operators

Give binary operators a trailing margin of 0.3 em, then add 1 pt when the next operator is unary.

```typst
#let groups = (
  binary: group(test: a => a.role == "binary"),
  unary: group(test: a => a.role == "unary"),
)
#show math.equation: spacing.with(groups: groups, rules: (
  rule(0.3em, left: "binary"),
  rule(e => e.width + 1pt, left: "binary", right: "unary"),
))
$a + -b$
```

### Widen implications when an equality is present

The rule doubles the margins of `=>` when an equality occurs in the same run.

```typst
#show math.equation: spacing.with(
  groups: (equality: group(sym.eq), implies: group(sym.arrow.r.double)),
  rules: (rule(200%, when: e =>
    "implies" in (e.left.groups + e.right.groups)
      and e.run.any(a => "equality" in a.groups)),),
)
$a => b$  $a = b => c$
```

### Use context across alignment columns

Apply a fixed margin around an implication when an equality occurs anywhere in the same row. The first row gains the custom margin because the equality on the left of `&` is visible to the rule on the right. The second row retains the native implication spacing.

```typst
#show math.equation: spacing.with(
  rows: "context",
  groups: (
    equality: group(sym.eq),
    implication: group(sym.arrow.r.double),
  ),
  rules: (rule(6pt, when: e =>
    "implication" in (e.left.groups + e.right.groups)
      and e.row.atoms.any(a => "equality" in a.groups)),),
)

$
  a = &b => c \
      &d => e
$
```

### Space a continuation sign

```typst
#show math.equation: spacing.with(
  rows: "aligned",
  continuation: sign => sign.row-index == 1 and sign.node == $+$.body,
  groups: (binary: group(sym.plus, after: 4pt, test: a => a.at("spacing-role", default: a.role) == "binary"),),
)

$ a = &b \ + &c + d $
```

The predicate selects the leading plus in the second row. The group gives it a 4 pt trailing gap in PDF while `b` and `c` share an alignment coordinate. The same group also matches the ordinary binary plus in `c + d`. A rule returning `auto` restores native spacing at the boundary it matches.

### Scale a hierarchy dynamically

Use the example profile from a checkout. To use it in a separate project, copy [row-profile.typ](examples/row-profile.typ) next to your document and replace its first import path with `@local/better-math-spacing:0.2.1`.

```typst
#import "row-profile.typ": row-profile

#show math.equation: row-profile(minimum: 2pt, multiplier: 2)

$
  (a+b, c+d) = &x => y \
        a + b = &sum_i x_i + z
$
```

The profile ranks arithmetic and set operations, relations, logical connectives and implications. Only groups present in `edge.row.atoms` consume a level, starting at zero. The higher-ranking group at a boundary determines its gap as `minimum × multiplier^level`. A matrix, sum or product in that scope raises every level once. Each nested sequence computes its own levels. Punctuation and unselected unary signs retain native spacing. [Profile implementation](examples/row-profile.typ) · [Side-by-side example](examples/aligned-rows.typ)

![Native and row-aware spacing for the same two aligned equations](docs/aligned-rows.svg)

## PDF and HTML output

| Behavior | PDF and other paged formats | HTML and MathML |
| --- | --- | --- |
| Rules within an editable run | Use the requested spacing and any enabled row context. | Use the requested spacing and the same row context. |
| Gap across an eligible `&` | The gap is placed in the right-aligned cell before the marker. Terms in the next column share an alignment coordinate. A wider cell can move the common anchor on the page. | The gap stays native and the cross-marker boundary is omitted from rule callbacks. An extra space in the cell can change the exported MathML operator `form`. |
| Selected continuation | The typographic role can set the crossed gap and affect other row-aware rules. | The typographic role remains available to rules within runs. MathML keeps the native operator form at the crossed boundary. |

## Known limitations

- The native profile estimates spacing from Typst's math classes and script styles. It uses `auto` for some font-dependent boundaries. [Typst 0.15.1 spacing algorithm](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/process.rs#L256-L295)
- Explicit spacing, text, opaque content, row breaks and alignment points divide editable runs. With `rows: "aligned"`, the package can replace a gap before the first, third or subsequent odd-numbered marker in a top-level, multiline display equation. The left atom must be a direct glyph of class `vary`, `binary`, `unary`, `relation` or `large`. The right atom can be a simple letter, ordinary glyph or number, including a term with a subscript, superscript or both on such a base. Compound bases such as fractions, left scripts and attachments with opaque scripts retain their native cross-marker gap. Whitespace in the source is harmless. Explicit gaps on either side, consecutive markers (`&&`), even markers, inline and single-row equations retain their native cross-marker spacing. An opaque expansion or nested fence with hidden layout markers can also disable crossing. Within-run edits still apply. Opaque roots and some nested compounds are delegated to Typst. The package also leaves boundaries native when adding a gap could change an operator's role.
- Typst 0.15.1 exposes identical glyph content for `xor` and `plus.o` (⊕). Callbacks cannot recover which spelling was used. A profile can give that glyph a shared interpretation or leave its spacing native. The example leaves it native.
- Equal sequences in the same selector scope must receive the same plan. Two identical branches of one fraction produce a diagnostic if they request different plans. Separate siblings have independent scopes.
- External show rules can change a class, size or content after the package analyzes an equation. Combine spacing transformations in a single `rules` array to control their order.

## Development

Run the regression suite with Typst 0.15.1 and Python 3:

```sh
python3 tests/check.py
mkdir -p build
typst compile --root . --ignore-system-fonts examples/gallery.typ build/gallery.pdf
```

The suite covers rendered geometry, MathML, equation references, style interactions and scope collisions. The technical reports include the original measurements. [Design notes](docs/design.md) · [Original audit](docs/audit.md) · [Comparative audit](docs/review.md) · [Row compatibility and timings](docs/row-audit.md) · [Changelog](CHANGELOG.md)

The package is MIT-licensed. [License](LICENSE) · [Third-party data notices](NOTICE)
