# Velvet UI × Arc — Inventario y propuesta de tokens v0.2

> Estado: **propuesta, esperando aprobación**. No se tocó código.
> Alcance: solo capa visual / tokens. APIs públicas y estructura de componentes intactas.

---

## 0. Inventario (paso 1)

### 0.1 Tokens existentes

| Capa | Archivo | Qué hay | Estado |
|---|---|---|---|
| Colores | `Tokens/DSColors.swift` | `DSColorPalette` (19 slots: primary/secondary/tertiary, 4 status, 3 backgrounds, 4 text, border/borderFocused/divider). Paleta light (coral `#FF385C` + indigo `#5B5FEF` + teal) y dark. `Color(hex:)`. Overlays negro 0.4 / 0.15. | Completo, pero **la paleta dark nunca se aplica** (ver 0.3) |
| Tema | `Tokens/DSTheme.swift` | `DSTheme: ObservableObject` con `light`/`dark`, environment key `\.dsTheme`, modifier `.dsTheme()`. | **Desconectado**: ningún componente lo lee |
| Tipografía | `Tokens/DSTypography.swift` | 15 estilos. Rounded en hero/largeTitle/title1/title2/button/buttonSmall/display. Kerning solo en overline (+1.5), hero (−0.5), display (−1 / −0.5). `.ds()` y `.dsTextStyle()`. | Completo |
| Spacing | `Tokens/DSSpacing.swift` | Grilla 4pt: 2→64 (11 pasos) + márgenes de pantalla (20/16/16/24). | Completo |
| Radios | `Tokens/DSRadius.swift` | 4, 8, 12, 16, 20, 24, pill. `.dsCornerRadius(_, strokeColor:)` (aplica **borde**). | Completo |
| Sombras | `Tokens/DSShadow.swift` | sm/md/lg/xl: radius 4/8/16/24, opacity 0.04/0.08/0.12/0.16, y 1/4/8/12. Color siempre negro. | Completo, pero duras para el objetivo Arc |
| Motion | `Animation/DSAnimation.swift` | Curvas: micro 0.2 easeOut, fast 0.3, normal 0.4, slow 0.6 (easeInOut). Springs: snappy (0.3/0.7), smooth (0.45/0.75), gentle (0.6/0.8), bouncy (0.5/0.5), interactive. Transiciones dsSlideUp/dsScale/dsFade/dsPush. | Completo. `dsStaggerIn` es un no-op; `DSAnimatedValue` stub sin uso |
| Haptics | `Haptics/DSHaptics.swift` | 9 estilos, engine pre-warmed, `dsHaptic()`, `.dsHapticTap()`. Guardado con `#if canImport(UIKit)`. | Completo |
| Layout | `Layout/DSLayout.swift` | DSScreen, DSHorizontalScroll, DSVStack/HStack, DSGrid. | Completo |

### 0.2 Componentes

