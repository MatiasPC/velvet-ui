import SwiftUI
import VelvetUI

// MARK: - Checkout flow
// An example, not a component: a cart, promo code, totals and a slide-to-pay,
// ending in a confirmation moment. It shows DSCard, DSStepper, DSTextField,
// DSNumberTicker, DSSlideToConfirm, DSToggle, DSEmptyState, DSSuccessCheck,
// .dsConfetti and DSButton working together.
// Copy it with `swift velvet.swift add Checkout` and adapt it.

struct CheckoutFlow: View {
    var onFinish: () -> Void = {}

    @State private var items = CheckoutItem.sample
    @State private var code = ""
    @State private var promo = PromoState.idle
    @State private var simulatesDecline = false
    @State private var declineMessage: String?
    @State private var orderNumber: String?
    /// Bumped on the same beat as the swap to the confirmation; drives the confetti.
    @State private var celebrations = 0
    /// Changing this remounts the slide control, so it starts fresh after "Done".
    @State private var slideID = 0

    private var subtotal: Double { items.reduce(0) { $0 + $1.price * Double($1.quantity) } }
    private var discount: Double { promo == .applied ? subtotal * CheckoutPromo.rate : 0 }
    private var total: Double { subtotal - discount }
    private var isEmpty: Bool { items.allSatisfy { $0.quantity == 0 } }

    var body: some View {
        ZStack {
            if let orderNumber {
                CheckoutConfirmation(orderNumber: orderNumber, onDone: reset)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                cart
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The paper falls through the whole screen, so it goes on the root.
        .dsConfetti(trigger: celebrations, origin: UnitPoint(x: 0.5, y: 0.3))
    }

    // MARK: Cart

    private var cart: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Checkout").ds(.largeTitle)
                if isEmpty {
                    DSEmptyState(
                        icon: "bag",
                        title: "Your cart is empty",
                        message: "Add something you like and it will show up here.",
                        actionTitle: "Restore cart"
                    ) {
                        withAnimation(DSAnimation.springSmooth) { items = CheckoutItem.sample }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    cartCard
                    CheckoutPromoField(code: $code, promo: $promo)
                    CheckoutTotals(subtotal: subtotal, discount: discount, total: total)
                    payControl
                }
                demoCard
            }
            .dsScreenPadding()
        }
        .onChange(of: code) { _, _ in promo = .idle }
    }

    private var cartCard: some View {
        DSCard {
            VStack(spacing: DSSpacing.md) {
                ForEach($items) { $item in
                    CheckoutRow(item: $item)
                }
            }
        }
    }

    private var payControl: some View {
        VStack(spacing: DSSpacing.xs) {
            DSSlideToConfirm(
                "Slide to pay \(total.formatted(.currency(code: "USD")))",
                confirmedLabel: "Paid",
                finish: .morphAndVanish
            ) {
                declineMessage = nil
                do {
                    let number = try await CheckoutService.charge(amount: total, declined: simulatesDecline)
                    place(number)
                } catch {
                    declineMessage = "Card declined. Try another card."
                    throw error   // the control re-opens for a retry
                }
            }
            .id(slideID)
            if let declineMessage {
                CheckoutNote(declineMessage, icon: "exclamationmark.circle")
                    .transition(.dsFade)
            }
        }
        .animation(DSAnimation.springSmooth, value: declineMessage)
    }

    private var demoCard: some View {
        DSCard(style: .flat) {
            DSToggle("Simulate a declined card", isOn: $simulatesDecline)
        }
    }

    // MARK: Actions

    /// The swap and the confetti share one beat.
    private func place(_ number: String) {
        withAnimation(DSAnimation.springSmooth) { orderNumber = number }
        celebrations += 1
    }

    private func reset() {
        onFinish()
        withAnimation(DSAnimation.springSmooth) {
            orderNumber = nil
            items = CheckoutItem.sample
            code = ""
            promo = .idle
            declineMessage = nil
        }
        slideID += 1
    }
}

// MARK: - Model and service

private struct CheckoutItem: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let price: Double
    var quantity: Int

    static let sample = [
        CheckoutItem(name: "Linen shirt", symbol: "tshirt", price: 48, quantity: 1),
        CheckoutItem(name: "Canvas tote", symbol: "bag", price: 24.5, quantity: 2),
        CheckoutItem(name: "Ceramic mug", symbol: "cup.and.saucer", price: 18, quantity: 1),
    ]
}

