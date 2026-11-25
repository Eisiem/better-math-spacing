# Row spacing in 0.2.0

## Compatibility and geometry

All 69 equations passed under each of the five existing profiles. A comparison against commit `61a1922` found identical MathML for all 345 outputs, including explicit spaces and operator attributes. The example row profile also preserved all 69 native trees and changed spacing in 61. The native-estimate control reached every equation and reproduced the native paged width in all 69. The suite also checked equation references, external show rules, the two proofs, the gallery and the existing collision diagnostics. [Corpus](../tests/audit/corpus.typ) · [Regression runner](../tests/check.py)

For the 16 pt fixture `a = &b \ + &c + d`, requesting 9 pt added 9 pt to the horizontal distance between the leading plus and `c`. The SVG glyph origins of `b` and `c` agreed within 0.001 pt. Opting the sign into binary spacing alone added 4/18 em. Returning `auto` restored the original positions. A 40 pt continuation gap moved the common anchor on the page while keeping both terms aligned. In the four-column fixture the later plus was already binary, so replacing its medium native gap with 9 pt added only the difference. These tests compare positions within rows as well as alignment between rows. [Geometry fixtures](../tests/aligned.typ)

The MathML comparison includes table cells, glyph content and the `form` attribute on every operator. Inserting a space before the marker in the leading-plus fixture made Typst drop `form="prefix"`. Paged output can safely insert that space. HTML retains the native crossed gap. The two targets still share the row classification used to rank ordinary boundaries. A wider right-aligned cell can increase the overall width and shift a centered equation on the page. [Visual comparison](aligned-rows.svg) · [API and limits](../README.md#known-limitations)

## Compilation cost

An initial prototype eagerly added the row and typographic role to existing callbacks. Its 5,000-equation cycled hierarchical and adaptive runs were 12% and 14% slower than the baseline. The final API builds row context on request and records a role override only for selected continuations. The same boundary resolver handles ordinary and crossed gaps. Static rules run group predicates on the original content, then cache plans by element kind and class wherever node identity is unobservable.

Typst 0.15.1 (9dfd3a08), Linux x86-64, Intel Core i7-13700HX. Each observation is a fresh, single-job PDF compilation with bundled fonts. Time is wall-clock seconds and memory is peak process RSS in MiB. The unaligned workload cycles 67 equations. It excludes the single aligned case and the historical throughput exclusion `fraction-style`. Distinct workloads append a different numerical identifier to each equation. Both exclusions remain in the functional corpus. The existing-profile tables show the baseline followed by the revised implementation, using medians of five processes per revision. [Individual measurements](row-audit-data.tsv) · [Audit harness](../tests/audit/audit.py)

On 5,000 distinct unaligned equations the five existing profiles ranged from -7.5% to +7.3% in wall time and -2.5% to +6.9% in peak RSS relative to 0.1.1. Explicitly requesting aligned row context on the revised implementation ranged from -1.9% to +1.7% in time relative to its default. These figures describe this compiler and workload.

Contextual callbacks retain a measurable cost on this machine. With 5,000 cycled equations, the hierarchical profile rose from 1.792 s to 1.918 s and from 192.6 to 214.2 MiB. On 1,000 distinct display equations, adaptive took 0.776 s at baseline, 0.819 s with the revised default and 0.870 s with row context enabled. The benchmark therefore supports the gains for static profiles and shows a remaining cost for contextual profiles even without alignment markers.

### Existing profiles, time in seconds

| Equations | Native | Basic | Compact | Hierarchical | Adaptive | Wide |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 cycled | 0.019 → 0.016 | 0.057 → 0.062 | 0.054 → 0.060 | 0.093 → 0.099 | 0.080 → 0.087 | 0.055 → 0.059 |
| 1,000 cycled | 0.071 → 0.072 | 0.156 → 0.136 | 0.157 → 0.137 | 0.407 → 0.456 | 0.445 → 0.474 | 0.154 → 0.138 |
| 1,000 distinct | 0.090 → 0.093 | 0.400 → 0.412 | 0.451 → 0.426 | 0.751 → 0.806 | 0.783 → 0.826 | 0.454 → 0.428 |
| 5,000 cycled | 0.308 → 0.299 | 0.586 → 0.468 | 0.593 → 0.480 | 1.792 → 1.918 | 2.023 → 2.105 | 0.596 → 0.478 |
| 5,000 distinct | 0.429 → 0.428 | 1.869 → 1.925 | 2.159 → 1.996 | 3.594 → 3.851 | 3.811 → 4.088 | 2.161 → 2.030 |

### Existing profiles, peak RSS in MiB

| Equations | Native | Basic | Compact | Hierarchical | Adaptive | Wide |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 cycled | 29.8 → 30.0 | 37.0 → 36.6 | 36.9 → 36.9 | 37.5 → 37.5 | 39.5 → 39.5 | 37.0 → 36.7 |
| 1,000 cycled | 43.9 → 43.7 | 56.0 → 54.9 | 56.8 → 55.6 | 67.0 → 67.6 | 75.2 → 76.4 | 56.6 → 55.7 |
| 1,000 distinct | 50.4 → 50.4 | 99.5 → 101.9 | 105.2 → 107.4 | 107.0 → 106.5 | 131.3 → 130.9 | 107.2 → 107.4 |
| 5,000 cycled | 112.3 → 112.5 | 143.9 → 139.6 | 148.1 → 144.8 | 192.6 → 214.2 | 236.0 → 243.0 | 148.4 → 144.3 |
| 5,000 distinct | 141.9 → 141.8 | 377.8 → 373.6 | 418.8 → 408.5 | 382.4 → 408.7 | 523.0 → 523.7 | 419.4 → 411.5 |

### Cost of requesting rows

The following control enables `rows: "aligned"` on the same unaligned inputs without changing the original profile rules. It isolates the cost of making the extra context available. Each cell shows the revised default followed by the opted-in result. The opted-in and original mixed-corpus control each use three processes per cell. A consumer that scans the row for every edge also pays for its own predicate.

| Equations | Native | Basic | Compact | Hierarchical | Adaptive | Wide |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 cycled | 0.016 → 0.017 | 0.062 → 0.061 | 0.060 → 0.057 | 0.099 → 0.097 | 0.087 → 0.088 | 0.059 → 0.055 |
| 1,000 cycled | 0.072 → 0.074 | 0.136 → 0.141 | 0.137 → 0.141 | 0.456 → 0.490 | 0.474 → 0.507 | 0.138 → 0.145 |
| 1,000 distinct | 0.093 → 0.092 | 0.412 → 0.437 | 0.426 → 0.428 | 0.806 → 0.837 | 0.826 → 0.870 | 0.428 → 0.444 |
| 5,000 cycled | 0.299 → 0.312 | 0.468 → 0.478 | 0.480 → 0.484 | 1.918 → 2.073 | 2.105 → 2.294 | 0.478 → 0.478 |
| 5,000 distinct | 0.428 → 0.421 | 1.925 → 1.919 | 1.996 → 1.990 | 3.851 → 3.917 | 4.088 → 4.135 | 2.030 → 1.992 |

| 5,000 distinct | Default RSS (MiB) | Row mode RSS (MiB) | Mixed workload default time (s) | Mixed workload default RSS (MiB) |
| --- | ---: | ---: | ---: | ---: |
| Native | 141.8 | 142.0 | 0.420 | 141.5 |
| Basic | 373.6 | 371.3 | 1.910 | 374.4 |
| Compact | 408.5 | 411.0 | 1.970 | 412.6 |
| Hierarchical | 408.7 | 409.2 | 3.785 | 407.9 |
| Adaptive | 523.7 | 524.8 | 3.949 | 522.0 |
| Wide | 411.5 | 410.6 | 1.977 | 412.5 |

The mixed control uses all 68 historical throughput cases, including the aligned equation. The timing runs measure whole processes. Sub-millisecond differences on short compilations are sensitive to process startup and scheduling.

### Display equations without alignment markers

This additional control typesets 1,000 distinct equations as display math. The baseline, revised default and revised aligned mode rotate order between rounds. Values are medians of three processes. The workload inputs are `workload=unaligned`, `count=1000`, `unique=true` and `display=true`. The final column pair also supplies `rows=aligned`.

| Profile | 0.1.1 time (s) | Revised time (s) | Opt-in time (s) | 0.1.1 RSS (MiB) | Revised RSS (MiB) | Opt-in RSS (MiB) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Native | 0.083 | 0.083 | 0.082 | 45.8 | 45.8 | 45.8 |
| Basic | 0.390 | 0.406 | 0.417 | 96.8 | 99.0 | 102.7 |
| Compact | 0.448 | 0.418 | 0.435 | 103.2 | 105.6 | 109.0 |
| Hierarchical | 0.742 | 0.788 | 0.827 | 100.7 | 101.1 | 102.7 |
| Adaptive | 0.776 | 0.819 | 0.870 | 131.0 | 128.9 | 133.5 |
| Wide | 0.447 | 0.417 | 0.435 | 104.7 | 105.1 | 109.1 |

## Reproduction

From the repository root, run the following commands on Linux with the pinned Typst CLI. Copying the workload driver gives the baseline the same unaligned filter and equation ordering.

```sh
baseline=$(mktemp -d)
git archive 61a1922 | tar -x -C "$baseline"
cp tests/audit/run.typ "$baseline/tests/audit/run.typ"
python3 tests/check.py
python3 tests/audit/audit.py --root "$baseline" --bench-only --unaligned --bench 5
python3 tests/audit/audit.py --unaligned --bench 5
python3 tests/audit/audit.py --bench-only --unaligned --rows aligned --bench 3
python3 tests/audit/audit.py --bench-only --bench 3
```

The display-only control uses the same driver. Run each profile on each checkout, optionally adding `--input rows=aligned` on the revision. For example:

```sh
typst compile --root . --ignore-system-fonts --jobs 1 --input workload=unaligned \
  --input count=1000 --input unique=true --input display=true --input profile=adaptive \
  tests/audit/run.typ /tmp/row-spacing-display.pdf
```
