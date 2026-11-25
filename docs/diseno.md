# Diseño propuesto

Documento histórico de la fase de viabilidad. La versión 0.1.0 incorpora factores porcentuales y un perfil nativo. El contrato vigente está en la [documentación del paquete](../README.md).

El paquete decidiría **una distancia por cada frontera entre dos átomos vecinos**. Así puede resolver qué ocurre entre dos operadores que solicitan espacio en el mismo sitio. Los átomos seguirían siendo elementos de Typst. La decisión sería una longitud o `auto`, que delega esa frontera al motor.

Los fragmentos de esta página describen la futura interfaz. Las versiones que se pueden ejecutar hoy están en las [políticas de las sondas](../probes/policies.typ) y en la [prueba con dos niveles](../probes/nested.typ).

## Uso básico

```typst
#let signos = group(sym.plus, sym.minus, before: 4mm, after: 4mm)

#show math.equation: spacing.with(groups: (signos: signos))
$a + b - c$
```

La configuración puede aplicarse a todo el documento o al ámbito de un bloque mediante la regla `show` habitual. `group`, `rule` y `spacing` serían las tres funciones públicas.

| Función | Contrato propuesto |
| --- | --- |
| `group(..miembros, before:, after:, test:)` | Un miembro puede ser un símbolo de Typst, el nombre de una clase matemática o una función de elemento como `math.frac`. Se acepta cualquiera de los miembros. Un `test` adicional filtra el resultado. Con sólo `test` se admiten los átomos que satisfacen el predicado. Los lados omitidos no hacen petición. |
| `rule(valor, left:, right:, when:)` | `left` y `right` son nombres de grupo opcionales. Si están presentes deben coincidir, junto con el predicado `when`. El valor es una longitud, `auto` o una función `e => nueva-distancia`. Una longitud sustituye el espacio. Una función puede sumar, multiplicar o calcular una distancia a partir de ambas peticiones. |
| `spacing(eq, groups: (:), rules: ())` | Regla de presentación para una ecuación. `groups` es un diccionario ordenado. `rules` es una lista ordenada o una función de la ecuación analizada que devuelve esa lista. Esta última forma permite calcular una condición una vez y compartirla entre todas las subexpresiones. |

Las longitudes admiten `pt`, `mm`, `em` y sus combinaciones. Un `em` se resuelve al componer el elemento en su tamaño matemático local. Los porcentajes de ancho y las fracciones de espacio disponible tendrían un diagnóstico al configurar el paquete. Los bordes exteriores de la ecuación carecen de pareja y no generan separaciones.

**Precedencia.** Dentro de cada átomo, el último grupo coincidente que declare un lado fija su petición para ese lado. Entre dos átomos se toma el `before` del derecho si está declarado. En su defecto se toma el `after` del izquierdo. A falta de ambos se parte de `auto`. Las reglas explícitas se aplican después, en orden de declaración. Esta convención da una decisión determinista incluso al combinar peticiones en mm y em con tamaño local desconocido. Por ejemplo, `rule(1mm, left: "suma", right: "signo")` fija el espacio entre esos dos grupos. Para sumar ambas peticiones se usaría la siguiente política.

```typst
#let sumar-lados = rule(e => e.left-after + e.right-before,
  when: e => e.left-after != none and e.right-before != none)
```

Sobre una base conocida, fijar 3 pt, sumar 1 pt y duplicar da 8 pt. Cambiar de orden las dos últimas operaciones da 7 pt. La función de transformación lee la distancia acumulada en `e.width`. Para hacer aritmética necesita una base numérica. También puede devolver `auto` para delegar la frontera. La sonda de composición comprueba ambos órdenes. [Prueba de transformaciones](../probes/nested.typ)

## Predicados y ámbitos

Un átomo expondría `node` (contenido original), `class` (clase identificada), `role` (unario/binario cuando se puede determinar) y `groups` (nombres coincidentes una vez clasificado). Los miembros de tipo elemento se comparan con `node.func()`. Por ejemplo, `group(math.frac, math.mat, before: 0.15em)` selecciona fracciones y matrices. Un `math.attach` puede ser simultáneamente un adjunto por tipo y un operador grande por la clase de su base. Una clase desconocida se representa con `none`. En un `group(test: ...)`, las propiedades disponibles son `node`, `class` y `role`.

