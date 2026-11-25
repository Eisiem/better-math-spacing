#import "../../lib.typ": spacing
#import "../../examples/profiles.typ": profiles
#import "corpus.typ": corpus

#let profile = sys.inputs.at("profile", default: "native")
#show math.equation: spacing.with(..profiles.at(profile))
#set text(lang: "en")
#set math.equation(numbering: "(1)")

= Gram–Schmidt orthogonalization

Let $(v_1, dots, v_n)$ be a linearly independent family in a real Euclidean
space. Set $u_1 = v_1$. If the vectors constructed through $k-1$ are
orthogonal, define
#math.equation(corpus.gram.body, block: true) <gram>

For $i<k$, linearity and the induction hypothesis give
$ chevron.l u_k,u_i chevron.r
  = chevron.l v_k,u_i chevron.r -
    (chevron.l v_k,u_i chevron.r / chevron.l u_i,u_i chevron.r)
    chevron.l u_i,u_i chevron.r = 0. $
All denominators in @gram are positive. If $u_k = 0$, @gram expresses
$v_k$ as a linear combination of the preceding vectors, contradicting
linear independence. By induction, @gram also gives
$ op("span")(u_1, dots, u_k) = op("span")(v_1, dots, v_k). $
Dividing each vector by its norm yields an orthonormal basis of the same subspace.

= Uniform convergence and integration

Let $f_n$ and $f$ be continuous on $[a,b]$, with $a<b$. Suppose $f_n$ converges
uniformly to $f$. Define
$ M_n = sup_(x in [a,b]) abs(f_n(x)-f(x)), quad M_n -> 0. $
By the triangle inequality and monotonicity of the integral,
$ abs(integral_a^b f_n(x) dif x - integral_a^b f(x) dif x)
   <= integral_a^b abs(f_n(x)-f(x)) dif x <= (b-a) M_n. $ <bound>
Given $epsilon>0$, there is an index beyond which
$M_n < epsilon/(b-a)$. Then @bound bounds the difference of the integrals
by $epsilon$, so
$ lim_(n -> oo) integral_a^b f_n(x) dif x = integral_a^b f(x) dif x. $
