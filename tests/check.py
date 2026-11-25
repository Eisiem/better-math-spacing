"""Probe regressions. Requires Python 3 and the Typst 0.15.1 CLI."""
from html.parser import HTMLParser
from pathlib import Path
import json
import subprocess
from tempfile import TemporaryDirectory
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]


class MathPage(HTMLParser):
    """Read the MathML fragments embedded in Typst’s HTML output."""

    def __init__(self, html):
        super().__init__()
        self.builder = None
        self.formulas = []
        self.links = []
        self.feed(html)
        self.close()

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            self.links.append(dict(attrs).get("href"))
        if tag == "math":
            if self.builder is None:
                self.builder = ET.TreeBuilder()
                self.depth = 0
            self.depth += 1
        if self.builder is not None:
            self.builder.start(tag, dict(attrs))

    def handle_endtag(self, tag):
        if self.builder is not None:
            self.builder.end(tag)
            if tag == "math":
                self.depth -= 1
                if self.depth == 0:
                    self.formulas.append(self.builder.close())
                    self.builder = None

    def handle_data(self, data):
        if self.builder is not None:
            self.builder.data(data)


def structure(node):
    attrs = {k: v for k, v in node.attrib.items() if k not in ("lspace", "rspace")}
    return node.tag, node.text, attrs, [structure(n) for n in node if n.tag != "mspace"]


def widths(node):
    return [space.get("width") for space in node.iter("mspace")]


def gallery_edges(formula):
    def atom_text(node):
        if node.tag in ("msub", "msup", "msubsup", "munder", "mover", "munderover"):
            node = node[0]
        return "".join(node.itertext())

    found = []
    for parent in formula.iter():
        for index, node in enumerate(parent):
            if node.tag == "mspace":
                assert 0 < index < len(parent) - 1, "unexpected space at an edge"
                pair = atom_text(parent[index - 1]) + atom_text(parent[index + 1])
                found.append((pair, node.get("width")))
    return found


def check_gallery(formulas):
    expected = [
        [("𝑎+", "11.3386pt"), ("+𝑏", "11.3386pt"), ("𝑏−", "11.3386pt"), ("−𝑐", "11.3386pt")],
        [("+−", "0.65em")],
        [],
        [("∑=", "0.5556em"), ("=∏", "0.5556em"), ("∏𝑥", "0.3333em"),
         ("𝑥⇒", "0.5556em"), ("⇒𝑦", "0.5556em")],
        [],
        [("𝑏⇒", "0.6em"), ("⇒𝑐", "0.6em")],
        [("𝑎+", "0.12em"), ("+𝑏", "0.12em"), (",𝑐", "0.75em"),
         ("𝑐+", "0.12em"), ("+𝑑", "0.12em")],
        [("−𝑎", "0.08em"), ("𝑎−", "0.35em"), ("−𝑏", "0.35em")],
    ]
    assert len(formulas) == 2 * len(expected)
    for i, edges in enumerate(expected):
        native, edited = formulas[2 * i:2 * i + 2]
        assert structure(native) == structure(edited), f"structure, row {i + 1}"
        assert gallery_edges(native) == [] and gallery_edges(edited) == edges, f"boundaries, row {i + 1}"


def check_scopes(native, changed):
    assert len(native.formulas) == len(changed.formulas) == 4
    slash, call, rebuilt, collision = changed.formulas
    assert [op.text for op in slash.iter("mo")] == ["(", "+", ")", "/", "(", "−", ")"]
    assert [op.text for op in call.iter("mo")] == ["+", "/", "−"]
    assert structure(call) == structure(rebuilt)
    for a, b in zip(native.formulas, changed.formulas):
        assert structure(a) == structure(b)
        assert widths(a) == [] and widths(b) == ["3pt"] * 4
    # A value selector aimed at the numerator matches both branches.
    num, denom = collision.find("mfrac")
    assert widths(num) == widths(denom) == ["3pt", "3pt"]


