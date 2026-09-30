import SwiftUI

/// Role: Rail. Press, pill, nameplate, and reset styles. Tokens only. Retract is not destructive.
struct SpreadPillStyle: ButtonStyle {
    var isLoading: Bool = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: RailSpace.inner) {
            if isLoading {
                ProgressView()
                    .tint(RailInk.surface)
            }
            configuration.label
                .font(RailType.font(.headline))
                .lineLimit(1)
        }
        .foregroundStyle(isEnabled ? RailInk.surface : RailInk.muted)
        .frame(maxWidth: .infinity, minHeight: RailSpace.hit)
        .padding(.horizontal, RailSpace.card)
        .background(fill(pressed: configuration.isPressed), in: Capsule())
        .contentShape(Capsule())
        .scaleEffect(RailMotion.scale(pressed: configuration.isPressed, reduceMotion: reduceMotion))
        .animation(RailMotion.press(reduceMotion), value: configuration.isPressed)
        .opacity(isEnabled ? 1 : 0.55)
    }

    private func fill(pressed: Bool) -> Color {
        if !isEnabled { return RailInk.muted.opacity(0.35) }
        return pressed ? RailInk.accent.opacity(0.82) : RailInk.accent
    }
}

/// Role: Rail. Whole Rampin nameplate. Covers default, pressed, focused, disabled, selected, and error.
struct HookPlateStyle: ButtonStyle {
    var isSelected: Bool = false
    var isError: Bool = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RailType.font(.headline))
            .foregroundStyle(ink)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: RailSpace.hit, alignment: .leading)
            .padding(RailSpace.card)
            .background(fill(pressed: configuration.isPressed), in: plate)
            .overlay(plate.stroke(stroke, lineWidth: isFocused || isSelected ? 2 : 0))
            .contentShape(plate)
            .scaleEffect(RailMotion.scale(pressed: configuration.isPressed, reduceMotion: reduceMotion))
            .animation(RailMotion.press(reduceMotion), value: configuration.isPressed)
            .opacity(isEnabled ? (isError ? 0.55 : 1) : 0.45)
    }

    private var plate: RoundedRectangle {
        RoundedRectangle(cornerRadius: RailRadius.card, style: .continuous)
    }

    private var ink: Color {
        if isError { return RailInk.muted }
        if isSelected { return RailInk.ink }
        return RailInk.ink
    }

    private var stroke: Color {
        if isError { return RailInk.muted }
        if isFocused { return RailInk.ink }
        if isSelected { return RailInk.accent }
        return RailInk.muted
    }

    private func fill(pressed: Bool) -> Color {
        if isError { return RailInk.surface }
        if isSelected { return RailInk.surface }
        return pressed ? RailInk.muted.opacity(0.12) : RailInk.surface
    }
}

/// Role: Rail. Whole canvas tile. One target, fill hit, press scale.
struct LiftTileStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: RailRadius.card, style: .continuous))
            .scaleEffect(RailMotion.scale(pressed: configuration.isPressed, reduceMotion: reduceMotion))
            .animation(RailMotion.press(reduceMotion), value: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.7)
    }
}

/// Role: Rail. Secondary retract. Not the destructive variant.
struct RetractRailStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RailType.font(.headline))
            .foregroundStyle(isEnabled ? RailInk.accent : RailInk.muted)
            .frame(maxWidth: .infinity, minHeight: RailSpace.hit)
            .padding(.horizontal, RailSpace.card)
            .background(fill(pressed: configuration.isPressed), in: Capsule())
            .overlay(
                Capsule().stroke(isEnabled ? RailInk.accent.opacity(0.45) : RailInk.muted.opacity(0.28), lineWidth: 1)
            )
            .contentShape(Capsule())
            .scaleEffect(RailMotion.scale(pressed: configuration.isPressed, reduceMotion: reduceMotion))
            .animation(RailMotion.press(reduceMotion), value: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.5)
    }

    private func fill(pressed: Bool) -> Color {
        if !isEnabled { return RailInk.muted.opacity(0.12) }
        return RailInk.accent.opacity(pressed ? 0.22 : 0.14)
    }
}

/// Role: Rail. resetAllData only. Delete does not wear accent.
struct ResetRailStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RailType.font(.headline))
            .foregroundStyle(RailInk.ink)
            .frame(maxWidth: .infinity, minHeight: RailSpace.hit)
            .padding(.horizontal, RailSpace.card)
            .background(
                (configuration.isPressed ? RailInk.muted.opacity(0.22) : RailInk.muted.opacity(0.16)),
                in: Capsule()
            )
            .contentShape(Capsule())
            .scaleEffect(RailMotion.scale(pressed: configuration.isPressed, reduceMotion: reduceMotion))
            .animation(RailMotion.press(reduceMotion), value: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

/// Role: Rail. Icon-only chrome. Min 44pt. VoiceOver labels live on the Button.
struct RailIconStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RailType.font(.headline))
            .foregroundStyle(RailInk.ink)
            .frame(minWidth: RailSpace.hit, minHeight: RailSpace.hit)
            .background(RailInk.surface, in: RoundedRectangle(cornerRadius: RailRadius.chip, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: RailRadius.chip, style: .continuous))
            .scaleEffect(RailMotion.scale(pressed: configuration.isPressed, reduceMotion: reduceMotion))
            .animation(RailMotion.press(reduceMotion), value: configuration.isPressed)
    }
}

extension View {
    func railHit() -> some View {
        frame(minWidth: RailSpace.hit, minHeight: RailSpace.hit)
            .contentShape(Rectangle())
    }
}
