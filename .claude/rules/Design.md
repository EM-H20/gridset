# Design System Inspired by Lovable

## 1. Visual Theme & Atmosphere

Lovable's website radiates warmth through restraint. The entire page sits on a creamy, parchment-toned background (`#f7f4ed`) that immediately separates it from the cold-white conventions of most developer tool sites. This isn't minimalism for minimalism's sake — it's a deliberate choice to feel approachable, almost analog, like a well-crafted notebook. The near-black text (`#1c1c1c`) against this warm cream creates a contrast ratio that's easy on the eyes while maintaining sharp readability.

The custom **MoneygraphyPixel** typeface (`assets/fonts/Moneygraphy-Pixel.ttf`) is the system's secret weapon. Unlike geometric sans-serifs that signal "tech company," the pixel typeface carries a retro, hand-crafted warmth — blocky glyphs on a 16px grid that evoke early computing without feeling dated. Because this is a bitmap-derived pixel font, **all font sizes MUST be multiples of 16** (16px, 32px, 48px, 64px, 80px, 96px…). Using non-16 multiples causes sub-pixel interpolation that blurs or "breaks" the glyph edges. At display sizes (48px–96px) the font reads as a confident editorial statement; at 16px it remains crisp for UI and body copy. No `letter-spacing` adjustments — the pixel grid already defines spacing, and any non-zero tracking will visibly mis-align glyphs.

What makes Lovable's visual system distinctive is its opacity-driven depth model. Rather than using a traditional gray scale, the system modulates `#1c1c1c` at varying opacities (0.03, 0.04, 0.4, 0.82–0.83) to create a unified tonal range. Every shade of gray on the page is technically the same hue — just more or less transparent. This creates a visual coherence that's nearly impossible to achieve with arbitrary hex values. The border system follows suit: `1px solid #eceae4` for light divisions and `1px solid rgba(28, 28, 28, 0.4)` for stronger interactive boundaries.

**Key Characteristics:**

- Warm parchment background (`#f7f4ed`) — not white, not beige, a deliberate cream that feels hand-selected
- **MoneygraphyPixel** pixel typeface — all sizes MUST be multiples of 16px to avoid glyph breakage
- Opacity-driven color system: all grays derived from `#1c1c1c` at varying transparency levels
- Inset shadow technique on buttons: `rgba(255,255,255,0.2) 0px 0.5px 0px 0px inset, rgba(0,0,0,0.2) 0px 0px 0px 0.5px inset`
- Warm neutral border palette: `#eceae4` for subtle, `rgba(28,28,28,0.4)` for interactive elements
- Full-pill radius (`9999px`) used extensively for action buttons and icon containers
- Focus state uses `rgba(0,0,0,0.1) 0px 4px 12px` shadow for soft, warm emphasis
- shadcn/ui + Radix UI component primitives with Tailwind CSS utility styling

## 2. Color Palette & Roles

### Primary

- **Cream** (`#f7f4ed`): Page background, card surfaces, button surfaces. The foundation — warm, paper-like, human.
- **Charcoal** (`#1c1c1c`): Primary text, headings, dark button backgrounds. Not pure black — organic warmth.
- **Off-White** (`#fcfbf8`): Button text on dark backgrounds, subtle highlight. Barely distinguishable from pure white.

### Neutral Scale (Opacity-Based)

- **Charcoal 100%** (`#1c1c1c`): Primary text, headings, dark surfaces.
- **Charcoal 83%** (`rgba(28,28,28,0.83)`): Strong secondary text.
- **Charcoal 82%** (`rgba(28,28,28,0.82)`): Body copy.
- **Muted Gray** (`#5f5f5d`): Secondary text, descriptions, captions.
- **Charcoal 40%** (`rgba(28,28,28,0.4)`): Interactive borders, button outlines.
- **Charcoal 4%** (`rgba(28,28,28,0.04)`): Subtle hover backgrounds, micro-tints.
- **Charcoal 3%** (`rgba(28,28,28,0.03)`): Barely-visible overlays, background depth.

### Surface & Border

- **Light Cream** (`#eceae4`): Card borders, dividers, image outlines. The warm divider line.
- **Cream Surface** (`#f7f4ed`): Card backgrounds, section fills — same as page background for seamless integration.

### Interactive

