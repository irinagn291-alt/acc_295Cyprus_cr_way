import SwiftUI

/// Role: Rail. One-shot cover. Three pages. Continue full width at the bottom. Skip writes defaults. Re-runnable from Settings.
struct OnboardingCover: View {
    var onSkip: () -> Void
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                if page < 2 {
                    Button("Skip", action: onSkip)
                        .font(RailType.font(.caption, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                        .railHit()
                        .buttonStyle(RailIconStyle())
                        .accessibilityLabel("Skip onboarding")
                }
            }
            .padding(.horizontal, RailSpace.outer)
            .padding(.top, RailSpace.inner)

            ViewThatFits(in: .vertical) {
                pageSwitch(showsSpacer: true)
                ScrollView {
                    pageSwitch(showsSpacer: false)
                }
                .scrollIndicators(.hidden)
            }
            .id(page)
            .animation(RailMotion.swap(reduceMotion), value: page)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            HStack(spacing: RailSpace.gap) {
                ForEach(0 ..< 3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: RailRadius.chip, style: .continuous)
                        .fill(index == page ? RailInk.accent : RailInk.surface)
                        .frame(
                            width: index == page ? RailSpace.step(3) : RailSpace.inner,
                            height: RailSpace.inner
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, RailSpace.outer)
            .padding(.bottom, RailSpace.inner)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Page \(RailFigures.count(page + 1)) of \(RailFigures.count(3))"
            )

            Button(page < 2 ? "Continue" : "Next") {
                if page < 2 {
                    page += 1
                } else {
                    onFinish()
                }
            }
            .buttonStyle(SpreadPillStyle())
            .padding(.horizontal, RailSpace.outer)
            .padding(.bottom, RailSpace.outer)
        }
        .background(RailInk.background.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private func pageSwitch(showsSpacer: Bool) -> some View {
        switch page {
        case 0:
            pageBody(
                art: RailArt.onboarding1,
                headline: RailCopy.onboarding1Title,
                line: RailCopy.onboarding1Line,
                showsSpacer: showsSpacer
            )
        case 1:
            pageBody(
                art: RailArt.onboarding2,
                headline: RailCopy.onboarding2Title,
                line: RailCopy.onboarding2Line,
                showsSpacer: showsSpacer
            )
        default:
            pageBody(
                art: RailArt.onboarding3,
                headline: RailCopy.onboarding3Title,
                line: RailCopy.onboarding3Line,
                showsSpacer: showsSpacer
            )
        }
    }

    private func pageBody(art: String, headline: String, line: String, showsSpacer: Bool) -> some View {
        VStack(alignment: .leading, spacing: RailSpace.card) {
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: showsSpacer ? .infinity : RailSpace.step(28))
                .accessibilityHidden(true)
            Text(headline)
                .font(RailType.font(.display, size: typeSize))
                .foregroundStyle(RailInk.ink)
                .lineLimit(typeSize.isAccessibilitySize ? 3 : 2)
            Text(line)
                .font(RailType.font(.body, size: typeSize))
                .foregroundStyle(RailInk.muted)
            if showsSpacer {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, RailSpace.outer)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
