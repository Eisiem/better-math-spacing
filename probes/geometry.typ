// Experimento aislado para Typst 0.15.1. Sólo usa el motor de Typst.
#set text(size: 12pt)
#show math.equation: set text(font: "New Computer Modern Math")

#let w(eq) = measure(eq).width
#let close(x, y) = assert(calc.abs(x - y) < 0.001pt,
  message: "medida inesperada: " + repr(x) + ", esperada " + repr(y))

#context {
  // Las dos distancias excluyen los márgenes intrínsecos de los glifos.
  let advances = w($a$) + w($+$) + w($b$)
  let native = w($a+b$)
  close(native - advances, 2 * 12pt * 4/18)
  close(w($a#h(0pt)+#h(0pt)b$), advances)
  close(w($a#h(4mm)+#h(4mm)b$), advances + 8mm)

  // El espacio explícito antes de un operador variable borra su contexto.
  close(w($a #h(0pt) + b$), advances)
  close(w($a + #h(0pt) b$), advances + 12pt * 4/18)
  close(w($a #h(4mm) class("binary", +) b$), advances + 4mm + 12pt * 4/18)

  // Para '=' no cambia la clase al modificar un único lado.
  close(w($a=b$) - w($a#h(0pt)=b$), 12pt * 5/18)
  close(w($a=b$) - w($a=#h(0pt)b$), 12pt * 5/18)
  close(w($a#h(2pt)=#h(6pt)b$) - w($a#h(0pt)=#h(0pt)b$), 8pt)

  // La frontera entre binario y unario admite una excepción independiente.
  close(w($a+#h(2pt)-b$) - w($a+#h(0pt)-b$), 2pt)
  close(w($-b$), w($-$) + w($b$))
  close(w($a-b$), native)

  // Un em usa el cuerpo local de la matemática. El porcentaje y el fr se
  // descartan en este contexto. El factor es independiente de las unidades.
  close(w($a#h(1em)+#h(1em)b$) - advances, 24pt)
  let sub = w($x_(a#h(1em)+#h(1em)b)$) - w($x_(a#h(0pt)+#h(0pt)b)$)
  close(sub, 16.8pt)
  close(w($a#h(10%)+#h(10%)b$), native)
  close(w($a#h(1fr)+#h(1fr)b$), native)
  metadata((native: native.pt(), zero: advances.pt(), four-mm: (advances+8mm).pt(), script-two-em: sub.pt()))
}

// Una regla externa que redefine la clase cambia el lado todavía automático.
#show $+$.body.func().where(text: "+"): op => math.class("relation", op)
#context {
  let as-relation = w($a #h(0pt) + b$)
  let forced = w($a #h(0pt) class("binary", +) b$)
  close(as-relation - forced, 12pt * (5/18 - 4/18))
}
