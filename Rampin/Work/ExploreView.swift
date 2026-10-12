import SwiftUI

/// Role: Work. Explore sheet. Philadelphia Museum of Art search plus the local PMA shelf. Empty, populated, and error.
struct ExploreView: View {
    @Bindable var chrome: RailChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var cut: ShelfCut = .all
    @State private var order: ShelfOrder = .shelf
    @State private var study: CatalogRow?

    var body: some View {
        NavigationStack {
            Group {
                if chrome.exploreIsEmpty {
                    BarePage(
                        art: RailArt.emptyList,
                        headline: RailCopy.exploreHeadline,
                        line: RailCopy.exploreLine,
                        actionTitle: "Search"
                    ) {
                        chrome.query = "eakins"
                        chrome.scheduleSeek()
                    }
                } else {
                    populated
                }
            }
            .background(RailInk.background.ignoresSafeArea())
            .navigationTitle(RailCopy.explore)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(RailIconStyle())
                    .accessibilityLabel("Close Explore")
                }
            }
        }
        .task {
            if chrome.seekHits.isEmpty {
                chrome.scheduleSeek()
            }
            await CanvasFace.shared.loadMany(chrome.seekHits.flatMap { CanvasFace.imageURLs(for: $0) })
        }
        .onChange(of: chrome.query) { _, _ in
            chrome.scheduleSeek()
        }
        .sheet(item: $study) { row in
            StudySheet(chrome: chrome, row: row)
                .presentationDetents([.large])
                .presentationCornerRadius(RailRadius.card)
                .presentationBackground(RailInk.surface)
                .presentationDragIndicator(.visible)
        }
    }

    private var visibleRows: [CatalogRow] {
        let saved = Set(chrome.rail.works.map(\.objectID))
        return ShelfQuery.apply(rows: chrome.seekHits, cut: cut, order: order, saved: saved)
    }

    private var populated: some View {
        List {
            if chrome.rail.readyToSpread {
                Section {
                    VStack(alignment: .leading, spacing: RailSpace.inner) {
                        Text(RailCopy.waitingHeadline(chrome.rail.waitingWorks.count))
                            .font(RailType.font(.headline, size: typeSize))
                            .foregroundStyle(RailInk.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(chrome.rail.fold == .settled ? RailCopy.settledLine : RailCopy.readyLine)
                            .font(RailType.font(.caption, size: typeSize))
                            .foregroundStyle(RailInk.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(chrome.rail.fold == .settled ? RailCopy.spreadNext : RailCopy.spread) {
                            dismiss()
                            Task { await chrome.spreadRail() }
                        }
                        .buttonStyle(SpreadPillStyle(isLoading: chrome.spreadBusy))
                        .disabled(!chrome.spreadEnabled)
                        if chrome.rail.canSpreadMisses {
                            Text(RailCopy.missesLine)
                                .font(RailType.font(.caption, size: typeSize))
                                .foregroundStyle(RailInk.muted)
                                .fixedSize(horizontal: false, vertical: true)
                            Button(RailCopy.spreadMisses) {
                                dismiss()
                                Task { await chrome.spreadRail(misses: true) }
                            }
                            .buttonStyle(RetractRailStyle())
                            .disabled(!chrome.spreadEnabled)
                        }
                    }
                    .padding(.vertical, RailSpace.inner)
                    .listRowBackground(RailInk.surface)
                }
            }
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RailSpace.inner) {
                        ForEach(ShelfCut.allCases) { item in
                            Button(item.title) {
                                cut = item
                            }
                            .buttonStyle(ChipPickStyle(isSelected: cut == item))
                            .accessibilityAddTraits(cut == item ? .isSelected : [])
                        }
                        Button(order.title) {
                            order = order.next
                        }
                        .buttonStyle(ChipPickStyle(isSelected: order != .shelf))
                        .accessibilityLabel(order.title)
                    }
                    .padding(.vertical, RailSpace.gap)
                }
                TextField("Maker or title", text: $chrome.query)
                    .font(RailType.font(.body, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .accessibilityLabel("Search the museum")
            }
            if let fault = chrome.seekFault, !fault.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: RailSpace.inner) {
                        Text(fault)
                            .font(RailType.font(.body, size: typeSize))
                            .foregroundStyle(RailInk.ink)
                        Button("Try again") {
                            chrome.scheduleSeek()
                        }
                        .buttonStyle(RetractRailStyle())
                    }
                    .listRowBackground(RailInk.surface)
                }
            }
            if chrome.isSeeking {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: RailSpace.hit)
                        .listRowBackground(RailInk.surface)
                }
            }
            if let note = chrome.crateNote {
                Section {
                    Text(note)
                        .font(RailType.font(.caption, size: typeSize))
                        .foregroundStyle(RailInk.muted)
                        .listRowBackground(RailInk.surface)
                }
            }
            if visibleRows.isEmpty && !chrome.seekHits.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: RailSpace.inner) {
                        Text(RailCopy.filterEmpty)
                            .font(RailType.font(.body, size: typeSize))
                            .foregroundStyle(RailInk.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(RailCopy.showAll) {
                            cut = .all
                        }
                        .buttonStyle(RetractRailStyle())
                    }
                    .listRowBackground(RailInk.surface)
                }
            }
            Section {
                ForEach(visibleRows) { row in
                    rowCard(row)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(RailInk.background)
    }

    private func rowCard(_ row: CatalogRow) -> some View {
        let focused = chrome.rail.focusedWorkID.flatMap { id in
            chrome.rail.works.first { $0.id == id && $0.objectID == row.objectID }
        } != nil
        let already = chrome.rail.works.contains { $0.objectID == row.objectID }
        return HStack(alignment: .center, spacing: RailSpace.card) {
            Color.clear
                .frame(width: RailSpace.step(8), height: RailSpace.step(8))
                .overlay {
                    ZStack {
                        RailInk.surface
                        if let face = CanvasFace.shared.picture(for: row) {
                            face
                                .resizable()
                                .scaledToFill()
                        } else {
                            CanvasThumb(title: row.title)
                        }
                    }
                    .clipped()
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: RailRadius.chip, style: .continuous))
                .task {
                    await CanvasFace.shared.loadMany(CanvasFace.imageURLs(for: row))
                }
            VStack(alignment: .leading, spacing: RailSpace.gap) {
                Text(row.title)
                    .font(RailType.font(.headline, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .lineLimit(2)
                Text(row.artist)
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.muted)
                    .lineLimit(1)
                if let dated = row.dated, !dated.isEmpty {
                    Text(dated)
                        .font(RailType.font(.micro, size: typeSize))
                        .foregroundStyle(RailInk.muted)
                        .monospacedDigit()
                }
                if let note = studyLine(for: row) {
                    Text(note)
                        .font(RailType.font(.caption, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                }
                Button(RailCopy.study) {
                    study = row
                }
                .buttonStyle(.plain)
                .font(RailType.font(.headline, size: typeSize))
                .foregroundStyle(RailInk.accent)
                .frame(minHeight: RailSpace.hit, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityLabel("Study \(row.title)")
                if already {
                    Text(focused ? RailCopy.focusedNote : "On the rail")
                        .font(RailType.font(.micro, size: typeSize))
                        .foregroundStyle(RailInk.ink)
                }
            }
            Spacer(minLength: 0)
            Button(already ? "Keep" : "Save") {
                Task { await chrome.fileWork(row) }
            }
            .buttonStyle(SpreadPillStyle(isLoading: chrome.stockingObjectID == row.objectID))
            .frame(maxWidth: RailSpace.step(12))
            .disabled(chrome.stockingObjectID != nil)
            .accessibilityLabel(already ? "Keep this work on the rail" : "Save this work")
        }
        .padding(.vertical, RailSpace.inner)
        .listRowBackground(focused ? RailInk.muted.opacity(0.12) : RailInk.surface)
        .listRowInsets(EdgeInsets(
            top: RailSpace.inner,
            leading: RailSpace.outer,
            bottom: RailSpace.inner,
            trailing: RailSpace.outer
        ))
        .accessibilityElement(children: .contain)
    }

    private func studyLine(for row: CatalogRow) -> String? {
        row.studyNote ?? PmaShelf.note(for: row.objectID)
    }
}