| Componente | Archivo | Estado | Notas |
|---|---|---|---|
| DSButton (5 variantes × 3 tamaños, icon, loading) | DSButton | ✅ Completo | press 0.96 ✓, haptic ✓, `.outline` usa stroke 1.5 |
| DSIconButton | DSButton | ✅ | press 0.88 (inconsistente con 0.96) |
| DSCard (flat/elevated/outlined) | DSCard | ⚠️ | Radio default 16 (tu regla dice 20). `.flat` usa `backgroundElevated` → invisible sobre fondo blanco. `.outlined` = borde |
| DSInteractiveCard | DSCard | ✅ | press **0.97** (inconsistente con 0.96) |
| DSImageCard | DSCard | ⚠️ A medio | Acepta `imageURL` pero nunca lo carga (sin AsyncImage) |
| DSBadge (filled/soft/outline) | DSBadge | ✅ | `.outline` = borde |
| DSCountBadge | DSBadge | ⚠️ | Valores crudos: `.white`, 11pt, paddings 6/4, minWidth 20 |
| DSAvatar | DSBadge | ⚠️ A medio | Acepta `imageURL` pero nunca lo usa |
| DSTextField (5 estados) | DSTextField | ✅ | Focus/error = stroke 1.5. Altura 48 hardcoded |
| DSSearchBar | DSTextField | ✅ | Altura 44 hardcoded |
| DSListCell / DSSectionHeader / DSDivider | DSList | ✅ | — |
| DSToast | DSToast | ✅ | **Único uso de `.ultraThinMaterial` hoy** — ya apunta al lenguaje nuevo |
| DSEmptyState | DSToast | ✅ | — |
| DSSegmentedControl (pill/underline) | DSSegmentedControl | ✅ | matchedGeometry, haptic selection ✓ |
| DSToggle | DSToggle | ✅ | — |
| DSRating | DSRating | ✅ | Accesibilidad completa ✓ |
| DSPageControl | DSPageControl | ✅ | — |
| DSCodeField | DSCodeField | ✅ | Bordes 1–2pt en cajas (choca con "sin bordes") |
| Progress ×4 + DSAnimatedNumber | DSProgressAnimation | ✅ | — |
| DSShimmer | DSProgressAnimation | ⚠️ | Offset fijo 200 → se rompe en vistas anchas; blanco hardcoded |
| DSPulse | DSProgressAnimation | ✅ | — |
| ComponentCatalog | Preview | ✅ internal | Solo `#Preview`; no es usable desde un target externo (relevante para paso 5) |

### 0.3 Hallazgos estructurales (condicionan la propuesta)

1. **`DSTheme` está desconectado.** Todos los componentes leen `DSColors.defaultPalette` (estático, light). `DSColors.primary` también devuelve siempre la paleta light. Consecuencia: la paleta dark existe pero **ningún componente la usa**, y el theming "en vivo" del paso 5 es imposible con la plomería actual. Es el único cambio interno no-visual que necesito hacer (ver §3); no cambia firmas públicas.
2. **`iOS_DESIGN.md` no existe** ni en este repo ni en `~/Documents`. Trabajé con `DesignSystem.swift` (es solo un comentario de cabecera), los tokens, y la skill `design-system` (`~/.claude/skills/design-system/`), que es la doc real del sistema.
3. **`~/Documents/DesignSystem` es un clon viejo** del mismo repo (5 commits atrás, en `b0deebe`). La skill y el CLAUDE.md global apuntan ahí. Conviene apuntar a `velvet-ui` o hacer `git pull`.
4. **Dos tensiones entre tus reglas y la referencia Arc**, resueltas en §5:
   - "cornerRadius(20) en cards" vs Arc "12–16px en cards".
   - "sin bordes" vs variantes públicas `.outline` / `.outlined` y los focus rings de inputs.

---

## 1. Principios: qué se conserva, qué cambia

**Se conserva (no negociable):**
- Springs (`springSnappy/Smooth/Gentle/Bouncy`) con sus valores actuales.
- Haptics en toda acción primaria.
- `scaleEffect(0.96)` en press. Se **unifica**: InteractiveCard pasa de 0.97 a 0.96; IconButton queda en 0.88 por ser un target chico (regla explícita en token).
- Radio 20 en cards de primer nivel.
- SF Pro Rounded en números (y se refuerza con `monospacedDigit`).
- Grilla 4pt, escala tipográfica, spacing, layout helpers: sin cambios.

**Cambia (el lenguaje nuevo):**
- **Superficie**: de "blanco elevado con sombra" a **vidrio (`Material`) sobre gradiente temático**.
- **Separación**: de `stroke()` a **wash translúcido** (blanco 40–55 %) con highlight de borde superior.
- **Sombra**: de dura/corta a **difusa y ambiental** (radius 24–32, opacity ≤ 0.08) + glow tintado opcional bajo CTAs.
- **Acento**: de un coral fijo a un **acento derivado del tema de gradiente activo**.
- **Motion de curvas**: 200 ms micro, 320 ms vistas, con curvas cúbicas suaves. Springs intactos.
- **Titulares**: SF Pro (no rounded) con tracking negativo. Números y botones siguen rounded.

