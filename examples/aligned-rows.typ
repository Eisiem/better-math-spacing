#import "row-profile.typ": row-profile

#set page(width: 520pt, height: auto, margin: 24pt, fill: rgb("#f4f8f8"))
#set text(font: "Libertinus Serif", size: 12pt, fill: rgb("#1a3039"))
#set par(leading: 0.6em)
#let ink = rgb("#12666b")
#let continuation(sign) = sign.row-index == 1 and sign.node == $+$.body
#let aligned = $ a = &b \ + &c + d $
#let hierarchy = $ (a+b, c+d) = &x => y \ a + b = &sum_i x_i + z $

#let card(title, first, second) = block(
  width: 100%, fill: white, radius: 5pt, inset: 14pt,
  [
    #text(fill: ink, weight: "bold")[#title]
    #v(4pt)
    #set text(size: 15pt)
    #first
    #second
  ],
)

#text(size: 22pt, weight: "bold")[Spacing across aligned rows]
#v(4pt)
#text(fill: rgb("#4f646c"))[The continuation sign gains a gap while the right-hand terms stay aligned.]
#v(12pt)
#grid(
  columns: (1fr, 1fr), gutter: 12pt,
  card("Native Typst", aligned, hierarchy),
  {
    show math.equation: row-profile(minimum: 4pt, multiplier: 1.5, continuation: continuation)
    card("Row-aware profile", aligned, hierarchy)
  },
)
