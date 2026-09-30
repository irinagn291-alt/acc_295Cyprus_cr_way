import SwiftUI

/// Role: Rail. Locked Quiz hook rail. Spread, Lift, Hook, and Retract fuse here. Explore, Saved, Settings, and Twist arrive as sheets.
struct QuizView: View {
    @Bindable var chrome: RailChrome
    @State private var faces = CanvasFace.shared
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if chrome.quizIsEmpty {
                bareBoard
            } else if chrome.rail.fold == .settled {
                settledBoard
            } else {
                spreadBoard
            }
        }
        .background(RailInk.background.ignoresSafeArea())
        .id(chrome.dayStamp)
        .sensoryFeedback(.impact(weight: .medium), trigger: chrome.hookPulse)
        .animation(RailMotion.swap(reduceMotion), value: chrome.rail.fold)
        .animation(RailMotion.swap(reduceMotion), value: chrome.rail.liftedWorkID)
        .task(id: chrome.heroWork?.objectID) {
            await faces.load(chrome.heroWork?.imageURL)
            await faces.loadMany(chrome.companionWorks.map(\.imageURL))
            await faces.loadMany(chrome.rail.works.flatMap { CanvasFace.imageURLs(for: $0) })
        }
        .sheet(item: $chrome.cover) { cover in
            RailCoverPane {
                coverView(cover)
            }
            .presentationDetents([.large])
            .presentationContentInteraction(.scrolls)
            .presentationCornerRadius(RailRadius.card)
            .presentationBackground(RailInk.surface)
            .presentationDragIndicator(.visible)
        }
    }

    private var bareBoard: some View {
        VStack(alignment: .leading, spacing: 0) {
            topChrome
            BarePage(
                art: RailArt.emptyHome,
                headline: chrome.recoveredNotice ? RailCopy.recoverHeadline : RailCopy.bareHeadline,
                line: chrome.recoveredNotice ? RailCopy.recoverLine : RailCopy.bareLine,
                actionTitle: RailCopy.explore
            ) {
                chrome.present(.explore)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var settledBoard: some View {
        VStack(alignment: .leading, spacing: 0) {
            topChrome
            VStack(alignment: .leading, spacing: RailSpace.card) {
                Image(RailArt.successMark)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
                Text(RailCopy.settledHeadline)
                    .font(RailType.font(.display, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                Text(RailCopy.settledLine)
                    .font(RailType.font(.body, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .fixedSize(horizontal: false, vertical: true)
                statusChip
                hookStrip
                dropStat
                spreadButton
                retractButton
            }
            .padding(.horizontal, RailSpace.outer)
            .padding(.bottom, RailSpace.outer)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var spreadBoard: some View {
        Group {
            if sizeClass == .regular {
                wideBoard
            } else {
                ScrollView {
                    compactBoard
                        .padding(.horizontal, RailSpace.outer)
                        .padding(.top, RailSpace.inner)
                        .padding(.bottom, RailSpace.outer)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .safeAreaInset(edge: .top, spacing: 0) {
            topChrome
                .background(RailInk.background)
        }
    }

    private var compactBoard: some View {
        VStack(alignment: .leading, spacing: RailSpace.card) {
            preface
            heroBlock
            hookButton
            nameplateRail
            companionRow
            hookStrip
            dropStat
            successMark
            retractButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var wideBoard: some View {
        GeometryReader { geo in
            let gutter = RailSpace.card
            let column = max((geo.size.width - gutter) / 2, 1)
            HStack(alignment: .top, spacing: gutter) {
                wallColumn
                    .frame(width: column, height: geo.size.height)
                VStack(alignment: .leading, spacing: RailSpace.card) {
                    railCue
                    heroCaptionBlock
                    preface
                    hookButton
                    nameplateRail
                    runBoard
                    retractButton
                }
                .frame(width: column, height: geo.size.height, alignment: .topLeading)
            }
        }
        .padding(.horizontal, RailSpace.outer)
        .padding(.top, RailSpace.inner)
        .padding(.bottom, RailSpace.outer)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var wallColumn: some View {
        VStack(alignment: .leading, spacing: RailSpace.card) {
            if let work = chrome.heroWork {
                let caption = chrome.rail.caption(for: work.id)
                canvasButton(
                    work: work,
                    caption: caption,
                    isHero: true,
                    isLifted: caption == .lifted,
                    fillsSlot: true,
                    showsCaption: false
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)
            }
            HStack(alignment: .top, spacing: RailSpace.card) {
                ForEach(chrome.companionWorks) { work in
                    let caption = chrome.rail.caption(for: work.id)
                    canvasButton(
                        work: work,
                        caption: caption,
                        isHero: false,
                        isLifted: caption == .lifted,
                        fillsSlot: true,
                        showsCaption: false
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var topChrome: some View {
        VStack(alignment: .leading, spacing: RailSpace.inner) {
            Text(RailCopy.appName)
                .font(RailType.font(.headline, size: typeSize))
                .foregroundStyle(RailInk.ink)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: RailSpace.inner) {
                iconButton("magnifyingglass", RailCopy.explore) { chrome.present(.explore) }
                iconButton("bookmark", RailCopy.saved) { chrome.present(.saved) }
                iconButton("gearshape", RailCopy.settings) { chrome.present(.settings) }
                iconButton("rectangle.on.rectangle", RailCopy.twist) { chrome.present(.twist) }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, RailSpace.outer)
        .padding(.top, RailSpace.inner)
        .padding(.bottom, RailSpace.inner)
    }

    private func iconButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .accessibilityHidden(true)
        }
        .buttonStyle(RailIconStyle())
        .accessibilityLabel(label)
    }

    private var railCue: some View {
        let plate = RoundedRectangle(cornerRadius: RailRadius.card, style: .continuous)
        return Image(RailArt.hookRail)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: RailSpace.step(7))
            .clipped()
            .background(RailInk.surface)
            .clipShape(plate)
            .accessibilityHidden(true)
    }

    private var heroCaptionBlock: some View {
        VStack(alignment: .leading, spacing: RailSpace.inner) {
            if let work = chrome.heroWork {
                Text(work.title)
                    .font(RailType.font(.headline, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(work.artist)
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(RailCopy.caption(chrome.rail.caption(for: work.id)))
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.muted)
            }
            HStack(spacing: RailSpace.inner) {
                ForEach(chrome.companionWorks) { work in
                    Text(RailCopy.caption(chrome.rail.caption(for: work.id)))
                        .font(RailType.font(.caption, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                        .padding(.horizontal, RailSpace.card)
                        .padding(.vertical, RailSpace.inner)
                        .background(RailInk.surface, in: Capsule())
                        .accessibilityLabel("\(work.title), \(RailCopy.caption(chrome.rail.caption(for: work.id)))")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var runBoard: some View {
        VStack(alignment: .leading, spacing: RailSpace.inner) {
            Text("This run")
                .font(RailType.font(.caption, size: typeSize))
                .foregroundStyle(RailInk.muted)
            Text(
                "\(RailCopy.fold(chrome.rail.fold)) rail. \(RailFigures.count(chrome.rail.settledWorks.count)) seated. \(RailFigures.count(chrome.rail.hookMarks.count)) hooks. \(RailFigures.count(chrome.rail.dropMarks.count)) drops."
            )
            .font(RailType.font(.body, size: typeSize))
            .foregroundStyle(RailInk.ink)
            .fixedSize(horizontal: false, vertical: true)
            hookStrip
            dropStat
            successMark
        }
        .padding(RailSpace.card)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RailInk.surface, in: RoundedRectangle(cornerRadius: RailRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "This run, \(RailCopy.fold(chrome.rail.fold)), \(RailFigures.count(chrome.rail.hookMarks.count)) hooks, \(RailFigures.count(chrome.rail.dropMarks.count)) drops"
        )
    }

    private var preface: some View {
        VStack(alignment: .leading, spacing: RailSpace.inner) {
            Text(RailCopy.hookTitle)
                .font(RailType.font(.display, size: typeSize))
                .foregroundStyle(RailInk.ink)
                .lineLimit(typeSize.isAccessibilitySize ? 3 : 2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            Text(
                RailCopy.railJob(
                    work: chrome.heroWork,
                    lifted: chrome.rail.liftedWorkID != nil,
                    field: chrome.rail.cartelField
                )
            )
            .font(RailType.font(.body, size: typeSize))
            .foregroundStyle(RailInk.muted)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            chips
            if let fault = chrome.railFault, !fault.isEmpty {
                Text(fault)
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if chrome.recoveredNotice {
                Text(RailCopy.recoverHeadline)
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chips: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: RailSpace.card) {
                statusChip
                fieldChip
            }
            VStack(alignment: .leading, spacing: RailSpace.inner) {
                statusChip
                fieldChip
            }
        }
    }

    @ViewBuilder
    private var fieldChip: some View {
        if let field = chrome.rail.cartelField {
            Text(RailCopy.field(field))
                .font(RailType.font(.caption, size: typeSize))
                .foregroundStyle(RailInk.muted)
                .padding(.horizontal, RailSpace.card)
                .padding(.vertical, RailSpace.inner)
                .background(RailInk.surface, in: Capsule())
        }
    }

    private var statusChip: some View {
        Text(RailCopy.fold(chrome.rail.fold))
            .font(RailType.font(.caption, size: typeSize))
            .foregroundStyle(RailInk.surface)
            .padding(.horizontal, RailSpace.card)
            .padding(.vertical, RailSpace.inner)
            .background(RailInk.ink, in: Capsule())
            .accessibilityLabel(RailCopy.fold(chrome.rail.fold))
    }

    @ViewBuilder
    private var heroBlock: some View {
        if let work = chrome.heroWork {
            let caption = chrome.rail.caption(for: work.id)
            let lifted = caption == .lifted
            canvasButton(work: work, caption: caption, isHero: true, isLifted: lifted)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .clipped()
        }
    }

    private var companionRow: some View {
        HStack(alignment: .top, spacing: RailSpace.card) {
            ForEach(chrome.companionWorks) { work in
                let caption = chrome.rail.caption(for: work.id)
                canvasButton(work: work, caption: caption, isHero: false, isLifted: caption == .lifted)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func canvasButton(
        work: Work,
        caption: CanvasCaption,
        isHero: Bool,
        isLifted: Bool,
        fillsSlot: Bool = false,
        showsCaption: Bool = true
    ) -> some View {
        let tile = CanvasTile(
            work: work,
            caption: caption,
            isHero: isHero,
            isLifted: isLifted,
            face: faces.picture(for: work),
            fillsSlot: fillsSlot,
            showsCaption: showsCaption
        )
        Button {
            Task { await tapCanvas(work) }
        } label: {
            tile
        }
        .buttonStyle(LiftTileStyle())
        .disabled(chrome.liftBusy != nil && work.seat.isWaiting)
        .task(id: work.objectID) {
            await faces.loadWork(work)
        }
        .accessibilityLabel("\(work.title), \(work.artist), \(RailCopy.caption(caption))")
        .accessibilityHint(canvasHint(for: work))
    }

    private func canvasHint(for work: Work) -> String {
        if work.seat.isWaiting { return "Lift this waiting canvas" }
        if work.seat.isHooked { return "Open Saved to review this hook" }
        return "This canvas is on the rail"
    }

    private func tapCanvas(_ work: Work) async {
        if work.seat.isWaiting {
            await chrome.liftWork(work.id)
            return
        }
        if work.seat.isHooked || work.seat.isSettled {
            chrome.present(.saved)
        }
    }

    private var hookButton: some View {
        Button(RailCopy.hookAction) {
            Task { await chrome.hookPrimary() }
        }
        .buttonStyle(SpreadPillStyle(isLoading: chrome.hookBusy != nil))
        .disabled(!chrome.primaryHookEnabled)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(RailCopy.hookAction)
        .accessibilityHint("Hang the painting under the title that names it")
    }

    private var nameplateRail: some View {
        VStack(alignment: .leading, spacing: RailSpace.inner) {
            Text(RailCopy.plateReady)
                .font(RailType.font(.caption, size: typeSize))
                .foregroundStyle(RailInk.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(chrome.rail.planted.enumerated()), id: \.element.id) { index, peg in
                let seated = chrome.work(for: peg)?.seat.isHooked == true
                    || chrome.work(for: peg)?.seat.isSettled == true
                Button {
                    Task { await chrome.hookRampin(peg.id) }
                } label: {
                    HStack(alignment: .center, spacing: RailSpace.card) {
                        Image(RailArt.cartelPlate)
                            .resizable()
                            .scaledToFit()
                            .frame(width: seated ? RailSpace.step(4) : RailSpace.step(5), height: seated ? RailSpace.step(4) : RailSpace.step(5))
                            .clipped()
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: RailSpace.gap) {
                            Text(peg.cartel.text)
                                .font(RailType.font(index == 0 && !seated ? .title : .headline, size: typeSize))
                                .strikethrough(peg.isStruck, color: RailInk.muted)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(RailCopy.plateLine(seated: seated, struck: peg.isStruck))
                                .font(RailType.font(.caption, size: typeSize))
                                .foregroundStyle(RailInk.muted)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(
                    HookPlateStyle(
                        isSelected: seated,
                        isError: peg.isStruck
                    )
                )
                .disabled(!chrome.primaryHookEnabled)
                .accessibilityLabel(peg.cartel.text)
                .accessibilityHint(peg.isStruck ? "Missed seat. Dimmed and struck." : "Seat the lifted canvas here")
                .accessibilityAddTraits(seated ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hookStrip: some View {
        VStack(alignment: .leading, spacing: RailSpace.inner) {
            Text("Recent hooks")
                .font(RailType.font(.caption, size: typeSize))
                .foregroundStyle(RailInk.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: RailSpace.inner) {
                    ForEach(chrome.recentHooks) { mark in
                        VStack(alignment: .leading, spacing: RailSpace.gap) {
                            Text(mark.cartelText)
                                .font(RailType.font(.caption, size: typeSize))
                                .foregroundStyle(RailInk.ink)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(RailFigures.dayLabel(mark.daykey))
                                .font(RailType.font(.micro, size: typeSize))
                                .foregroundStyle(RailInk.muted)
                                .monospacedDigit()
                        }
                        .padding(RailSpace.card)
                        .frame(minWidth: RailSpace.step(14), minHeight: RailSpace.hit, alignment: .leading)
                        .background(RailInk.surface, in: RoundedRectangle(cornerRadius: RailRadius.chip, style: .continuous))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Recent hooks, \(RailFigures.count(chrome.rail.hookMarks.count))")
    }

    private var dropStat: some View {
        VStack(alignment: .leading, spacing: RailSpace.gap) {
            Text(RailFigures.count(chrome.rail.dropMarks.count))
                .font(RailType.font(.title, size: typeSize))
                .foregroundStyle(RailInk.ink)
                .monospacedDigit()
            Text("Drops on Saved")
                .font(RailType.font(.caption, size: typeSize))
                .foregroundStyle(RailInk.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(RailSpace.card)
        .frame(maxWidth: .infinity, minHeight: RailSpace.hit, alignment: .leading)
        .background(RailInk.surface, in: RoundedRectangle(cornerRadius: RailRadius.chip, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Drops, \(RailFigures.count(chrome.rail.dropMarks.count))")
    }

    @ViewBuilder
    private var successMark: some View {
        if chrome.showSuccess {
            Image(RailArt.successMark)
                .resizable()
                .scaledToFit()
                .frame(height: RailSpace.step(8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
                .accessibilityLabel("Hook seated")
        }
    }

    private var spreadButton: some View {
        Button(chrome.rail.fold == .settled ? RailCopy.spreadNext : RailCopy.spread) {
            Task { await chrome.spreadRail() }
        }
        .buttonStyle(SpreadPillStyle(isLoading: chrome.spreadBusy))
        .disabled(!chrome.spreadEnabled)
        .accessibilityLabel(chrome.rail.fold == .settled ? RailCopy.spreadNext : RailCopy.spread)
    }

    private var retractButton: some View {
        Button(RailCopy.retract) {
            Task { await chrome.retractNewestMark() }
        }
        .buttonStyle(RetractRailStyle())
        .disabled(!chrome.retractEnabled)
        .accessibilityLabel(RailCopy.retract)
    }

    @ViewBuilder
    private func coverView(_ cover: RailCover) -> some View {
        switch cover {
        case .explore:
            ExploreView(chrome: chrome)
        case .saved:
            SavedView(chrome: chrome)
        case .settings:
            SettingsView(chrome: chrome)
        case .twist:
            TwistSheet(chrome: chrome)
        }
    }
}
