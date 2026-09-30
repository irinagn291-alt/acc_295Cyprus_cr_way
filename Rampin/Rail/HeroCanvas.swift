import SwiftUI

/// Role: Rail. Custom drawing lives only here. Shape, Path, and one Material on the lifted hero.
struct RailPegShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let neck = rect.maxY - 22
        let bowl = rect.maxY - 6
        path.move(to: CGPoint(x: midX - 14, y: neck))
        path.addQuadCurve(
            to: CGPoint(x: midX + 14, y: neck),
            control: CGPoint(x: midX, y: bowl)
        )
        path.addLine(to: CGPoint(x: midX + 8, y: neck - 10))
        path.addQuadCurve(
            to: CGPoint(x: midX - 8, y: neck - 10),
            control: CGPoint(x: midX, y: neck + 2)
        )
        path.closeSubpath()
        return path
    }
}

/// Role: Rail. Photography tile. Caption sits under a hung plate. A missing Commons face still fills the cell.
struct CanvasTile: View {
    var work: Work
    var caption: CanvasCaption
    var isHero: Bool
    var isLifted: Bool
    var face: Image?
    var fillsSlot: Bool = false
    var showsCaption: Bool = true
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: RailSpace.inner) {
            canvas
            if showsCaption, face != nil {
                underCaption
            }
        }
        .frame(maxWidth: .infinity, maxHeight: fillsSlot ? .infinity : nil, alignment: .topLeading)
    }

    private var underCaption: some View {
        VStack(alignment: .leading, spacing: RailSpace.gap) {
            Text(work.title)
                .font(RailType.font(isHero ? .headline : .caption, size: typeSize))
                .foregroundStyle(RailInk.ink)
                .lineLimit(isHero ? 3 : 2)
                .fixedSize(horizontal: false, vertical: true)
            if isHero {
                Text(work.artist)
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(RailCopy.caption(caption))
                .font(RailType.font(.caption, size: typeSize))
                .foregroundStyle(RailInk.muted)
                .monospacedDigit()
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var canvas: some View {
        plateFrame
            .overlay {
                ZStack {
                    RailInk.surface
                    if let face {
                        face
                            .resizable()
                            .scaledToFill()
                    } else {
                        CanvasVacant(title: work.title, seat: RailCopy.caption(caption))
                    }
                    if isLifted {
                        RoundedRectangle(cornerRadius: RailRadius.card, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RailPegShape()
                            .fill(RailInk.accent.opacity(0.88))
                            .padding(.horizontal, RailSpace.card)
                    }
                }
                .clipped()
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: RailRadius.card, style: .continuous))
            .shadow(
                color: isHero ? RailLift.shade : .clear,
                radius: isHero ? RailLift.shadeRadius : 0,
                x: 0,
                y: isHero ? RailLift.shadeY : 0
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(work.title), \(RailCopy.caption(caption))")
    }

    @ViewBuilder
    private var plateFrame: some View {
        if fillsSlot {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Color.clear
                .aspectRatio(isHero ? 4.0 / 3.0 : 1.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }
}

/// Role: Rail. Opaque hung plate when the Commons face is missing. Title and seat live on the plate.
struct CanvasVacant: View {
    var title: String
    var seat: String
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RailInk.surface
            VStack(alignment: .leading, spacing: RailSpace.inner) {
                Image(systemName: "rectangle.portrait")
                    .font(RailType.font(.title, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .accessibilityHidden(true)
                Text(title)
                    .font(RailType.font(.headline, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                Text(seat)
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .lineLimit(1)
            }
            .padding(RailSpace.card)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Role: Rail. Row image slot. Glyph on a tinted square. Never row type inside the thumb.
struct CanvasThumb: View {
    var title: String
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack {
            RailInk.muted.opacity(0.16)
            Text(initial)
                .font(RailType.font(.title, size: typeSize))
                .foregroundStyle(RailInk.ink)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var initial: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "R" }
        return String(first).uppercased()
    }
}
