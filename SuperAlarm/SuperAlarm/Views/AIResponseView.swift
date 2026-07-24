import SwiftUI

/// Full-screen AI wake-up briefing with typewriter text animation and schedule cards.
struct AIResponseView: View {

    let aiResponse: String
    var isLoading: Bool = false
    let schedule: [ScheduleItem]
    var onDismiss: () -> Void

    @State private var displayedCharacterCount: Int = 0
    @State private var isAnimating: Bool = true

    // MARK: - Theme

    private let gradientStart = Color(red: 0.04, green: 0.086, blue: 0.157) // #0A1628
    private let gradientEnd = Color(red: 0.102, green: 0.04, blue: 0.18)    // #1A0A2E
    private let accentCyan = Color(red: 0.0, green: 0.87, blue: 0.87)

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [gradientStart, gradientEnd, gradientStart.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow particles
            GeometryReader { geo in
                Circle()
                    .fill(accentCyan.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.1)

                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.6)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // AI Response
                    aiResponseSection

                    // Schedule Cards
                    scheduleSection

                    // Dismiss button
                    dismissButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startTypewriterAnimation()
        }
        .onChange(of: aiResponse) { _, newValue in
            if !newValue.isEmpty {
                startTypewriterAnimation()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .orange.opacity(0.4), radius: 20)

            Text("好啊看看今天的行程吧")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.bottom, 8)
    }

    // MARK: - AI Response

    private var aiResponseSection: some View {
        Group {
            if isLoading || aiResponse.isEmpty {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentCyan))
                        .scaleEffect(1.2)

                    Text("AI 正在准备今日简报...")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            } else {
                // Typewriter text
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(accentCyan)
                            .font(.system(size: 18, weight: .semibold))

                        Text("AI 管家说")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(accentCyan)
                    }

                    Text(typewriterText)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(accentCyan.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Schedule Cards

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日日程")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.leading, 4)

            ForEach(Array(schedule.enumerated()), id: \.element.id) { index, item in
                scheduleCard(item: item, index: index)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
    }

    private func scheduleCard(item: ScheduleItem, index: Int) -> some View {
        HStack(spacing: 16) {
            // Time-based icon
            let icon = iconForTime(date: item.date)
            let color = colorForTime(date: item.date)
            
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)

                Text(item.timeString)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Time slot tag
            Text(item.timeString)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(color.opacity(0.15))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: schedule.count)
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button(action: onDismiss) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))

                Text("知道了，开始新的一天")
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [accentCyan, accentCyan.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: accentCyan.opacity(0.3), radius: 12, y: 4)
        }
        .padding(.top, 8)
    }

    // MARK: - Typewriter Animation

    private var typewriterText: String {
        let chars = Array(aiResponse)
        let endIndex = min(displayedCharacterCount, chars.count)
        return String(chars.prefix(endIndex))
    }

    private func startTypewriterAnimation() {
        guard !aiResponse.isEmpty else { return }
        displayedCharacterCount = 0

        let totalChars = aiResponse.count
        let interval: TimeInterval = 0.03 // 30ms per character

        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if displayedCharacterCount < totalChars {
                displayedCharacterCount += 1
            } else {
                timer.invalidate()
                isAnimating = false
            }
        }
    }

    // MARK: - Helpers

    private func iconForTime(date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12: return "sunrise.fill"
        case 12..<18: return "sun.max.fill"
        case 18..<22: return "moon.stars.fill"
        default: return "moon.fill"
        }
    }

    private func colorForTime(date: Date) -> Color {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12: return .orange
        case 12..<18: return .yellow
        case 18..<22: return .purple
        default: return Color(red: 0.0, green: 0.87, blue: 0.87)
        }
    }
}

// MARK: - Preview

#Preview {
    AIResponseView(
        aiResponse: "起床了！你今天有重要的日程要处理，不要再赖床了！赶紧看看今天的安排吧。",
        schedule: ScheduleItem.defaultSchedule,
        onDismiss: {}
    )
}
