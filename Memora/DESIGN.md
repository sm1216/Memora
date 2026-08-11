# Memora Design System

/* Hallmark · product: travel-memory app · genre: editorial-tactile · theme: Clay Journal
 * axes: paper mid-light · geometric-rounded-sans (SF) · warm clay accent
 * strategy: restrained-committed (clay ≤12% of chrome; night surface on map home)
 */

## Intent
- **Audience:** people who keep souvenirs and want stories to open with a tap
- **Use:** create memory · write NFC · open story from sticker
- **Tone:** clay journal — warm, tactile, quiet confidence. Not SaaS, not neon AI.

## Surfaces
| Token | Role | Approx |
|-------|------|--------|
| `paper` | default app bg | near-white, chroma toward clay not yellow |
| `paperElevated` | cards | pure white |
| `night` | map / globe shell | near-black charcoal |
| `nightElevated` | floating bars on map | charcoal + 8% white |
| `ink` | primary text | deep umber |
| `inkSecondary` | supporting text | warm gray ≥4.5:1 on paper |
| `clay` | primary actions / pins | terracotta brand |
| `clayDeep` | pressed / emphasis | deeper clay |
| `sage` | secondary calm accent | muted green |
| `danger` | destructive | soft red |
| `success` | linked / ok | forest |

## Type
- **Family:** SF Pro (system) — rounded for display/wordmark, default for body
- **Scale:** title 32 bold · headline 22 semibold · body 16 · callout 14 · caption 12 medium · micro 11
- **Tracking:** micro labels +1.5…2.0; never tiny uppercase on every section

## Space
4pt grid: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 72 (tab clearance)

## Radius
- chip/pill: full
- button: 14 continuous
- card: 16–20 continuous
- sheet hero: 22–26
- never 32+ on cards

## Motion
- press: 0.97 scale, 120ms ease-out
- sheet: system
- reduced motion: respect environment

## Components
- Primary button: clay fill, white label
- Secondary: paperElevated + 1px ink/8% border
- Ghost: ink secondary label only
- Chips: selected = clay, idle = elevated
- Tab bar: floating capsule, clay center scan
- Polaroid: white frame, soft shadow (blur ≤8), tape accent

## Anti-patterns (banned)
- Glassmorphism everywhere
- Gradient text
- Side-stripe accent borders
- Identical icon+title+body card grids as only layout
- Tiny uppercase eyebrow on every block
- Invented metrics
