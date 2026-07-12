---
name: TLU Calendar
description: OLED-dark instrument panel for Thuy Loi University students — schedule, exams, grades, tuition
colors:
  void-black: "#000000"
  zinc-900: "#18181B"
  zinc-800: "#27272A"
  zinc-400: "#A1A1AA"
  zinc-500: "#71717A"
  zinc-200: "#E4E4E7"
  zinc-100: "#F4F4F5"
  zinc-950: "#09090B"
  white: "#FAFAFA"
  indigo-500: "#6366F1"
  indigo-600: "#4F46E5"
  red-500: "#EF4444"
typography:
  display:
    fontFamily: "Be Vietnam Pro, system-ui, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-1.0px"
  headline:
    fontFamily: "Be Vietnam Pro, system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.5px"
  title:
    fontFamily: "Be Vietnam Pro, system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.1px"
  body:
    fontFamily: "Be Vietnam Pro, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: "normal"
  label:
    fontFamily: "Be Vietnam Pro, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "normal"
rounded:
  sm: "8px"
  md: "12px"
  lg: "16px"
  pill: "30px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  card:
    backgroundColor: "{colors.zinc-900}"
    rounded: "{rounded.lg}"
    padding: "16px"
  card-light:
    backgroundColor: "{colors.white}"
    rounded: "{rounded.md}"
    padding: "16px"
  button-filled:
    backgroundColor: "{colors.white}"
    textColor: "{colors.void-black}"
    rounded: "{rounded.sm}"
    padding: "12px 24px"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.white}"
    rounded: "{rounded.sm}"
    padding: "12px 24px"
  input:
    backgroundColor: "{colors.zinc-900}"
    textColor: "{colors.white}"
    rounded: "{rounded.sm}"
    padding: "12px 16px"
  navigation-bar:
    backgroundColor: "{colors.void-black}"
    activeColor: "{colors.indigo-500}"
    inactiveColor: "{colors.zinc-400}"
    rounded: "{rounded.pill}"
---

# Design System: TLU Calendar

## 1. Overview

**Creative North Star: "The Instrument Panel"**

This is an information-dense utility where the data IS the interface. Every screen exists to answer a question — what class is next, what's my GPA, when is that exam — and the design should get out of the way of that answer. No decorative elements that don't carry meaning. No loading shimmer when data is already cached. No onboarding tour for a tool a university student can figure out in ten seconds.

The palette is OLED-black depth with cool indigo precision — a night-sky atmosphere that feels focused and premium without being cold. Typography is Be Vietnam Pro at a tight, confident scale. Surfaces are flat and tonal, using zinc darkness levels to create hierarchy without shadows. Motion is minimal and functional: state changes, not choreography.

The system explicitly rejects generic AI templates — cream backgrounds, identical card grids, gradient text, glassmorphism, tiny uppercase eyebrows on every section. This is a student's pocket instrument, not a SaaS landing page.

**Key Characteristics:**
- OLED-black scaffold with zinc tonal surfaces for depth hierarchy
- Indigo accent used sparingly — active states, primary actions, focused elements
- Be Vietnam Pro type at a tight scale with negative letter-spacing on display sizes
- Flat surfaces, zero shadows — depth through color contrast alone
- Liquid Glass navigation bar with backdrop blur
- Vietnamese-native copy, direct and brief

## 2. Colors

The palette is built on absolute black and a narrow zinc neutral ramp, with a single indigo accent. Light mode mirrors the same logic: pure white surfaces with the same indigo and a darker neutral ramp.

### Primary

