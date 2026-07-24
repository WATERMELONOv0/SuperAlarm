import SwiftUI

// MARK: - Animated Tab Icon
struct AnimatedTabIcon: View {
    let systemName: String
    let isSelected: Bool
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
            .symbolEffect(.bounce, value: isSelected)
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var alarmViewModel: AlarmViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                AlarmListView()
                    .environmentObject(alarmViewModel)
                    .toolbar(.hidden, for: .tabBar)
                    .tag(0)
                
                ScheduleView(viewModel: alarmViewModel)
                    .toolbar(.hidden, for: .tabBar)
                    .tag(1)
                
                SettingsView(viewModel: settingsViewModel)
                    .toolbar(.hidden, for: .tabBar)
                    .tag(2)
            }
            
            // Custom glassmorphism tab bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        // 闹钟响起全屏覆盖
        .fullScreenCover(isPresented: $alarmViewModel.showFiringView) {
            if let alarm = alarmViewModel.firingAlarm {
                AlarmFiringView(
                    onWakeUp: {
                        alarmViewModel.handleWakeUp()
                    },
                    onSnooze: {
                        alarmViewModel.handleSnooze()
                    },
                    currentSnoozeCount: Binding(
                        get: { alarm.currentSnoozeCount },
                        set: { _ in }
                    ),
                    maxSnooze: Binding(
                        get: { alarm.maxSnooze },
                        set: { _ in }
                    ),
                    isSnoozeExhausted: $alarmViewModel.isSnoozeExhausted
                )
            }
        }
        // AI 日程话术展示
        .sheet(isPresented: $alarmViewModel.showAIResponse) {
            AIResponseView(
                aiResponse: alarmViewModel.aiResponse,
                isLoading: alarmViewModel.isLoadingAI,
                schedule: alarmViewModel.schedule,
                onDismiss: {
                    alarmViewModel.showAIResponse = false
                }
            )
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "alarm.fill", label: "闹钟", tag: 0)
            tabBarItem(icon: "calendar", label: "日程", tag: 1)
            tabBarItem(icon: "gearshape.fill", label: "设置", tag: 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "0A1628").opacity(0.7),
                                Color(hex: "1A0A2E").opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, y: -5)
        .padding(.horizontal, 12)
    }
    
    private func tabBarItem(icon: String, label: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 6) {
                AnimatedTabIcon(systemName: icon, isSelected: selectedTab == tag)
                
                Text(LocalizedStringKey(label))
                    .font(.system(size: 11, weight: selectedTab == tag ? .semibold : .regular))
            }
            .foregroundStyle(
                selectedTab == tag
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(Color.white.opacity(0.4))
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    MainTabView()
        .environmentObject(AlarmViewModel())
        .environmentObject(SettingsViewModel())
        .preferredColorScheme(.dark)
}
