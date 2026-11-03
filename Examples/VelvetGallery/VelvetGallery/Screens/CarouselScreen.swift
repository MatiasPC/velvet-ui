import SwiftUI
import VelvetUI

private struct Destination: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let price: String
    let gradientIndex: Int
}

private let destinations = [
    Destination(id: 0, title: "Lisbon", subtitle: "3 nights, tram 28", price: "$480", gradientIndex: 0),
    Destination(id: 1, title: "Kyoto", subtitle: "5 nights, temples", price: "$1,240", gradientIndex: 1),
    Destination(id: 2, title: "Oaxaca", subtitle: "4 nights, mezcal", price: "$620", gradientIndex: 2),
    Destination(id: 3, title: "Reykjavik", subtitle: "2 nights, aurora", price: "$870", gradientIndex: 0),
    Destination(id: 4, title: "Marrakesh", subtitle: "4 nights, medina", price: "$540", gradientIndex: 1)
]

/// A destination card: gradient fill from the theme with title, subtitle and price.
private struct DestinationCard: View {
    let destination: Destination
    var height: CGFloat = 200

    @DSThemed private var theme

    var body: some View {
        let stops = theme.gradient.stops
        let tint = stops[destination.gradientIndex % stops.count]
        RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous)
            .fill(LinearGradient(colors: [tint, theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(destination.title).ds(.title2, color: theme.onAccent)
                    Text(destination.subtitle).ds(.callout, color: theme.onAccent)
                    Text(destination.price).ds(.title3, color: theme.onAccent)
                        .padding(.top, DSSpacing.xxs)
                }
                .padding(DSSpacing.md)
            }
            .frame(height: height)
            .accessibilityElement(children: .combine)
    }
}

struct CarouselScreen: View {
    @State private var page = 0
    @State private var compactPage = 0

    var body: some View {
        GalleryScreen(title: "Carousel", caption: "Snapping, peeking, with depth") {
            LabeledExample("Featured destinations") {
                VStack(spacing: DSSpacing.md) {
                    DSCarousel(destinations, currentPage: $page) { item in
                        DestinationCard(destination: item)
                    }
                    .frame(height: 200)
                    .padding(.horizontal, -DSSpacing.screenHorizontal)

                    DSPageControl(currentPage: $page, numberOfPages: destinations.count)
                }
                .frame(maxWidth: .infinity)
            }

            LabeledExample("Compact — smaller peek, no haptic") {
                VStack(spacing: DSSpacing.sm) {
                    DSCarousel(destinations, currentPage: $compactPage, peek: DSSpacing.lg, spacing: DSSpacing.sm, haptic: nil) { item in
                        DestinationCard(destination: item, height: 96)
                    }
                    .frame(height: 96)
                    .padding(.horizontal, -DSSpacing.screenHorizontal)

                    DSPageControl(currentPage: $compactPage, numberOfPages: destinations.count)
                }
                .frame(maxWidth: .infinity)
            }

            LabeledExample("Self-managed index") {
                DSCarousel(destinations) { item in
                    DestinationCard(destination: item, height: 96)
                }
                .frame(height: 96)
                .padding(.horizontal, -DSSpacing.screenHorizontal)
            }
        }
    }
}

struct CarouselStage: View {
    let autoplay: Bool
    @State private var page = 0

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            DSCarousel(destinations.prefix(5).map { $0 }, currentPage: $page) { item in
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(item.title).ds(.title2)
                    Text(item.subtitle).ds(.callout, color: DSColors.textSecondary)
                    Spacer(minLength: 0)
                    Text(item.price).ds(.title3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(DSSpacing.md)
                .dsSurface(.glass, radius: DSRadius.card)
            }
            .frame(height: 240)
            .padding(.horizontal, -DSSpacing.screenHorizontal)

            DSPageControl(currentPage: $page, numberOfPages: 5)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(1.6)
                page = (page + 1) % 5
            }
        }
    }
}
