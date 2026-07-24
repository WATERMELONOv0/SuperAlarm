import SwiftUI
import UserNotifications
import AVFoundation

// MARK: - App Entry Point

@main
struct SuperAlarmApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var alarmViewModel = AlarmViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @AppStorage("appLanguage") private var appLanguage: String = "zh-Hans"

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(alarmViewModel)
                .environmentObject(settingsViewModel)
                .preferredColorScheme(.dark)
                .environment(\.locale, Locale(identifier: appLanguage))
                .onAppear {
                    // Share alarm view model with delegate for notification handling
                    appDelegate.alarmViewModel = alarmViewModel
                }
        }
    }

    /// Configure global navigation bar and tab bar appearance for the dark theme.
    private func configureAppearance() {
        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance

        // Tab bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = UIColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 0.95)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

// MARK: - App Delegate

/// Handles notification delegation and alarm action responses.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var alarmViewModel: AlarmViewModel?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Configure audio session for alarm playback
        AlarmManager.shared.configureAudioSession()

        // Request notification permissions
        AlarmManager.shared.requestPermission()

        // Register notification actions
        registerNotificationActions()

        return true
    }

    /// Register SNOOZE and WAKE notification actions.
    private func registerNotificationActions() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "再睡一会 💤",
            options: []
        )

        let wakeAction = UNNotificationAction(
            identifier: "WAKE_ACTION",
            title: "我醒了 ☀️",
            options: [.foreground]
        )

        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [wakeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notifications received while app is in foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let alarmIdString = notification.request.content.userInfo["alarmId"] as? String ?? ""

        if let alarmId = UUID(uuidString: alarmIdString) {
            Task { @MainActor in
                if let viewModel = self.alarmViewModel, viewModel.isRecentlyHandled(id: alarmId) {
                    completionHandler([])
                    return
                }
                
                self.alarmViewModel?.triggerAlarm(id: alarmId)
                completionHandler([.banner, .sound, .badge])
            }
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }

    /// Handle notification action responses (SNOOZE or WAKE).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let alarmIdString = response.notification.request.content.userInfo["alarmId"] as? String ?? ""

        Task { @MainActor in
            guard let alarmId = UUID(uuidString: alarmIdString) else {
                completionHandler()
                return
            }

            // Ensure alarm is shown as firing
            alarmViewModel?.triggerAlarm(id: alarmId)

            switch response.actionIdentifier {
            case "SNOOZE_ACTION":
                alarmViewModel?.handleSnooze()

            case "WAKE_ACTION":
                alarmViewModel?.handleWakeUp()

            case UNNotificationDefaultActionIdentifier:
                // 用户点击通知本体进入App，只弹出叫醒全屏界面，不直接算作已起床
                break

            case UNNotificationDismissActionIdentifier:
                // User dismissed — treat as snooze
                alarmViewModel?.handleSnooze()

            default:
                break
            }

            completionHandler()
        }
    }
}
