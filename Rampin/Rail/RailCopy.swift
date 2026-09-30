import Foundation

/// Role: Rail. Warm voice. Human and brief. No em dash, no emoji. The ui axis string is never a title.
enum RailCopy {
    static let appName = "CR Way"
    static let hookTitle = "Seat this painting"
    static let hookAction = "Seat this painting"
    static let nextLift = "Tap Seat to hang the waiting painting under its title."
    static let nextHook = "Tap Seat to hang this painting under its title."
    static let nextSpread = "Three seated. Spread when three wait."
    static let nextBare = "Save three works, then hook."
    static let plateReady = "Seat it here"
    static let plateOpen = "Not seated"
    static let plateMiss = "Miss, try another"
    static let plateSeated = "Already seated"
    static let bareHeadline = "Rail bare."
    static let bareLine = "Save three works, then hook."
    static let settledHeadline = "Rail settled."
    static let settledLine = "Those three left for Saved. Spread the next trio."
    static let exploreHeadline = "Shelf is quiet."
    static let exploreLine = "Search the museum, or save a waiting work from this shelf."
    static let savedHeadline = "Nothing seated."
    static let savedLine = "Hook a canvas. Marks land here."
    static let settingsHeadline = "Rail is empty."
    static let settingsLine = "Save three works, then hook."
    static let recoverHeadline = "The rail could not be read."
    static let recoverLine = "Start a fresh crate. Save three works, then hook."
    static let writeFailed = "The rail could not be written."
    static let shelfNote = "Showing the local shelf."
    static let filedNote = "Waiting on the rail."
    static let focusedNote = "Already on the rail."
    static let seekFailed = "Search could not finish. The shelf is still here."
    static let twistTitle = "Spread, then hook"
    static let twistLine = "Three canvases. Three nameplates. Lift a painting, then seat it under the cartel that names it."
    static let onboarding1Title = "Seat each canvas"
    static let onboarding1Line = "Save a museum painting, then hook it under the nameplate that names it."
    static let onboarding2Title = "Lift, then hook"
    static let onboarding2Line = "Tap a waiting canvas, then the nameplate that belongs with it."
    static let onboarding3Title = "Keep the rail"
    static let onboarding3Line = "Misses stay on Saved. Retract peels the newest mark."
    static let resetTitle = "Erase this rail?"
    static let resetLine = "Hooks, drops, and saved works leave this device."
    static let contact = "Contact"
    static let museum = "Philadelphia Museum of Art"
    static let openAccess = "Open access credit"
    static let replay = "Walk the pages again"
    static let reset = "Erase the rail"
    static let retract = "Retract newest mark"
    static let spread = "Spread"
    static let spreadNext = "Spread next"
    static let explore = "Explore"
    static let saved = "Saved"
    static let settings = "Settings"
    static let twist = "Spread then hook"

    static func caption(_ value: CanvasCaption) -> String {
        switch value {
        case .waiting: return "Waiting"
        case .lifted: return "Lifted"
        case .hooked: return "Hooked"
        case .settled: return "Settled"
        }
    }

    static func fold(_ value: RailFold) -> String {
        switch value {
        case .bare: return "Bare"
        case .spread: return "Spread"
        case .settled: return "Settled"
        }
    }

    static func field(_ value: CartelField) -> String {
        switch value {
        case .artist: return "Nameplates show the maker"
        case .title: return "Nameplates show the title"
        }
    }

    static func nextTap(fold: RailFold, lifted: Bool) -> String {
        switch fold {
        case .bare:
            return nextBare
        case .settled:
            return nextSpread
        case .spread:
            return lifted ? nextHook : nextLift
        }
    }

    static func railJob(work: Work?, lifted: Bool, field: CartelField?) -> String {
        guard let work else { return nextBare }
        let cue = field == .artist ? "maker" : "title"
        if lifted {
            return "\(work.title) by \(work.artist) is ready. Tap Seat to hang it under its \(cue)."
        }
        return "\(work.title) by \(work.artist). Tap Seat to hang it under its \(cue)."
    }

    static func plateLine(seated: Bool, struck: Bool) -> String {
        if seated { return plateSeated }
        if struck { return plateMiss }
        return plateOpen
    }

    static func fault(_ error: Error) -> String {
        if let fault = error as? RailFault {
            return faultLine(fault)
        }
        if let fault = error as? CatalogFault {
            return seek(fault)
        }
        return writeFailed
    }

    static func faultLine(_ fault: RailFault) -> String {
        switch fault {
        case .alreadySpread:
            return "This rail is already spread."
        case .hookWithoutLift, .dropWithoutLift:
            return "Lift a canvas first."
        case .unknownWork:
            return "That canvas is not on this rail."
        case .unknownRampin:
            return "That nameplate is not on this rail."
        case .notWaiting:
            return "That canvas is not waiting."
        case .notSpread:
            return "Spread the rail first."
        case .emptyObjectID:
            return "That work has no accession."
        case .nothingToPeel:
            return "Nothing to retract."
        }
    }

    static func seek(_ fault: CatalogFault) -> String {
        switch fault {
        case .cancelled:
            return ""
        case .missing:
            return "No match. The shelf is still here."
        case .refused:
            return "Search was refused. The shelf is still here."
        case .transport:
            return seekFailed
        case .malformed:
            return "Search came back odd. The shelf is still here."
        }
    }
}
