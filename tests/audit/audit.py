"""Reproduce functional and performance measurements using only Typst and Python."""
import argparse
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
from tempfile import TemporaryDirectory
from time import perf_counter

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from check import MathPage, structure, widths

ROOT = Path(__file__).resolve().parents[2]
MODES = ("native", "basic", "compact", "hierarchical", "adaptive", "wide")


def arguments(root, mode, **inputs):
    args = ["--root", str(root), "--ignore-system-fonts", "--jobs", "1"]
    for key, value in dict(profile=mode, **inputs).items():
        args.extend(("--input", f"{key}={value}"))
    return args


def functional(root, temporary):
    source = root / "tests/audit/run.typ"
    out = temporary / "formula.html"
    ids = json.loads(subprocess.check_output(["typst", "eval", "--root", root,
        '{import "tests/audit/corpus.typ": corpus; corpus.keys()}'], text=True))
    outcomes = []
    for key in ids:
        row = {"id": key}
        traces = {}
        for mode in (*MODES, "admit", "estimate"):
            args = arguments(root, mode, case=key)
            result = subprocess.run(["typst", "compile", "--features", "html", *args, source, out],
                                    capture_output=True, text=True)
            if mode == "admit":
                row["analyzed"] = "AUDIT: analyzed" in result.stderr
                assert row["analyzed"] or result.returncode == 0, result.stderr
            elif result.returncode:
                if mode == "native":
                    raise RuntimeError(result.stderr)
                row[mode] = {"error": result.stderr.splitlines()[0]}
            else:
                page = MathPage(out.read_text())
                traces[mode] = page.formulas
                base = traces["native"]
                if mode != "native":
                    row[mode] = {
                        "structure": [structure(n) for n in base] == [structure(n) for n in page.formulas],
                        "changed": [widths(n) for n in base] != [widths(n) for n in page.formulas],
                    }
        if "error" not in row["estimate"] and row["analyzed"]:
            result = subprocess.run(["typst", "eval", *arguments(root, "estimate", case=key),
                "--in", source, "query(metadata).first().value.delta"], capture_output=True, text=True)
            if result.returncode:
                row["estimate"]["paged-error"] = result.stderr.splitlines()[0]
            else:
                row["estimate"]["delta-pt"] = json.loads(result.stdout)
        outcomes.append(row)
    return outcomes


def benchmark(root, temporary, repeats, unaligned, rows):
    source = root / "tests/audit/run.typ"
    out = temporary / "benchmark.pdf"
    samples = []
    # The mixed-style fraction is a measured error case. The throughput
    # document uses the rest of the corpus so each profile can finish.
    for count, unique in ((100, False), (1000, False), (1000, True), (5000, False), (5000, True)):
        for repetition in range(repeats):
            for mode in MODES[repetition % len(MODES):] + MODES[:repetition % len(MODES)]:
                args = arguments(root, mode, count=count, unique=str(unique).lower(),
                                 workload="unaligned" if unaligned else "true")
                if rows:
                    args.extend(("--input", f"rows={rows}"))
                with (temporary / "stderr").open("w+") as log:
                    start = perf_counter()
                    child = subprocess.Popen(["typst", "compile", *args, source, out],
                                             stdout=subprocess.DEVNULL, stderr=log)
                    _, status, usage = os.wait4(child.pid, 0)
                    child.returncode = os.waitstatus_to_exitcode(status)
                    elapsed = perf_counter() - start
                    if child.returncode:
                        log.seek(0)
                        raise RuntimeError(log.read())
                samples.append(dict(count=count, unique=unique, profile=mode, seconds=elapsed,
                                    peak_mib=usage.ru_maxrss / 1024))
        print(f"{count} {'distinct' if unique else 'cycled'} equations measured", file=sys.stderr)
    return samples


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--bench", type=int, default=0, metavar="REPS")
    parser.add_argument("--bench-only", action="store_true")
    parser.add_argument("--unaligned", action="store_true", help="exclude the aligned fixture from timing runs")
    parser.add_argument("--rows", choices=("context", "aligned"), help="request row metadata in benchmark profiles")
    args = parser.parse_args()
    root = args.root.resolve()
    stamp = dict(typst=subprocess.check_output(["typst", "--version"], text=True).strip(),
                 platform=platform.platform())
    with TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        if not args.bench_only:
            stamp["functional"] = functional(root, tmp)
        if args.bench:
            stamp["workload"] = dict(repeats=args.bench, unaligned=args.unaligned, rows=args.rows)
            stamp["samples"] = benchmark(root, tmp, args.bench, args.unaligned, args.rows)
    print(json.dumps(stamp, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
