# DSSlideToConfirm → slide-to-pay: design

**Date:** 2026-09-08
**Status:** approved, ready to implement
**Branch:** `feat/slide-to-pay`, cut from `chore/motion-review-harness`

## Problem

`DSSlideToConfirm` today is a confirmation gate for destructive actions: drag
past 75 %, the track fills, the label dissolves letter by letter, a check
appears and the control rests. It works, and the drag itself already feels
right.

What it cannot do is carry a **payment**. A payment has a second half the
current component has no vocabulary for: the money moves somewhere, that takes
real time, and it can be **refused**. The control has no way to say "working",
no way to say "declined", and no way to hand off to whatever comes next.

This change gives it that vocabulary, and takes the opportunity to make the
gesture itself worth watching — the component is meant to be shown in a video,
so the moment of success has to land.

## Non-goals

- No payment-specific API: no amount, no currency, no card. The component is a
  *gesture*, not a checkout. The caller writes the money into the label.
- No `DSSlideToPay` sibling component. See "Decisions", D1.
- No public particle API. See D5.
- No failure *messaging* inside the control (no "card declined" text). The
  control reports the failure by staying neutral and re-opening; the parent
  owns the words.

## Decisions

Each of these was a fork with a real alternative; the alternative is recorded
so a later reader does not re-litigate it blind.

### D1 — One component, configurable finish

`DSSlideToConfirm` gains a `finish:` parameter rather than growing a
`DSSlideToPay` sibling.

*Why:* the drag engine, the letter dissolve, the haptics and the particle field
are identical for both uses; only the last 800 ms differ. A sibling would
duplicate ~300 lines or force an awkward shared-core extraction, for a
difference that is genuinely just a choreography.

*Rejected:* a separate `DSSlideToPay`; and replacing the current choreography
outright (destructive actions lose their persistent "Confirmed" state).

### D2 — `onConfirm` becomes `async throws`

The closure carries both the latency and the outcome.

*Why:* it keeps the public API at **one closure** — no extra `Binding`, no
state enum for the caller to drive — while making the two things a payment
needs expressible. `throws` over `-> Bool` because it preserves the error, so
the parent can surface *why* the charge failed.

*Compatibility:* `() -> Void` is a subtype of `() async throws -> Void`, so
every existing call site (`DSSlideToConfirm("Slide to delete") { delete() }`)
compiles unchanged.

### D3 — Pure 1:1 tracking

No rubber-banding, no magnetic snap past the threshold. The knob is the finger,
exactly.

*Why:* physics tricks under a payment gesture read as the control second-
guessing you. All the pleasure is carried by haptics, light and particles,
which do not lie about where your finger is.

*Rejected:* a detent curve (weight building to 75 %, releasing into a magnet);
and magnet-only.

### D4 — Particles surround the knob and carry the result

Tiny particles are born and die in a short radius **around the knob** — around
the finger — for as long as the drag lasts. Their tint is the status channel:
neutral while dragging, sweeping to green on success, **staying neutral** on
failure.

*Why:* it makes the outcome a property of the thing the user is already looking
at (their own finger) instead of a separate badge. And because the `Canvas`
re-reads one tint value per frame, the whole living cloud turns at once — that
single frame is the payoff.

*Rejected:* a trail left behind the knob; an ambient halo around the whole
track.

### D5 — `DSParticleField` is internal, not public

It lives in its own file under `Animation/`, but nothing outside the module can
use it yet.

*Why:* `CLAUDE.md` requires a component to prove itself in a real app before
entering the design system, and a particle emitter is a large public surface
for a single consumer. It gets promoted when a second consumer appears.

### D6 — The vanished control keeps its layout slot

After `.morphAndVanish` completes, the view is invisible but still 56 pt tall.

*Why:* a layout jump on the exact frame of the payoff would ruin the moment.
The parent cross-fades its own success state in place; a parent that wants the
collapse wraps the control in an `if`.

*Reset:* no new API. The parent re-mounts with `.id(attempt)`.

## Architecture

### State machine

`Phase` is private to the component and drives everything else.

```
idle ──touch──▶ dragging ──release <75%──▶ idle          (.light, snap back)
                    │
                    └──release ≥75%──▶ committing        (fill edge-to-edge, 0.10 s)
                                          │
                    .settle ◀─────────────┴─────▶ .morphAndVanish
                       │                              │
                       │                         collapsing       (pill → circle, 0.25 s)
                       └──────────┬───────────────────┘
                                  ▼
                             processing   spinner · await onConfirm() · min dwell 0.5 s
                                  │
                    ┌─────────────┴─────────────┐
                 ok ▼                    throws ▼
             succeeded                   failing
     particles → GREEN               particles stay NEUTRAL
     check pop · .success            .error · knob returns to start
             │                       (.morphAndVanish also re-opens
     .settle ┤ rests                  the circle back into the pill)
             └ .morphAndVanish ▼              │
                          vanishing           ▼
                    exhale + fade           idle  (retryable)
                           ▼
                          gone
```

The spinner is drawn wherever the phase left it: inside the collapsed circle
for `.morphAndVanish`, inside the knob at the trailing edge for `.settle`.