---

## 2. Tokens nuevos y revisados

### 2.1 `DSGradientTheme` — tema de gradiente (NUEVO)

Un tema = gradiente de fondo + 4 colores derivados. Cada slot tiene una función concreta para no repetir el problema "un solo `primary` para todo":

| Slot | Uso | Regla de contraste |
|---|---|---|
| `stops: [Color]` | Fondo de pantalla (`DSBackdrop`), fills decorativos, `DSGradientProgress` | — |
| `accent` | Fill de CTA primario, toggle on, indicador de página, segment activo, rating | Es el primer stop (color vivo) |
| `onAccent` | Texto/ícono sobre `accent` | ≥ 4.5:1 sobre `accent` |
| `ink` | Texto, íconos, links y focus rings **sobre vidrio claro** | ≥ 4.5:1 sobre blanco |
| `inkDark` | Ídem, en dark mode sobre vidrio oscuro | ≥ 4.5:1 sobre `#1A1A2E` |

Tres temas iniciales (valores verificados a mano para AA; se afinan en pantalla en el paso 3):

| Tema | Stops | `accent` | `onAccent` | `ink` (light) | `inkDark` |
|---|---|---|---|---|---|
| **Sunset** (default propuesto) | `#FF7E5F → #FEB47B` | `#FF7E5F` | `#2B1510` (oscuro) | `#C2361A` | `#FFA98F` |
| **Aurora** | `#7F5AF0 → #E84393` | `#7F5AF0` | `#FFFFFF` | `#6D47E6` | `#B9A3FF` |
| **Lagoon** | `#16F2B3 → #0DB4F7` | `#16F2B3` | `#06231D` (oscuro) | `#0B7D8C` | `#5EF5CB` |

Notas de diseño:
- **`onAccent` oscuro en Sunset y Lagoon** es deliberado y muy Arc: pill peach con texto casi negro, pill menta con texto casi negro. Solo Aurora usa blanco. Esto evita apagar los colores para que pase el contraste.
- **Dark mode = mismo gradiente + capa negra**, no una segunda paleta. Un solo knob: `darkDim = 0.58` (negro al 58 % sobre el gradiente). Preserva el hue, garantiza que el vidrio oscuro lea, y no hay 3 paletas más que mantener. Light mode tiene `lightWash = 0.08` (blanco al 8 %) para bajar apenas la saturación bajo texto.
- Dirección del gradiente: `topLeading → bottomTrailing`, con un `RadialGradient` blanco muy suave (0.18) arriba a la izquierda como "luz" — le da profundidad sin ser un efecto.
- Por qué Sunset como default: continuidad con el coral `#FF385C` actual; el cambio se lee como evolución, no como rebrand.

Dónde vive: `Tokens/DSGradientTheme.swift`. Se cuelga de `DSTheme` como `@Published var gradient` (aditivo, §3).

### 2.2 `DSSurface` — vidrio esmerilado (NUEVO)

Cuatro niveles de superficie, del más transparente al más opaco. Un solo modifier `.dsSurface(_ level, radius:)` que aplica material + clip continuo + **wash edge** (§2.3).

| Nivel | Material | Para |
|---|---|---|
| `.glassThin` | `.ultraThinMaterial` | Chips, badges, toolbars, page control track, toast |
| `.glass` | `.thinMaterial` | **Cards (default)**, list groups, inputs, segmented track |
| `.glassThick` | `.regularMaterial` | Sheets, modales, popovers |
| `.solid` | `backgroundElevated` | Fallback: `accessibilityReduceTransparency`, o cuando la app no usa `DSBackdrop` |

Regla: **`.glass` (thin) es el default de cards, no ultraThin.** Sobre un gradiente saturado, ultraThin deja pasar demasiado color y el texto secundario pierde contraste. UltraThin queda para elementos chicos que se benefician de "flotar".

