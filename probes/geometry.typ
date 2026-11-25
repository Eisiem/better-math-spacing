// Standalone experiment using only Typst 0.15.1.
#set text(size: 12pt)
#show math.equation: set text(font: "New Computer Modern Math")

#let w(eq) = measure(eq).width
#let close(x, y) = assert(calc.abs(x - y) < 0.001pt,
  message: "Unexpected measurement: " + repr(x) + ", expected " + repr(y))

#context {
  // Both gaps exclude intrinsic glyph bearings.
  let advances = w($a$) + w($+$) + w($b$)
  let native = w($a+b$)
  close(native - advances, 2 * 12pt * 4/18)
  close(w($a#h(0pt)+#h(0pt)b$), advances)
  close(w($a#h(4mm)+#h(4mm)b$), advances + 8mm)

  // Explicit spacing before a variable operator clears its context.
  close(w($a #h(0pt) + b$), advances)
  close(w($a + #h(0pt) b$), advances + 12pt * 4/18)
  close(w($a #h(4mm) class("binary", +) b$), advances + 4mm + 12pt * 4/18)

  // Changing one side of an equals sign preserves its class.
  close(w($a=b$) - w($a#h(0pt)=b$), 12pt * 5/18)
  close(w($a=b$) - w($a=#h(0pt)b$), 12pt * 5/18)
  close(w($a#h(2pt)=#h(6pt)b$) - w($a#h(0pt)=#h(0pt)b$), 8pt)

  // The boundary between binary and unary operators admits a separate exception.
  close(w($a+#h(2pt)-b$) - w($a+#h(0pt)-b$), 2pt)
  close(w($-b$), w($-$) + w($b$))
  close(w($a-b$), native)

  // An em uses the local math font size. Typst ignores percentage and fr units
  // here. A scale factor is independent of the units.
  close(w($a#h(1em)+#h(1em)b$) - advances, 24pt)
  let sub = w($x_(a#h(1em)+#h(1em)b)$) - w($x_(a#h(0pt)+#h(0pt)b)$)
  close(sub, 16.8pt)
  close(w($a#h(10%)+#h(10%)b$), native)
  close(w($a#h(1fr)+#h(1fr)b$), native)
  metadata((native: native.pt(), zero: advances.pt(), four-mm: (advances+8mm).pt(), script-two-em: sub.pt()))
}

// An external class override changes the side that still uses automatic spacing.
#show $+$.body.func().where(text: "+"): op => math.class("relation", op)
#context {
  let as-relation = w($a #h(0pt) + b$)
  let forced = w($a #h(0pt) class("binary", +) b$)
  close(as-relation - forced, 12pt * (5/18 - 4/18))
}