The **minimum dwell** on `processing` exists so a fast (or synchronous) closure
does not make the spinner flash for one frame; the phase lasts
`max(closureDuration, 0.5 s)`.

### Public API

```swift
public enum DSSlideFinish: Sendable {
    /// Stays filled, showing the check and `confirmedLabel`. Default; today's behaviour.
    case settle
    /// Pill collapses to a circle, resolves, then fades out leaving its slot.
    case morphAndVanish
}

public init(
    _ label: String,
    icon: String = "chevron.right",
    confirmedLabel: String = "Confirmed",
    accent: Color? = nil,
    finish: DSSlideFinish = .settle,
    onConfirm: @escaping () async throws -> Void
)
```

`finish:` is placed **after** `accent:` so no existing parameter changes label
or position (`CLAUDE.md` rule 3).

### The morph

At 100 % the trail fills the track edge to edge and the knob — filled with the
same accent gradient — sits flush against the trailing edge. In that frame the
whole control is **one solid gradient pill**: the knob is indistinguishable
from the fill, which is why the collapse can travel to the **centre** without
the knob appearing to walk backwards.

Because the track already uses `DSRadius.chip` (a capsule), **a capsule whose
width equals its height is a circle**. The morph is therefore just animating
`width: trackWidth → 56`. No `matchedGeometryEffect`, no shape interpolation,
no second view tree.

```
[●──────────────────────]   dragging
[■■■■■■■■■■■■■■■■■■■■■●]   committing   — one gradient
[      ■■■■■●■■■■      ]   collapsing
[          (◌)         ]   processing   — spinner
[          (✓)         ]   succeeded
[           ·          ]   vanishing
```

### `DSParticleField`

`Sources/DesignSystem/Animation/DSParticleField.swift`, internal.
`TimelineView(.animation)` driving a `Canvas`.

- Ring buffer of 48 particles. Each carries `birth`, `origin`, `velocity`,
  `size`, `seed`.
- Position is **analytic**: `p = p₀ + v·age` with a soft drag term. The `Canvas`
  closure only evaluates — it never mutates state during a draw.
- **Emission around the knob:** each spawn seeds at a random angle,
  `knobRadius ± 4 pt` from the knob centre, with a small outward drift.
  Size 1–2.5 pt, lifetime 0.5–0.9 s, peak opacity ≈ 0.5.
- **Rate = baseline + k · speed**, applied in an `onChange(of: timeline.date)`
  (state mutation outside the `Canvas`). The baseline keeps the cloud alive
  when the finger holds still; the speed term brightens it on a fast drag.
- Render: `blendMode = .plusLighter` with `addFilter(.blur(radius: 1.5))`.
- **Tint is the status channel:** `palette.textTertiary` → `palette.success`.
- **Exhale:** entering `vanishing` emits ~18 particles with radial velocity
  from the circle centre. Same engine, different call.
- Reduce Motion or Reduce Transparency → the field is not drawn at all.

`TimelineView`, `Canvas` and `.plusLighter` all exist on iOS 18 and macOS 15,
so the file needs no `#if os(iOS)`.

### Haptics

| Moment | Style |
|---|---|
| Drag travel | `.soft`, `intensity` ramped 0.2 → 0.6, ~8 ticks across the track |
| Crossing 75 % | `.rigid` *(exists)* |
| Success | `.success`, same frame as the green sweep |
| Failure | `.error` |
| Snap back | `.light` *(exists)* |

Tick count and the intensity ramp are tuned on device; the simulator has no
Taptic Engine.

## Implementation order

1. `DSParticleField` alone, with its own `#Preview` — the field is the only
   genuinely new machinery, so it gets proved before anything depends on it.
2. `Phase` state machine inside `DSSlideToConfirm`, replacing the `isConfirmed`
   boolean. Behaviour unchanged at this step: `.settle` still looks like today.
3. `async throws` closure + the `processing` / `failing` phases.
4. `.morphAndVanish`: collapse, exhale, vanish.
5. Particle field wired into the component, tint driven by phase.
6. Haptic texture on the drag.
7. `Examples/MotionReview`: a payment section with a ~1.2 s fake `onConfirm`
   and a **"next charge fails"** toggle, so both paths are reviewable.

## Verification

- `swift build` and `swift test` (macOS).
- `xcodebuild build -scheme DesignSystem -destination 'generic/platform=iOS Simulator'`.
- `Examples/MotionReview` in the simulator for the choreography, on device for
  the haptics.
- Reduce Motion and Reduce Transparency both on: no particles, no morph
  overshoot, the control still confirms.
- Light and dark, on all three gradient themes.

## Definition of done

Per the repo `CLAUDE.md`: code + `#Preview` (light and dark on `.dsBackdrop()`),
a `ComponentCatalog` section, the `docs/components.md` entry updated,
a `CHANGELOG.md` line under `[Unreleased]`, the capsule-is-a-circle trick and
the analytic-simulation rationale in `docs/engineering-notes.md`, and the
`~/.claude/skills/design-system/references/` update.

## Risk

`DSSlideToConfirm` is **not on `main`** — it lives on
`chore/motion-review-harness` (PRs #80 / #81, unmerged). This branch is cut
from there, so it lands only after those do. Accepted deliberately: porting the
component to `main` first would be a separate merge and would leave the review
harness behind.
