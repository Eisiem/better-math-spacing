"""Regresiones de las sondas. Requiere Python 3 y la CLI de Typst 0.15.1."""
from html.parser import HTMLParser
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]


class MathPage(HTMLParser):
    """Lee los fragmentos MathML embebidos en el HTML generado por Typst."""

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
            self.builder = ET.TreeBuilder()
        if self.builder is not None:
            self.builder.start(tag, dict(attrs))

    def handle_endtag(self, tag):
        if self.builder is not None:
            self.builder.end(tag)
            if tag == "math":
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
                assert 0 < index < len(parent) - 1, "espacio inesperado en un extremo"
                pair = atom_text(parent[index - 1]) + atom_text(parent[index + 1])
                found.append((pair, node.get("width")))
    return found


def check_gallery(page):
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
    assert len(page.formulas) == 2 * len(expected)
    for i, edges in enumerate(expected):
        native, edited = page.formulas[2 * i:2 * i + 2]
        assert structure(native) == structure(edited), f"estructura, fila {i + 1}"
        assert gallery_edges(native) == [] and gallery_edges(edited) == edges, f"fronteras, fila {i + 1}"


def check_scopes(native, changed):
    assert len(native.formulas) == len(changed.formulas) == 4
    slash, call, rebuilt, collision = changed.formulas
    assert [op.text for op in slash.iter("mo")] == ["(", "+", ")", "/", "(", "−", ")"]
    assert [op.text for op in call.iter("mo")] == ["+", "/", "−"]
    assert structure(call) == structure(rebuilt)
    for a, b in zip(native.formulas, changed.formulas):
        assert structure(a) == structure(b)
        assert widths(a) == [] and widths(b) == ["3pt"] * 4
    # Un selector por valor apuntaba al numerador. Alcanza las DOS ramas.
    num, denom = collision.find("mfrac")
    assert widths(num) == widths(denom) == ["3pt", "3pt"]


def check():
    with TemporaryDirectory() as tmp:
        def render(name, ext="svg", *inputs):
            args = ["typst", "compile", "--ignore-system-fonts"]
            if ext == "html":
                args.extend(["--features", "html"])
            for setting in inputs:
                args.extend(["--input", setting])
            out = Path(tmp) / f"{name}.{ext}"
            cmd = [*args, str(ROOT / "probes" / f"{name}.typ"), str(out)]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode:
                raise RuntimeError(result.stderr)
            return out.read_text(encoding="utf-8")

        def page(name, *inputs):
            return MathPage(render(name, "html", *inputs))

        for fixture in ("geometry", "structure", "cases", "nested"):
            render(fixture)
        cases = page("cases")
        assert cases.links == ["#primera", "#segunda"]
        assert [widths(eq) for eq in cases.formulas] == [["11.3386pt"] * 2] * 2
        check_gallery(page("gallery"))
        check_scopes(page("scopes"), page("scopes", "scope=edited"))

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
        assert native.links == edited.links == ["#estruct"]
        assert "𝑞" in "".join(b.itertext())  # regla externa z → q
        for tag in ("mfrac", "mtable", "msubsup"):
            assert b.find(".//" + tag) is not None
        for mode in ("no", "guard"):
            svg = render("interop", "svg", f"spaced={mode}")
            assert "#0074d9" in svg and "#ff4136" in svg  # dos show-set externos


if __name__ == "__main__":
    print(subprocess.check_output(["typst", "--version"], text=True).strip())
    check()
    print("OK · Geometría, ocho comparaciones, estructura, MathML, referencias y controles negativos.")
