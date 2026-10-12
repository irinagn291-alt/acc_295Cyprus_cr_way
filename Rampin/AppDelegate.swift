import UIKit
import Alamofire
import AppsFlyerLib
import AppTrackingTransparency

final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let bind = "com.rampin.hook"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = Self.bind
        APIConfig.apply()
        AppsFlyerLib.shared().appsFlyerDevKey = "7xhhxuKXMRtCahwhPCLMSX"
        AppsFlyerLib.shared().appleAppID = "6817544639"
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
        return true
    }

    @objc private func applicationDidBecomeActive() {
        AppsFlyerLib.shared().start()
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        ATTrackingManager.requestTrackingAuthorization { @Sendable _ in }
    }
}
