# Better math spacing 0.1.0 audit

The initial audit used commit `c16af5d` and repeated the tests after local fixes. The independent corpus contains 69 equations covering signs, decimals, delimiters, orthogonal projections, normal equations, uniform convergence and series. A separate document contains two complete proofs with 21 equations in context. [Corpus](../tests/audit/corpus.typ) · [Proofs](../tests/audit/proofs.typ)

## Functional coverage

All 69 equations compiled with native Typst. A configuration callback emitted a diagnostic when it received the analyzed equation. This distinguished an equation delegated to Typst from one whose rules left spacing unchanged. Each formula compiled separately to isolate selector collisions.

The HTML comparison checked MathML nodes, text and attributes, including `form`. It excluded `mspace` nodes and the `lspace` and `rspace` attributes that encode distances. “Modified” indicates a spacing change with the original structure preserved. “Unchanged” indicates that analysis completed and the two outputs matched under these checks.

| Configuration after fixes | Modified | Unchanged | Delegated | Compilation error |
| --- | ---: | ---: | ---: | ---: |
| Basic, 0.32 em on both sides of `+` and `−` | 42 (60.9%) | 15 (21.7%) | 12 (17.4%) | 0 |
| Compact | 53 (76.8%) | 3 (4.3%) | 12 (17.4%) | 1 (1.4%) |
| Hierarchical | 20 (29.0%) | 37 (53.6%) | 12 (17.4%) | 0 |
| Adaptive | 53 (76.8%) | 3 (4.3%) | 12 (17.4%) | 1 (1.4%) |
| Wide | 53 (76.8%) | 3 (4.3%) | 12 (17.4%) | 1 (1.4%) |

Of 345 combinations, 282 passed after analysis (81.7%), 60 were delegated (17.4%) and three failed to compile (0.9%). The same fraction case caused all three errors. Before the fixes, the basic configuration changed `form` in five formulas and delegated decimals to Typst. Both complete proofs retained their MathML trees and four equation links. Basic modified five proof formulas, hierarchical modified two, and each of the other three profiles modified 13.

## Geometric fidelity

The check materialized positive gaps predicted by the native profile as `h` nodes. It used 12 pt New Computer Modern Math and measured paged widths with `measure`. The 56 equations that completed analysis and compiled under the control profile matched native widths within 0.01 pt. HTML confirmed emitted gaps in 53 of them. Twelve equations were delegated and one triggered the collision diagnostic. Total widths can hide internal errors that cancel out or occur in a narrower matrix row. The regressions also check individual glyph pairs and `mspace` positions.