- **Indigo Electric** (#6366F1): Active navigation indicator, focused inputs, primary action buttons (dark mode), selected states. The single accent color — used on ≤15% of any given screen. Its rarity is the point.
- **Indigo Deep** (#4F46E5): Primary accent in light mode. Same hue, slightly deeper — compensates for the lighter background.

### Neutral

- **Void Black** (#000000): OLED scaffold background (dark mode). True black for maximum OLED power savings and contrast. Never use Zinc900 as a scaffold — it exists only for elevated surfaces.
- **Zinc 900** (#18181B): Cards, inputs, sheets, elevated surfaces (dark mode). One step above void — creates subtle surface hierarchy without shadows.
- **Zinc 800** (#27272A): Borders, dividers, hairlines (dark mode). The thinnest structural element — 1px lines that define edges without weight.
- **Zinc 400** (#A1A1AA): Muted text, captions, secondary labels (dark mode). Must hit 4.5:1 contrast against Zinc900 backgrounds.
- **Zinc 500** (#71717A): Muted text in light mode. Equivalent role, adapted for light backgrounds.
- **Zinc 200** (#E4E4E7): Borders and dividers in light mode.
- **Zinc 100** (#F4F4F5): Secondary surfaces, elevated cards in light mode.
- **Zinc 950** (#09090B): Primary text in light mode. Near-black for maximum readability.
- **White** (#FAFAFA): Primary text foreground (dark mode). Slightly off-white to reduce harshness against pure black.

### Semantic

- **Destructive Red** (#EF4444): Error states, destructive actions, offline indicator badge. Used only for error/destructive context — never as a decorative accent.

### Named Rules

**The Void Rule.** The scaffold background is always #000000 in dark mode. Zinc900 is an elevated surface, not a background. Confusing them destroys the depth hierarchy.

**The Indigo Budget Rule.** Indigo appears on ≤15% of any screen's surface area. When in doubt, make it less. The black canvas is the primary visual; indigo is a surgical highlight.

## 3. Typography

**Display Font:** Be Vietnam Pro (with system-ui, sans-serif fallback)
**Body Font:** Be Vietnam Pro (same family, lighter weights)

**Character:** A single workhorse sans-serif used at multiple weights. Be Vietnam Pro's excellent Vietnamese diacritics support and clear numerals make it ideal for dense information display. The hierarchy relies on weight contrast (700 → 400) and size contrast (32px → 13px) rather than font-family mixing.

### Hierarchy

- **Display** (800, 32px, line-height 1.2, letter-spacing -1.0px): Greeting headers, hero numbers. Only on the Today screen and similar entry points. Tight tracking makes large text feel precise, not shouty.
- **Headline** (700, 24px, line-height 1.2, letter-spacing -0.5px): Section headings, screen titles.
- **Title** (600, 17px, line-height 1.3, letter-spacing -0.2px): Card titles, list item primary text, navigation labels.
- **Body** (400, 15px, line-height 1.5): Descriptions, secondary content, schedule details. Standard readability weight.
- **Label** (500, 13px, line-height 1.4): Metadata, timestamps, badges, small UI elements. Semi-bold for scannability at small sizes.

### Named Rules

**The Tight Scale Rule.** All heading sizes use negative letter-spacing (-0.1px to -0.9px). Be Vietnam Pro's default metrics are slightly wider at large sizes; tightening them makes the type feel engineered rather than typeset. Never set display-size Be Vietnam Pro at normal or positive tracking.

**The Single Family Rule.** Be Vietnam Pro is the only font. No serif accents, no mono for code, no decorative pairing. The type system's strength is weight contrast within one family, not variety between families.

## 4. Elevation

Zero shadows. Depth is communicated entirely through tonal layering — darker surfaces recede, lighter surfaces advance. In dark mode: Void Black (receded) → Zinc 900 (elevated) → Zinc 800 (edge). In light mode: White (base) → Zinc 100 (elevated).

The Liquid Glass navigation bar uses `backdrop-filter: blur(20px)` with a semi-transparent background — this is the single exception to the flat rule, and it's structural (the bar floats over content), not decorative.

### Named Rules

**The Flat-By-Default Rule.** No `box-shadow` anywhere in the system. If you're about to add a shadow, use a darker surface color or a 1px border instead. Shadows are a last resort for modal overlays only (and even then, prefer a scrim).

## 5. Components

### Buttons

- **Shape:** Gently curved edges (8px radius)
- **Filled (Primary):** White background (#FAFAFA), black text (#000000). High contrast on dark surfaces — the button pops by being the brightest element. Padding: 12px 24px.
- **Outlined:** Transparent background, white 1px border (#27272A), white text. For secondary actions. Same radius and padding.
- **Hover / Focus:** No hover state on mobile. Focus ring uses indigo (#6366F1) border — 1.5px, same radius.

### Cards / Containers

- **Corner Style:** 16px radius (dark), 12px radius (light)
- **Background:** Zinc 900 (#18181B) in dark, White (#FFFFFF) in light
- **Border:** 1px solid Zinc 800 (#27272A) in dark, 1px solid Zinc 200 (#E4E4E7) in light
- **Shadow Strategy:** None — see Elevation section. Depth is tonal.
- **Internal Padding:** 16px consistent
- **Margin:** Zero (spacing between cards is handled by parent layout)

### Inputs / Fields

- **Style:** Zinc 900 fill, 1px Zinc 800 border, 8px radius. White text. Padding: 12px 16px.
- **Focus:** Indigo (#6366F1) border, 1.5px width. No glow, no shadow — just the border color shift.
- **Error:** Red (#EF4444) border, same width.
- **Placeholder:** Zinc 400 (#A1A1AA) — must hit 4.5:1 contrast against Zinc 900.

### Navigation (Liquid Glass Bottom Bar)

- **Style:** Floating bar with 20px backdrop blur, semi-transparent background, 30px pill radius
- **Position:** Bottom of screen, 16px margin from edges
- **Active state:** Indigo (#6366F1) icon + label, 15% opacity background pill
- **Inactive state:** Zinc 400 (#A1A1AA) icon + label
- **Typography:** 11px, weight 500, Be Vietnam Pro
- **Badge:** Red (#EF4444) dot for offline mode; count badge for active courses

### Tile Groups (Forui FTile)

- **Style:** Zinc 900 background cards with 16px radius, 1px Zinc 800 border
- **Prefix icon:** Indigo (#6366F1) for primary actions
- **Suffix:** Chevron right (Zinc 400, 20px)
- **Typography:** Title (15px/600) for tile text

### Skeleton Loading

- **Style:** Zinc 900 base with animated shimmer (Zinc 800 → Zinc 700 sweep)
- **Purpose:** Loading state for schedule and grade data. Only shown when data is genuinely loading, never as a decorative placeholder.

## 6. Do's and Don'ts

### Do:

- **Do** use Void Black (#000000) as the scaffold background in dark mode. Always. No exceptions.
- **Do** use indigo (#6366F1) only for active/focused/selected states. It's a surgical highlight, not a decorative color.
- **Do** use negative letter-spacing on all heading sizes. Be Vietnam Pro at display scale without tightening looks amateur.
- **Do** use the Zinc tonal ramp for surface hierarchy. Zinc 900 for cards, Zinc 800 for borders, Zinc 400 for muted text — never invent new grays.
- **Do** keep card radius at 16px (dark) or 12px (light). Consistency is the entire visual system.
- **Do** use Vietnamese-first copy. Direct, brief, no English filler. "Hôm nay chiến 3 môn nhé" not "You have 3 classes today."

### Don't:

- **Don't** use generic AI templates — cream/beige backgrounds, identical card grids with icon+heading+text, gradient text (`background-clip: text`), glassmorphism as decoration, tiny uppercase tracked eyebrows above every section. PRODUCT.md calls these out explicitly: *"Generic AI templates — cream/beige backgrounds, identical card grids, gradient text, glassmorphism, tiny uppercase tracked eyebrows."*
- **Don't** use `box-shadow` for elevation. The flat tonal system is the design. Shadows are forbidden outside modal overlays.
- **Don't** use border-left or border-right greater than 1px as a colored accent on cards, list items, or callouts. Never intentional.
- **Don't** use two font families. Be Vietnam Pro is the only typeface. No serif accents, no mono for code blocks.
- **Don't** use warm-tinted neutrals (cream, sand, beige, bone). The neutral ramp is zinc — cool, blue-gray, precise. Warmth comes from the student context, not from the palette.
- **Don't** use numbered section markers as default scaffolding (01 / 02 / 03). Numbers earn their place only when the section is an actual ordered sequence.
- **Don't** set Indigo as a background color for large surfaces. It's an accent. See the Indigo Budget Rule.
- **Don't** use bounce or elastic easing curves. Motion is functional — ease-out-quart or quint only.
