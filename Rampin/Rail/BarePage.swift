import SwiftUI

/// Role: Rail. Full-page empty. Generated cutout, one headline, one line, bottom full-width pill.
struct BarePage: View {
    var art: String
    var headline: String
    var line: String
    var actionTitle: String
    var action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, RailSpace.outer)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: RailSpace.inner) {
                Text(headline)
                    .font(RailType.font(.display, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .lineLimit(typeSize.isAccessibilitySize ? 3 : 2)
                Text(line)
                    .font(RailType.font(.body, size: typeSize))
                    .foregroundStyle(RailInk.muted)
            }
            .padding(.horizontal, RailSpace.outer)
            .padding(.top, RailSpace.card)
            .padding(.bottom, RailSpace.card)
            Button(actionTitle, action: action)
                .buttonStyle(SpreadPillStyle())
                .padding(.horizontal, RailSpace.outer)
                .padding(.bottom, RailSpace.outer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RailInk.background)
    }
}
