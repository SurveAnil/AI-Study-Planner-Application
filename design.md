# AI Study Planner — Design System & UI Specification
**Version:** 2.0  
**Prepared by:** Senior UI/UX Design  
**Audience:** Prototype developers, UI engineers, Figma designers  
**Platform:** Mobile (Android primary) · Web (responsive)  
**Design Framework:** Material Design 3  

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Design System](#2-design-system)
   - 2.1 Color Palette
   - 2.2 Typography Scale
   - 2.3 Spacing & Grid (8pt)
   - 2.4 Elevation & Shadows
   - 2.5 Border Radius
   - 2.6 Iconography
3. [Component Specifications](#3-component-specifications)
   - 3.1 Buttons
   - 3.2 Input Fields
   - 3.3 Cards
   - 3.4 Navigation Bar
   - 3.5 Chips & Tags
   - 3.6 Progress Indicators
   - 3.7 Dialogs & Bottom Sheets
   - 3.8 Toast & Snackbar
   - 3.9 Empty States
   - 3.10 Offline Wall
4. [Screen Inventory](#4-screen-inventory)
   - S01 Onboarding
   - S02 Create Profile
   - S03 Home Dashboard
   - S04 Generate / Manual Plan
   - S05 Today's Schedule
   - S06 Active Study Session
   - S07 Revision Calendar
   - S08 Progress Report
   - S09 Subject Analytics
   - S10 Resources
   - S11 Settings
   - S12 Performance Prediction
5. [User Flows & Prototyping](#5-user-flows--prototyping)
   - 5.1 App Launch Flow
   - 5.2 Onboarding Flow
   - 5.3 AI Plan Generation Flow (Online)
   - 5.4 Manual Plan Creation Flow (Offline)
   - 5.5 Study Session Flow
   - 5.6 Revision Flow
   - 5.7 Progress & Analytics Flow
6. [Motion & Interaction Design](#6-motion--interaction-design)
7. [Accessibility Checklist](#7-accessibility-checklist)
8. [Dark Mode Specifications](#8-dark-mode-specifications)

---

## 1. Design Philosophy

Four principles govern every visual and interaction decision in this app. When in doubt, return to these.

### 1.1 Principles

| # | Principle | What It Means in Practice |
|---|-----------|--------------------------|
| 01 | **Clarity Over Complexity** | Every screen serves one primary purpose. The most critical action is always the largest element. No decorative elements that don't carry meaning. |
| 02 | **Flow State Preservation** | The app never interrupts a student mid-session. Notifications are suppressed during active timers. Every interaction is completable in ≤ 2 taps. |
| 03 | **Progress as Motivation** | Streaks, completion rings, and performance charts are first-class UI citizens — not afterthoughts. Use green for growth, amber for caution. Never use red for a progress metric. |
| 04 | **Offline is a Condition, Not an Error** | Being offline does not break the app's core experience. Offline states are calm and informative, never red or alarming. |

### 1.2 Visual Personality

- **Tone:** Focused, encouraging, calm — like a knowledgeable study partner
- **Aesthetic:** Clean rounded cards, generous whitespace, purposeful color
- **Density:** Comfortable — not cramped like productivity apps, not airy like a lifestyle app
- **Motion:** Purposeful and brief. Transitions reinforce spatial relationships.

---

## 2. Design System

### 2.1 Color Palette

#### Primary Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `primary` | `#4F6FE8` | `#818CF8` | Primary CTAs, active nav tab, selected states, focus rings |
| `primaryVariant` | `#3D59D0` | — | Pressed/active state of primary |
| `primaryContainer` | `#EEF2FF` | `#312E81` | Chip backgrounds, info banners, active tab indicator fill |
| `onPrimary` | `#FFFFFF` | `#1E1B4B` | Text/icons placed on primary-colored surfaces |
| `onPrimaryContainer` | `#3D59D0` | `#C7D2FE` | Text/icons placed inside primaryContainer |

**Primary Color Rationale:** Indigo `#4F6FE8` sits at the intersection of trust (blue) and creativity (purple). Educational UX research consistently shows blue-spectrum primaries reduce perceived cognitive load — sessions feel more manageable when the UI calms rather than excites.

#### Secondary Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `secondary` | `#34D399` | `#6EE7B7` | Completion states, streaks, positive feedback, done badges |
| `secondaryVariant` | `#059669` | — | Pressed secondary state |
| `secondaryContainer` | `#D1FAE5` | `#064E3B` | Done-state card fills, success banner backgrounds |
| `onSecondary` | `#FFFFFF` | `#003822` | Text on secondary surfaces |

#### Surface Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `background` | `#F8FAFC` | `#0F172A` | Screen background |
| `surface` | `#FFFFFF` | `#1E293B` | Cards, dialogs, modals, bottom sheets |
| `surfaceVariant` | `#F1F5F9` | `#334155` | Input field fills, dividers, secondary card backgrounds |
| `outline` | `#E2E8F0` | `#475569` | Borders, dividers, card edges |
| `onBackground` | `#0F172A` | `#F1F5F9` | Primary body text |
| `onSurface` | `#1E293B` | `#E2E8F0` | Text on cards and surfaces |
| `onSurfaceVariant` | `#64748B` | `#94A3B8` | Secondary text, placeholders, inactive icons |

#### Semantic / Accent Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `error` | `#EF4444` | `#FCA5A5` | Validation errors, destructive actions only |
| `errorContainer` | `#FEF2F2` | `#7F1D1D` | Error message background panels |
| `success` | `#10B981` | `#6EE7B7` | Positive trends, completed sessions, improvement indicators |
| `successContainer` | `#ECFDF5` | `#022C22` | Success state backgrounds |
| `warning` | `#F59E0B` | `#FCD34D` | Approaching deadlines, caution states, overdue items |
| `warningContainer` | `#FFFBEB` | `#451A03` | Warning banner backgrounds |

#### Special Purpose

| Token | Value | Context |
|-------|-------|---------|
| `timerArc` | `#4F6FE8` (primary) | Circular progress arc in session timer |
| `breakBlock` | `#94A3B8` | Break time block cards in schedule |
| `revisionBlock` | `#3B82F6` | Revision task dots in calendar |
| `practiceBlock` | `#F97316` | Practice task dots |
| `testBlock` | `#EF4444` | Test task dots |
| `finalBlock` | `#8B5CF6` | Final revision dots |
| `offlineIcon` | `#94A3B8` | Wifi icon on offline wall — calm, not alarming |
| `overlayScrim` | `#0F172A` at 50% opacity | Modal backdrop |

---

### 2.2 Typography Scale

**Font Families:**
- **Display & UI:** `Plus Jakarta Sans` — geometric-humanist hybrid. Weights: 300 · 400 · 500 · 600 · 700
- **Monospace (timers, stats, numeric data):** `DM Mono` — tabular figures ensure timer digits don't shift width. Weights: 400 · 500

> **Rule:** DM Mono is used exclusively for timers (MM:SS), percentage readouts, scores, and any numeric value that updates in real time. All other text uses Plus Jakarta Sans.

#### Type Scale Table

| Token | Font | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|------|--------|------------|---------------|-------|
| `displayLarge` | Plus Jakarta Sans | 57sp | 700 | 64sp | −0.25sp | Hero score numbers (78%), splash |
| `displayMedium` | DM Mono | 45sp | 700 | 52sp | 0 | Active session countdown timer |
| `displaySmall` | Plus Jakarta Sans | 36sp | 600 | 44sp | 0 | Section hero stats |
| `headlineLarge` | Plus Jakarta Sans | 32sp | 700 | 40sp | 0 | Screen titles (H1) |
| `headlineMedium` | Plus Jakarta Sans | 28sp | 600 | 36sp | 0 | Card headings, subject names |
| `headlineSmall` | Plus Jakarta Sans | 24sp | 600 | 32sp | 0 | Section headers |
| `titleLarge` | Plus Jakarta Sans | 22sp | 600 | 28sp | 0 | Dialog titles, bottom sheet headers |
| `titleMedium` | Plus Jakarta Sans | 16sp | 500 | 24sp | +0.15sp | List item titles, task names |
| `titleSmall` | Plus Jakarta Sans | 14sp | 500 | 20sp | +0.10sp | Chip labels, tab labels |
| `bodyLarge` | Plus Jakarta Sans | 16sp | 400 | 24sp | +0.15sp | Primary body copy |
| `bodyMedium` | Plus Jakarta Sans | 14sp | 400 | 20sp | +0.25sp | Card descriptions, secondary body |
| `bodySmall` | Plus Jakarta Sans | 12sp | 400 | 16sp | +0.40sp | Captions, metadata, helper text |
| `labelLarge` | Plus Jakarta Sans | 14sp | 500 | 20sp | +0.10sp | Button labels |
| `labelMedium` | Plus Jakarta Sans | 12sp | 500 | 16sp | +0.50sp | Badge labels, chip text |
| `labelSmall` | Plus Jakarta Sans | 11sp | 500 | 16sp | +0.50sp | Overlines, category tags |

---

### 2.3 Spacing & Grid (8pt Grid System)

The entire layout uses an **8pt grid**. All spacing values must be multiples of 8. Use named tokens — never hardcode values.

#### Spacing Scale

| Token | Value | px equivalent | Usage |
|-------|-------|--------------|-------|
| `space-xs` | 4dp | 4px | Icon-to-label micro gap, badge inner padding |
| `space-sm` | 8dp | 8px | Internal card gaps, chip horizontal padding |
| `space-md` | 16dp | 16px | **Standard screen horizontal margin, card content padding** |
| `space-lg` | 24dp | 24px | Between unrelated UI groups, dialog padding |
| `space-xl` | 32dp | 32px | Between major screen sections |
| `space-2xl` | 40dp | 40px | Top padding below AppBar |
| `space-3xl` | 48dp | 48px | Hero section vertical padding |
| `space-4xl` | 64dp | 64px | Bottom safe area buffer |

#### Layout Grid

| Property | Value | Notes |
|----------|-------|-------|
| Screen horizontal margin | `16dp` (space-md) | Applied to all content. Cards go edge-to-edge only for hero cards. |
| Column grid (compact phone < 600dp) | 4 columns, 16dp gutter | Primary layout |
| Column grid (large phone 600–840dp) | 8 columns, 24dp gutter | Tablets in portrait |
| Column grid (expanded > 840dp) | 12 columns, 24dp gutter | Tablets landscape / web |
| Vertical rhythm baseline | 8dp | All stacked elements align to 8dp vertical grid |
| Content max-width | 428dp (soft cap) | Content centers on large screens |
| Minimum touch target | **48 × 48dp** | All interactive elements. Smaller visuals use padding to reach this. |
| AppBar height | 56dp | Standard Material 3 |
| Bottom nav bar height | 80dp | 64dp bar + 16dp safe area bottom inset |
| Card internal padding | 16dp all sides | 12dp for compact list cards |
| Section spacing | 32dp | Between distinct content sections on a scrollable screen |
| FAB position | 16dp from right edge, 16dp above bottom nav | |

---

### 2.4 Elevation & Shadows

| Level | Elevation | Shadow | Usage |
|-------|-----------|--------|-------|
| Level 0 | 0 | None | Flat surfaces: nav bar, app bar, filled cards |
| Level 1 | 1dp | `0 1 3 rgba(0,0,0,0.08)` | List cards, compact cards |
| Level 2 | 2dp | `0 2 8 rgba(0,0,0,0.08)` | Standard elevated cards, modals |
| Level 3 | 4dp | `0 4 16 rgba(0,0,0,0.10)` | Hero cards, FABs |
| Level 4 | 8dp | `0 8 24 rgba(79,111,232,0.25)` | Primary FAB (indigo shadow) |

---

### 2.5 Border Radius

| Token | Value | Applied To |
|-------|-------|-----------|
| `radius-sm` | 8dp | TextButton, small chips, SnackBar |
| `radius-md` | 12dp | Input fields (top corners), OutlinedButton, FAB standard |
| `radius-lg` | 16dp | Standard cards, FilledButton, NavigationBar indicator |
| `radius-xl` | 20dp | Hero cards, large feature cards |
| `radius-2xl` | 24dp | Dialogs |
| `radius-3xl` | 28dp | Bottom sheets (top corners only) |
| `radius-full` | 999dp | Chips, pill badges, CircleAvatar |

---

### 2.6 Iconography

- **Primary library:** Material Symbols Rounded (`material_symbols_icons` ^4.x)
- **Supplemental:** Lucide Icons (for productivity metaphors not in Material Symbols)
- **Style rule:** Rounded only — never Sharp or Outlined variants. They conflict with the rounded card aesthetic.
- **Fill variable:** `fill: 0` (inactive/secondary) → `fill: 1` (active/selected). Animate the transition.

| Size | Value | Context |
|------|-------|---------|
| Dense | 20dp | Inside chips, badges |
| Standard | 24dp | All general use |
| Section heading | 32dp | Section header icons |
| Hero / Empty state | 64dp | Illustrations, empty state icons (60% opacity) |

**Navigation bar icons:**
`home` · `calendar_today` · `bar_chart` · `folder` · `settings`

---

## 3. Component Specifications

### 3.1 Buttons

#### Primary — FilledButton

```
Background:     primary (#4F6FE8)
Text:           onPrimary (#FFFFFF), labelLarge (14sp/500)
Border Radius:  12dp (radius-md)
Height:         52dp
Min Width:      120dp
Horizontal Pad: 24dp
Icon (optional):24dp, 8dp gap to label
Elevation:      Level 0 (flat)
Disabled:       All elements at 38% opacity
Loading state:  Replace label with CircularProgressIndicator.adaptive(),
                strokeWidth: 2.5, same color as label
```

**States:**
- Default: bg `#4F6FE8`, text white
- Hovered: +8% primary overlay layer on bg
- Pressed: +12% overlay, scale 0.97 during press
- Focused: 2dp focus ring `#4F6FE8`, 2dp offset
- Disabled: `#4F6FE8` at 38% opacity, text at 38% opacity

#### Secondary — OutlinedButton

```
Background:     transparent
Border:         1.5dp solid primary (#4F6FE8)
Text:           primary (#4F6FE8), labelLarge
Border Radius:  12dp
Height:         48dp
Horizontal Pad: 24dp
Disabled:       border and text at 38% opacity
```

#### Tertiary — TextButton

```
Background:     transparent
Text:           primary (#4F6FE8), labelLarge
Border Radius:  8dp
Height:         40dp
Horizontal Pad: 16dp
Use case:       Skip, Later, Dismiss, inline link actions
```

#### FAB — Large (primary creation action)

```
Background:     primary (#4F6FE8)
Icon:           onPrimary (#FFFFFF), 32dp
Size:           96 × 96dp
Border Radius:  16dp (radius-lg)
Elevation:      Level 4 (indigo shadow)
Position:       16dp right, 16dp above bottom nav
Use case:       Generate Study Plan on Dashboard
```

#### FAB — Standard

```
Background:     primary (#4F6FE8)
Icon:           onPrimary, 24dp
Size:           56 × 56dp
Border Radius:  16dp
Elevation:      Level 4
Use case:       Add task, Add resource
```

#### IconButton — Filled (timer controls)

```
Background:     primaryContainer (#EEF2FF)
Icon:           primary (#4F6FE8), 24dp
Size:           40 × 40dp
Border Radius:  full (radius-full)
Elevation:      Level 0
```

---

### 3.2 Input Fields

All inputs use FilledInputDecoration by default. OutlinedInputDecoration only inside modal dialogs.

#### Standard FilledTextField

```
Fill:           surfaceVariant (#F1F5F9)
Border Radius:  12dp top / 0dp bottom
Min Height:     56dp
Horizontal Pad: 16dp
Vertical Pad:   12dp (content inside)
Font:           bodyLarge (16sp, Plus Jakarta Sans Regular)
Label font:     bodySmall (12sp, floated) / bodyLarge (placeholder position)
Cursor:         primary (#4F6FE8)
Selection:      primary at 25% opacity
Leading icon:   24dp, onSurfaceVariant
Trailing:       24dp (clear, visibility, dropdown arrow)
```

**States:**

| State | Fill | Indicator | Label Color |
|-------|------|-----------|------------|
| Inactive | `surfaceVariant` | None | `onSurfaceVariant` |
| Focused | `primaryContainer` (#EEF2FF) | 2dp bottom `primary` | `primary` |
| Filled (has value) | `surfaceVariant` | None | `onSurfaceVariant` (floated) |
| Error | `errorContainer` (#FEF2F2) | 2dp bottom `error` | `error` + error icon trailing |
| Disabled | `#F8FAFC` | None | `#CBD5E1` at 38% |
| Read-only | `#F8FAFC` | None | `onSurfaceVariant` |

#### Time Picker Field

```
Same as FilledTextField
Trailing icon:  access_time (24dp, primary)
Input mask:     HH:MM (24h only)
Tap behavior:   Open native time picker dialog
Error state:    Show if end_time <= start_time
```

#### Search Field

```
Border Radius:  radius-full (pill shape)
Leading icon:   search (24dp)
Trailing icon:  mic or close (contextual)
Hint text:      bodyLarge, onSurfaceVariant
```

#### Multi-line TextArea

```
Same as FilledTextField
Min lines:      3
Max lines:      8 (scrollable beyond)
Use case:       Long-term goals (onboarding), notes
```

---

### 3.3 Cards

#### Elevated Card (standard)

```
Background:     surface (#FFFFFF)
Border Radius:  16dp (radius-lg)
Elevation:      Level 2
Shadow:         0 2 8 rgba(0,0,0,0.08)
Internal Pad:   16dp all sides (12dp compact list cards)
Selected state: 2dp border primary, primaryContainer bg tint
Pressed:        Ripple from touch point, primary at 8% opacity
```

#### Hero Card (full-width feature card)

```
Background:     primary (#4F6FE8)
Text:           onPrimary (#FFFFFF)
Border Radius:  20dp (radius-xl)
Elevation:      Level 3
Shadow:         0 8 24 rgba(79,111,232,0.25)
Internal Pad:   24dp
Use case:       Today's plan hero, streak banner, greeting card
```

#### Filled Card (flat info panel)

```
Background:     surfaceVariant (#F1F5F9)
Border Radius:  16dp
Elevation:      Level 0
Internal Pad:   16dp
Use case:       AI suggestion banner, tip cards, subject summaries
```

#### Outlined Card (neutral)

```
Background:     surface (#FFFFFF)
Border:         1dp solid outline (#E2E8F0)
Border Radius:  16dp
Elevation:      Level 0
Internal Pad:   16dp
Use case:       Resource cards, settings rows, secondary info
```

#### Task Block Card (schedule items)

```
Background:     surface
Left border:    4dp solid (subject color or block_type color)
Border Radius:  12dp
Elevation:      Level 1
Padding:        12dp
Left col:       Time label (titleSmall, onSurfaceVariant)
Center col:     Subject chip + topic name (titleMedium, bold) + resource icon
Right col:      Status badge + action button
```

#### Break Block Card

```
Background:     surfaceVariant
Left border:    4dp solid breakBlock (#94A3B8)
Border Radius:  12dp
Opacity:        80% — visually softer than study blocks
Not interactive (no tap target)
```

---

### 3.4 Navigation Bar

```
Height:         80dp (64dp visible + 16dp safe area)
Background:     surface (#FFFFFF)
Top border:     1dp solid outline (#E2E8F0) — replaces elevation shadow
Elevation:      Level 0

Tab count:      5
Tab items:      Icon + Label

Active tab:
  Icon:         filled variant, primary (#4F6FE8), 24dp
  Label:        titleSmall 12sp 500, primary
  Indicator:    64 × 32dp pill, primaryContainer, border-radius full

Inactive tab:
  Icon:         outlined variant (fill: 0), onSurfaceVariant, 24dp
  Label:        titleSmall 12sp 500, onSurfaceVariant

Transition:     AnimatedSwitcher 200ms, Curves.easeInOut on icon fill change
```

**Tab Definitions:**

| Tab | Icon | Label | Screen |
|-----|------|-------|--------|
| 1 | `home` | Home | S03 Dashboard |
| 2 | `calendar_today` | Schedule | S05 Today's Schedule |
| 3 | `bar_chart` | Progress | S08 Progress Report |
| 4 | `folder` | Resources | S10 Resources |
| 5 | `settings` | Settings | S11 Settings |

---

### 3.5 Chips & Tags

#### Filter Chip

```
Height:         32dp
Border Radius:  radius-full
Font:           labelMedium (12sp/500)

Unselected:
  Fill:         surfaceVariant
  Border:       1dp outline
  Text:         onSurfaceVariant

Selected:
  Fill:         primaryContainer (#EEF2FF)
  Border:       1.5dp primary
  Text:         primary
  Icon:         check (20dp, primary) — prepended

Disabled:       38% opacity all elements
```

#### Subject Chip (in task cards)

```
Height:         24dp
Border Radius:  radius-full
Font:           labelSmall (11sp/500)
Color:          Per-subject assigned color (from a palette of 8 preset subject colors)
Max Width:      Subject name + 8dp padding each side
```

**Subject Color Palette** (8 options, auto-assigned on creation):

| # | Subject Color Token | Hex | Usage |
|---|--------------------|----|-------|
| 1 | `subject-indigo` | `#4F6FE8` | Default (matches primary) |
| 2 | `subject-teal` | `#0D9488` | |
| 3 | `subject-amber` | `#D97706` | |
| 4 | `subject-rose` | `#E11D48` | |
| 5 | `subject-violet` | `#7C3AED` | |
| 6 | `subject-emerald` | `#059669` | |
| 7 | `subject-orange` | `#EA580C` | |
| 8 | `subject-sky` | `#0284C7` | |

#### Status Badge

```
Height:         20dp
Border Radius:  radius-full
Font:           labelSmall (11sp/700)
Horizontal Pad: 8dp

Pending:   bg warningContainer, text warning
In Progress: bg primaryContainer, text primary
Done:      bg secondaryContainer, text secondary (darker variant)
Skipped:   bg surfaceVariant, text onSurfaceVariant
```

---

### 3.6 Progress Indicators

#### Linear Progress Bar (task completion)

```
Height:         8dp
Border Radius:  4dp (radius-full)
Track:          surfaceVariant (#F1F5F9)
Value:          primary (#4F6FE8)
Transition:     Animated, duration 400ms
Use case:       Daily completion bar, session X/5 counter
```

#### Circular Progress (session timer arc)

```
Stroke width:   4dp
Stroke cap:     StrokeCap.round
Background arc: outline (#E2E8F0) at 30% opacity
Foreground arc: primary (#4F6FE8)
Size:           Fills timer display zone (220 × 220dp)
Animation:      Continuous rotation + countdown shrink
```

#### Consistency Score Gauge

```
Style:          Semi-circle gauge (180°)
Track:          surfaceVariant
Fill:           Gradient: secondary (#34D399) → primary (#4F6FE8)
Center text:    Score % in displaySmall, then gamification label in bodyMedium
Size:           180dp diameter
```

#### Streak Badge

```
Icon:           local_fire_department (filled, 16dp)
Icon color:     #F97316 (orange — warm fire color)
Text:           "N-day streak" labelMedium 500
Pill:           warningContainer bg, 20dp height
```

---

### 3.7 Dialogs & Bottom Sheets

#### Alert Dialog

```
Background:     surface
Border Radius:  24dp (radius-2xl)
Max Width:      280dp (phone)
Padding:        24dp
Title:          titleLarge (22sp/600), onSurface
Body:           bodyMedium (14sp/400), onSurfaceVariant
Action row:     Right-aligned, TextButton + FilledButton
Scrim:          overlayScrim (#0F172A at 50%)
Entry:          Scale 0.8 → 1.0, Fade in, 200ms ease
```

#### Modal Bottom Sheet

```
Background:     surface (#FFFFFF)
Border Radius:  28dp top corners (radius-3xl)
Handle:         32 × 4dp, surfaceVariant, centered, 8dp from top
Drag zone:      48dp touch target around handle
Padding:        24dp sides, 16dp top (below handle), 32dp bottom
Entry:          Slide up, 280ms, Curves.easeOutCubic
Dismiss:        Drag down past 40% height, or tap scrim
Scrim:          overlayScrim
Max height:     85% of screen height (scrollable content inside)
```

#### Conflict Resolution Sheet (sync conflicts)

```
Extends Modal Bottom Sheet
Two panels side-by-side: "Your Version" | "Newer Version"
Each panel: Card with key field differences highlighted
CTA row: "Keep Mine" (OutlinedButton) | "Use Newer" (FilledButton)
```

---

### 3.8 Toast & Snackbar

#### Standard SnackBar

```
Background:     #1E293B (dark slate — visible in both light/dark modes)
Text:           #F1F5F9, bodyMedium, max 2 lines
Action:         primary (#818CF8 adjusted for dark bg), labelLarge, right side
Border Radius:  12dp
Elevation:      Level 3
Position:       Floating, 16dp margin all sides, above bottom nav
Duration:       4 seconds (with action) / 2 seconds (info only)
Entry:          Slide up from bottom, 250ms ease
Dismiss:        Slide down or swipe left/right
```

#### Success SnackBar variant

```
Left border:    4dp solid success (#10B981)
Icon:           check_circle (20dp, success), left of text
```

#### Warning SnackBar variant

```
Left border:    4dp solid warning (#F59E0B)
Icon:           warning (20dp, warning)
```

---

### 3.9 Empty States

Every screen that can have no data must define an empty state. No blank white screens.

#### Structure

```
Layout:         Centered, vertical stack
Icon:           64dp, filled variant, onSurfaceVariant at 60% opacity
Heading:        headlineSmall (24sp/600), onSurface, centered
Body:           bodyMedium (14sp), onSurfaceVariant, centered, max 200dp wide
CTA Button:     FilledButton (optional — only when there's a clear action)
Top margin:     40% of screen height above icon (visual center-ish)
```

#### Empty State Inventory

| Screen | Icon | Heading | Body | CTA |
|--------|------|---------|------|-----|
| S05 (no plan today) | `event_note` | "No plan for today" | "Generate a study plan or build one manually" | "Create Plan" |
| S07 (no revisions) | `auto_stories` | "No revisions scheduled" | "Complete a study session to auto-schedule revision tasks" | None |
| S08 (no sessions yet) | `bar_chart` | "Nothing to show yet" | "Complete your first study session to start tracking progress" | "Start Studying" |
| S10 (no resources) | `folder_open` | "No resources yet" | "Attach PDFs, links, or slides to your study tasks" | "Add Resource" |
| S12 (no data) | `insights` | "Unlock predictions" | "Complete 5 study sessions to activate performance prediction" | Progress bar X/5 |

---

### 3.10 Offline Wall Component

This is a purpose-built, reusable component used whenever a cloud-only feature is attempted offline.

```
Background:     surfaceVariant (#F1F5F9) — intentionally calm, not white, not alarming
Border Radius:  0dp (full screen or section, never a card inside a screen)

Layout (vertical, centered):
  ┌─────────────────────────────────────────┐
  │                                         │
  │                  [56dp]                 │  ← top breathing room
  │                                         │
  │         📡 Icon: wifi_off               │  ← 64dp, #94A3B8 (muted)
  │                  [24dp]                 │
  │     "You're currently offline"          │  ← headlineMedium, onSurface
  │                  [12dp]                 │
  │  "AI Plan Generation needs an internet  │  ← bodyMedium, onSurfaceVariant
  │   connection to build your personalized │     centered, max 280dp wide
  │   study plan."                          │
  │                  [40dp]                 │
  │  ┌─────────────────────────────────┐    │
  │  │ 🌐 Go Online — I'll wait       │    │  ← FilledButton, full width
  │  └─────────────────────────────────┘    │
  │                  [12dp]                 │
  │  ┌─────────────────────────────────┐    │
  │  │ 📝 Build Plan Manually         │    │  ← OutlinedButton, full width
  │  └─────────────────────────────────┘    │
  │                  [16dp]                 │
  │           ← Back                        │  ← TextButton, centered
  │                                         │
  │  ─────────────────────────────────────  │
  │  ⟳ Checking for connection...           │  ← bodySmall, onSurfaceVariant
  │    Animated scanning dots               │    visible only after tapping "Go Online"
  └─────────────────────────────────────────┘

Connectivity Poll:     Every 5 seconds after "Go Online" is tapped
On reconnect:          Auto-dismiss this wall → navigate to PlanDraftInitial
Animation (reconnect): Brief success flash (primary color pulse on wifi icon) → fade out
```

**Critical UX rules for this component:**
- Never use red, never use error styling. Offline is a condition, not a failure.
- Never show a loading spinner. This is a decision screen.
- The animated dots under "Checking for connection..." only appear after the user taps "Go Online — I'll wait". Not on initial render.

---

## 4. Screen Inventory

All screens use 16dp horizontal margins unless specified. Bottom navigation is visible on all Tab screens (S03, S05, S08, S10, S11). Sub-screens use a standard AppBar with back navigation.

---

### S01 — Onboarding

**Purpose:** Introduce the app's value proposition on first launch. Branch to chat or form based on connectivity.

**Mode A: Slides (always shown first)**

```
Layout:         Full-screen, no AppBar
Background:     background

Slide 1 — "Plan Smarter"
  Top 50%:      Illustration (planner/calendar graphic)
  Middle 25%:   Title (headlineLarge/700), 2-line subtitle (bodyLarge, onSurfaceVariant)
  Bottom 25%:   Dot indicator (3 dots) + "Skip" TextButton (top-right corner)

Slide 2 — "Study with Focus"
  Same structure, different illustration (timer/focus)

Slide 3 — "Improve Every Day"
  Same structure, different illustration (chart/analytics)
  Bottom:       "Get Started" FilledButton (full width, 52dp) replaces dot indicator as primary CTA

Slide interactions:
  Swipe L/R:    Change slides
  Dot tap:      Jump to slide
  Skip:         Jump to S02 (or Chat Mode if online)
  Get Started:  → S02 (offline) or Chat Mode (online)

Transitions:    Horizontal slide, 300ms Curves.easeInOut
```

**Mode B: Conversation Mode (online only)**

```
Layout:         Chat interface
AppBar:         Minimal — progress indicator "Getting to know you... (1/4)"
Background:     background

Chat area:
  AI bubbles:   Left-aligned, filled card (surface), 16dp max-width constraint
  User bubbles: Right-aligned, primaryContainer bg, 16dp constraint
  Typing indicator: 3 animated dots in AI bubble style

Input row:      FilledTextField + Send icon button (primary)

After 4-5 turns: Profile Preview Card appears above input
  Card:         Elevated card, all extracted fields listed
  Each field:   Editable (tap to correct inline)
  CTA:          "Looks Good — Start Planning →" FilledButton (full width)
  Below CTA:    "Fill out manually instead" TextButton

Transition to S02: Fade in profile confirm card, then slide to S03
```

---

### S02 — Create Profile

**Purpose:** Structured form fallback for offline onboarding, and for Settings-initiated profile edits.

```
AppBar:         "Set Up Your Profile" | Step indicator "1 of 2" (right)
Background:     background

Scrollable content (sections separated by 24dp):

  Section: Basic Info
    - Full Name (FilledTextField, required)
    - Email (FilledTextField, optional, trailing: "for backup")

  Section: Subjects  [label: "What are you studying?"]
    - Multi-select chip grid (from preset list + custom)
    - "+" chip at end: opens mini dialog "Add subject name"
    - Selected chips: primaryContainer fill, primary border

  Section: Study Goal  [label: "Daily study goal"]
    - Stepper row: "−" IconButton | [N hours] titleLarge | "+" IconButton
    - Range: 1–8 hours
    - Spaced Repetition toggle: Switch + "Auto-schedule revision" label

  Section: Study Window  [label: "When do you usually study?"]
    - Two time pickers side-by-side: "From" | "To"
    - Each is a FilledTextField with clock icon trailing

  Section: Learning Style  [label: "How do you learn best?"]
    - 4 selection cards (radio): Visual · Reading · Practice · Mixed
    - Each card: icon (32dp) + label (titleMedium) + 1-line description (bodySmall)
    - Selected: primaryContainer border (2dp), checkmark top-right

  Section: Exam Date (optional)
    - Date picker field: "Exam / deadline date (optional)"
    - If set: shows countdown chip "X days away"

Bottom CTA:     "Continue →" FilledButton, full width, sticky at bottom
                (floats above keyboard)
```

---

### S03 — Home Dashboard

**Purpose:** Central hub. Greet user, show today's status, provide quick actions.

**Tab:** Home (Tab 1)

```
AppBar:         App logo/wordmark (left) | Notification bell icon (right)
                No back arrow (root screen)

Zone 1 — Greeting Hero Card (Hero Card style, full width)
  Content:      "Good morning, [Name]! 🌅" (headlineMedium/600, white)
                Date line (bodyMedium, white at 80%)
                Streak badge: "🔥 5-day streak" (warningContainer pill)
  Height:       ~120dp
  Padding:      24dp

Zone 2 — Quick Stats Row (3 equal-width Elevated Cards, 8dp gap)
  Card 1:       Today's Study Hours
                Value: "2h 15m" (headlineMedium/600, primary)
                Label: "studied today" (bodySmall, onSurfaceVariant)
                Icon: schedule (24dp, primary)
  Card 2:       Consistency Score
                Value: "82%" (headlineMedium/600, success)
                Label: "consistency" (bodySmall)
                Icon: track_changes (24dp, success)
  Card 3:       Tasks Done
                Value: "3 / 7" (headlineMedium/600, primary)
                Label: "completed" (bodySmall)
                Icon: check_circle (24dp, secondary)

Zone 3 — Today's Schedule Preview
  Header:       "Today's Schedule" (titleLarge) | "View All →" (TextButton, primary)
  Content:      Up to 3 Task Block Cards (compact 12dp padding)
  Empty state:  "No plan for today" + "Create Plan" TextButton

Zone 4 — Quick Actions Grid (2×2, 8dp gap)
  Each cell:    Outlined Card, icon (32dp, primary) + label (titleSmall)
  Actions:      ✨ Generate Plan | 📅 Revision Calendar
                📊 View Progress | 📁 Resources

Zone 5 — AI Suggestion Banner (Filled Card, if weak subject detected)
  Left:         lightbulb icon (24dp, primary)
  Body:         "DBMS is your weakest subject — schedule a revision today"
                (bodyMedium, onSurface)
  Right CTA:    "Add Revision" (TextButton, primary)
  Dismissible:  Swipe to dismiss (X icon top-right)

Bottom:         Navigation Bar
```

---

### S04 — AI Plan (Chat-Based Planning Interface)

**Purpose:** Enable users to generate a personalized study plan through a conversational AI interface, then review, edit, and export it into executable tasks.

---

#### Interaction Flow

```
Chat → AI Draft → Review/Edit → Export to Tasks
```

---

#### AppBar

```
Title:          "AI Plan"
Subtitle:       "Plan smarter with AI"
Actions:        Overflow menu (Clear chat, Help)
```

---

#### Chat Interface (Input Layer)

```
AI Prompt (Initial Message):
  "Tell me your available time and what you want to study."

User Input:
  - Free text input (chat style)
  - Supports natural language
```

---

#### AI Response — Structured Draft Output

AI returns a **Plan Draft Card** instead of plain text.

```
Plan Draft Card:
  Title:          "Today's Study Plan"
  Block list:
    Each block:   Time range · Subject · Task title
  Optional:       Warnings / suggestions below block list
```

---

#### Draft Review & Editing

Displayed below the AI response as editable task blocks.

```
Each Block Includes:
  - Time
  - Subject
  - Type
  - Priority

User Actions:
  - Edit block
  - Add new block
  - Delete block
  - Reorder blocks (drag & drop)
```

---

#### Primary Action

```
Button:         "Export to Tasks"
Behavior:
  - Triggers CommitPlanEvent
  - Writes plan to SQLite (transaction)
  - Transitions to Task Screen
```

#### Secondary Actions

```
- Regenerate Plan
- Edit Input
```

---

#### States

| State | Description |
|-------|-------------|
| Initial | Empty chat + AI prompt |
| Loading | AI typing indicator |
| Draft | Editable blocks visible below response |
| Error | Retry option shown |
| Offline | Show OfflinePlanningState (see 3.10) |

---

#### Manual Mode (No AI)

```
Accessible via:
  - Offline wall
  - Navigation from Task Screen

Behavior:
  - Form-based block creation
  - Same structure as AI output
  - Saves via same commit logic
```

---

### S05 — Task Screen (Execution Dashboard)

**Purpose:** Central workspace where users can view, manage, and execute study tasks.

**Tab:** Schedule (Tab 2)

---

#### AppBar

```
Title:          "Today's Tasks"
Subtitle:       Current date + completion status
```

---

#### Task List

Scrollable list of task cards.

```
Each Task Card Includes:
  - Time range
  - Subject chip
  - Task title
  - Status badge
  - Action button (Start / Complete)
```

---

#### Floating Action Button (FAB)

```
Icon:           + (add)
Behavior:       On tap → Navigate to Manual Plan (S04 Manual Mode)
```

---

#### Task Sources

| Source | Flow |
|--------|------|
| AI Plan | AI Plan → Export → SQLite → Task Screen |
| Manual Plan | Manual Plan → Save → SQLite → Task Screen |

---

#### States

| State | Description |
|-------|-------------|
| Tasks Available | Show scrollable task list |
| Empty State | Show message + "Create Plan" button |

---

#### User Actions

```
- Start task
- Mark task complete
- Add new task (via FAB → Manual Plan)
- (Future) Edit task
```

---

### S06 — Active Study Session

**Purpose:** Full-screen distraction-free focus mode. Launched from S05.

```
Background:     background (deep dark in dark mode for immersion)
AppBar:         MINIMAL — subject label (titleMedium, center) | Minimize icon (left)
                No other elements.

Zone 1 — Task Info
  Subject chip (primary color)
  Topic name:   headlineMedium/600, onBackground, centered
  Planned time: "45 min session" (bodyMedium, onSurfaceVariant, centered)

Zone 2 — Timer Display (center of screen)
  Outer circle:  220dp, arc progress (see 3.6)
  Center:        MM:SS countdown (displayMedium/DM Mono, primary)
  Below center:  "Elapsed: 12:34" (bodySmall, DM Mono, onSurfaceVariant)
  Below elapsed: "Focus Score: Building..." (bodySmall, onSurfaceVariant)
                 Becomes numeric after 2 minutes of uninterrupted study

Zone 3 — Timer Controls (horizontal row, center-aligned)
  Pause:        IconButton Filled (pause icon) — 56dp
  End Session:  IconButton Filled (stop icon) — 56dp — triggers confirm dialog
  +5 min:       IconButton Standard (add icon) — 40dp

Zone 4 — Resources Panel (collapsible, bottom)
  Collapsed:    "Resources (3)" chip — tap to expand
  Expanded:     Bottom sheet slides up (50% height)
                Lists attached resources: icon + filename + subject tag
                Tap resource: opens in-app viewer or browser

Session Complete State (replaces timer display):
  Animation:    Confetti (lottie) — 2 seconds
  Icon:         check_circle (64dp, success, scale animation in)
  Heading:      "Session Complete!" (headlineLarge, success)
  Body:         "Focus score: 87%" (bodyLarge, primary)
  CTA row:      "Mark Done ✓" FilledButton | "Add 10 min" OutlinedButton
  Below:        "Skip for Now" TextButton (sets status to skipped)
```

---

### S07 — Revision Calendar

**Purpose:** View and manage auto-scheduled revision tasks across the month.

```
AppBar:         "Revision Calendar" | ← → Month navigation arrows

Zone 1 — Month Calendar Grid
  Layout:       Standard 7-column calendar, 6 rows max
  Date cell:    Date number (labelLarge) + colored dot indicator(s) below
  Today:        Circled with primary color
  Dot colors:   revision=Blue (#3B82F6) | practice=Orange (#F97316) 
                test=Red (#EF4444) | final=Purple (#8B5CF6)

Zone 2 — Legend Strip
  4 color chips: Revision · Practice · Test · Final Revision
  Layout:       Horizontal scroll row, below calendar

Zone 3 — Selected Day Detail Panel
  Appears:      When user taps a date (animated expand, 200ms)
  Header:       Selected date (titleLarge)
  Content:      List of revision tasks for that day
                Each item: type badge + topic name + subject chip + "Start" button
  Empty date:   "No tasks for this day" (bodySmall, onSurfaceVariant)

Zone 4 — Upcoming Revisions List
  Header:       "Next 7 Days" (titleLarge)
  Content:      Scrollable list of upcoming revision cards
                Sorted by date ascending
                "Mark Done" action on each card
```

---

### S08 — Progress Report

**Purpose:** Weekly/monthly analytics overview.

**Tab:** Progress (Tab 3)

```
AppBar:         "Progress"
Top-right:      Segmented control "Week / Month"

Zone 1 — Consistency Score Card (Hero Card, full width)
  Left:         Semi-circle gauge (see 3.6), 160dp wide
  Right:        Score % (displaySmall, onPrimary)
                Level label (titleMedium, onPrimary, 80%)
                Streak badge (fire icon + N days)

Zone 2 — Study Hours Bar Chart (Elevated Card)
  Chart:        7 bars (weekly) or 30 bars (monthly)
                X-axis: day labels (labelSmall)
                Y-axis: hours (labelSmall)
                Today's bar: primary fill; others: primaryContainer
                Goal line: dashed, warning color
  Header:       "Study Hours" (titleMedium) | average label (bodySmall)

Zone 3 — Task Completion Doughnut (Elevated Card)
  Chart:        Doughnut, 3 segments
                Completed: secondary | Pending: primaryContainer | Skipped: surfaceVariant
  Center:       Completion % (headlineMedium/700)
  Legend:       Below chart, horizontal chips

Zone 4 — Subject-wise Time (Elevated Card)
  Layout:       Horizontal bar per subject
                Subject chip (left) | bar fill | hours label (right)
  Sorted:       Most hours descending

Zone 5 — Trends Line Chart (Elevated Card)
  Chart:        Consistency score over last 4 weeks
  Trend label:  Arrow icon + "Improved by 12% vs last week" (bodySmall, success)
  Or:           Arrow down + "Dropped 5% — let's get back on track" (bodySmall, warning)

Zone 6 — Export Button
  "Download Report" OutlinedButton, full width, bottom
```

---

### S09 — Subject Analytics

**Purpose:** Deep-dive per-subject ML-driven analysis.

```
AppBar:         Subject name (headlineMedium) — dynamic

Zone 1 — Performance Badge
  Large pill:   STRONG (success) / MODERATE (warning) / WEAK (error)
                Based on K-Means cluster output
  Subtext:      "Based on your study history" (bodySmall, onSurfaceVariant)

Zone 2 — Key Metrics Row (3 equal cards)
  Card 1: Total Study Hours (14 days)
  Card 2: Avg Practice Score (0–100)
  Card 3: Revision Count

Zone 3 — Score History Chart (Elevated Card)
  Line chart:   Practice scores over last 5–10 sessions
  X-axis:       Dates
  Y-axis:       Score %
  Trend line:   Visible
  Data points:  Tappable (shows tooltip with session date + score)

Zone 4 — Revision Log (list)
  Each item:    Date | Type badge | Score (if test/practice) | Pass/Needs Work chip
  Color-coded:  Pass = success | Needs Work = warning

Zone 5 — AI Recommendation Card (Filled Card)
  Icon:         lightbulb (24dp, primary)
  Body:         "You study [Subject] for only 2h/week. Consider increasing to 4h for better results."
  CTA:          "Schedule More Sessions" TextButton
```

---

### S10 — Resources

**Purpose:** Central library for all attached study materials.

**Tab:** Resources (Tab 4)

```
AppBar:         "Resources" | Search icon (expands inline on tap)

Zone 1 — Filter Chips Row
  Horizontal scroll: All · PDF · Video · PPT · Practice Sets
  Style:        Filter Chips (see 3.5)
  Active:       primaryContainer fill

Zone 2 — Resource Grid (2 columns, 8dp gap)
  Card:         Outlined Card (12dp radius, compact)
                Top-center: File type icon (32dp, subject color)
                Title:      titleSmall, bold, 2-line max, centered
                Subject:    Subject Chip
                Date added: labelSmall, onSurfaceVariant
  Tap:          Open resource (PDF viewer in-app / browser for video)
  Long-press:   Context menu: Delete | Move to Subject | Share

  Empty state:  [See 3.9 — S10 empty state]

FAB (standard):  "+" icon — opens Add Resource bottom sheet
  Sheet options: Upload PDF | Paste Link | Import from Files
```

---

### S11 — Settings

**Purpose:** App preferences, profile management, notifications, AI toggles.

**Tab:** Settings (Tab 5)

```
AppBar:         "Settings" (no back arrow — root screen)

Section 1 — Profile
  Layout:       CircleAvatar (48dp) + Name (titleMedium) + "Edit" TextButton (right)
  Tap Edit:     Opens S02 in edit mode

Section 2 — Study Preferences  (divider above)
  Row: Daily Study Goal    Stepper (1–8 hours), right side
  Row: Session Length      Dropdown (30 / 45 / 60 min)
  Row: Break Duration      Dropdown (5 / 10 / 15 min)
  Row: Study Window        Two time fields (From | To)

Section 3 — Notifications  (divider above)
  Toggle: Daily Plan Reminder    + time picker (indented, shown when on)
  Toggle: Revision Alerts
  Toggle: Weekly Report Summary

Section 4 — AI Settings  (divider above)
  Toggle: AI Plan Generation     (requires online — shows wifi icon when off)
  Toggle: Performance Prediction
  Toggle: Weak Subject Detection
  Info:   "AI runs locally for analysis. Plan generation needs internet."
          (bodySmall, onSurfaceVariant, italic)

Section 5 — Data  (divider above)
  Row: Export Study Data (CSV)       chevron_right icon
  Row: Clear All Data                Red text (error color) — triggers confirm dialog
  Row: App Version                   "v2.0.1 (build 42)" — read-only, trailing

Each settings row: 56dp height | 16dp side padding | titleMedium label
                   Tap ripple on interactive rows only
```

---

### S12 — Performance Prediction

**Purpose:** ML-powered exam score forecast with what-if simulation.

```
AppBar:         "Exam Prediction"

Zone 1 — Headline Prediction Card (Hero Card, full width)
  Background:   Gradient — primary (#4F6FE8) → #312E81
  Center:       "Overall Predicted Score" (titleMedium, white 80%)
                Score: "78%" (displayLarge/DM Mono, white)
                "Based on your last 30 days" (bodySmall, white 70%)

Empty state:    [See 3.9 — S12 empty state] — shown if < 5 sessions

Zone 2 — Subject Breakdown Table (Elevated Card)
  Columns:      Subject | Hours | Revisions | Practice | Predicted Score
  Score color:  > 70% = success | 50–70% = warning | < 50% = error
  Sorted:       Predicted score ascending (weakest first)

Zone 3 — Key Factors Card (Elevated Card)
  Header:       "Your Input Factors" (titleMedium)
  4 rows:       Study Hours: 18h | Revision Count: 6
                Task Completion: 82% | Avg Practice: 71%
  Each row:     Icon (20dp) + label (bodyMedium) + value (titleSmall/600, primary)
  Mini bar:     Shows relative weight of each factor

Zone 4 — What-If Slider (Elevated Card)
  Header:       "What if you studied more?" (titleMedium)
  Slider:       "Add [N] more revision hours" — Slider (0–10h, 0.5 step)
  Live update:  Prediction % updates as slider moves (debounced 300ms)
  Delta label:  "+4%" (success) or "−2%" (warning) badge next to score

Zone 5 — Recommendations List (Filled Card)
  Header:       "To reach your goal" (titleMedium)
  Items:        3–5 bullet points (check_circle icon + bodyMedium text)

Bottom CTA:     "Create Improvement Plan →" FilledButton, full width
                → Opens S04 pre-filled with suggested sessions
```

---

## 5. User Flows & Prototyping

### 5.1 App Launch Flow

```
App opens
   │
   ├── users record with onboarding_complete=1 exists?
   │      YES → check pending revisions
   │              > 0 → S03 Dashboard (RevisionAlert banner at top)
   │              = 0 → S03 Dashboard (normal)
   │
   └── NO user record
          │
          ├── Online? → S01 Onboarding Slides → Conversation Mode → S02 Confirm → S03
          └── Offline? → S01 Onboarding Slides → S02 Structured Form → S03

Prototype transition: S01 → S03: Full-screen fade (400ms)
                      S02 → S03: Slide up (350ms, Curves.easeOutCubic)
```

### 5.2 Onboarding Flow

```
S01 (Slide 1) ──swipe──► S01 (Slide 2) ──swipe──► S01 (Slide 3)
                                                          │
                                              "Get Started" tap
                                                          │
                            ┌─────────────────────────────┴────────────────────┐
                         Online                                             Offline
                            │                                                   │
                  Conversation Mode                                   S02 Structured Form
                     │                                                          │
              AI chat turns (S01-chat)                              Fill all fields
                     │                                                          │
              Profile Preview Card                                  "Continue →"
                     │                                                          │
              "Looks Good →" tap                                                │
                     │                                                          │
                  S02 Confirm Card                                              │
                     └──────────────────────────────────────────────────────────┘
                                                          │
                                               POST /onboarding/commit
                                                          │
                                                    S03 Dashboard
                                          (fade in with "Welcome!" toast)

Prototype notes:
  - Each chat turn: AI bubble slides in from left (150ms), user bubble from right
  - Profile card: slides up from bottom over chat (280ms)
  - Confirm → S03: celebratory scale-in of greeting hero card
```

### 5.3 AI Plan Generation Flow (Online)

```
S03 Dashboard
   │
   "✨ Generate Plan" CTA tap (or FAB)
   │
   Connectivity check (instant)
   │
   ├── ONLINE → S04 (PlanDraftInitial)
   │              │
   │           "✨ Generate with AI" tap
   │              │
   │           S04 (PlanDraftLoading)
   │           "Building your context..." → "Asking the AI..."
   │              │
   │           LLM responds (avg 3–8 seconds)
   │              │
   │     ┌────────┴──────────────┐
   │   Success                 Failure
   │     │                        │
   │  S04 (PlanDraft)          Error card + "Try Again" + "Build Manually"
   │  User reviews draft
   │     │
   │   (Optional) Tap block → PlanDraftEditing → edit bottom sheet → "Save"
   │     │
   │   "Export to Device" FAB tap
   │     │
   │   Validation check (guards 9–12)
   │     │
   │   PlanCommitInProgress (overlay)
   │     │
   │   Success → PlanCommitted bottom sheet
   │              "View Schedule →" → S05
   │
   └── OFFLINE → S04 (OfflinePlanningState)
                  │
                  ├── "Go Online — I'll wait" → poll 5s → on connect: PlanDraftInitial
                  └── "Build Plan Manually" → PlanDraftInitial (manual mode)

Prototype transitions:
  S03 → S04: Slide up (root → sub-screen), 280ms
  Loading → Draft: Fade out loading, fade in cards with stagger (each card +50ms delay)
  Block tap → edit sheet: Slide up, 250ms
  Draft → commit overlay: Fade in, 150ms
  Commit → success sheet: Slide up, 280ms, confetti optional
```

### 5.4 Manual Plan Creation Flow (Offline)

```
S04 (PlanDraftInitial) or Offline Wall
   │
   "📝 Build Plan Manually" tap
   │
   S04 manual mode (PlanDraftInitial, no loading state)
   Shows:  Date picker + empty block list + "Add Study Block" button
   │
   "Add Study Block" → Edit bottom sheet (same as AI draft editing)
   Fill:   Title / Subject / Type / Start & End time / Priority
   "Save" → Block card appears in list
   │
   Repeat for each block
   │
   "Save Plan" button (same as "Export to Device") → CommitService
   │
   PlanCommitted → "View Schedule →" → S05

Prototype transitions: Identical to AI flow from CommitPlanEvent onward
```

### 5.5 Study Session Flow

```
S05 (Today's Schedule)
   │
   Tap "▶ Start" on a task card
   │
   S06 (Active Session) — slide up full-screen, 300ms
   │
   ┌─────────────────────────────────────────────────┐
   │            TIMER RUNNING                         │
   │  Pause tap → timer pauses (pause icon → play)    │
   │  Play tap  → resumes                             │
   │  +5 min    → extends planned duration            │
   │  End tap   → confirm dialog: "End session now?"  │
   └─────────────────────────────────────────────────┘
   │
   Timer completes (or user ends)
   │
   Session Complete state (confetti → check animation)
   │
   "Mark Done ✓" → writes STUDY_SESSIONS + 4 REVISION_TASKS
                   → slide down back to S05
                   → task card shows ✓ (animated)
   "Add 10 min"  → extends, timer resumes
   "Skip for Now"→ status = skipped, slide down to S05

Prototype transitions:
  S05 → S06: Slide up full-screen (hero transition from task card to session screen)
  Session complete animation: confetti overlay (1.5s lottie) → scale in check icon
  S06 → S05: Slide down, 280ms
```

### 5.6 Revision Flow

```
S07 (Revision Calendar)
   │
   Tap date with dots → Day detail panel expands (animated height, 200ms)
   │
   Tap "Start" on revision task → S06 (Active Session in revision mode)
   │
   Session complete → "Mark Done" → status updated → dot removed from calendar
   │
   OR: From task card "Mark Done" directly (without timer):
   S07 task → "Mark Done" → Log Score bottom sheet (optional 0–100 input)
   → PERFORMANCE_DATA written → chip turns to success color
```

### 5.7 Progress & Analytics Flow

```
S08 (Progress Report)
   │
   Tap subject in subject-wise chart → S09 (Subject Analytics)
   │
   S09: "Schedule More Sessions" → S04 (pre-filled with subject)
   │
   OR: S08 → FAB or link → S12 (Performance Prediction)
   │
   S12: "Create Improvement Plan →" → S04 (pre-filled with AI suggestions)

Prototype transitions:
  S08 → S09: Slide left (drilling deeper), 280ms
  S09 → S04: Slide up (action trigger), 280ms
  S12 → S04: Slide up, 280ms
```

---

## 6. Motion & Interaction Design

### 6.1 Duration Guidelines

| Type | Duration | Curve | When to Use |
|------|----------|-------|-------------|
| Micro | 100ms | `easeInOut` | Icon state changes, color swaps |
| Quick | 150ms | `easeOut` | Toast appearance, chip selection |
| Standard | 200ms | `easeInOut` | Most UI transitions, dialogs fade |
| Expressive | 280ms | `easeOutCubic` | Screen transitions, sheet slides |
| Deliberate | 350–400ms | `easeInOut` | Full-screen transitions, celebration animations |
| Never exceed | 500ms | — | Anything longer feels broken |

### 6.2 Transition Patterns

| Pattern | How to prototype in Figma | When |
|---------|--------------------------|------|
| **Slide Up** | Frame → Frame, vertical offset | Sub-screen push, bottom sheet open |
| **Slide Down** | Reverse of above | Sub-screen back, bottom sheet close |
| **Slide Left/Right** | Horizontal offset | Peer screens (S08 → S09) |
| **Fade** | Opacity 0 → 1 | State changes within same screen |
| **Scale + Fade** | Scale 0.8→1.0 + Opacity | Dialogs, success states, cards appearing |
| **Stagger** | Sequential delay (+50ms per item) | List items loading after AI response |
| **Hero** | Shared element transition | Task card → Session screen |

### 6.3 Specific Interaction Specs

| Interaction | Spec |
|-------------|------|
| Button press | Scale 0.97, ripple from touch point, primary at 12% overlay |
| Card press | Ripple from touch point, primary at 8% overlay, no scale |
| Swipe to dismiss | Threshold 40% width, snap back if not reached, fade-delete if released |
| Pull to refresh | Standard Material pull indicator, primary color |
| Drag to reorder | Lift shadow (Level 4), haptic feedback, placeholder outline left in place |
| Tab switch | Icon fill animates (200ms), label color transitions |
| Timer tick | Every second: subtle pulse on elapsed text (scale 1.0 → 1.02 → 1.0, 200ms) |
| Focus score update | Number ticks up with CountUp animation (ease), green pulse on milestone |
| Connectivity restored | Primary color pulse on wifi icon → fade to normal → wall dismisses |

---

## 7. Accessibility Checklist

These are non-negotiable requirements, not nice-to-haves.

| Requirement | Specification |
|-------------|--------------|
| **Contrast — body text** | Minimum 4.5:1 (WCAG AA). All body text against backgrounds. |
| **Contrast — large text** | Minimum 3:1 (WCAG AA). Headings ≥ 18sp or ≥ 14sp bold. |
| **Touch targets** | All interactive elements minimum 48 × 48dp. Smaller visual elements use invisible padding. |
| **Text scaling** | Test at 1.0× and 1.5× text scale. No truncation, no overflow at 1.5×. Avoid fixed-height text containers. |
| **Focus order** | Logical tab/focus order follows visual reading order. |
| **Screen reader labels** | All icon buttons have `semanticLabel` (Tooltip or Semantics widget). Icon-only buttons are unusable without. |
| **Error announcements** | Validation errors are announced to screen readers immediately on occurrence. |
| **Color independence** | Never use color as the only signal. Status badges have text, not just color. Charts have patterns or labels. |
| **Motion sensitivity** | All animations respect `MediaQuery.disableAnimations`. Provide static fallbacks. |
| **Dark mode** | Full dark mode support. All tokens have dark equivalents (see Part 8). |

---

## 8. Dark Mode Specifications

Dark mode is a **core mode**, not an optional theme. Students often study late at night. The dark palette is designed for comfortable extended use.

### Full Token Reference — Dark Mode

| Token | Dark Value | Light Value |
|-------|-----------|------------|
| `primary` | `#818CF8` | `#4F6FE8` |
| `primaryContainer` | `#312E81` | `#EEF2FF` |
| `secondary` | `#6EE7B7` | `#34D399` |
| `secondaryContainer` | `#064E3B` | `#D1FAE5` |
| `background` | `#0F172A` | `#F8FAFC` |
| `surface` | `#1E293B` | `#FFFFFF` |
| `surfaceVariant` | `#334155` | `#F1F5F9` |
| `outline` | `#475569` | `#E2E8F0` |
| `onBackground` | `#F1F5F9` | `#0F172A` |
| `onSurface` | `#E2E8F0` | `#1E293B` |
| `onSurfaceVariant` | `#94A3B8` | `#64748B` |
| `error` | `#FCA5A5` | `#EF4444` |
| `errorContainer` | `#7F1D1D` | `#FEF2F2` |
| `success` | `#6EE7B7` | `#10B981` |
| `warning` | `#FCD34D` | `#F59E0B` |

### Dark Mode Specific Adjustments

- **Hero cards:** Use darker gradient in dark mode — `#312E81` → `#1E1B4B` instead of indigo solid
- **Shadows:** Remove drop shadows in dark mode. Use border (`1dp outline`) instead of elevation to separate layers.
- **Charts:** Chart lines remain primary/secondary colors — they're already accessible on dark backgrounds.
- **Offline wall:** Background changes to `#1E293B` (surface dark) — still calm, not alarmingly dark.
- **Timer screen:** Background darkens to `#0F172A` (deepest dark) — creates an immersive tunnel-vision focus environment.

### Toggle Behavior

```
Settings → dark mode switch → ValueNotifier<ThemeMode> updates
All surfaces animate: cross-fade 200ms (not instant flash)
Persisted in shared_preferences across sessions
System default: follow device theme (default state on first launch)
```

---

*AI Study Planner — Design System & UI Specification v2.0*  
*For prototype questions, refer to the SKILL.md for data logic and component behavior context.*  
*Last updated: v2.0 — Cloud LLM Architecture*
