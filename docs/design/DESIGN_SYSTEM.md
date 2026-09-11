# Voca design system

The shared design language and its two implementations.

Mobile and admin share **tokens and principles**, never components. A Flutter widget and a
React component solve different problems on different platforms, and a library abstract
enough to serve both would be harder to use than either (ARCHITECTURE.md 44).

```
docs/design  (this document: the language)
     │
     ├── Flutter   mobile/lib/core/theme
     └── React     admin/src/app/globals.css + admin/src/components/ui
```

Every value below is **IMPLEMENTED** in both applications unless marked otherwise.

---

## Visual direction

Minimal, premium, calm. Large type, generous whitespace, soft depth, restrained
translucency.

Deliberately not: a generic SaaS dashboard, neon, a gaming interface, a brightly coloured
language-learning app, or a glassmorphism template. Glass marks one surface as floating; a
screen where everything is glass has no hierarchy.

---

## Colour — IMPLEMENTED

Semantic names only. A raw hex value outside the token file is a bug.

| Token | Light | Meaning |
|-------|-------|---------|
| `primary` | `#0A6E4F` | Brand accent, primary action, focus |
| `primaryPressed` | `#085A40` | Held state of a primary control |
| `primaryMuted` | `#D6F5E8` | Quiet accent wash, selected rows |
| `onPrimary` | `#FFFFFF` | Content on `primary` |
| `background` | `#EDF5F1` (dark `#0B0F17`) | The page. Light leans mint green, so white glass has colour to sit on and reads as glass |
| `surface` | `#FFFFFF` | Cards and sheets |
| `textPrimary` | `#111827` | Body and headings |
| `textSecondary` | `#374151` (dark `#CBD0D8`) | Supporting text. Darker than the usual gray-500 because it sits on the coloured background and on glass; `contrast_test` checks it over every background field |
| `textDisabled` | `#D1D5DB` | Unavailable content |
| `border` | `#E5E7EB` | Hairline separation |
| `borderStrong` | `#D1D5DB` | Input outlines |
| `success` | `#16A34A` | |
| `warning` | `#B45309` | |
| `error` | `#DC2626` | |
| `successMuted` / `warningMuted` / `errorMuted` | `#DCFCE7` / `#FEF3C7` / `#FEE2E2` | Fills behind status text |
| `onSuccessMuted` / `onWarningMuted` / `onErrorMuted` | `#14532D` / `#78350F` / `#991B1B` | Text on those fills |

### Why the status colours are darker than the usual palette

The vivid weights (`#22C55E`, `#F59E0B`) were the starting direction and they **failed
contrast**: 2.28:1 and 2.15:1 against a white card, well under the 3:1 floor. They are used
as foreground here, for status icons and badge text, so the darker weights became the
semantic tokens and the pale weights became the muted fills behind them.

This was caught by an automated test, not by eye. See `Accessibility` below.

Dark mode is **IMPLEMENTED and complete**, but **not visually designed**. Every token has a
coherent dark value and the contrast tests pass in both themes, so the app runs correctly
in dark mode today. Refining it is a design task; the token set will not change.

---

## Typography — IMPLEMENTED

The system font: SF Pro on Apple platforms, Roboto on Android, Geist on web. It renders
Uzbek Latin diacritics correctly, needs no download, and matches what people already read.

| Style | Size | Weight |
|-------|------|--------|
| display | 34 | 700 |
| headline | 26 | 700 |
| title | 20 | 600 |
| subtitle | 17 | 600 |
| body | 16 | 400 |
| bodyMedium | 15 | 400 |
| label | 14 | 600 |
| caption | 12 | 400 |

Line heights: 1.15 tight, 1.35 standard, 1.5 relaxed. Generous, because the direction is
spacious and Uzbek body text needs room.

Text scaling is clamped to 0.85–1.4 on mobile. People legitimately enlarge text and the
layout must accommodate it; past that bound the design breaks rather than adapts, and a
broken layout is less accessible than a slightly smaller one.

---

## Spacing — IMPLEMENTED

`4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48`