### 2.3 `DSWash` — reemplazo de bordes (NUEVO)

Nunca `stroke(border)`. Dos herramientas:

| Token | Valor light | Valor dark | Uso |
|---|---|---|---|
| `DSWash.surface` | `white 0.45` | `white 0.10` | Fill translúcido plano (sin blur) para separar una superficie dentro de otra: input dentro de card, track de toggle off, celda seleccionada. Barato, sin `Material`. |
| `DSWash.edge` | gradiente `white 0.55 → 0.05` (top → bottom), 1pt | `white 0.18 → 0.02` | Highlight "especular" en el borde superior del vidrio. Es lo que hace legible el vidrio sin dibujar una línea. Se aplica por dentro con `strokeBorder`, así que nunca cambia el layout. |
| `DSWash.focus` | `ink 0.35`, 2pt, blur 2 | `inkDark 0.35` | Reemplaza el focus ring de inputs/code field: un glow difuso del color del tema, no un borde. |

Las variantes públicas `.outline` (Button, Badge) y `.outlined` (Card) **se conservan como API**, pero se re-renderizan como **"wash"**: fondo `DSWash.surface` + `DSWash.edge`, sin stroke de color. Visualmente pasan de "borde de color" a "vidrio más denso". Decisión en §5.

### 2.4 `DSShadow` — sombras difusas + glow (REVISADO)

Misma API (`sm/md/lg/xl`, `.dsShadow()`), nuevos valores. Regla Arc: radio grande, opacidad baja, offset moderado.

| Nivel | Antes (radius / opacity / y) | **Después** | Uso |
|---|---|---|---|
| `.sm` | 4 / 0.04 / 1 | **8 / 0.04 / 2** | Knob del toggle, segment activo |
| `.md` | 8 / 0.08 / 4 | **16 / 0.06 / 4** | Cards en reposo |
| `.lg` | 16 / 0.12 / 8 | **24 / 0.08 / 8** | Cards interactivas, toast, popovers |
| `.xl` | 24 / 0.16 / 12 | **32 / 0.10 / 12** | Sheets, modales |

Nuevo: `DSShadow.glow(accent)` — sombra **del color del acento**, radius 20, opacity 0.28 light / 0.40 dark, y 8. Solo para el CTA primario y el toggle en `on`. Es el detalle que hace que un botón "emita luz" sobre el gradiente.

Nota de implementación: sombra bajo `Material` se ve a través del vidrio como un halo en los bordes. Con estas opacidades queda bien; si molesta, `compositingGroup()` antes de la sombra.

### 2.5 `DSRadius` — alias semánticos (ADITIVO)

La escala numérica no cambia. Se agregan alias con intención, para que el "20 en cards" sea una regla del sistema y no una convención oral:

| Alias | Valor | Para |
|---|---|---|
| `DSRadius.card` | 20 (`xl`) | DSCard, DSInteractiveCard, DSImageCard, sheets |
| `DSRadius.surface` | 16 (`lg`) | Superficies anidadas: toast, list group, empty state container |
| `DSRadius.control` | 12 (`md`) | Botones medium/large, inputs, code field boxes |
| `DSRadius.chip` | pill | Badges, tags, botones small, search bar, segmented pill |

Cambios concretos: DSCard default 16 → **20**. DSButton `.small` 8 → **pill** (Arc usa pills en todo control chico). `.dsCornerRadius(strokeColor:)` se mantiene por compatibilidad pero se marca `@available(*, deprecated)` a favor de `.dsSurface()`.

### 2.6 `DSAnimation` — duraciones y curvas (REVISADO, springs intactos)

Los `static let` cambian de valor, no de nombre:

