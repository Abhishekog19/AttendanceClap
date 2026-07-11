# DESIGN.md — Onboarding UI Design System

Extracted from Stitch project "Attendance AI Onboarding Flow" (ID: 13912202415305631836).
All values are literal — extracted from the Tailwind config in the HTML code exports.

---

## Color Palette

| Token | Hex |
|---|---|
| background / surface / surface-bright | #F9F9F9 |
| on-background / on-surface | #1B1B1B |
| primary | #000000 |
| on-primary | #FFFFFF |
| primary-container | #1B1B1B |
| on-primary-container | #848484 |
| secondary | #5E5E5E |
| on-secondary | #FFFFFF |
| secondary-container | #E2E2E2 |
| on-secondary-container | #646464 |
| surface-container-lowest | #FFFFFF |
| surface-container-low | #F3F3F3 |
| surface-container | #EEEEEE |
| surface-container-high | #E8E8E8 |
| surface-container-highest | #E2E2E2 |
| surface-dim | #DADADA |
| surface-variant | #E2E2E2 |
| on-surface-variant | #4C4546 |
| outline | #7E7576 |
| outline-variant | #CFC4C5 |
| inverse-surface | #303030 |
| inverse-on-surface | #F1F1F1 |
| error | #BA1A1A |
| on-error | #FFFFFF |
| error-container | #FFDAD6 |
| on-error-container | #93000A |
| tertiary | #000000 |
| tertiary-container | #1B1B1B |
| on-tertiary-container | #848484 |
| primary-fixed / tertiary-fixed | #E2E2E2 |
| primary-fixed-dim / inverse-primary | #C6C6C6 |

**No inconsistencies found across screens** — all 8 HTML exports have identical color tokens.

---

## Typography

### Font Families
- Headlines: **Plus Jakarta Sans** (weights 700, 800)
- Body / Label / Button: **Hanken Grotesk** (weights 400, 500, 700)

### Type Scale
| Style | Font | Size | Line-height | Weight | Letter-spacing |
|---|---|---|---|---|---|
| headline-lg | Plus Jakarta Sans | 32px | 40px | 800 | -0.02em |
| headline-lg-mobile | Plus Jakarta Sans | 28px | 36px | 800 | -0.01em |
| headline-md | Plus Jakarta Sans | 24px | 32px | 700 | — |
| body-lg | Hanken Grotesk | 18px | 28px | 400 | — |
| body-md | Hanken Grotesk | 16px | 24px | 400 | — |
| label-bold | Hanken Grotesk | 14px | 20px | 700 | — |
| label-sm | Hanken Grotesk | 12px | 16px | 500 | — |

---

## Corner Radii

| Tailwind token | Value |
|---|---|
| rounded-DEFAULT | 16px |
| rounded-lg | 32px |
| rounded-xl | 48px |
| rounded-full | 9999px |

Usage:
- Screen-edge cards (date tiles, subject card): rounded-xl (48px) or rounded-[24px]
- Inner containers, section cards: rounded-DEFAULT (16px) or rounded-xl
- CTA button: rounded-full (pill)
- Back button / icon buttons: rounded-full (circle)
- Input fields: rounded-DEFAULT (16px)
- Chips: rounded-full

---

## Spacing
| Token | Value |
|---|---|
| container-margin (horiz. screen padding) | 20px |
| xs | 8px |
| sm | 16px |
| md | 24px |
| lg | 32px |
| xl | 48px |
| base | 4px |

---

## CTA Button (Primary)
- Fill: #000000
- Text: #FFFFFF
- Font: Plus Jakarta Sans 24px/32px weight 700 (headline-md)
- Vertical padding: 18px each side → ~60px total height
- Shape: rounded-full
- Trailing icon: arrow_forward, 24px, white
- Active scale: 0.98
- Shadow: slight elevation + hover opacity 90%

## CTA Button (Secondary / Outlined)
- Fill: transparent
- Border: outline-variant (~#CFC4C5) with opacity
- Text: on-surface (#1B1B1B) or on-surface-variant (#4C4546)
- Shape: rounded-full

---

## Progress Indicator (Header)

Seen in College Details, Attendance Import:
- [Back button circle] [Linear progress bar, flex-1, h-8px] [Step text "N of 9"]
- Track: surface-container-highest (#E2E2E2), h-2, rounded-full
- Fill: primary (#000000), rounded-full
- Step text: label-bold style, on-surface-variant (#4C4546)

Pill-dot variant (Subject Setup):
- Row of dots: inactive = w-2 h-2 circle, surface-variant; active = w-8 h-2 pill, primary

Segmented bars (Semester, Review):
- h-1.5 each bar, inactive = surface-variant, active = primary with glow shadow

---

## Cards
- Background: surface-container-lowest (#FFFFFF) or surface-container-low (#F3F3F3)
- Border: surface-variant/50 or outline-variant/30
- Corner radius: rounded-xl (in practice ~16-24px range)
- Shadow: 0 8px 24px rgba(0,0,0,0.04)
- Padding: md (24px)

### Selected state
- Background: primary-container (#1B1B1B) → this is dark — for subject color accent border only
- Border: primary (#000000)

---

## Icon Style
- Material Symbols Outlined, wght=400, FILL=0 by default
- Active/selected icons: FILL=1
- Icon sizes: 24px standard, 18px for small, 28px for card heroes

---

## Consistency
All 8 screens share identical Tailwind config in their HTML — zero discrepancies in color, font, or spacing tokens.