Named `xxs · xs · sm · md · lg · xl · xxl · xxxl · huge`. A layout needing a value off this
scale has usually drifted.

## Radius — IMPLEMENTED

Mobile: `8 small · 12 medium · 20 large · 28 xlarge · 999 pill`.
Admin sits one step tighter (`8 · 12 · 16`) because it is data-dense.

Moderately rounded. Fully rounded surfaces read as playful and pull toward the colourful
language-learning look Voca is avoiding. `pill` is for chips and badges, never cards.

---

## Glass — IMPLEMENTED (mobile only)

| Token | Light |
|-------|-------|
| tint | `#FFFFFF` at 80% |
| border | white at 20% |
| blur sigma | 18 |
| radius | 20 |
| shadow | wide, soft, low opacity |

Two rules govern every value. **Blur stays low**: heavy blur is expensive on mid-range
Android and turns the background into noise behind text. **Contrast outranks the effect**:
the tint is opaque enough that body text on glass still meets contrast requirements.

### Liquid and glass on the UI

The direction is Apple's iOS Liquid Glass, and what defines it is restraint: no glossy
highlight blobs, no coloured glows, no candy gradients. Those turned an earlier version
into a cartoon of glass.

The background is a still wash of blurred colour fields (`LiquidBackground`) and never
moves. Dark keeps two indigo fields and a quiet green one. Light sits on a pale mint page
with teal, green and a touch of indigo, so white glass in front of it is visible.

| Piece | Looks like | Used for |
|---|---|---|
| `GlassSurface` | clear glass: blur plus a saturation boost of what is behind, a thin tint (20% white in light, 40% in dark), soft light fading from the top, light gathering just inside the rim, a hairline rim brightest along the top, a soft shadow outside only | cards, lists, sheets, dialogs, the tab bar, glass buttons |
| `LiquidDrop` | glass tinted with a colour: a faint light across the top, a slightly deeper bottom, a hairline rim; the label band in the middle stays the plain colour | the primary button, filled icon wells, progress fills, chart columns, check marks, avatar initials |
| `GlassBead` | clear glass: a thin fill fading from the top, a hairline rim | filter pills, sound symbols, code cells, the avatar ring, page dots |

The tab bar is a floating capsule of clear glass. Destinations are plain icons and labels;
the selected one gets a lighter glass lens behind it, which slides to a new destination,
stretching a little and settling with a slight overshoot. Buttons are capsules.

Details taken from Apple's Liquid Glass:

- **Specular rim.** The hairline rim carries two highlights, the brighter top-left where
  the light comes from and a fainter one bottom-right where it leaves (`specularRim`).
- **Lensing.** Light gathers just inside the rim and fades inward, never behind text.
- **Saturation.** What is seen through blurred glass is made 1.8x more saturated, so
  colour glows through instead of turning grey.
- **Touch light.** Pressing a glass control makes it glow softly from the point of
  contact (`GlassTouchLight`). There is no Material ripple anywhere in the app.
- **Scroll edge.** Content scrolling up under the status bar fades out.

Cards follow a reference the product owner chose: dark smoked glass (a near-black tint
in dark mode) with a dim hairline rim, and a teal light pooling at the top-right and
bottom-left corners that spills a little past the edge. The light stays near its corner.
Controls, the tab bar and selection cards keep a plain hairline, so a screen has one
kind of lit object.

The tab bar follows a reference tab bar: a tall clear capsule with a thin light rim,
outline icons at rest, and the selected destination in a lighter pill of liquid glass
(lit across the top, a touch deeper at the bottom) with its icon filled. Voca keeps its
own destinations, icons and labels; only the design comes from the reference.

**Brand colour.** A deep emerald (`#0A6E4F` light, `#34D399` dark). Filled controls run
it from a lighter top down towards black, which is where the brand gets its depth; a label
only ever sits on the colour itself or darker, so it keeps its contrast. The background
fields keep their own indigo, so the page does not move when the brand does.

**One radius.** Every element uses the same corner radius, 20 (`VocaRadius.element`).
Anything shorter than 40 comes out as a capsule, because a corner larger than half a side
is scaled to fit. Only the tab bar and its pill are capsules by design.

