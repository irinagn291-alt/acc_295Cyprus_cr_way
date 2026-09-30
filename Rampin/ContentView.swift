import SwiftUI
import UIKit

/// Role: Rail. Root shell. Onboarding cover, then the locked Quiz rail. ReviewScreen is applied after onboarding.
struct ContentView: View {
    @State private var chrome: RailChrome
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(chrome: RailChrome = RailChrome.live()) {
        _chrome = State(wrappedValue: chrome)
    }

    var body: some View {
        ZStack {
            RailInk.background.ignoresSafeArea()
            if chrome.isBooting {
                Image(RailArt.splash)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            } else if chrome.showsOnboarding {
                OnboardingCover(
                    onSkip: { Task { await chrome.finishOnboarding() } },
                    onFinish: { Task { await chrome.finishOnboarding() } }
                )
            } else {
                QuizView(chrome: chrome)
            }
        }
        .preferredColorScheme(.light)
        .tint(RailInk.accent)
        .animation(RailMotion.swap(reduceMotion), value: chrome.showsOnboarding)
        .animation(RailMotion.swap(reduceMotion), value: chrome.isBooting)
        .task { await chrome.boot() }
        .task {
            for await notice in NotificationCenter.default.notifications(named: .railJob) {
                if let job = RailJob.parse(notification: notice) {
                    chrome.handle(job)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            Task { await chrome.handle(phase: phase) }
        }
        .onOpenURL { chrome.handle(url: $0) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            chrome.refreshDay()
        }
    }
}

#Preview {
    ContentView()
}
