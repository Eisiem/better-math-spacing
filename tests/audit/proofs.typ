#import "../../lib.typ": spacing
#import "../../examples/profiles.typ": profiles
#import "corpus.typ": corpus

#let profile = sys.inputs.at("profile", default: "native")
#show math.equation: spacing.with(..profiles.at(profile))
#set text(lang: "es")
#set math.equation(numbering: "(1)")
= Ortogonalización de Gram–Schmidt

Sea $(v_1, dots, v_n)$ una familia linealmente independiente en un espacio
euclídeo real. Tomamos $u_1 = v_1$. Si los vectores construidos hasta
$k-1$ son ortogonales, definimos
#math.equation(corpus.gram.body, block: true) <gram>

Para $i<k$, la linealidad y la hipótesis inductiva dan
$ chevron.l u_k,u_i chevron.r
  = chevron.l v_k,u_i chevron.r -
    (chevron.l v_k,u_i chevron.r / chevron.l u_i,u_i chevron.r)
    chevron.l u_i,u_i chevron.r = 0. $
Todos los denominadores de @gram son positivos. Si $u_k = 0$, @gram
expresa $v_k$ como combinación lineal de los anteriores, lo que contradice
la independencia. Además, @gram implica por inducción
$ op("span")(u_1, dots, u_k) = op("span")(v_1, dots, v_k). $
Dividir cada vector por su norma produce una base ortonormal del mismo subespacio.

= Convergencia uniforme e integración

Sean $f_n$ y $f$ funciones continuas en $[a,b]$, con $a<b$. Supongamos que
$f_n$ converge uniformemente a $f$. Definimos
$ M_n = sup_(x in [a,b]) abs(f_n(x)-f(x)), quad M_n -> 0. $
Por la desigualdad triangular y la monotonía de la integral,
$ abs(integral_a^b f_n(x) dif x - integral_a^b f(x) dif x)
   <= integral_a^b abs(f_n(x)-f(x)) dif x <= (b-a) M_n. $ <bound>
Dado $epsilon>0$, existe un índice a partir del cual
$M_n < epsilon/(b-a)$. Entonces @bound acota la diferencia de las integrales
por $epsilon$, y concluimos
$ lim_(n -> oo) integral_a^b f_n(x) dif x = integral_a^b f(x) dif x. $
