# Examples

Three small flows that show Velvet components composed into real app moments: an onboarding, a settings screen and a checkout.

> Example — not a component. Copy it and adapt it.

They are not part of the library and you don't import them. Each one is a single Swift file that uses only SwiftUI and VelvetUI, so you can copy it into your app and change it. They follow the rules in [AGENTS.md](../../AGENTS.md): one theme injected at the root, screens on the backdrop, tokens only, and async work awaited inside the component.

| Example | What it shows |
|---|---|
| [Onboarding](Onboarding.md) | Four swipeable pages, live theme picker, success check and confetti |
| [Settings](Settings.md) | Grouped settings, appearance switch, delete-account sheet, toasts |
| [Checkout](Checkout.md) | Cart, promo code, rolling total, slide to pay, confirmation |

## Run them

Open `Examples/VelvetGallery/VelvetGallery.xcodeproj`, run the Gallery, and open the **Examples** section. Each flow runs on its own fake services, so nothing leaves your device.

## Copy them

The CLI copies a flow together with the Velvet source it needs:

```bash
curl -fsSLO https://raw.githubusercontent.com/MatiasPC/velvet-ui/main/scripts/velvet.swift
swift velvet.swift list
swift velvet.swift add Checkout --dest MyApp/VelvetUI
```

Pick one install path per target: the Swift package, or copied sources. See [AGENTS.md](../../AGENTS.md#setup-once-per-app).
