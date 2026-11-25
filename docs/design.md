# Proposed design

These historical notes cover the feasibility stage. Version 0.1.0 includes percentage factors and a native profile. The README documents the current API. [Package documentation](../README.md)

The package would decide one distance per boundary between adjacent math atoms. That gives one answer when two operators request space at the same boundary. The atoms would remain Typst elements. A rule would choose a length or return `auto` to let Typst decide.

The examples below illustrate the proposed interface. The policy and nesting probes are executable demonstrations. [Policy probes](../probes/policies.typ) · [Nesting probe](../probes/nested.typ)

## Basic configuration

```typst
#let signs = group(sym.plus, sym.minus, before: 4mm, after: 4mm)

#show math.equation: spacing.with(groups: (signs: signs))
$a + b - c$
```

A regular show rule can scope the configuration to the document or to a block. The proposed public functions were `group`, `rule` and `spacing`.

| Function | Proposed contract |
| --- | --- |
| `group(..members, before:, after:, test:)` | Matches any listed Typst symbol, math class name or element function such as `math.frac`. An optional predicate further filters the matches. With no members, the predicate determines membership. Omitted sides make no request. |
| `rule(value, left:, right:, when:)` | Optional `left` and `right` group names and a `when` predicate must all match when supplied. The value can be a length, `auto` or a function such as `e => new-width`. A length replaces the gap. A function can add, multiply or compute a distance from both requests. |
| `spacing(eq, groups: (:), rules: ())` | A show rule for an equation. `groups` is an ordered dictionary. `rules` is an ordered array or a function that takes the analyzed equation and returns that array. The function form lets subexpressions share a condition computed once. |

Lengths accept `pt`, `mm`, `em` and combinations of these units. Typst resolves em units at the local math size. Percentage widths and fractions of available space would trigger configuration diagnostics. Outer equation edges have no adjacent pair and generate no gap.

**Precedence.** For each side of an atom, the last matching group that supplies a length wins. At a boundary, the right atom's `before` takes priority, followed by the left atom's `after`, then `auto`. Explicit rules run in declaration order. The result is deterministic even when requests combine mm and em at an unknown local size. For instance, `rule(1mm, left: "sum", right: "sign")` fixes the gap between those groups. A rule can also add both requests.

```typst
#let add-sides = rule(e => e.left-after + e.right-before,
  when: e => e.left-after != none and e.right-before != none)
```

Starting with a known value, setting 3 pt, adding 1 pt and doubling gives 8 pt. Reversing the final two steps gives 7 pt. A transformation reads the accumulated value in `e.width` and needs a numeric basis for arithmetic. It can return `auto` to delegate the boundary to Typst. [Transformation probe](../probes/nested.typ)

## Predicates and scopes

An atom would expose the original `node`, its `class` and operator `role` when known, plus its matched `groups` after classification. Element members match by `node.func()`. For example, `group(math.frac, math.mat, before: 0.15em)` selects fractions and matrices. A `math.attach` can match both its own element type and the large-operator class of its base. Unknown classes use `none`. A group predicate can inspect `node`, `class` and `role`.

A boundary `e` would expose `left`, `right`, `index`, `run`, `path` and `equation`. The run contains sibling atoms. The path records container functions, fields and cell indices where applicable. `left-class` and `right-class` are the facing classes. A delimited group can present an opening class to its left neighbor and a closing class to its right neighbor. `left-after` and `right-before` expose the original group requests. The zero-based index identifies the left atom in the run. The equation view contains its original `node` and accessible `runs` in reading order. Rules can examine the whole formula and apply a change in a script, or check only siblings. As rules compose, only `width` changes. Atoms and paths refer to the original content.

## Configurations that motivated the interface

### Adjacent operators and sign roles

```typst
#let operators = (
  infix: group(test: a => a.role == "binary", before: 0.35em, after: 0.35em),
  prefix: group(test: a => a.role == "unary", after: 0.08em),
)
#let adjacent = rule(0.65em, left: "infix", right: "prefix")
#show math.equation: spacing.with(groups: operators, rules: (adjacent,))
$a + -b$  $-a - b$
```

The first expression resolves the gap between `+` and `−` once. In the second, only the middle sign requests leading binary spacing. The probe gallery shows the exception and sign roles in separate rows.

### Hierarchy based on nearby operators

```typst
#let operators = (
  equality: group(sym.eq),
  implies: group(sym.arrow.r.double),
)
#let touches(e, group-name) = group-name in e.left.groups or group-name in e.right.groups
#let base = 5em / 18
#let hierarchy = rule(
  2.16 * base,
  when: e => touches(e, "implies") and e.run.any(a => "equality" in a.groups),
)
#show math.equation: spacing.with(groups: operators, rules: (hierarchy,))
$a => b$  $a = b => c$
```

The lone implication keeps `auto`. In the second sample, the reference relation keeps 5/18 em and the implication gets 0.6 em. The local search keeps an equality in a denominator from activating an outer implication. Both the factor and the reference group come from the configuration.

### A condition that scales gaps throughout an equation