The audit separately measured 16 variants with delimiters, fractions and scripts. Before the fix, `lr(bracket.r -x bracket.l)` gained **5.333 pt** when the native estimate was emitted explicitly. The initial character was classified as a closing delimiter even though Typst treated it as an opening delimiter. After the fix, all 16 variants matched in width and height within 0.01 pt. [Geometry probes](../tests/audit/fidelity.typ) · [Typst delimiter resolution](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/resolve.rs#L815-L918)

## Compatibility and fixes

- The package keeps native spacing between an opening delimiter and a unary variable sign. In five formulas this preserves the exported operator form. Other requested gaps in those formulas can still apply.
- Decimals with a single point receive the same numeric classification as integers, matching Typst's interpretation of text nodes in math. [Number resolution](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/resolve.rs#L255-L289)
- An external `set h(weak: true)` removed a requested 4 pt gap after a delimiter. Explicit `weak: false` restored the reference width of 39.669 pt from 35.669 pt. [Compatibility checks](../tests/audit/compat.typ)
- An external `show` that reclassifies the same `+` as a relation can still compete with the package's decision. With the left gap fixed at 4 pt, the relation's right gap gives a reference width of 28.333 pt. The audit measured 27.667 pt because the emitted spacing preserved the binary class.
- Two overlapping `show math.equation: spacing.with(...)` rules compete for the same sequence. With 0.5 em and 200% in separate rules, changing their order gives widths of 33 and 31.667 pt. Declaring both operations in one `rules` array composes them and gives 45 pt.
- The 12 delegated equations contain boxes, free text, style wrappers, `dif`, alignment points, `mid`, `cases`, accents and a percentage gap. Delegation can happen even when an operator elsewhere in the equation is supported. The regression suite checks labels, references, colors and simple glyph substitutions.

## Performance

The audit measured the full CLI process from startup through writing a temporary PDF. It used Typst 0.15.1, Linux x86-64, an i7-13700HX, embedded fonts and one thread (`--jobs 1`). The first profile rotated between rounds. Each cell reports the medians of five runs in wall-clock seconds and peak RSS in MiB. The workload cycles 68 corpus formulas, excluding the collision case so that each profile can finish. The distinct workloads append a different identifier to each equation. Native mode compiles without loading the package.

| Workload | Native | Basic | Compact | Hierarchical | Adaptive | Wide |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 cycled | 0.020 s · 29.6 MiB | 0.086 s · 40.4 MiB | 0.075 s · 40.1 MiB | 0.126 s · 42.9 MiB | 0.096 s · 41.2 MiB | 0.072 s · 40.2 MiB |
| 1,000 cycled | 0.074 s · 43.8 MiB | 0.223 s · 63.3 MiB | 0.260 s · 64.0 MiB | 0.407 s · 71.4 MiB | 0.416 s · 76.6 MiB | 0.263 s · 64.2 MiB |
| 1,000 distinct | 0.091 s · 50.0 MiB | 0.490 s · 115.4 MiB | 0.542 s · 117.0 MiB | 0.821 s · 120.1 MiB | 0.773 s · 133.9 MiB | 0.549 s · 116.8 MiB |
| 5,000 cycled | 0.303 s · 111.8 MiB | 0.851 s · 167.9 MiB | 1.081 s · 172.9 MiB | 1.629 s · 201.4 MiB | 1.823 s · 233.3 MiB | 1.081 s · 172.9 MiB |
| 5,000 distinct | 0.427 s · 141.1 MiB | 2.248 s · 406.6 MiB | 2.571 s · 452.5 MiB | 3.769 s · 440.4 MiB | 3.647 s · 511.9 MiB | 2.574 s · 453.2 MiB |

With 5,000 distinct equations, profiles took 5.3 to 8.8 times the native time and used 2.9 to 3.6 times the native peak memory.

Contextual rules inspect runs and neighbors during compilation. The hierarchical profile searches for group presence at each boundary. The adaptive profile computes some factors once per equation and applies four rules at each pair. Distinct equations offer less opportunity for reuse and also incur the cost of laying out their identifiers. Compare profiles within each row.

## Complexity and open questions

- A dictionary built when the module loads replaced character searches through strings. The package also skips building boundary context when there is neither a group request nor a rule. The Unicode table, public constructors and pairwise resolution model were retained.
- Analysis visits atoms and groups. With `n` atoms, `g` groups and `r` rules, the common path considers about `n·(g+r)` combinations, plus predicate work. A predicate that scans an entire run at every boundary can cost quadratic time. Gathering global information in `rules: eq => ...` avoids repeating that work. Per-run context could help local hierarchies, pending a decision on whether it belongs in the public API.
- Collision detection compares plans by child value and uses linear searches across sequences. It can cost quadratic time in the number of runs in one equation. A replacement should preserve exact equality and be justified by measurements that isolate this cost. Text representations can collide across different content.
- The remaining error combines two fractions with equal public numerators and different vertical and horizontal styles. Native binary spacing differs by math size. A value selector merges the two occurrences, and reconstructing fractions from public fields would lose private information. This needs a reliable way to address individual occurrences or an explicit collision policy.
- Opaque structures, external reclassification and the composition of separate show rules share a scoping problem. The package analyzes content before realization, while its selectors run during realization. Delegating just an opaque subtree or coordinating multiple show rules requires identifying occurrences and knowing which elements are realized. The native profile may also lack fence geometry or style information introduced during realization.

## Reproduce the measurements

```sh
python3 tests/check.py
python3 tests/audit/audit.py > functional.json
python3 tests/audit/audit.py --bench 5 --bench-only > performance.json
typst compile --root . tests/audit/proofs.typ proofs.pdf
typst compile --root . --input profile=adaptive tests/audit/proofs.typ proofs-adaptive.pdf
```

The audit program records each formula and timing run in JSON. Use `--root` to repeat the comparison in a clean checkout of another commit containing the same audit files and example profiles. [Audit program](../tests/audit/audit.py) · [Per-formula results and 150 measurements](audit-data.json)