Una frontera `e` expondría `left`, `right`, `index`, `run` (lista de átomos hermanos), `path` (pasos desde la raíz con función de contenedor, campo e índices de celda cuando proceda) y `equation`. Las propiedades `left-class` y `right-class` son las clases que se enfrentan en esa frontera. Para un grupo delimitado, la clase que ofrece a su vecino izquierdo es apertura y la que ofrece a su vecino derecho es cierre cuando ésas son las de sus delimitadores. Las peticiones originales de los grupos se leen en `left-after` y `right-before`. El índice empieza en cero e identifica al átomo izquierdo. La vista de ecuación ofrece `node` y `runs`, las listas accesibles con sus átomos en orden de lectura. Así se puede buscar una condición en toda la fórmula y aplicarla dentro de un índice, o comprobar presencia sólo entre hermanos. Los átomos y la ruta corresponden al contenido original. Sólo `width` se actualiza al encadenar reglas.

## Configuraciones que motivan la interfaz

### Dos operadores consecutivos y distinción de signos

```typst
#let operadores = (
  infijo: group(test: a => a.role == "binary", before: 0.35em, after: 0.35em),
  prefijo: group(test: a => a.role == "unary", after: 0.08em),
)
#let encuentro = rule(0.65em, left: "infijo", right: "prefijo")
#show math.equation: spacing.with(groups: operadores, rules: (encuentro,))
$a + -b$  $-a - b$
```

En la primera expresión se resuelve una vez la distancia entre `+` y `−`. En la segunda, sólo el signo intermedio solicita un margen binario anterior. Las comparaciones de la galería aíslan la excepción y la distinción de roles en filas separadas.

### Jerarquía relativa a los elementos presentes

```typst
#let operadores = (
  igualdad: group(sym.eq),
  implica: group(sym.arrow.r.double),
)
#let toca(e, grupo) = grupo in e.left.groups or grupo in e.right.groups
#let base = 5em / 18
#let jerarquia = rule(
  2.16 * base,
  when: e => toca(e, "implica") and e.run.any(a => "igualdad" in a.groups),
)
#show math.equation: spacing.with(groups: operadores, rules: (jerarquia,))
$a => b$  $a = b => c$
```

La implicación sola se queda en `auto`. En la segunda muestra, la relación de referencia conserva sus 5/18 em y la implicación toma 0,6 em. La búsqueda local evita que una igualdad de un denominador active una implicación exterior. El factor y el grupo de referencia son datos de la configuración.

### Una condición que multiplica todas las distancias de la ecuación

```typst
#let grupos = (
  grande: group("large"),
  relacion: group("relation"),
  disparador: group(sym.eq),
  binario: group(test: a => a.role == "binary"),
)
#let entre-grandes(xs) = xs.windows(3).any(t =>
  "grande" in t.at(0).groups and "disparador" in t.at(1).groups
    and "grande" in t.at(2).groups
)
#let toca(e, grupo) = grupo in e.left.groups or grupo in e.right.groups
#let perfil(eq) = {
  if not eq.runs.any(entre-grandes) { return () }
  (
    rule(1em / 6, when: e => toca(e, "grande") and e.right-class != "opening"),
    rule(4em / 18, when: e => toca(e, "binario")),
    rule(5em / 18, when: e => toca(e, "relacion")),
    rule(e => if e.width == auto { auto } else { 2 * e.width }),
  )
}
#show math.equation: spacing.with(groups: grupos, rules: perfil)
$sum_i^n = product_j^m x => y$  $sum_i^n = product_j^m (a+b)$
```

En estas dos muestras en estilo de texto, el perfil asigna una base a **todas las fronteras con separación nativa positiva**. Las restantes quedan en `auto` y conservan su separación nula. La primera duplica también la de `x ⇒ y`. La segunda duplica la del binario en el grupo delimitado. Para esa segunda configuración, el borde izquierdo del grupo delimitado se interpreta como apertura al decidir el espacio con el producto. En un perfil más amplio hay que definir la política para signos de puntuación, relaciones contiguas o tamaños de índice cuando corresponda. La medida del espacio automático pertenece al motor de Typst. [Sonda plana](../probes/cases.typ) · [Sonda con grupo anidado](../probes/nested.typ)

### Cohesión alrededor de la coma

```typst
#let grupos = (
  suma: group(sym.plus, before: 0.12em, after: 0.12em),
  coma: group(sym.comma, after: 0.75em),
)
#show math.equation: spacing.with(groups: grupos)
$(a + b, c + d)$
```

