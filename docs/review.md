# Better math spacing 0.1.0 architecture review

The review extends analysis to the 12 equations previously delegated in full and resolves the sibling-fraction collision that caused errors in three profiles. All 345 combinations of 69 equations and five configurations compile with native MathML structure, including mixed equations where only some runs are editable. The baseline is `bdeb191` and the revised implementation is `99613c8`. [Corpus](../tests/audit/corpus.typ) · [Original audit](audit.md)

## Profiling the original implementation

Four cutoffs in the original compilation isolated the work done at each stage. In temporary copies of `bdeb191`, the first three cutoffs returned the original equation at successive stages. The final run compiled the edited PDF. Both profiles used 1,000 distinct equations, one thread and three independent processes per cell. The table reports cumulative measurements from a repeat of this diagnostic on the same commit. The final stage includes laying out the edited result. Peak RSS measures the whole process.

| Last stage executed | Basic, s · MiB | Adaptive, s · MiB |
| --- | ---: | ---: |
| Entry, before analysis | 0.100 · 51.8 | 0.096 · 51.9 |
| Atom runs collected | 0.292 · 87.1 | 0.283 · 85.1 |
| Edit plans and collisions resolved | 0.423 · 95.3 | 0.663 · 113.7 |
| PDF with edits | 0.477 · 111.9 | 0.755 · 133.6 |

Atom collection took time and memory in both profiles. Boundary resolution added the largest time increment in the adaptive profile. The revision removes recursion into glyphs already classified and inlines path construction. Static profiles skip the equation view and the boundary record used by callbacks. The emission step copies the slices between edits in batches. Rules and predicates retain their order, indices and arguments.

## Scope and selection

The occurrence probe applied 2 pt and 7 pt gaps to numerators with the same public children. It used each fraction's sibling index to install a local show rule, then passed the original fraction to Typst. Another sample combined two aligned rows, text, a bold expression and a box containing nested math. Only the selected sum gained new gaps. An earlier reconstruction probe showed that the public constructor lost private parentheses from slash notation. Passing the original container preserves that information. [Occurrence probe](../probes/occurrences.typ) · [Reconstruction probe](../probes/scopes.typ)

