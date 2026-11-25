# Auditoría de Better math spacing 0.1.0

Se auditó la versión `c16af5d` y se repitieron las pruebas tras aplicar correcciones locales. El corpus independiente contiene 69 ecuaciones, desde signos, decimales y delimitadores hasta proyecciones ortogonales, ecuaciones normales, convergencia uniforme y series. Un documento adicional compone dos demostraciones completas con 21 ecuaciones en contexto. [Corpus](../tests/audit/corpus.typ) · [Demostraciones](../tests/audit/proofs.typ)

## Cobertura funcional

Las 69 ecuaciones compilaban con Typst nativo. Para distinguir una delegación de una regla que legítimamente no cambia ningún espacio, se usó una función de configuración que emite un diagnóstico cuando recibe la ecuación analizada. Cada fórmula se compiló por separado para que una colisión no ocultara los demás resultados.

La comparación en HTML verificó nodos, texto y atributos MathML, incluido `form`. Se descontaron los nodos `mspace` y los atributos `lspace` y `rspace`, que representan distancias. «Modificada» indica que se observó un cambio en `mspace` y se conservó la estructura. «Sin cambios» indica que el análisis se completó y ambos resultados coincidieron según esas comprobaciones.

| Configuración tras las correcciones | Modificada | Sin cambios | Delegada | Error de compilación |
| --- | ---: | ---: | ---: | ---: |
| Básica, 0,32 em a ambos lados de `+` y `−` | 42 (60,9 %) | 15 (21,7 %) | 12 (17,4 %) | 0 |
| Compacta | 53 (76,8 %) | 3 (4,3 %) | 12 (17,4 %) | 1 (1,4 %) |
| Jerárquica | 20 (29,0 %) | 37 (53,6 %) | 12 (17,4 %) | 0 |
| Adaptativa | 53 (76,8 %) | 3 (4,3 %) | 12 (17,4 %) | 1 (1,4 %) |
| Amplia | 53 (76,8 %) | 3 (4,3 %) | 12 (17,4 %) | 1 (1,4 %) |

En conjunto, hubo 282 ejecuciones correctas tras el análisis de 345 combinaciones (81,7 %), 60 delegaciones (17,4 %) y tres errores (0,9 %). El mismo caso de fracciones provocó los tres errores. Antes de las correcciones, cinco fórmulas con la configuración básica cambiaban `form` y los decimales se delegaban. En las dos demostraciones completas se conservaron los árboles MathML y los cuatro enlaces a ecuaciones. El perfil básico modificó cinco fórmulas, el jerárquico dos y cada uno de los otros tres perfiles 13.

## Fidelidad geométrica

A 12 pt, con New Computer Modern Math, se materializaron como `h` los espacios positivos previstos por el perfil nativo. Se comparó el ancho paginado con `measure`. Coincidieron las 56 ecuaciones que completaron el análisis y la compilación del perfil de control, con tolerancia de 0,01 pt. En 53 de ellas el HTML confirmó la emisión de espacios. Doce ecuaciones se delegaron y una produjo el diagnóstico de colisión. Las mediciones de ancho total pueden ocultar errores internos que se compensen o queden dentro de una fila más estrecha de una matriz. Los casos de regresión verifican además los pares concretos de glifos y las posiciones de `mspace`.