| Token | Antes | **Después** | Curva |
|---|---|---|---|
| `.micro` | 0.20 easeOut | **0.20** | `timingCurve(0.25, 0.10, 0.25, 1.0)` — "standard" |
| `.fast` | 0.30 easeInOut | **0.24** | `timingCurve(0.20, 0.00, 0.00, 1.0)` — decelerate |
| `.normal` | 0.40 easeInOut | **0.32** | `timingCurve(0.20, 0.00, 0.00, 1.0)` — transiciones de vista |
| `.slow` | 0.60 easeInOut | **0.48** | `timingCurve(0.30, 0.00, 0.10, 1.0)` |
| Springs ×5 | — | **sin cambios** | — |

Nuevo: `DSPress` con constantes `scale = 0.96`, `iconScale = 0.88`, `animation = springSnappy`. Todo press state del catálogo pasa a leer de ahí.

Arreglos colaterales (sin cambio de API): `dsStaggerIn` pasa a animar de verdad (opacity 0→1 + offset y 8→0 con `stagger(index:)`); `DSShimmer` calcula el offset con `GeometryReader` en vez de 200 fijo.

### 2.7 `DSTypography` — tracking y números (REVISADO)

| Estilo | Antes | **Después** |
|---|---|---|
| `.hero` 34 bold | rounded, −0.5 | **default (SF Pro), −0.8** |
| `.largeTitle` 28 bold | rounded, 0 | **default, −0.6** |
| `.title1` 22 semibold | rounded, 0 | **default, −0.4** |
| `.title2` 20 semibold | rounded, 0 | **default, −0.3** |
| `.title3` 17 semibold | default, 0 | default, **−0.2** |
| `.body` / `.callout` / `.footnote` / captions | default | sin cambio |
| `.button` / `.buttonSmall` | rounded | **rounded (sin cambio)** — la tactilidad del botón es Velvet |
| `.overline` | default, +1.5 | default, **+1.2** |
| `.displayLarge` / `.displayMedium` | rounded, −1 / −0.5 | **rounded + `monospacedDigit`**, −1.2 / −0.6 |

Nuevo: `DSTextStyle.numeric` (17 semibold rounded, monospacedDigit) para precios, contadores, timers inline.

### 2.8 `DSBackdrop` — fondo de pantalla temático (NUEVO, view)

View pública `DSBackdrop()` que pinta el gradiente del tema activo con la capa light/dark y la luz radial. `DSScreen` gana un parámetro `backdrop: Bool = false` (aditivo) para usarlo. Sin `DSBackdrop`, todo cae a `.solid` y el sistema se ve como hoy: **adopción opt-in por pantalla**.

---

## 3. Plomería mínima para que el theming funcione

Sin esto, ni dark mode ni el selector de temas del paso 5 pueden funcionar. Todo es interno o aditivo:

1. **`DSTheme` gana `@Published var gradient: DSGradientTheme`** (default `.sunset`). Ya es `ObservableObject` e inyecta `environmentObject`, así que cambiarlo en vivo re-renderiza.
2. **Los componentes resuelven la paleta desde el environment**: `@Environment(\.colorScheme)` + `@Environment(\.dsTheme)` → `theme.palette(for: colorScheme)` y `theme.gradient`. Reemplaza los `DSColors.defaultPalette.x` internos. Cero cambio de firma.
3. **Defaults de color en inits pasan de `Color = DSColors.defaultPalette.primary` a `Color? = nil`** (nil = "seguí el tema"). Es **source-compatible**: quien pasaba un color sigue compilando, quien no pasaba nada sigue compilando. Es el único toque a firmas públicas y es aditivo. Afecta: DSBadge, DSCountBadge, DSToggle `onColor`, DSRating `tint/emptyColor`, DSPageControl `activeColor/inactiveColor`, DSSegmentedControl `accent`, DSIconButton `color`, progress ×4.
4. **`DSColors.primary` y compañía se vuelven adaptativos** light/dark vía color dinámico de plataforma (`UIColor { trait in }` / `NSColor(name:dynamicProvider:)`), para que el uso crudo de tokens en apps también respete dark mode. Opcional pero recomendado.

