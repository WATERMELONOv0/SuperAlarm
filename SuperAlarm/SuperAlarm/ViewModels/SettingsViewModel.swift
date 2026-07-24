import Foundation
import Combine

/// ViewModel for managing API configuration settings (DeepSeek AI integration).
/// API key is stored securely in Keychain; other settings in UserDefaults.
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var apiKey: String = ""
    @Published var baseURL: String = "https://api.deepseek.com"
    @Published var modelName: String = "deepseek-chat"
    @Published var isSaved: Bool = false
    @Published var isTesting: Bool = false
    @Published var testResult: TestResult?

    enum TestResult {
        case success
        case failure(String)
    }

    // MARK: - Keys

    private let baseURLDefaultsKey = "superalarm.baseURL"
    private let modelNameDefaultsKey = "superalarm.modelName"

    // MARK: - Init

    init() {
        loadSettings()
    }

    // MARK: - Settings Management

    /// Load settings from Keychain (API key) and UserDefaults (base URL, model name).
    func loadSettings() {
        if let savedKey = KeychainService.loadAPIKey() {
            apiKey = savedKey
        }
        if let savedURL = UserDefaults.standard.string(forKey: baseURLDefaultsKey) {
            baseURL = savedURL
        }
        if let savedModel = UserDefaults.standard.string(forKey: modelNameDefaultsKey) {
            modelName = savedModel
        }
    }

    /// Save settings to their respective stores with confirmation animation.
    func saveSettings() {
        // Save API key to Keychain (using same key AIService reads)
        KeychainService.saveAPIKey(apiKey)

        // Save base URL to both Keychain (for AIService) and UserDefaults (for UI)
        if baseURL != "https://api.deepseek.com" {
            KeychainService.saveBaseURL(baseURL)
        }
        UserDefaults.standard.set(baseURL, forKey: baseURLDefaultsKey)
        UserDefaults.standard.set(modelName, forKey: modelNameDefaultsKey)

        // Show save confirmation
        isSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isSaved = false
        }
    }

    /// Test the API connection with a simple request.
    func testConnection() async -> Bool {
        isTesting = true
        testResult = nil

        do {
            let service = AIService()
            let testSchedule = [ScheduleItem(title: "测试连接")]
            let response = await service.generateWakeUpMessage(schedule: testSchedule)

            let isSuccess = !response.contains("Connect Failed") && !response.contains("连接失败") && !response.isEmpty
            testResult = isSuccess ? .success : .failure("API 返回异常")
            isTesting = false
            return isSuccess
        }
    }
}