Se midieron por separado 16 variantes geométricas con delimitadores, fracciones e índices. Antes de la corrección, `lr(bracket.r -x bracket.l)` ganaba **5,333 pt** al materializar el perfil. El carácter inicial se clasificaba como cierre aunque Typst lo usaba como apertura. Después de la corrección, las 16 variantes coinciden en ancho y altura dentro de 0,01 pt. [Sondas geométricas](../tests/audit/fidelity.typ) · [Resolución de delimitadores de Typst](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/resolve.rs#L815-L918)

## Compatibilidad y correcciones

- Se conserva el margen de Typst entre un delimitador inicial y un signo variable unario. Así se evita que un espacio explícito cambie la forma exportada en cinco fórmulas del corpus. Los demás márgenes solicitados en esas fórmulas pueden aplicarse.
- Los decimales con un solo punto reciben la misma clasificación numérica que los enteros. Typst aplica ese criterio al interpretar nodos de texto en matemáticas. [Resolución de números](https://github.com/typst/typst/blob/v0.15.1/crates/typst-library/src/math/ir/resolve.rs#L255-L289)
- Un `set h(weak: true)` externo eliminaba un margen solicitado de 4 pt después de un delimitador. La emisión explícita con `weak: false` recuperó el ancho de referencia de 39,669 pt desde 35,669 pt. [Pruebas de compatibilidad](../tests/audit/compat.typ)
- Un `show` que convierte el mismo `+` en relación sigue pudiendo alterar la decisión que tomó el paquete antes de realizar el contenido. Al fijar el margen izquierdo a 4 pt, el ancho esperado con el margen derecho de relación era 28,333 pt. Se observaron 27,667 pt porque la emisión dio prioridad a la clase binaria.
- Dos reglas `show math.equation: spacing.with(...)` superpuestas compiten por la misma secuencia. Con 0,5 em y 200 % en dos reglas, invertir el orden cambia el ancho entre 33 y 31,667 pt. Al declarar las dos operaciones en una sola lista `rules`, se acumulan y dan 45 pt.
- Las 12 delegaciones incluyen cajas, texto libre, envoltorios de estilo, `dif`, puntos de alineación, `mid`, `cases`, acentos y un espacio porcentual. Una ecuación puede contener un operador compatible en otra región y aun así delegarse. Los controles de `tests/check.py` cubren la conservación de etiquetas, referencias, colores y sustituciones simples de glifos.

## Rendimiento

Se midió el proceso de la CLI completa, desde el lanzamiento hasta la escritura de un PDF temporal, con Typst 0.15.1, Linux x86-64, i7-13700HX, fuentes incorporadas y un hilo (`--jobs 1`). Se alternó el perfil que comenzaba cada ronda. Cada celda contiene las medianas de cinco ejecuciones del tiempo de pared en segundos y del pico de RSS del proceso en MiB. El ensayo cicla 68 fórmulas del corpus. Se excluyó el caso de colisión para que todos los perfiles generaran un documento completo. En las variantes distintas se añade un índice de identificación diferente a cada fórmula. El modo nativo de esta medición compila sin cargar el paquete.

| Carga | Nativo | Básico | Compacto | Jerárquico | Adaptativo | Amplio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 en ciclo | 0,020 s · 29,6 MiB | 0,086 s · 40,4 MiB | 0,075 s · 40,1 MiB | 0,126 s · 42,9 MiB | 0,096 s · 41,2 MiB | 0,072 s · 40,2 MiB |
| 1.000 en ciclo | 0,074 s · 43,8 MiB | 0,223 s · 63,3 MiB | 0,260 s · 64,0 MiB | 0,407 s · 71,4 MiB | 0,416 s · 76,6 MiB | 0,263 s · 64,2 MiB |
| 1.000 distintas | 0,091 s · 50,0 MiB | 0,490 s · 115,4 MiB | 0,542 s · 117,0 MiB | 0,821 s · 120,1 MiB | 0,773 s · 133,9 MiB | 0,549 s · 116,8 MiB |
| 5.000 en ciclo | 0,303 s · 111,8 MiB | 0,851 s · 167,9 MiB | 1,081 s · 172,9 MiB | 1,629 s · 201,4 MiB | 1,823 s · 233,3 MiB | 1,081 s · 172,9 MiB |
| 5.000 distintas | 0,427 s · 141,1 MiB | 2,248 s · 406,6 MiB | 2,571 s · 452,5 MiB | 3,769 s · 440,4 MiB | 3,647 s · 511,9 MiB | 2,574 s · 453,2 MiB |

Con 5.000 ecuaciones distintas, los perfiles tardaron entre 5,3 y 8,8 veces el tiempo nativo. El pico de memoria fue entre 2,9 y 3,6 veces el del proceso nativo.

Los programas contextuales examinan listas y vecinos durante la compilación. El perfil jerárquico vuelve a buscar grupos presentes en la lista para cada frontera. El adaptativo decide una parte de sus factores una vez por ecuación, aunque aplica cuatro reglas a cada pareja. La carga de fórmulas distintas mide un escenario con menos reutilización de contenido y también incluye el trabajo adicional de componer los identificadores. La comparación de perfiles siempre se hace dentro de la misma fila.

## Complejidad y decisiones pendientes

- Se sustituyó la búsqueda del carácter en cadenas por una consulta directa en un diccionario construido al cargar el módulo. Se evita asimismo construir el contexto de frontera sin una petición de grupo ni reglas. La tabla Unicode, los constructores públicos y el modelo de resolución por parejas se conservan.
- La fase de análisis recorre átomos y grupos. Para `n` átomos, `g` grupos y `r` reglas, la parte común recorre del orden de `n·(g+r)` combinaciones, aparte del trabajo de los predicados. Un predicado que vuelve a recorrer todos los hermanos por frontera puede ser cuadrático en una lista larga. Reunir los datos globales en `rules: eq => ...` reduce ese trabajo cuando el criterio es global. Un contexto calculado una vez por lista podría ayudar a la jerarquía local, pero requeriría decidir si se incorpora al contrato público.
- El detector de colisiones compara planes por el valor de los hijos y usa búsquedas lineales entre secuencias, lo que puede dar coste cuadrático en el número de listas de una sola ecuación. Sólo compensa sustituir las comparaciones si se conserva una verificación de igualdad exacta y las medidas aíslan este coste. Una clave por representación textual puede colisionar con contenido distinto.
- El error que permanece combina dos fracciones con numeradores públicos iguales y estilos vertical y horizontal. Los márgenes nativos del binario difieren según el tamaño matemático. El selector por valor no distingue ambas ocurrencias. Sustituir contenedores desde sus campos perdería parte de la información privada de las fracciones. Haría falta un mecanismo fiable para seleccionar por ocurrencia o una política explícita que decida qué hacer ante una colisión.
- Las estructuras opacas, las reclasificaciones externas y la acumulación entre reglas `show` distintas comparten un problema de alcance. El paquete analiza el contenido anterior a la realización, pero instala selectores que se evalúan durante ella. Delegar sólo el subárbol opaco o coordinar múltiples reglas requiere distinguir ocurrencias y conocer qué elementos llegan a realizarse. El perfil también puede desconocer parte de la geometría de cercas o estilos que se introducen durante la realización.

## Reproducir

```sh
python3 tests/check.py
python3 tests/audit/audit.py > funcional.json
python3 tests/audit/audit.py --bench 5 --bench-only > rendimiento.json
typst compile --root . tests/audit/proofs.typ pruebas.pdf
typst compile --root . --input profile=adaptive tests/audit/proofs.typ pruebas-adaptativas.pdf
```

El programa de auditoría registra cada fórmula y cada ejecución de rendimiento en JSON. `--root` permite repetir la comparación en una copia limpia de otro commit que contenga los mismos archivos de `tests/audit` y `examples/profiles.typ`. [Programa de auditoría](../tests/audit/audit.py) · [Resultados por fórmula y 150 mediciones](auditoria-datos.json)