---

## 4. Cómo se ve aplicado, componente por componente (preview de los pasos 3–4)

Sin código; para que veas el alcance visual antes de aprobar.

- **DSCard** → `.elevated` = `.glass` + `DSWash.edge` + `DSShadow.md`, radio 20. `.flat` = `DSWash.surface` (por fin visible). `.outlined` = `.glassThick` + edge, sin stroke.
- **DSButton** → `.primary` = fill `accent` + texto `onAccent` + `glow`. `.secondary` = `.glassThin` + texto `ink`. `.outline` = `DSWash.surface` + edge + texto `ink`. `.ghost` = texto `ink`, sin fondo. `.destructive` sin cambio de color, gana glow rojo. Small → pill.
- **DSTextField / DSSearchBar** → fondo `DSWash.surface`, focus = `DSWash.focus` (glow), no stroke.
- **DSCodeField** → cajas `DSWash.surface`, activa = glow del tema; error/success mantienen tinte en el fill y glow de su color.
- **DSBadge** → `.soft` = `accent 0.16` + texto `ink`; `.filled` = `accent`/`onAccent`; `.outline` = `.glassThin` + edge.
- **DSToggle** → track off = `DSWash.surface`; on = `accent` + `glow`.
- **DSSegmentedControl** → track `.glassThin`, indicador `.glass` + edge + `sm`.
- **DSPageControl / DSRating** → `accent` para activo, `DSWash.surface` para inactivo.
- **DSToast** → `.glassThin` (ya lo es) + edge + `lg`, radio 16.
- **DSListCell** → sin cambio; los grupos de celdas se envuelven en `.glass` desde la app.
- **Progress** → track `DSWash.surface`; `DSGradientProgress` usa `stops` del tema por default.
- **Tipografía** → títulos SF Pro con tracking negativo; números rounded + monospaced.

**Candidato para el paso 3 (prueba de concepto): `DSCard`.** Es el componente donde conviven las 4 novedades a la vez (vidrio, wash edge, sombra difusa, radio 20) sobre el `DSBackdrop`. La vista de demo lo mostraría en los 3 temas × light/dark, con `.elevated / .flat / .outlined` lado a lado. Si preferís `DSButton` (acento + onAccent + glow + press), también es buen candidato; lo elegís en §5.

---

## 5. Decisiones que necesito de vos

| # | Decisión | Mi recomendación | Alternativa |
|---|---|---|---|
| A | Tema default | **Sunset** (continuidad con el coral actual) | Aurora (más "Arc" a primera vista) |
| B | Radio en cards | **20 en cards de primer nivel, 16 en anidadas, 12 en controles** (tu regla + Arc conviven por jerarquía) | 16 en todo (Arc literal, rompe tu regla) |
| C | Variantes `.outline` / `.outlined` | **Conservar API, re-renderizar como wash** (sin stroke de color) | Mantener stroke fino de `ink` al 30 % |
| D | Títulos | **SF Pro con tracking negativo**; rounded solo en números y botones | Mantener rounded en títulos (look actual) |
| E | Dark mode | **Mismo gradiente + dim negro 0.58** | Paletas dark dedicadas por tema |
| F | Defaults `Color` → `Color?` | **Hacerlo** (source-compatible, habilita theming en vivo) | No tocar firmas → sin theming en vivo en el paso 5 |
| G | Componente del paso 3 | **DSCard** | DSButton |
| H | `DSColors.x` adaptativos light/dark | **Hacerlo** | Dejar como está |

---

## 6. Fuera de alcance (no toco en pasos 2–4)

- APIs públicas más allá de F (aditivo).
- Estructura interna de componentes, gestos, accesibilidad.
- Los "a medio terminar" del inventario (`imageURL` en ImageCard/Avatar, tests): los anoto para después, no forman parte de este cambio.
- El target de demo (paso 5) — solo dejo constancia de que `ComponentCatalog` es `internal` y la app tendrá sus propias vistas.
