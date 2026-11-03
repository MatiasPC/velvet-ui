# Velvet UI Pro: proposal

> **Status: proposal.** Nothing on this page is built or for sale yet. It records how a paid tier would be structured so that the free library can be shaped for it now, without giving anything up.

Velvet UI is, and stays, a free MIT library of components. **Velvet UI Pro** would be a separate, paid package of what you build *with* those components: complete screens, end-to-end flows, an app starter and theme presets, for people who want to ship a polished app faster.

## Principles

1. **The free core stays complete.** Every component, token, motion primitive, accessibility behavior, doc page, the CLI and the example flows stay MIT in this repo. Pro never removes, delays or gates a core feature, and component fixes always land in the free core.
2. **Pro is composition, not components.** Pro screens are assembled only from the public `VelvetUI` API. When a Pro screen needs a new primitive (a component, a token, a modifier), that primitive is proposed and landed in the free core first, in public.
3. **Separate repository, separate package.** Pro lives in its own private repository and SwiftPM product. Nothing Pro-only is committed here.
4. **Source, not binaries.** Buyers get readable Swift they can copy, change and hand to an AI agent. Pro ships the same agent files as the core (`AGENTS.md`, `llms.txt`, `registry.json`).
5. **Same quality bar.** Light and dark, Reduce Motion, VoiceOver, Dynamic Type and haptics on every screen, plus a Gallery stage for each so it can be previewed and recorded.

## What Pro contains

| Area | Contents (first release target) | Example |
|---|---|---|
| **Screens** | 20–30 production screens grouped by domain: onboarding (3 variants), paywall (3), sign-in / sign-up / passwordless code, settings, profile, checkout and order confirmation, dashboard, activity feed, search with filters, detail page with hero, notifications, AI chat with streaming replies. | `PaywallScreen(plans:selection:onPurchase:)` |
| **Flows** | Screens wired into journeys with navigation and state: onboarding → permissions → paywall; email → code → profile; cart → address → pay → success; subscription management; account deletion. | `CheckoutFlow(cart:onPlaceOrder:)` |
| **App starter** | A ready Xcode project: tab shell, theme picker, onboarding, settings, a StoreKit 2 paywall stub, haptics and analytics hooks, App Store screenshot stages, and `AGENTS.md` / `CLAUDE.md` configured for agents. | `velvet-starter` template |
| **Presets** | Additional gradient themes with tested AA contrast, matching palettes and documented pairings. | `DSGradientTheme.pro.ember` |

The free repo keeps three deliberately simple example flows (onboarding, settings, checkout) to show how components compose. Pro screens are richer, cover far more of an app, and are ready to drop in.

## Package structure

```
velvet-ui-pro/                      (private repository)
├── Package.swift                   product "VelvetUIPro", depends on velvet-ui
├── Sources/VelvetUIPro/
│   ├── Screens/<Domain>/<Name>Screen.swift
│   ├── Flows/<Name>Flow.swift
│   ├── Presets/                    themes and palettes
│   └── Support/                    plain models and protocols screens are configured with
├── Templates/AppStarter/           project.yml + committed .xcodeproj + App/
├── Examples/ProGallery/            one screen and one recording stage per item
├── registry.json                   same schema as the core, with "tier": "pro"
├── AGENTS.md, llms.txt, llms-full.txt
└── LICENSE                         commercial
```

```swift
// Package.swift of an app using Pro
dependencies: [
    .package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0"),
    .package(url: "git@github.com:MatiasPC/velvet-ui-pro.git", from: "0.3.0"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "VelvetUI", package: "velvet-ui"),
        .product(name: "VelvetUIPro", package: "velvet-ui-pro"),
    ])
]
```

**Screen API conventions.** Screens take data as plain models and closures and never do networking or persistence themselves: `PaywallScreen(plans: [Plan], selection: $plan, onPurchase: { plan in try await store.buy(plan) })`. No singletons. Optional adapters (StoreKit 2, Sign in with Apple) sit in `Support/` and are opt-in.

## Delivery

| Option | How it works | Pros | Cons |
|---|---|---|---|
| **A. Private GitHub repo access** (recommended to start) | A storefront that grants GitHub repository access on purchase (for example Polar, which has this built in, or Lemon Squeezy with a webhook). Buyers add the package over SSH or a token, or copy files. | No backend. Updates are `git pull`. Agents can read the source. A merchant of record handles tax. | Buyers need a GitHub account. CI needs a deploy key or token. Access has to be revoked on refund. |
| **B. License key + CLI** | `swift velvet.swift add --pro PaywallScreen --key …` downloads files from a small authenticated endpoint (for example a Cloudflare Worker in front of private storage). | The same copy-in flow as the free CLI. No GitHub account needed. | A backend to run. Keys can be shared. More moving parts. |
| C. Binary XCFramework | Ship compiled binaries. | Hides the source. | Can't be customized or read by agents, and doesn't fit the copy-and-own model. **Not recommended.** |

Start with **A**. Add **B** only if buyers ask for copy-in without GitHub.

## Licensing and pricing (to decide)

- A commercial license: use in unlimited apps you or your team ship; no redistribution as a UI kit or template.
- Personal and team seats. A one-time price with a year of updates, or lifetime access, decided before launch.
- The core stays MIT. Nothing in Pro changes the license of anything in this repo.

## Versioning

- Pro `0.x` tracks the core's minor version: Pro 0.3.x requires `velvet-ui` 0.3.x.
- Pro's CI also builds against the core's `main` every night, so breaking changes surface before a core release.
- Core changes that Pro needs go through this repo's normal PR process first.

## Readiness in the free core

Already in place: the public `@DSThemed` / `DSResolvedTheme` API that screens paint with, `DSGradientTheme(id:name:stops:accent:onAccent:ink:inkDark:)` for presets, the `registry.json` schema and CLI, and Gallery recording stages.

Open questions before Pro work starts:

- **Typography presets** need themable text styles. `DSTextStyle` is static today, so this would be a core proposal first.
- **Native Liquid Glass** on iOS 26 for Pro screens depends on the core's surface work landing first.
- **Waitlist:** the landing page and sign-up link are placeholders until there is something to show.
