// Configuraciones experimentales de una misma sonda. Las fórmulas son datos.
#let signs = ("+", "−")
#let touches(left, right, chars) = left.ch in chars or right.ch in chars

#let four-mm = row => (l, r) => if touches(l, r, signs) { 4mm } else { auto }
#let pair = row => (l, r) => {
  if l.role == "binary" and r.role == "unary" { 0.65em } else { auto }
}
#let roles = row => (l, r) => {
  if l.role == "unary" { 0.08em }
  else if l.role == "binary" or r.role == "binary" { 0.35em }
  else { auto }
}
#let hierarchy = row => {
  let has-equal = row.any(it => it.ch == "=")
  (l, r) => if has-equal and touches(l, r, ("⇒",)) { 0.6em } else { auto }
}
#let punctuation = row => (l, r) => {
  if l.ch == "," { 0.75em }
  else if touches(l, r, ("+",)) { 0.12em }
  else { auto }
}
#let doubled = row => {
  let surrounded = range(1, row.len() - 1).any(i =>
    row.at(i).ch == "=" and row.at(i - 1).kind == "large" and row.at(i + 1).kind == "large"
  )
  // En estas muestras en estilo de texto, este perfil coincide con el espacio
  // nativo alrededor de relaciones y grandes operadores. Se dobla también ⇒.
  (l, r) => {
    if not surrounded { return auto }
    let width = if l.kind == "relation" or r.kind == "relation" { 5em / 18 }
    else if l.kind == "large" or r.kind == "large" { 1em / 6 }
    else { 0pt }
    2 * width
  }
}

#let samples = (
  (name: "Signos a 4 mm por lado", eq: $a + b - c$, policy: four-mm),
  (name: "Operadores consecutivos", eq: $a + -b$, policy: pair),
  (name: "Condición ausente", eq: $a = product_j^m x => y$, policy: doubled),
  (name: "Condición entre dos grandes", eq: $sum_i^n = product_j^m x => y$, policy: doubled),
  (name: "Implicación sola", eq: $a => b$, policy: hierarchy),
  (name: "Implicación con igualdad", eq: $a = b => c$, policy: hierarchy),
  (name: "Dos términos separados por coma", eq: $(a + b, c + d)$, policy: punctuation),
  (name: "Signo prefijo y resta binaria", eq: $-a - b$, policy: roles),
)