- **Ring Blue** (`#3b82f6` at 50% opacity): `--tw-ring-color`, Tailwind focus ring.
- **Focus Shadow** (`rgba(0,0,0,0.1) 0px 4px 12px`): Focus and active state shadow — soft, warm, diffused.

### Inset Shadows

- **Button Inset** (`rgba(255,255,255,0.2) 0px 0.5px 0px 0px inset, rgba(0,0,0,0.2) 0px 0px 0px 0.5px inset, rgba(0,0,0,0.05) 0px 1px 2px 0px`): The signature multi-layer inset shadow on dark buttons.

## 3. Typography Rules

### Font Family

- **Primary**: `MoneygraphyPixel` (asset: `assets/fonts/Moneygraphy-Pixel.ttf`)
- **Flutter declaration**: `fontFamily: 'MoneygraphyPixel'`
- **Weight**: Single weight only (400). This is a bitmap-style pixel font — synthetic weight manipulation (bold/italic) corrupts the pixel grid and must not be used.
- **⚠️ SIZE RULE — CRITICAL**: Every `fontSize` value MUST be an integer multiple of **16** (16, 32, 48, 64, 80, 96, 112, 128…). Any other size causes sub-pixel blurring that breaks glyph readability. This overrides the standard 1px type scale.
- **Letter-spacing**: Always `0` (normal). Pixel fonts ship their own optical spacing on the 16px grid — any custom tracking mis-aligns glyph edges.

### Hierarchy (16-multiple Scale)

| Role            | Font             | Size | Weight | Line Height       | Letter Spacing | Notes                                |
| --------------- | ---------------- | ---- | ------ | ----------------- | -------------- | ------------------------------------ |
| Display Hero    | MoneygraphyPixel | 96px | 400    | 1.00 (tight)      | 0              | Maximum impact                       |
| Display Alt     | MoneygraphyPixel | 80px | 400    | 1.00 (tight)      | 0              | Alt hero / large headline            |
| Section Heading | MoneygraphyPixel | 64px | 400    | 1.00 (tight)      | 0              | Feature section titles               |
| Sub-heading     | MoneygraphyPixel | 48px | 400    | 1.00 (tight)      | 0              | Sub-sections                         |
| Card Title      | MoneygraphyPixel | 32px | 400    | 1.00 (tight)      | 0              | Card headings, stats                 |
| Body Large      | MoneygraphyPixel | 32px | 400    | 1.50              | 0              | Introductions, emphasized copy       |
| Body            | MoneygraphyPixel | 16px | 400    | 1.50              | 0              | Standard reading text (baseline 1x)  |
| Button          | MoneygraphyPixel | 16px | 400    | 1.50              | 0              | Button labels                        |
| Button Small    | MoneygraphyPixel | 16px | 400    | 1.50              | 0              | Compact buttons (same size — tighter padding instead) |
| Link            | MoneygraphyPixel | 16px | 400    | 1.50              | 0              | Underline decoration                 |
| Link Small      | MoneygraphyPixel | 16px | 400    | 1.50              | 0              | Footer links                         |
| Caption         | MoneygraphyPixel | 16px | 400    | 1.50              | 0              | Metadata, small text                 |

> **Note on "small" sizes**: Because 16px is the smallest allowed size, compact variants (buttons, captions, links) share the same 16px type size. Create visual hierarchy via **padding, color opacity, and spacing** instead of reducing font size below 16px. Never use 12px / 14px — they will render with broken pixels.

### Principles

- **Pixel-grid voice**: MoneygraphyPixel gives the product a retro, crafted personality — readable, playful, and unmistakably *designed*. Treat the glyph grid as a feature, not a constraint.
- **16-multiple type scale**: The entire typographic system is built on a strict 16px base unit. Headings scale as 1x, 2x, 3x, 4x, 5x, 6x — never in-between.
- **Hierarchy through size & color, not weight**: No bold/semibold variants exist. Create emphasis with size jumps (16 → 32 → 48) and opacity (`#1c1c1c` at 100% for emphasis, 82% for body, 40% for muted).
- **No tracking, no italic, no synthetic bold**: All three distort the pixel grid and cause visible breakage. Keep `letterSpacing: 0`, `fontStyle: FontStyle.normal`, and `fontWeight: FontWeight.w400`.

## 4. Component Stylings

### Buttons

**Primary Dark (Inset Shadow)**

