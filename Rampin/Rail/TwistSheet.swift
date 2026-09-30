import SwiftUI

/// Role: Rail. Spread-then-hook page of its own. Quiz already wears the same mechanic on the locked rail.
struct TwistSheet: View {
    @Bindable var chrome: RailChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Image(RailArt.twistHero)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, RailSpace.outer)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: RailSpace.inner) {
                    Text(RailCopy.twistTitle)
                        .font(RailType.font(.display, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                    Text(RailCopy.twistLine)
                        .font(RailType.font(.body, size: typeSize))
                        .foregroundStyle(RailInk.muted)
                    HStack(spacing: RailSpace.card) {
                        Text(RailCopy.fold(chrome.rail.fold))
                            .font(RailType.font(.caption, size: typeSize))
                            .foregroundStyle(RailInk.surface)
                            .padding(.horizontal, RailSpace.card)
                            .padding(.vertical, RailSpace.inner)
                            .background(RailInk.ink, in: Capsule())
                        Text("\(RailFigures.count(chrome.rail.planted.count)) nameplates")
                            .font(RailType.font(.caption, size: typeSize))
                            .foregroundStyle(RailInk.muted)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, RailSpace.outer)
                .padding(.top, RailSpace.card)
                .padding(.bottom, RailSpace.card)
                Button(RailCopy.hookTitle) {
                    dismiss()
                }
                .buttonStyle(SpreadPillStyle())
                .padding(.horizontal, RailSpace.outer)
                .padding(.bottom, RailSpace.outer)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(RailInk.background.ignoresSafeArea())
            .navigationTitle(RailCopy.twistTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(RailIconStyle())
                    .accessibilityLabel("Close spread then hook")
                }
            }
        }
    }
}