El mayor espacio aparece sólo después de la coma. Cada suma conserva su propio ritmo, y los paréntesis permanecen bajo el control de `lr`. Una configuración que necesite distinguir una coma de matriz puede usar el tipo del contenedor en la ruta. Las celdas nativas son campos independientes, y la coma sintáctica que separa argumentos de `mat` no forma parte de su contenido. [Referencia de matrices](https://typst.app/docs/reference/math/mat/)

## Cómo llegar del contenido al renderizado

1. **Leer el cuerpo original.** Examinar `func()` y los campos conocidos. `-` y `=>` llegan como `−` y `⇒`. El símbolo `+` se distingue del texto `"+"`. Los enteros literales y el texto entre comillas pueden llegar ambos como nodos `text`. La sonda obtiene el discriminante de símbolo con `$+$.body.func()`. Para clasificar símbolos simples, la versión distribuible necesitaría las clases Unicode de la versión objetivo y los ajustes de Typst. Reconocer también `math.class` explícita, la base de los adjuntos y los bordes de `lr`. En 0.15.1, `vary` adquiere papel binario tras normal, alfabético, cierre o cerca. [Contenido público](https://typst.app/docs/reference/foundations/content/#representation) · [Clases de los bordes](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/item.rs#L96-L133)
2. **Decidir entre hermanos.** Leer por separado numerador, denominador, celdas, base, índices y cuerpo delimitado. Mantener los espacios de sintaxis en el contenido y omitirlos al buscar vecinos simbólicos. Un espacio explícito del autor, un salto o un punto de alineación delimitan dónde se permite intervenir. Las cajas, el texto compuesto, los contenidos diferidos y los envoltorios de estilo sin acceso fiable se tratan como opacos. Los predicados se evalúan antes de insertar distancias. Los campos observables y su igualdad se prueban en la sonda estructural. [Prueba de estructura pública](../probes/structure.typ)
3. **Aplicar sólo los cambios decididos.** Devolver la ecuación original con una regla local sobre la secuencia concreta y emitir sus hijos originales en el mismo orden más un único `h` por frontera modificada. El valor `auto` conserva los nodos originales. Si un `h` interrumpe el contexto izquierdo de un `vary` binario simple y su clase está establecida, fijar ese símbolo con `math.class("binary", ...)`. Los sumatorios con límites, los delimitadores extensibles y las fracciones conservan sus contenedores. El portador `sequence` se reconoce mediante una muestra de sintaxis y deberá volver a verificarse al cambiar de versión. [Sonda de aplicación](../probes/edges.typ) · [Efectos de la clase matemática](https://typst.app/docs/reference/math/class/)

Para una secuencia, el análisis necesita recorrer sus hijos una vez y resolver sus fronteras una vez. Con `r` reglas, la resolución directa cuesta O(n·r), aparte de la clasificación en grupos y del trabajo que haga cada predicado. La forma funcional de `rules` evita repetir una búsqueda global por frontera. El coste de aplicar varios selectores locales depende del motor y del número de secuencias distintas. La medida de anchos se utiliza para las pruebas. El algoritmo propuesto puede decidir el espaciado sin medir cada par durante la composición.

## Frontera de compatibilidad

- **Selectores por valor.** Dos listas idénticas en el mismo ámbito pueden aceptar el mismo plan. Si requieren planes distintos, incluida una lista que debe quedar intacta, la primera versión debería detectar el conflicto y señalar ambas rutas antes de modificar el contenido. Elementos generados después por reglas ajenas pueden introducir coincidencias invisibles al análisis. Una promesa de selección universal por ruta exigiría otra técnica. [Control de colisión](../probes/scopes.typ)
- **Información privada.** Los paréntesis de ciertas fracciones horizontales dependen de indicadores internos. Volver a construir el contenedor desde `fields()` puede cambiar la notación aun cuando las comparaciones de contenido sean iguales. Conservar el contenedor original es un requisito de la estrategia. [Resolución de fracciones](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/resolve.rs#L721-L765)
- **Otras reglas de presentación.** Las pruebas combinan dos estilos externos, una sustitución independiente y referencias numeradas. Una regla que reclasifica el mismo operador después del análisis puede entrar en conflicto con la conservación del rol. La configuración tendría que reflejar la clase deseada o delegar esa frontera. Las formas de rol incierto deberían mantenerse en composición nativa. [Prueba de interoperabilidad](../probes/interop.typ) · [Control de reclasificación](../probes/geometry.typ)
- **Alcance de esta fase.** La sonda de adyacencias reconoce un alfabeto pequeño y listas planas o directamente delimitadas. Las demás sondas aíslan recursión, alcance y estructura. El clasificador completo, la detección de colisiones y las tres funciones públicas quedan como diseño. Los saltos, la alineación y los desbordamientos pertenecen al segundo paquete.
