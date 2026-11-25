# Changelog

## Unreleased · 0.1.1 API extension

- Expose row-local atoms and row indices to spacing rules. Each nested sequence keeps its own rows.
- Allow profiles to style eligible operator–term gaps across an alignment point and opt individual continuation signs into binary spacing for paged output.
- Add a row hierarchy example and regressions for glyph positions, native operator roles and exported MathML.

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
