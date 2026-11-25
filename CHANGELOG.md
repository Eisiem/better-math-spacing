# Changelog

## 0.2.0 · Experimental

- Add opt-in row context through `rows: "context"` and `rows: "aligned"`. Boundary callbacks expose `edge.row.index`, `edge.row.atoms` and `edge.aligned` in these modes. Each nested sequence has its own rows.
- Let profiles adjust eligible gaps across `&` in paged output. The `continuation` predicate can opt a leading sign into binary spacing through `spacing-role` while retaining its native role.
- Keep cross-marker gaps native in HTML to preserve MathML operator form. Document Typst's identical content for spellings such as `xor` and `plus.o`.
- Include a multiline gallery, a configurable row hierarchy and geometric and MathML regressions. [API reference](README.md#api-reference) · [Row audit](docs/row-audit.md)

## 0.1.1 · Experimental

- Translate the remaining design notes, audit reports and test fixtures into English.
- Update the local installer and documented package import to 0.1.1.

## 0.1.0 · Experimental

- Add declarative spacing for groups of symbols, math classes and element types.
- Resolve spacing at the boundary between adjacent math atoms. Compose absolute lengths, native spacing estimates, percentage factors and contextual rules.
- Preserve equation numbering and references. Adjust safe runs around existing row breaks, alignment points, text and opaque elements.
- Scope nested edits to individual siblings so equal subexpressions in separate compounds can receive different spacing.
- Include five comparison profiles, a local package installer, and automated regression tests.

Verified with Typst 0.15.1. See the [known limitations](README.md#known-limitations) and [audit results](docs/review.md).
