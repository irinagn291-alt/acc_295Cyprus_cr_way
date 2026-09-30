import SwiftUI

/// Role: Rail. Sheet host. Scale 0.96 to 1 plus fade. Reduce Motion is opacity only. Quiz stays underneath.
struct RailCoverPane<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(RailInk.surface)
            .shadow(color: RailLift.shade, radius: RailLift.shadeRadius, x: 0, y: RailLift.shadeY)
            .scaleEffect(RailMotion.sheetScale(shown: shown, reduceMotion: reduceMotion))
            .opacity(shown ? 1 : 0)
            .onAppear {
                withAnimation(RailMotion.sheet(reduceMotion)) {
                    shown = true
                }
            }
    }
}