def check_aligned_rows(render):
    colors = {"#236ba3": "b", "#a3236b": "c", "#178459": "p",
              "#a35f23": "q", "#5f23a3": "+"}

    def positions(case, profile):
        svg = ET.fromstring(render("aligned", "svg", f"case={case}",
                                   f"profile={profile}", folder="tests"))
        result = {}
        for group in svg.findall("{*}g"):
            matrix = group.attrib["transform"].removeprefix("matrix(").removesuffix(")").split()
            for glyph in group.findall("{*}use"):
                color = glyph.get("fill")
                if color in colors:
                    assert matrix[:4] == ["1", "0", "0", "-1"], matrix
                    x = float(matrix[4]) + float(glyph.get("x", "0"))
                    result.setdefault(colors[color], []).append(x)
        assert result, (case, profile)
        return result

    def near(a, b):
        assert abs(a - b) < 0.001, (a, b)

    native = positions("leading", "native")
    assert positions("leading", "legacy") == native
    assert positions("leading", "across") == native
    assert positions("leading", "cancel") == native
    for profile, gap in (("binary", 9), ("groups", 9), ("role-only", 16 * 4 / 18), ("scale", 16 / 3)):
        edited = positions("leading", profile)
        near(edited["b"][0], edited["c"][0])
        if profile != "groups":
            near(edited["b"][0], native["b"][0])
        near((edited["c"][0] - edited["+"][0]) - (native["c"][0] - native["+"][0]), gap)

    wide = positions("leading", "large-gap")
    near(wide["b"][0], wide["c"][0])
    near((wide["c"][0] - wide["+"][0]) - (native["c"][0] - native["+"][0]), 40)
    assert abs(wide["b"][0] - native["b"][0]) > 1

    # A group selecting binary signs changes the infix sign later in this
    # row. The gap from the separate prefix + to c must still be native.
    for profile in ("groups", "role-only"):
        prefix = positions("prefix", profile)
        original = positions("prefix", "native")
        near(prefix["c"][0] - prefix["+"][0], original["c"][0] - original["+"][0])

    before = positions("columns", "native")
    after = positions("columns", "binary")
    for upper, lower, i in (("b", "c", 0), ("p", "q", 1)):
        near(after[upper][0], after[lower][0])
        near((after[lower][0] - after["+"][i]) - (before[lower][0] - before["+"][i]),
             9 - (0 if i == 0 else 16 * 4 / 18))
    for case in ("prefix", "even", "double", "explicit", "explicit-right", "fenced",
                 "opaque", "single", "trailing", "compound"):
        assert positions(case, "native") == positions(case, "binary"), case

    assert positions("rank-geometry", "profile") == positions("rank-geometry", "reference")
    for case in ("leading", "prefix", "columns", "double", "explicit", "opaque"):
        def formula(profile):
            return MathPage(render("aligned", "html", f"case={case}",
                                   f"profile={profile}", folder="tests")).formulas[0]
        original = formula("native")
        for profile in ("across", "binary", "groups", "role-only"):
            assert structure(formula(profile)) == structure(original), (case, profile)

    corpus = MathPage(render("aligned", "html", "case=corpus", folder="tests")).formulas
    assert len(corpus) == 2 * 69
    paired = list(zip(corpus[::2], corpus[1::2]))
    assert all(structure(a) == structure(b) for a, b in paired)
    assert sum(widths(a) != widths(b) for a, b in paired) == 61
    render("aligned", "svg", "case=nested-width", folder="tests")
    render("aligned", "svg", "case=contexts", folder="tests")
    render("aligned", "svg", "case=contexts", "profile=context-only", folder="tests")
    formulas = MathPage(render("aligned", "html", "case=profile", folder="tests")).formulas
    original = MathPage(render("aligned", "html", "case=profile", "profile=native-control",
                               folder="tests")).formulas
    assert [structure(f) for f in formulas] == [structure(f) for f in original]
    assert [widths(f) for f in formulas] == [
        ["2pt"] * 4 + ["3pt", "4pt", "4pt"] + ["2pt"] * 3,
        ["4pt"] * 3 + ["8pt"] * 2,
        ["2pt", "2pt", "8pt", "8pt", "1em", "4pt", "4pt"],
        ["2pt"],
        ["2pt", "2pt", "4pt", "4pt", "8pt", "8pt", "16pt", "16pt"],
        ["2pt", "2pt", "4pt", "4pt", "2pt", "2pt"],
        [],
        ["2pt", "2pt", "4pt", "2pt", "2pt", "4pt", "4pt"],
    ]