- Background: `#1c1c1c`
- Text: `#fcfbf8`
- Padding: 8px 16px
- Radius: 6px
- Shadow: `rgba(0,0,0,0) 0px 0px 0px 0px, rgba(0,0,0,0) 0px 0px 0px 0px, rgba(255,255,255,0.2) 0px 0.5px 0px 0px inset, rgba(0,0,0,0.2) 0px 0px 0px 0.5px inset, rgba(0,0,0,0.05) 0px 1px 2px 0px`
- Active: opacity 0.8
- Focus: `rgba(0,0,0,0.1) 0px 4px 12px` shadow
- Use: Primary CTA ("Start Building", "Get Started")

**Ghost / Outline**

- Background: transparent
- Text: `#1c1c1c`
- Padding: 8px 16px
- Radius: 6px
- Border: `1px solid rgba(28,28,28,0.4)`
- Active: opacity 0.8
- Focus: `rgba(0,0,0,0.1) 0px 4px 12px` shadow
- Use: Secondary actions ("Log In", "Documentation")

**Cream Surface**

- Background: `#f7f4ed`
- Text: `#1c1c1c`
- Padding: 8px 16px
- Radius: 6px
- No border
- Active: opacity 0.8
- Use: Tertiary actions, toolbar buttons

**Pill / Icon Button**

- Background: `#f7f4ed`
- Text: `#1c1c1c`
- Radius: 9999px (full pill)
- Shadow: same inset pattern as primary dark
- Opacity: 0.5 (default), 0.8 (active)
- Use: Additional actions, plan mode toggle, voice recording

### Cards & Containers

- Background: `#f7f4ed` (matches page)
- Border: `1px solid #eceae4`
- Radius: 12px (standard), 16px (featured), 8px (compact)
- No box-shadow by default — borders define boundaries
- Image cards: `1px solid #eceae4` with 12px radius

### Inputs & Forms

- Background: `#f7f4ed`
- Text: `#1c1c1c`
- Border: `1px solid #eceae4`
- Radius: 6px
- Focus: ring blue (`rgba(59,130,246,0.5)`) outline
- Placeholder: `#5f5f5d`

### Navigation

- Clean horizontal nav on cream background, fixed
- Logo/wordmark left-aligned (128 x 32px — snap to 16-multiples)
- Links: MoneygraphyPixel 16px weight 400, `#1c1c1c` text
- CTA: dark button with inset shadow, 6px radius
- Mobile: hamburger menu with 6px radius button
- Subtle border or no border on scroll

### Links

- Color: `#1c1c1c`
- Decoration: underline (default)
- Hover: primary accent (via CSS variable `hsl(var(--primary))`)
- No color change on hover — decoration carries the interactive signal

### Image Treatment

- Showcase/portfolio images with `1px solid #eceae4` border
- Consistent 12px border radius on all image containers
- Soft gradient backgrounds behind hero content (warm multi-color wash)
- Gallery-style presentation for template/project showcases

### Distinctive Components

**AI Chat Input**

- Large prompt input area with soft borders
- Suggestion pills with `#eceae4` borders
- Voice recording / plan mode toggle buttons as pill shapes (9999px)
- Warm, inviting input area — not clinical

**Template Gallery**

- Card grid showing project templates
- Each card: image + title, `1px solid #eceae4` border, 12px radius
- Hover: subtle shadow or border darkening
- Category labels as text links

**Stats Bar**

- Large metrics: "0M+" pattern in 48px or 64px MoneygraphyPixel weight 400
- Descriptive text below at 16px in muted gray
- Horizontal layout with generous spacing

## 5. Layout Principles

### Spacing System