```typst
#let groups = (
  large: group("large"),
  relation: group("relation"),
  trigger: group(sym.eq),
  binary: group(test: a => a.role == "binary"),
)
#let between-large-operators(xs) = xs.windows(3).any(t =>
  "large" in t.at(0).groups and "trigger" in t.at(1).groups
    and "large" in t.at(2).groups
)
#let touches(e, group-name) = group-name in e.left.groups or group-name in e.right.groups
#let profile(eq) = {
  if not eq.runs.any(between-large-operators) { return () }
  (
    rule(1em / 6, when: e => touches(e, "large") and e.right-class != "opening"),
    rule(4em / 18, when: e => touches(e, "binary")),
    rule(5em / 18, when: e => touches(e, "relation")),
    rule(e => if e.width == auto { auto } else { 2 * e.width }),
  )
}
#show math.equation: spacing.with(groups: groups, rules: profile)
$sum_i^n = product_j^m x => y$  $sum_i^n = product_j^m (a+b)$
```

In these text-style samples, the profile assigns a base to every boundary with positive native spacing. Other boundaries retain `auto` and their native zero gap. The first sample doubles the spacing around `x ⇒ y`. The second doubles the binary spacing within the delimited group. In that case, the product sees the group's left edge as an opening delimiter. A broader profile would also account for punctuation, adjacent relations and script sizes. Typst determines the automatic spacing. [Flat probe](../probes/cases.typ) · [Nested probe](../probes/nested.typ)

### Group terms around a comma

```typst
#let groups = (
  sum: group(sym.plus, before: 0.12em, after: 0.12em),
  comma: group(sym.comma, after: 0.75em),
)
#show math.equation: spacing.with(groups: groups)
$(a + b, c + d)$
```

The largest gap follows the comma. Each sum keeps its own spacing and `lr` retains control of the parentheses. A rule can inspect the container type along the path to distinguish other contexts. Native matrix cells are separate fields, and the commas that separate `mat` arguments are syntax. [Matrix reference](https://typst.app/docs/reference/math/mat/)

## From content to rendering

1. **Read the original body.** Inspect `func()` and known fields. `-` and `=>` arrive as `−` and `⇒`. The symbol `+` differs from the text `"+"`. Both integer literals and quoted strings can arrive as `text` nodes. The probe gets the symbol element function with `$+$.body.func()`. A distributable classifier would use the Unicode classes for the supported Typst version and Typst's overrides. It would also recognize explicit `math.class`, attachment bases and `lr` boundaries. In 0.15.1, `vary` becomes binary after a normal, alphabetic, closing or fence class. [Content inspection](https://typst.app/docs/reference/foundations/content/#representation) · [Facing classes](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/item.rs#L96-L133)
2. **Resolve boundaries between siblings.** Read numerators, denominators, cells, bases, scripts and delimited bodies separately. Preserve source spaces in the content and skip them when identifying symbol neighbors. An explicit gap, row break or alignment point limits where edits can apply. Boxes, compound text, deferred content and style wrappers with inaccessible content remain opaque. Evaluate predicates before inserting gaps. The structure probe checks public fields and equality. [Structure probe](../probes/structure.typ)
3. **Apply the chosen edits.** Return the original equation with a local show rule for the matching sequence. Emit the original children in order, with one `h` per changed boundary. `auto` preserves the original nodes. When `h` interrupts the left context of a simple binary `vary` symbol, pin the established class with `math.class("binary", ...)`. Summations with limits, stretchable delimiters and fractions retain their containers. The prototype identifies `sequence` from a syntax sample, which needs checking on compiler upgrades. [Emission probe](../probes/edges.typ) · [Math class reference](https://typst.app/docs/reference/math/class/)

For a sequence of `n` children, analysis visits the children once and resolves each boundary once. With `r` rules, direct resolution costs O(n·r) plus group classification and predicate evaluation. Functional `rules` can replace a repeated global search with one search per equation. The cost of applying local selectors depends on the compiler and the number of distinct sequences. Width measurements verify the output in tests. The algorithm can choose gaps without measuring each pair during layout.

## Compatibility boundaries

- **Value selectors.** Identical lists in the same scope can share a plan. Incompatible plans, including a case where one list should remain untouched, should trigger a diagnostic with both paths before any content is edited. External show rules can generate matches invisible during analysis. General path-based selection would require another technique. [Collision control](../probes/scopes.typ)
- **Private fields.** Some horizontal fractions use private flags for their parentheses. Reconstructing the container with `fields()` can change the notation even when the content compares equal. The strategy requires preserving the original container. [Fraction resolution](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/resolve.rs#L721-L765)
- **Other show rules.** The tests combine two external styles, an independent substitution and numbered references. A rule that reclassifies the same operator after analysis can interfere with role preservation. Configure the desired class or leave that boundary native. Native layout also handles uncertain operator roles. [Interoperability probe](../probes/interop.typ) · [Reclassification control](../probes/geometry.typ)
- **Feasibility scope.** The adjacency probe recognizes a small alphabet and flat or directly delimited lists. Other probes isolate recursion, scope and structure. The full classifier, collision detection and the three public functions were still proposals at this stage. A separate package was envisioned for line breaking, alignment and overflow.