The implementation makes one decision per boundary. A row break, alignment point, free text or opaque branch ends the current run. Other edits apply in the scope of the relevant child of the outer sequence. An `&` ends editable adjacency and retains the context used to determine a sign's role. A break at the root starts a new row. Inside a cell, a break can disappear during layout. When the preceding element leaves a sign's role uncertain, both neighboring gaps remain native. [Typst 0.15.1 row and sign resolution](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/process.rs#L119-L213) · [Relative space resolution](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/resolve.rs#L238-L254)

## Coverage and fidelity

| Profile | Analyzed before → after | Modified before → after | Delegated before → after | Errors before → after |
| --- | ---: | ---: | ---: | ---: |
| Basic | 57 → 69 | 42 → 47 | 12 → 0 | 0 → 0 |
| Compact | 57 → 69 | 53 → 66 | 12 → 0 | 1 → 0 |
| Hierarchical | 57 → 69 | 20 → 21 | 12 → 0 | 0 → 0 |
| Adaptive | 57 → 69 | 53 → 66 | 12 → 0 | 1 → 0 |
| Wide | 57 → 69 | 53 → 66 | 12 → 0 | 1 → 0 |

The baseline had 282 successful combinations (81.7%), 60 full delegations (17.4%) and three errors (0.9%). The revised implementation passed all 345. “Analyzed” counts equations that reached the rule constructor, including those where another configuration reported a collision. “Modified” requires at least one gap change and preservation of the MathML tree. Compact, adaptive and wide showed edits in all 12 previously delegated formulas. Basic changed five of them and hierarchical changed one.

The 282 combinations that already passed produced identical MathML trees, including spacing nodes and attributes. All 345 combinations were also checked against native Typst for text, nodes and structural attributes, including operator form. The proofs retained their 21 equations and four links in every profile. At the reviewed commit, compiling the gallery reproduced the checked-in SVG byte for byte.

The control that emits the native spacing estimate reached 69 equations, up from 56. All 69 matched native paged widths at 12 pt. The maximum recorded absolute difference was 0 pt, and 66 equations showed explicit gaps. Overall widths can hide differences within a matrix row. The 16 additional width and height controls were retained, and the aligned fixture checks gap positions by cell. [Geometry checks](../tests/audit/fidelity.typ) · [Scope regressions](../tests/audit/scopes.typ)

## Performance

The main comparison reran the original audit with the same corpus, profiles and embedded fonts. Each median summarizes five independent Typst 0.15.1 processes on an i7-13700HX running Linux with `--jobs 1`. The PDF workload cycles 68 formulas, including the 12 previously delegated cases. The workload still excludes `fraction-style` for comparability, even though it now compiles with all five profiles. In distinct workloads, every equation has its own additional identifier.

### Wall-clock time in seconds, baseline → revised

| Workload | Native | Basic | Compact | Hierarchical | Adaptive | Wide |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 cycled | 0.020 → 0.017 | 0.086 → 0.056 | 0.075 → 0.057 | 0.126 → 0.090 | 0.096 → 0.079 | 0.072 → 0.056 |
| 1,000 cycled | 0.074 → 0.071 | 0.223 → 0.152 | 0.260 → 0.158 | 0.407 → 0.405 | 0.416 → 0.434 | 0.263 → 0.155 |
| 1,000 distinct | 0.091 → 0.089 | 0.490 → 0.398 | 0.542 → 0.450 | 0.821 → 0.748 | 0.773 → 0.769 | 0.549 → 0.450 |
| 5,000 cycled | 0.303 → 0.294 | 0.851 → 0.571 | 1.081 → 0.579 | 1.629 → 1.766 | 1.823 → 1.974 | 1.081 → 0.580 |
| 5,000 distinct | 0.427 → 0.420 | 2.248 → 1.853 | 2.571 → 2.138 | 3.769 → 3.527 | 3.647 → 3.748 | 2.574 → 2.142 |

### Peak RSS in MiB, baseline → revised

| Workload | Native | Basic | Compact | Hierarchical | Adaptive | Wide |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 cycled | 29.6 → 29.9 | 40.4 → 36.8 | 40.1 → 36.9 | 42.9 → 37.3 | 41.2 → 39.3 | 40.2 → 36.8 |
| 1,000 cycled | 43.8 → 43.9 | 63.3 → 55.9 | 64.0 → 56.4 | 71.4 → 66.4 | 76.6 → 74.0 | 64.2 → 56.8 |
| 1,000 distinct | 50.0 → 50.3 | 115.4 → 99.3 | 117.0 → 105.9 | 120.1 → 103.8 | 133.9 → 130.9 | 116.8 → 106.8 |
| 5,000 cycled | 111.8 → 112.1 | 167.9 → 142.2 | 172.9 → 148.5 | 201.4 → 194.7 | 233.3 → 236.5 | 172.9 → 148.5 |
| 5,000 distinct | 141.1 → 141.5 | 406.6 → 378.2 | 452.5 → 419.0 | 440.4 → 380.9 | 511.9 → 521.3 | 453.2 → 419.4 |

With 5,000 distinct equations, four profiles reduced both time and memory. Basic cut time by 17.6% and hierarchical cut peak RSS by 13.5%. Adaptive took 2.8% longer and used 1.8% more memory. With 5,000 cycled equations, compact took 46.4% less time. Hierarchical and adaptive took 8.4% and 8.3% longer. The measurements cover full processes and include variation visible in the native control.

To isolate the cost of processing more formulas, a separate control used the 56 formulas that all profiles already supported. It kept the original predicates and the 5,000-equation cycled workload. Commits alternated between rounds, with three processes per cell.

| Profile, 56 cycled formulas | Baseline, s · MiB | Revised, s · MiB |
| --- | ---: | ---: |
| Hierarchical | 1.812 · 223.4 | 1.823 · 194.3 |
| Adaptive | 2.055 · 256.0 | 2.033 · 237.2 |

On the shared subset, time differed by about 1% for both profiles and peak memory decreased in both. The slowdown in the full cycled workload appears when the 12 newly supported formulas also run the contextual rules.

## Compatibility and limitations

- In `frac(a+b,c) = z`, an external rule replaces `z` with another `a+b`. Previously, the numerator selector added 3 pt and 4 pt margins to the generated copy as well. The revised implementation applies those margins only within the numerator. A box with an equal equation and a style wrapper with its own signs were also checked for isolation.
- Equal branches in the same fraction remain indistinguishable by their public fields during realization. Incompatible spacing plans trigger a diagnostic with both paths. A deeper opaque subtree may cause the entire compound to be preserved. Labelled sequences that would require flattening are also protected. Coverage counts equations with accessible runs.
- External reclassification of the same sign can still interfere with role preservation. The reclassification check measures 27.667 pt against a reference of 28.333 pt with the sign treated as a relation. Two overlapping equation rules yield 33 or 31.667 pt when their order is reversed. The same operations in one rule array give 45 pt. Content that external show rules generate within the same scope remains subject to Typst's public equality. [Compatibility controls](../tests/audit/compat.typ)
- Collision checks compare equivalent plans and detect outputs that would activate another selector within the same scope. A compound with many lists can require quadratic comparisons. User predicates can also scan a whole run at each boundary. The measurements supported reducing work on the common path while retaining the existing equality check and caching behavior.

## Reproduce the measurements

Run these commands from the repository root with Typst 0.15.1 and Python 3 on Linux.

```sh
python3 tests/check.py
python3 tests/audit/audit.py --bench 5 > review.json
```

The baseline cutoffs used the same PDF workload with `profile=basic` or `adaptive`, `workload=true`, `unique=true` and `count=1000`. In three copies of `bdeb191`, `spacing` returned `eq` just before collecting lists, building the equation view or building selectors. The fourth run used the original implementation. The data contains per-formula results, individual timings and peak RSS values. [Baseline data](audit-data.json) · [Review data](review-data.json) · [Measurement program](../tests/audit/audit.py)