def check():
    with TemporaryDirectory() as tmp:
        def render(name, ext="svg", *inputs, folder="probes", error=None):
            args = ["typst", "compile", "--ignore-system-fonts", "--root", str(ROOT)]
            if ext == "html":
                args.extend(["--features", "html"])
            for setting in inputs:
                args.extend(["--input", setting])
            out = Path(tmp) / f"{name}.{ext}"
            cmd = [*args, str(ROOT / folder / f"{name}.typ"), str(out)]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if error is not None:
                assert result.returncode and error in result.stderr, result.stderr
                return
            if result.returncode:
                raise RuntimeError(result.stderr)
            return out.read_text(encoding="utf-8")

        def page(name, *inputs):
            return MathPage(render(name, "html", *inputs))

        check_aligned_rows(render)

        for fixture in ("geometry", "structure", "cases", "nested"):
            render(fixture)
        cases = page("cases")
        assert cases.links == ["#first", "#second"]
        assert [widths(eq) for eq in cases.formulas] == [["11.3386pt"] * 2] * 2
        check_gallery(page("gallery").formulas)
        gallery = MathPage(render("gallery", "html", folder="examples"))
        assert len(gallery.formulas) == 40
        signatures = set()
        for i in range(0, 40, 5):
            native, *profiles = gallery.formulas[i:i + 5]
            signatures.add(tuple(tuple(widths(n)) for n in profiles))
            assert all(structure(native) == structure(n) for n in profiles)
        assert len(signatures) >= 5
        assert widths(gallery.formulas[2 * 5 + 2]) != widths(gallery.formulas[2 * 5 + 1])
        for case, expected in (("decimal", ["0.32em", "0.32em"]),
                               ("nested-sign", ["0.32em"] * 4)):
            native = MathPage(render("run", "html", f"case={case}", folder="tests/audit"))
            adjusted = MathPage(render("run", "html", f"case={case}", "profile=basic",
                                       folder="tests/audit"))
            a, = native.formulas
            b, = adjusted.formulas
            assert structure(a) == structure(b)
            assert widths(b) == expected, (case, widths(b))

        def audit_metadata(name, expression):
            command = ["typst", "eval", "--ignore-system-fonts", "--root", str(ROOT),
                       "--in", str(ROOT / f"tests/audit/{name}.typ"), expression]
            return json.loads(subprocess.check_output(command, text=True))

        fidelity = audit_metadata("fidelity", "query(metadata).map(n => n.value).flatten()")
        assert all(abs(item["w"]) < 0.01 and abs(item["y"]) < 0.01 for item in fidelity), fidelity
        compatibility = audit_metadata("compat", "query(metadata).first().value")
        assert abs(compatibility["weak"] - compatibility["weak-target"]) < 0.001
        proofs_native = MathPage(render("proofs", "html", folder="tests/audit"))
        assert len(proofs_native.formulas) == 21
        assert proofs_native.links == ["#gram", "#gram", "#gram", "#bound"]
        for profile in ("basic", "compact", "hierarchical", "adaptive", "wide"):
            proofs = MathPage(render("proofs", "html", f"profile={profile}", folder="tests/audit"))
            assert proofs.links == proofs_native.links
            assert [structure(n) for n in proofs.formulas] == [
                structure(n) for n in proofs_native.formulas
            ]

        native_scopes = MathPage(render("scopes", "html", folder="tests/audit")).formulas
        edited_scopes = MathPage(render("scopes", "html", "profile=scoped", folder="tests/audit")).formulas
        assert [structure(f) for f in native_scopes] == [structure(f) for f in edited_scopes]
        assert [widths(f) for f in edited_scopes] == [
            ["4pt", "7pt", "3pt", "4pt"], ["4pt"], ["3pt", "4pt"] * 2,
            ["3pt", "4pt", *widths(native_scopes[3]), "3pt", "4pt"],
            ["3pt", "4pt"] * 2, ["3pt", "4pt"], ["2pt", "2pt", "7pt", "7pt"],
        ]
        assert [widths(cell) for cell in edited_scopes[0].iter("mtd")] == [
            [], ["4pt"], ["7pt", "3pt", "4pt"], [],
        ]
        assert widths(edited_scopes[2].find(".//math")) == []
        assert widths(edited_scopes[5].find(".//mfrac")) == ["3pt", "4pt"]

        assert "#ff4136" in render("package", folder="tests")
        packaged = MathPage(render("package", "html", folder="tests"))
        formula, = packaged.formulas
        assert [op.text for op in formula.iter("mo")] == ["(", "+", ")", "/", "(", "+", ")"]
        assert [n.text for n in formula.iter("mi")].count("𝑧") == 2
        assert widths(formula) == ["11.3386pt"] * 4 and packaged.links == ["#control"]
        render("package", "svg", "case=collision", folder="tests", error="Conflicting spacing")
        render("package", "svg", "case=invalid", folder="tests", error="Expected a length")
        check_scopes(page("scopes"), page("scopes", "scope=edited"))
        fractions, local, mixed, split = page("occurrences").formulas
        assert structure(fractions) == structure(local)
        assert widths(local) == ["2pt", "2pt", "7pt", "7pt"]
        assert structure(mixed) == structure(split)
        assert widths(split) == ["3pt", "3pt", *widths(mixed)]


        original_nested = page("nested")
        changed_nested = page("nested", "spaced=yes")
        assert [structure(e) for e in original_nested.formulas] == [
            structure(e) for e in changed_nested.formulas
        ]
        assert [widths(e) for e in changed_nested.formulas] == [
            ["0.5556em"] * 2 + ["0.4444em"] * 2, [],
        ]

        native = page("interop")
        edited = page("interop", "spaced=guard")
        broken = page("interop", "spaced=bare")
        a, = native.formulas
        b, = edited.formulas
        c, = broken.formulas
        assert structure(a) == structure(b) and structure(a) != structure(c)
        assert widths(a) == [] and widths(b) == ["11.3386pt"] * 7
        assert native.links == edited.links == ["#structure"]
        assert "𝑞" in "".join(b.itertext())  # external z → q rule
        for tag in ("mfrac", "mtable", "msubsup"):
            assert b.find(".//" + tag) is not None
        for mode in ("no", "guard"):
            svg = render("interop", "svg", f"spaced={mode}")
            assert "#0074d9" in svg and "#ff4136" in svg  # two external show-set rules


if __name__ == "__main__":
    print(subprocess.check_output(["typst", "--version"], text=True).strip())
    check()
    print("OK · Row geometry, operator forms, probes, 40 gallery equations, references and collision checks passed.")
