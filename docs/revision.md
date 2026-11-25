# Revisión arquitectónica de Better math spacing 0.1.0

La revisión amplía el análisis a las 12 ecuaciones que antes se delegaban por completo. También resuelve la colisión entre fracciones hermanas que causaba errores en tres perfiles. Las 345 combinaciones de 69 ecuaciones y cinco configuraciones compilan con la estructura MathML nativa. Esto incluye las ecuaciones mixtas en las que el paquete procesa sólo algunos tramos. La referencia es `bdeb191` y el núcleo revisado es `99613c8`. [Corpus](../tests/audit/corpus.typ) · [Auditoría anterior](auditoria.md)

## Qué justificó el cambio

Antes de cambiar el núcleo se midieron cuatro cortes de la compilación original. En copias temporales de `bdeb191`, los tres primeros devolvían la ecuación original en etapas sucesivas. El último compilaba hasta el PDF con todas las ediciones. Las dos series usaron 1.000 ecuaciones distintas, un hilo y tres procesos independientes por celda. La tabla recoge la repetición del diagnóstico sobre el mismo commit. Las cifras son acumulativas. La última etapa incluye el coste de componer el resultado modificado. El pico de RSS pertenece al proceso completo.

| Última etapa ejecutada | Básico, s · MiB | Adaptativo, s · MiB |
| --- | ---: | ---: |
| Entrada, antes del análisis | 0,100 · 51,8 | 0,096 · 51,9 |
| Listas de átomos recogidas | 0,292 · 87,1 | 0,283 · 85,1 |
| Planes y colisiones resueltos | 0,423 · 95,3 | 0,663 · 113,7 |
| PDF con ediciones | 0,477 · 111,9 | 0,755 · 133,6 |

La recogida de átomos costaba tiempo y memoria en ambos perfiles. En el adaptativo, la resolución de fronteras añadía el mayor incremento de tiempo. Se eliminaron el descenso recursivo en glifos ya clasificados y la función intermedia que construía cada ruta. Los perfiles estáticos prescinden de la vista global y del diccionario que sólo leen los predicados de frontera. La emisión copia de una vez los tramos entre dos ediciones. El orden de las reglas, los índices y los argumentos que reciben los predicados se mantienen.

## Alcance y selección

La sonda de ocurrencias aplicó márgenes de 2 pt y 7 pt a numeradores con los mismos hijos públicos. Para hacerlo, instaló una regla local en cada fracción usando su índice entre los hermanos y entregó a Typst la fracción original. Otra muestra combinó dos filas alineadas, texto, una expresión en negrita y una caja con matemáticas anidadas. Los únicos márgenes nuevos aparecieron en la suma elegida. En la sonda anterior de reconstrucción, el constructor público perdía los paréntesis privados de la notación con barra. Entregar el contenedor original conserva esa información. [Sonda de ocurrencias](../probes/occurrences.typ) · [Sonda de reconstrucción](../probes/scopes.typ)

