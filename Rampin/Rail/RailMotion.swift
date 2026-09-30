import SwiftUI

/// Role: Rail. Snap motion. Press 0.97 in 160ms ease-out. Sheets 0.96 to 1 plus fade. Reduce Motion is opacity only.
enum RailMotion {
    static let pressDuration: Double = 0.16
    static let sheetDuration: Double = 0.22
    static let pressScale: CGFloat = 0.97
    static let sheetScale: CGFloat = 0.96

    static func press(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: pressDuration) : .easeOut(duration: pressDuration)
    }

    static func sheet(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: sheetDuration) : .easeOut(duration: sheetDuration)
    }

    static func swap(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: sheetDuration) : .easeOut(duration: sheetDuration)
    }

    static func scale(pressed: Bool, reduceMotion: Bool) -> CGFloat {
        if reduceMotion { return 1 }
        return pressed ? pressScale : 1
    }

    static func sheetScale(shown: Bool, reduceMotion: Bool) -> CGFloat {
        if reduceMotion { return 1 }
        return shown ? 1 : sheetScale
    }
}
