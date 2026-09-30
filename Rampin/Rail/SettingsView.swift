import SwiftUI

/// Role: Rail. Settings sheet. Philadelphia Museum of Art credit, Retract, contact, replay, reset. Empty, populated, and error.
struct SettingsView: View {
    @Bindable var chrome: RailChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Group {
                if chrome.settingsIsEmpty {
                    emptyBoard
                } else {
                    populated
                }
            }
            .background(RailInk.background.ignoresSafeArea())
            .navigationTitle(RailCopy.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(RailIconStyle())
                    .accessibilityLabel("Close Settings")
                }
            }
            .confirmationDialog(RailCopy.resetTitle, isPresented: $confirmReset, titleVisibility: .visible) {
                Button(RailCopy.reset, role: .destructive) {
                    Task { await chrome.resetAllData() }
                }
                Button("Keep the rail", role: .cancel) {}
            } message: {
                Text(RailCopy.resetLine)
            }
        }
    }

    private var emptyBoard: some View {
        VStack(alignment: .leading, spacing: 0) {
            BarePage(
                art: RailArt.emptyList,
                headline: chrome.store.lastWriteError != nil ? RailCopy.writeFailed : RailCopy.settingsHeadline,
                line: chrome.store.lastWriteError != nil
                    ? "Credit and contact still live below."
                    : RailCopy.settingsLine,
                actionTitle: RailCopy.explore
            ) {
                chrome.present(.explore)
            }
            formStack
        }
    }

    private var populated: some View {
        Form {
            formSections
        }
        .scrollContentBackground(.hidden)
        .background(RailInk.background)
        .safeAreaInset(edge: .bottom, spacing: RailSpace.outer) {
            eraseBar
        }
    }

    private var formStack: some View {
        Form {
            formSections
        }
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom, spacing: RailSpace.outer) {
            eraseBar
        }
    }

    private var eraseBar: some View {
        Button(RailCopy.reset) {
            confirmReset = true
        }
        .buttonStyle(ResetRailStyle())
        .padding(.horizontal, RailSpace.outer)
        .padding(.top, RailSpace.outer)
        .padding(.bottom, RailSpace.step(4))
        .frame(maxWidth: .infinity)
        .background(RailInk.background)
        .accessibilityLabel(RailCopy.reset)
    }

    @ViewBuilder
    private var formSections: some View {
        Section("Museum") {
            Button(RailCopy.museum) {
                openURL(CatalogClient.pmaHomeURL)
            }
            .font(RailType.font(.body, size: typeSize))
            .foregroundStyle(RailInk.ink)
            .railHit()
            Button(RailCopy.openAccess) {
                openURL(CatalogClient.pmaOpenAccessURL)
            }
            .font(RailType.font(.body, size: typeSize))
            .foregroundStyle(RailInk.ink)
            .railHit()
        }
        Section("Rail") {
            Button(RailCopy.retract) {
                Task { await chrome.retractNewestMark() }
            }
            .font(RailType.font(.body, size: typeSize))
            .foregroundStyle(chrome.retractEnabled ? RailInk.ink : RailInk.muted)
            .railHit()
            .disabled(!chrome.retractEnabled)
            if let fault = chrome.railFault, !fault.isEmpty {
                Text(fault)
                    .font(RailType.font(.caption, size: typeSize))
                    .foregroundStyle(RailInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        Section("Help") {
            Button(RailCopy.contact) {
                openURL(CatalogClient.contactURL)
            }
            .font(RailType.font(.body, size: typeSize))
            .foregroundStyle(RailInk.ink)
            .railHit()
            Button(RailCopy.replay) {
                chrome.replayOnboarding()
            }
            .font(RailType.font(.body, size: typeSize))
            .foregroundStyle(RailInk.ink)
            .railHit()
        }
    }
}