La implementación toma una decisión por frontera. Un salto, un punto de alineación, texto libre o una rama opaca cierran el tramo actual. Las decisiones restantes sólo se aplican en el ámbito del hijo correspondiente de la secuencia exterior. El marcador `&` corta la adyacencia editable y conserva el contexto del signo. Un salto en la raíz inicia una fila, mientras que un salto dentro de una celda puede desaparecer durante la composición. Si el elemento precedente no permite saber el rol de un signo, se conserva ese signo con sus dos bordes nativos. [Resolución de filas y de signos en Typst 0.15.1](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/process.rs#L119-L213) · [Resolución de espacios relativos](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/resolve.rs#L238-L254)

## Cobertura y fidelidad

| Perfil | Analizadas antes → después | Modificadas antes → después | Delegadas antes → después | Errores antes → después |
| --- | ---: | ---: | ---: | ---: |
| Básico | 57 → 69 | 42 → 47 | 12 → 0 | 0 → 0 |
| Compacto | 57 → 69 | 53 → 66 | 12 → 0 | 1 → 0 |
| Jerárquico | 57 → 69 | 20 → 21 | 12 → 0 | 0 → 0 |
| Adaptativo | 57 → 69 | 53 → 66 | 12 → 0 | 1 → 0 |
| Amplio | 57 → 69 | 53 → 66 | 12 → 0 | 1 → 0 |

En conjunto se pasó de 282 ejecuciones correctas (81,7 %), 60 delegaciones completas (17,4 %) y tres errores (0,9 %) a 345 ejecuciones correctas. «Analizada» cuenta las invocaciones al constructor de reglas por ecuación, incluso si otra configuración encuentra una colisión. «Modificada» exige al menos un cambio en la secuencia de espacios y conservación del árbol MathML. En los perfiles compacto, adaptativo y amplio se observaron ediciones en las doce fórmulas antes delegadas. El básico modificó cinco de ellas y el jerárquico, una.

Las 282 combinaciones que ya se procesaban correctamente en la versión anterior dieron exactamente el mismo árbol MathML, incluidos los nodos de espaciado y sus atributos. Para las 345 combinaciones se compararon con Typst nativo el texto, los nodos y los atributos estructurales, incluida la forma de los operadores. Las dos demostraciones conservaron sus 21 ecuaciones y cuatro enlaces en cada perfil. La galería compilada coincide byte por byte con el SVG guardado.

El control que materializa la estimación de Typst pudo medir 69 ecuaciones frente a 56. Las 69 coincidieron en ancho paginado a 12 pt y en 66 se observó la emisión de espacios. La diferencia absoluta máxima registrada fue 0 pt. El ancho total puede ocultar desviaciones dentro de una fila de matriz. Se mantuvieron los 16 controles adicionales de ancho y altura, y se verificaron las posiciones de los márgenes por celda en el caso alineado. [Controles geométricos](../tests/audit/fidelity.typ) · [Regresiones de los ámbitos](../tests/audit/scopes.typ)

## Rendimiento

Para la comparación principal se repitió el programa de la auditoría con el mismo corpus, configuraciones y fuentes incorporadas. Cada mediana resume cinco procesos independientes de Typst 0.15.1 en un i7-13700HX con Linux, `--jobs 1`. Los PDF de carga ciclan 68 fórmulas, incluida la parte antes delegada. Para mantener comparables los resultados se siguió excluyendo `fraction-style` de la carga, aunque ya compila en los cinco perfiles. En las series distintas cada fórmula lleva un índice adicional propio.

### Tiempo de pared en segundos, anterior → revisado

| Carga | Nativo | Básico | Compacto | Jerárquico | Adaptativo | Amplio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 en ciclo | 0,020 → 0,017 | 0,086 → 0,056 | 0,075 → 0,057 | 0,126 → 0,090 | 0,096 → 0,079 | 0,072 → 0,056 |
| 1.000 en ciclo | 0,074 → 0,071 | 0,223 → 0,152 | 0,260 → 0,158 | 0,407 → 0,405 | 0,416 → 0,434 | 0,263 → 0,155 |
| 1.000 distintas | 0,091 → 0,089 | 0,490 → 0,398 | 0,542 → 0,450 | 0,821 → 0,748 | 0,773 → 0,769 | 0,549 → 0,450 |
| 5.000 en ciclo | 0,303 → 0,294 | 0,851 → 0,571 | 1,081 → 0,579 | 1,629 → 1,766 | 1,823 → 1,974 | 1,081 → 0,580 |
| 5.000 distintas | 0,427 → 0,420 | 2,248 → 1,853 | 2,571 → 2,138 | 3,769 → 3,527 | 3,647 → 3,748 | 2,574 → 2,142 |

### Pico de RSS en MiB, anterior → revisado

| Carga | Nativo | Básico | Compacto | Jerárquico | Adaptativo | Amplio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 en ciclo | 29,6 → 29,9 | 40,4 → 36,8 | 40,1 → 36,9 | 42,9 → 37,3 | 41,2 → 39,3 | 40,2 → 36,8 |
| 1.000 en ciclo | 43,8 → 43,9 | 63,3 → 55,9 | 64,0 → 56,4 | 71,4 → 66,4 | 76,6 → 74,0 | 64,2 → 56,8 |
| 1.000 distintas | 50,0 → 50,3 | 115,4 → 99,3 | 117,0 → 105,9 | 120,1 → 103,8 | 133,9 → 130,9 | 116,8 → 106,8 |
| 5.000 en ciclo | 111,8 → 112,1 | 167,9 → 142,2 | 172,9 → 148,5 | 201,4 → 194,7 | 233,3 → 236,5 | 172,9 → 148,5 |
| 5.000 distintas | 141,1 → 141,5 | 406,6 → 378,2 | 452,5 → 419,0 | 440,4 → 380,9 | 511,9 → 521,3 | 453,2 → 419,4 |

Con 5.000 ecuaciones distintas, cuatro perfiles redujeron tiempo y memoria. El básico ahorró un 17,6 % de tiempo y el jerárquico un 13,5 % de RSS. El adaptativo subió un 2,8 % en tiempo y un 1,8 % en RSS. En el documento de 5.000 fórmulas en ciclo, el compacto bajó un 46,4 % en tiempo. El jerárquico y el adaptativo tardaron un 8,4 % y un 8,3 % más. Las medianas corresponden a procesos completos y reflejan también la variación visible en el control nativo.

Para distinguir el coste del trabajo adicional, se hizo un control con las 56 fórmulas que ya admitían todos los perfiles. Se conservaron el documento de 5.000 ecuaciones en ciclo y los predicados originales. Se alternaron los dos commits y se tomaron las medianas de tres procesos por celda.

| Perfil, 56 fórmulas en ciclo | Anterior, s · MiB | Revisado, s · MiB |
| --- | ---: | ---: |
| Jerárquico | 1,812 · 223,4 | 1,823 · 194,3 |
| Adaptativo | 2,055 · 256,0 | 2,033 · 237,2 |

Sobre el repertorio común, las diferencias de tiempo fueron del orden del 1 % en ambos perfiles y el pico de memoria bajó en los dos. La ralentización de los ciclos completos aparece al incluir las doce fórmulas que ahora también ejecutan las reglas contextuales.

## Compatibilidad y límites

- En `frac(a+b,c) = z`, una regla externa sustituye `z` por otro `a+b`. Antes, el selector del numerador añadía a la copia externa dos márgenes de 3 pt y 4 pt. Ahora esos dos márgenes aparecen únicamente dentro del numerador. También se comprobó el aislamiento de una caja con una ecuación idéntica y de un envoltorio de estilo con signos propios.
- Los campos públicos de dos ramas iguales de una misma fracción siguen sin distinguir su ocurrencia durante la realización. Si piden márgenes incompatibles se conserva el diagnóstico con ambas rutas. Un árbol opaco más profundo puede obligar a conservar todo su compuesto. Una secuencia etiquetada que habría que aplanar sigue protegida. Las cifras de cobertura cuentan ecuaciones con tramos accesibles.
- Una regla externa que reclasifique el mismo signo sigue pudiendo competir con la conservación de su rol. El control de reclasificación mide 27,667 pt frente a los 28,333 pt de la referencia con el signo como relación. Dos reglas de ecuación superpuestas dan 33 o 31,667 pt al invertir el orden. Las mismas transformaciones en una sola lista dan 45 pt. Los selectores externos que generan contenido dentro del mismo ámbito siguen sujetos a la igualdad pública de Typst. [Controles de compatibilidad](../tests/audit/compat.typ)
- La búsqueda de planes iguales y la detección de una salida que activa otro selector se hacen entre listas del mismo ámbito. En un compuesto con muchas listas pueden requerir comparaciones cuadráticas. Los predicados escritos por el usuario también pueden recorrer una lista completa por frontera. Las mediciones justificaron eliminar trabajo en el camino habitual sin introducir un índice por representación textual ni una caché global adicional.

## Reproducir

La verificación se ejecuta desde la raíz del repositorio con la CLI de Typst 0.15.1 y Python 3 en Linux.

```sh
python3 tests/check.py
python3 tests/audit/audit.py --bench 5 > revision.json
```

Para los cortes de referencia se usó el mismo documento PDF con `profile=basic` o `adaptive`, `workload=true`, `unique=true` y `count=1000`. En copias de `bdeb191`, se insertó `return eq` en `spacing` justo antes de recoger las listas, de construir la vista de ecuación y de construir los selectores, respectivamente. El cuarto control usó el archivo original. Los resultados completos incluyen medidas por fórmula, tiempos y picos individuales de RSS. [Datos anteriores](auditoria-datos.json) · [Datos de la revisión](revision-datos.json) · [Programa de medición](../tests/audit/audit.py)