- Base unit: 16px (matches the font's 16px pixel grid — keeps everything on one rhythm)
- Scale: 16px, 32px, 48px, 64px, 80px, 96px, 128px, 160px, 192px, 208px
- Micro-spacing (<16px) allowed only for non-textual gaps (icon padding, borders) — anything that aligns with text must use 16-multiples
- The scale expands generously at the top end — sections use 96px–208px vertical spacing for editorial breathing room

### Grid & Container

- Max content width: approximately 1200px (centered)
- Hero: centered single-column with massive vertical padding (96px+)
- Feature sections: 2–3 column grids
- Full-width footer with multi-column link layout
- Showcase sections with centered card grids

### Whitespace Philosophy

- **Editorial generosity**: Lovable's spacing is lavish at section boundaries (80px–208px). The warm cream background makes these expanses feel cozy rather than empty.
- **Content-driven rhythm**: Tight internal spacing within cards (12–24px) contrasts with wide section gaps, creating a reading rhythm that alternates between focused content and visual rest.
- **Section separation**: Footer uses `1px solid #eceae4` border and 16px radius container. Sections defined by generous spacing rather than border lines.

### Border Radius Scale

- Micro (4px): Small buttons, interactive elements
- Standard (6px): Buttons, inputs, navigation menu
- Comfortable (8px): Compact cards, divs
- Card (12px): Standard cards, image containers, templates
- Container (16px): Large containers, footer sections
- Full Pill (9999px): Action pills, icon buttons, toggles

## 6. Depth & Elevation

| Level                | Treatment                                                                                                          | Use                           |
| -------------------- | ------------------------------------------------------------------------------------------------------------------ | ----------------------------- |
| Flat (Level 0)       | No shadow, cream background                                                                                        | Page surface, most content    |
| Bordered (Level 1)   | `1px solid #eceae4`                                                                                                | Cards, images, dividers       |
| Inset (Level 2)      | `rgba(255,255,255,0.2) 0px 0.5px 0px inset, rgba(0,0,0,0.2) 0px 0px 0px 0.5px inset, rgba(0,0,0,0.05) 0px 1px 2px` | Dark buttons, primary actions |
| Focus (Level 3)      | `rgba(0,0,0,0.1) 0px 4px 12px`                                                                                     | Active/focus states           |
| Ring (Accessibility) | `rgba(59,130,246,0.5)` 2px ring                                                                                    | Keyboard focus on inputs      |

**Shadow Philosophy**: Lovable's depth system is intentionally shallow. Instead of floating cards with dramatic drop-shadows, the system relies on warm borders (`#eceae4`) against the cream surface to create gentle containment. The only notable shadow pattern is the inset shadow on dark buttons — a subtle multi-layer technique where a white highlight line sits at the top edge while a dark ring and soft drop handle the bottom. This creates a tactile, pressed-into-surface feeling rather than a hovering-above-surface feeling. The warm focus shadow (`rgba(0,0,0,0.1) 0px 4px 12px`) is deliberately diffused and large, creating a soft glow rather than a sharp outline.

### Decorative Depth

- Hero: soft, warm multi-color gradient wash (pinks, oranges, blues) behind hero — atmospheric, barely visible
- Footer: gradient background with warm tones transitioning to the bottom
- No harsh section dividers — spacing and background warmth handle transitions

## 7. Do's and Don'ts

### Do

- Use the warm cream background (`#f7f4ed`) as the page foundation — it's the brand's signature warmth
- Use `MoneygraphyPixel` at sizes that are **multiples of 16** only (16, 32, 48, 64, 80, 96…)
- Keep `letterSpacing: 0` — pixel fonts do not tolerate tracking
- Derive all grays from `#1c1c1c` at varying opacity levels for tonal unity
- Use the inset shadow technique on dark buttons for tactile depth
- Use `#eceae4` borders instead of shadows for card containment
- Use size + opacity for hierarchy (no bold/italic variants exist)
- Use full-pill radius (9999px) only for action pills and icon buttons
- Apply opacity 0.8 on active states for responsive tactile feedback

### Don't

- Don't use pure white (`#ffffff`) as a page background — the cream is intentional
- Don't use heavy box-shadows for cards — borders are the containment mechanism
- Don't introduce saturated accent colors — the palette is intentionally warm-neutral
- **Don't use any font size that is NOT a multiple of 16** (no 14px, 18px, 20px, 24px, 36px, 60px) — pixels break
- Don't use synthetic bold, italic, or variable weight — MoneygraphyPixel ships a single pixel-grid weight only
- Don't apply non-zero `letterSpacing` — it mis-aligns the pixel grid and breaks glyph edges
- Don't apply 9999px radius on rectangular buttons — pills are for icon/action toggles
- Don't use sharp focus outlines — the system uses soft shadow-based focus indicators
- Don't mix border styles — `#eceae4` for passive, `rgba(28,28,28,0.4)` for interactive
- Don't scale text with fractional values (`textScaleFactor` non-integer) — snap to integer 16-multiples

## 8. Responsive Behavior

### Breakpoints

| Name          | Width       | Key Changes                             |
| ------------- | ----------- | --------------------------------------- |
| Mobile Small  | <600px      | Tight single column, reduced padding    |
| Mobile        | 600–640px   | Standard mobile layout                  |
| Tablet Small  | 640–700px   | 2-column grids begin                    |
| Tablet        | 700–768px   | Card grids expand                       |
| Desktop Small | 768–1024px  | Multi-column layouts                    |
| Desktop       | 1024–1280px | Full feature layout                     |
| Large Desktop | 1280–1536px | Maximum content width, generous margins |

### Touch Targets

- Buttons: 8px 16px padding (comfortable touch)
- Navigation: adequate spacing between items
- Pill buttons: 9999px radius creates large tap-friendly targets
- Menu toggle: 6px radius button with adequate sizing

### Collapsing Strategy

- Hero: 96px → 64px → 48px headline scaling (all 16-multiples — never 60/36/24)
- Navigation: horizontal links → hamburger menu at 768px
- Feature cards: 3-column → 2-column → single column stacked
- Template gallery: grid → stacked vertical cards
- Stats bar: horizontal → stacked vertical
- Footer: multi-column → stacked single column
- Section spacing: 128px+ → 64px on mobile (stay on the 16-multiple grid)

### Image Behavior

- Template screenshots maintain `1px solid #eceae4` border at all sizes
- 12px border radius preserved across breakpoints
- Gallery images responsive with consistent aspect ratios
- Hero gradient softens/simplifies on mobile

## 9. Agent Prompt Guide

### Quick Color Reference

- Primary CTA: Charcoal (`#1c1c1c`)
- Background: Cream (`#f7f4ed`)
- Heading text: Charcoal (`#1c1c1c`)
- Body text: Muted Gray (`#5f5f5d`)
- Border: `#eceae4` (passive), `rgba(28,28,28,0.4)` (interactive)
- Focus: `rgba(0,0,0,0.1) 0px 4px 12px`
- Button text on dark: `#fcfbf8`

### Example Component Prompts

- "Create a hero section on cream background (#f7f4ed). Headline at 96px MoneygraphyPixel weight 400, line-height 1.00, letterSpacing 0, color #1c1c1c. Subtitle at 32px weight 400, line-height 1.50, color #5f5f5d. Dark CTA button (#1c1c1c bg, #fcfbf8 text, 6px radius, 16px padding, inset shadow, 16px label) and ghost button (transparent bg, 1px solid rgba(28,28,28,0.4) border, 6px radius)."
- "Design a card on cream (#f7f4ed) background. Border: 1px solid #eceae4. Radius 12px. No box-shadow. Title at 32px MoneygraphyPixel weight 400, line-height 1.00, color #1c1c1c. Body at 16px weight 400, color #5f5f5d. All font sizes must be multiples of 16."
- "Build a template gallery: grid of cards with 12px radius, 1px solid #eceae4 border, cream backgrounds. Each card: image with 12px top radius, 16px title below. Hover: subtle border darkening."
- "Create navigation: sticky on cream (#f7f4ed). MoneygraphyPixel 16px weight 400 for links, #1c1c1c text, letterSpacing 0. Dark CTA button right-aligned with inset shadow. Mobile: hamburger menu with 6px radius."
- "Design a stats section: large numbers at 64px MoneygraphyPixel weight 400, letterSpacing 0, #1c1c1c. Labels below at 16px weight 400, #5f5f5d. Horizontal layout with 32px gap."

### Iteration Guide

1. Always use cream (`#f7f4ed`) as the base — never pure white
2. Derive grays from `#1c1c1c` at opacity levels rather than using distinct hex values
3. Use `#eceae4` borders for containment, not shadows
4. **Every font size must be a multiple of 16px** — if you catch yourself typing 14 / 18 / 20 / 24 / 36 / 60, snap to the nearest 16-multiple
5. Single weight only (400). Emphasis comes from size + opacity, not bold
6. `letterSpacing: 0` everywhere — no exceptions for headings
7. The inset shadow on dark buttons is the signature detail — don't skip it
8. When in doubt, align both type size and spacing to the 16px grid

### Flutter Usage Snippet

```dart
Text(
  '그리드셋',
  style: TextStyle(
    fontFamily: 'MoneygraphyPixel',
    fontSize: 64,           // MUST be a multiple of 16
    fontWeight: FontWeight.w400,
    letterSpacing: 0,       // never non-zero
    height: 1.0,            // 1.0 for display, 1.5 for body
    color: Color(0xFF1C1C1C),
  ),
)
```