private enum PromoState { case idle, applied, invalid }

private enum CheckoutPromo {
    static let code = "VELVET"
    static let rate = 0.10
}

private enum CheckoutError: Error { case declined }

/// Stand-in for a payments backend, so the async path reads like real code.
private enum CheckoutService {
    static func charge(amount: Double, declined: Bool) async throws -> String {
        try await Task.sleep(for: .seconds(1.2))
        if declined { throw CheckoutError.declined }
        return "VX-\(Int.random(in: 10_000...99_999))"
    }
}

// MARK: - Pieces

private struct CheckoutRow: View {
    @Binding var item: CheckoutItem
    @DSThemed private var theme

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: item.symbol)
                .dsFont(.title2)
                .foregroundStyle(theme.ink)
                .frame(width: DSSpacing.huge, height: DSSpacing.huge)
                .dsSurface(.glassThin, radius: DSRadius.control)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                Text(item.name).ds(.body)
                Text(item.price.formatted(.currency(code: "USD")))
                    .ds(.callout, color: theme.palette.textSecondary)
            }
            Spacer()
            DSStepper(value: $item.quantity, in: 0...9)
                .accessibilityLabel("\(item.name) quantity")
        }
    }
}

private struct CheckoutPromoField: View {
    @Binding var code: String
    @Binding var promo: PromoState

    var body: some View {
        HStack(alignment: .bottom, spacing: DSSpacing.sm) {
            DSTextField(
                label: "Promo code",
                placeholder: "Try VELVET",
                icon: "tag",
                text: $code,
                state: fieldState
            )
            DSButton("Apply", size: .small) { apply() }
                .padding(.bottom, DSSpacing.xxs)
        }
    }

    private var fieldState: DSTextFieldState {
        switch promo {
        case .idle: return .normal
        case .applied: return .success
        case .invalid: return .error("That code doesn't work")
        }
    }

    private func apply() {
        let entered = code.trimmingCharacters(in: .whitespaces).uppercased()
        withAnimation(DSAnimation.springSnappy) {
            promo = entered == CheckoutPromo.code ? .applied : .invalid
        }
    }
}

private struct CheckoutTotals: View {
    let subtotal: Double
    let discount: Double
    let total: Double
    @DSThemed private var theme

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.sm) {
                line("Subtotal", subtotal.formatted(.currency(code: "USD")))
                if discount > 0 {
                    line("Discount (10%)", "-" + discount.formatted(.currency(code: "USD")),
                         color: theme.palette.success)
                        .transition(.dsFade)
                }
                HStack {
                    Text("Total").ds(.title3)
                    Spacer()
                    DSNumberTicker(total, format: .currency(code: "USD"), style: .displayMedium)
                }
            }
            .animation(DSAnimation.springSmooth, value: discount > 0)
        }
    }

    private func line(_ title: String, _ value: String, color: Color? = nil) -> some View {
        HStack {
            Text(title).ds(.callout, color: theme.palette.textSecondary)
            Spacer()
            Text(value).ds(.numeric, color: color)
        }
    }
}

private struct CheckoutNote: View {
    let text: String
    let icon: String
    @DSThemed private var theme

    init(_ text: String, icon: String) {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: DSSpacing.xs) {
            Image(systemName: icon).accessibilityHidden(true)
            Text(text).ds(.footnote, color: theme.palette.error)
            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.palette.error)
    }
}

private struct CheckoutConfirmation: View {
    let orderNumber: String
    let onDone: () -> Void
    @DSThemed private var theme

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer()
            DSSuccessCheck(isComplete: true, size: DSSpacing.massive + DSSpacing.xl)
            VStack(spacing: DSSpacing.xs) {
                Text("Order placed").ds(.largeTitle)
                Text("Order \(orderNumber)")
                    .ds(.numeric, color: theme.palette.textSecondary)
            }
            Spacer()
            DSButton("Done", size: .large, isFullWidth: true, action: onDone)
        }
        .dsScreenPadding()
        .padding(.bottom, DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsBackdrop()
    }
}

// MARK: - Previews

#Preview("Checkout — Light") {
    CheckoutFlow()
        .dsTheme(DSTheme(gradient: .sunset))
        .preferredColorScheme(.light)
}

#Preview("Checkout — Dark") {
    CheckoutFlow()
        .dsTheme(DSTheme(gradient: .aurora))
        .preferredColorScheme(.dark)
}
