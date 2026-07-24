import SwiftUI

/// Settings view for API configuration and app information.
struct SettingsView: View {

    @ObservedObject var viewModel: SettingsViewModel
    @State private var showAPIKey = false
    @State private var isTestingConnection = false

    // MARK: - App Storage
    @AppStorage("appLanguage") private var appLanguage: String = "zh-Hans"
    @AppStorage("aiPersona") private var aiPersona: String = "catgirl"

    // MARK: - Theme

    private let gradientStart = Color(red: 0.04, green: 0.086, blue: 0.157)
    private let gradientEnd = Color(red: 0.102, green: 0.04, blue: 0.18)
    private let accentCyan = Color(red: 0.0, green: 0.87, blue: 0.87)

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        githubSection
                        generalConfigSection
                        apiConfigSection
                        aboutSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - GitHub Section

    private var githubSection: some View {
        Link(destination: URL(string: "https://github.com/Nomelonah")!) {
            HStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nomelonah's GitHub")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(LocalizedStringKey("球球你给个Star吧"))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - General Configuration Section

    private var generalConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "globe", title: "通用", color: .blue)
            
            // Language Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("语言")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Picker("语言", selection: $appLanguage) {
                    Text("简体中文").tag("zh-Hans")
                    Text("English").tag("en")
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // AI Persona Picker
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey("AI 人设"))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Picker("AI 人设", selection: $aiPersona) {
                    Text(LocalizedStringKey("香软可爱的小猫娘")).tag("cutecatgirl")
                    Text(LocalizedStringKey("毒舌管家")).tag("butler")
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - API Configuration Section

    private var apiConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "key.fill", title: "API 配置", color: accentCyan)

            // API Key
            VStack(alignment: .leading, spacing: 6) {
                Text("API Key")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                HStack(spacing: 12) {
                    Group {
                        if showAPIKey {
                            TextField("输入 DeepSeek API Key", text: $viewModel.apiKey)
                        } else {
                            SecureField("输入 DeepSeek API Key", text: $viewModel.apiKey)
                        }
                    }
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                    Button(action: { showAPIKey.toggle() }) {
                        Image(systemName: showAPIKey ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 18))
                            .foregroundColor(accentCyan.opacity(0.7))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentCyan.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            // Base URL
            VStack(alignment: .leading, spacing: 6) {
                Text("Base URL")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                TextField("https://api.deepseek.com", text: $viewModel.baseURL)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }

            // Model Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Model Name")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                TextField("deepseek-chat", text: $viewModel.modelName)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }

            // Action buttons
            HStack(spacing: 12) {
                // Save button
                Button(action: { viewModel.saveSettings() }) {
                    HStack(spacing: 8) {
                        if viewModel.isSaved {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "square.and.arrow.down.fill")
                        }

                        Text(viewModel.isSaved ? "已保存" : "保存设置")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                    }
                    .foregroundColor(viewModel.isSaved ? .green : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.isSaved ? Color.green.opacity(0.2) : accentCyan)
                    )
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isSaved)

                // Test connection button
                Button(action: {
                    Task {
                        isTestingConnection = true
                        _ = await viewModel.testConnection()
                        isTestingConnection = false
                    }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isTesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: accentCyan))
                                .scaleEffect(0.8)
                        } else if let result = viewModel.testResult {
                            Image(systemName: testResultIcon(result))
                                .foregroundColor(testResultColor(result))
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }

                        Text(testButtonText)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                    }
                    .foregroundColor(accentCyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentCyan.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentCyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .disabled(viewModel.isTesting || viewModel.apiKey.isEmpty)
                .opacity(viewModel.apiKey.isEmpty ? 0.4 : 1.0)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "info.circle.fill", title: "关于", color: .purple)

            VStack(spacing: 14) {
                aboutRow(icon: "app.badge.fill", label: "应用名称", value: "SuperAlarm")
                Divider().background(Color.white.opacity(0.1))
                aboutRow(icon: "number", label: "版本", value: "1.0 ")
                Divider().background(Color.white.opacity(0.1))
                aboutRow(icon: "swift", label: "框架", value: "Swift")
                Divider().background(Color.white.opacity(0.1))

                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.purple.opacity(0.8))
                        .frame(width: 28)

                    Text("Author：Watermelon")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()
                }

                Divider().background(Color.white.opacity(0.1))

                HStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentCyan.opacity(0.8))
                        .frame(width: 28)

                    Text("Made in China")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)

            Text(LocalizedStringKey(title))
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private func aboutRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 28)

            Text(LocalizedStringKey(label))
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            Spacer()

            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var testButtonText: String {
        if viewModel.isTesting { return "测试中" }
        if let result = viewModel.testResult {
            switch result {
            case .success: return "连接成功"
            case .failure: return "连接失败"
            }
        }
        return "测试连接"
    }

    private func testResultIcon(_ result: SettingsViewModel.TestResult) -> String {
        switch result {
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        }
    }

    private func testResultColor(_ result: SettingsViewModel.TestResult) -> Color {
        switch result {
        case .success: return .green
        case .failure: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(viewModel: SettingsViewModel())
        .preferredColorScheme(.dark)
}