**Corner light length.** The teal light at a card's corners reaches about a third of the
card's longer side (between 70 and 170 points), so wide, short cards get light that runs
along their long edges instead of a dab at the corner.

**Tab bar.** Clear glass: a thin tint, a moderate blur that turns what passes under it
into soft colour, a thin light rim, and a see-through pill behind the selected
destination.

Glass shadows fall outside the pane only. Under translucent glass an ordinary shadow shows
through and turns the pane grey, so `GlassSurface` clips the pane's shape out of its own
shadow.

Contrast is checked against all of it, including the saturation boost (`contrast_test`).

Glass is deliberately **not** used in the admin. Translucency behind a dense data table
hurts readability for no benefit.

---

## Motion — IMPLEMENTED

| Token | Duration | Use |
|-------|----------|-----|
| instant | 120ms | State change under the finger |
| quick | 200ms | The default: fades, small scales |
| standard | 320ms | Surfaces and routes |
| emphasized | 480ms | A deliberate, noticeable movement |
| expressive | 720ms | Reserved for pronunciation results — **PLANNED**, unused |

Curves: `easeOutCubic` standard and entering, `easeInCubic` leaving (faster out than in),
`easeOutBack` for the rare moment that should feel alive.

Every animation passes through a reduce-motion check. The admin honours
`prefers-reduced-motion` in CSS.

---

## Accessibility — IMPLEMENTED

Non-negotiable, and outranking every visual effect.

- **Contrast is tested, not assumed.** `mobile/test/core/theme/contrast_test.dart` verifies
  every foreground/background pair in both themes against WCAG AA: 4.5:1 for text, 3:1 for
  large text and meaningful boundaries. It found three real failures in the starting
  palette. A failure there is a design bug, not a test bug.
- **Touch targets** are at least 48×48 on mobile, verified by widget tests. The admin uses
  smaller targets deliberately: a mouse is more precise than a thumb.
- **Icon-only buttons require a semantic label.** It is a required constructor argument on
  mobile, not an optional one.
- **Errors are announced**, not merely coloured red: `liveRegion` on mobile, `role="alert"`
  and `aria-describedby` on web.
- **Keyboard** is first-class in the admin: a visible focus ring and a skip-to-content link
  ahead of the sidebar.
- **Headings are marked** as headings so screen readers can navigate between sections.

---

## Components — IMPLEMENTED

| Mobile | Admin |
|--------|-------|
| `PrimaryButton`, `SecondaryButton`, `VocaTextButton`, `VocaIconButton` | `Button` with primary / secondary / ghost |
| `GlassSurface`, `GlassCard` | `Card` (opaque) |
| `AppTextField` | `Input` |
| `SectionHeader` | `Card` header |
| `AppBadge` | — **PLANNED** |
| `AppDivider` | border utilities |
| `LoadingView`, `SkeletonBox` | `LoadingState`, `Skeleton` |
| `ErrorView` | `ErrorState` |
| `EmptyView` | `EmptyState` |
| — | `Table`, `THead`, `TBody`, `TR`, `TH`, `TD` |
| `PageContainer` (responsive) | `AppShell`, `Sidebar`, `Header` |

Every interactive component supports default, pressed/hover, disabled and, where relevant,
loading. A loading button keeps its width so the layout does not jump.

---

## Responsiveness — IMPLEMENTED (mobile)

Layout branches on **available space**, never on a device name and never on a fixed width.

| Class | Width | Page inset |
|-------|-------|-----------|
| compact | under 360 | 16 |
| medium | 360–599 | 20 |
| expanded | 600+ | 24 |

`PageContainer` caps content at 560 logical pixels so a line of text on a tablet does not
stretch to an unreadable length. Covered by widget tests at 320, 390, 834 and 1200 points.

---

## Not built yet

**PLANNED**, listed so nobody assumes otherwise: a brand typeface, a visually designed dark
theme, illustrations, an icon set beyond Material defaults, the admin badge component,
mobile bottom navigation, and every product screen. Pronunciation feedback motion is
reserved in the token scale but unused.
