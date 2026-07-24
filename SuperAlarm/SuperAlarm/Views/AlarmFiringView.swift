import SwiftUI

struct AlarmFiringView: View {
    // Callbacks
    let onWakeUp: () -> Void
    let onSnooze: () -> Void
    
    // Bindings
    @Binding var currentSnoozeCount: Int
    @Binding var maxSnooze: Int
    @Binding var isSnoozeExhausted: Bool
    
    // Animation states
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.4
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.6
    @State private var gradientPhase: Double = 0.0
    @State private var shakeOffset: CGFloat = 0
    @State private var buttonPressed: String? = nil
    @State private var breatheScale: CGFloat = 1.0
    @State private var currentTime = Date()
    @State private var showContent = false
    @State private var urgentPulse: Bool = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
    
    private var secondsFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "ss"
        return f
    }
    
    var body: some View {
        ZStack {
            // MARK: - Animated Background
            animatedBackground
            
            // MARK: - Content
            VStack(spacing: 0) {
                Spacer()
                
                // Pulsating rings + time
                pulsatingRings
                    .opacity(showContent ? 1 : 0)
                
                Spacer()
                    .frame(height: 40)
                
                // Greeting
                greetingSection
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                Spacer()
                    .frame(height: 20)
                
                // Snooze dots
                if maxSnooze > 0 {
                    snoozeDots
                        .opacity(showContent ? 1 : 0)
                }
                
                Spacer()
                
                // Action buttons
                actionButtons
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 40)
                
                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onChange(of: isSnoozeExhausted) { _, exhausted in
            if exhausted {
                triggerShake()
            }
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            // Base gradient that shifts
            LinearGradient(
                colors: [
                    Color(hex: "0A1628"),
                    Color(hex: "0F1B35"),
                    Color(hex: "1A0A2E"),
                    Color(hex: "150828")
                ],
                startPoint: UnitPoint(
                    x: 0.3 + sin(gradientPhase) * 0.2,
                    y: 0.0 + cos(gradientPhase * 0.7) * 0.1
                ),
                endPoint: UnitPoint(
                    x: 0.7 + cos(gradientPhase) * 0.2,
                    y: 1.0 + sin(gradientPhase * 0.5) * 0.1
                )
            )
//            // Custom Background Image
//            Image("AlarmBackground")
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .ignoresSafeArea()
//                .overlay(Color.black.opacity(0.4))
//            
            // Ambient glow orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(
                    x: sin(gradientPhase * 0.6) * 60,
                    y: cos(gradientPhase * 0.4) * 80 - 100
                )
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(
                    x: cos(gradientPhase * 0.5) * 50 + 50,
                    y: sin(gradientPhase * 0.3) * 60 + 200
                )
            
            // Urgent red overlay when snooze exhausted
            if isSnoozeExhausted {
                Color.red.opacity(urgentPulse ? 0.08 : 0.03)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: urgentPulse)
            }
        }
    }
    
    // MARK: - Pulsating Rings + Time
    private var pulsatingRings: some View {
        ZStack {
            // Outer ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            isSnoozeExhausted ? .red.opacity(0.3) : .cyan.opacity(0.3),
                            isSnoozeExhausted ? .orange.opacity(0.1) : .blue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 260, height: 260)
                .scaleEffect(ringScale)
                .opacity(ringOpacity * 0.5)
            
            // Middle ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            isSnoozeExhausted ? .red.opacity(0.4) : .cyan.opacity(0.4),
                            isSnoozeExhausted ? .orange.opacity(0.15) : .purple.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 220, height: 220)
                .scaleEffect(ringScale * 0.95)
                .opacity(ringOpacity * 0.7)
            
            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (isSnoozeExhausted ? Color.red : Color.cyan).opacity(glowOpacity * 0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(breatheScale)
            
            // Time display
            VStack(spacing: 2) {
                Text(timeFormatter.string(from: currentTime))
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .shadow(color: (isSnoozeExhausted ? Color.red : Color.cyan).opacity(glowOpacity), radius: 20)
                    .shadow(color: (isSnoozeExhausted ? Color.red : Color.cyan).opacity(glowOpacity * 0.5), radius: 40)
                
                Text(secondsFormatter.string(from: currentTime))
                    .font(.system(size: 24, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .monospacedDigit()
            }
            .scaleEffect(pulseScale)
        }
    }
    
    // MARK: - Greeting
    private var greetingSection: some View {
        VStack(spacing: 12) {
            if isSnoozeExhausted {
                Text("过了太长时间啦，快起床!!!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .offset(x: shakeOffset)
                    .shadow(color: .red.opacity(0.3), radius: 8)
            } else {
                Text("早上好狗修金")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("今天也要开开心心啊")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    // MARK: - Snooze Dots
    private var snoozeDots: some View {
        HStack(spacing: 10) {
            ForEach(0..<maxSnooze, id: \.self) { index in
                Circle()
                    .fill(
                        index < currentSnoozeCount
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color.white.opacity(0.15))
                    )
                    .frame(width: 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentSnoozeCount)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        if isSnoozeExhausted {
            // URGENT: Only wake up button, pulsating red
            urgentWakeUpButton
        } else {
            // Normal: Wake up + Snooze
            VStack(spacing: 16) {
                wakeUpButton
                
                if maxSnooze > 0 && currentSnoozeCount < maxSnooze {
                    snoozeButton
                }
            }
        }
    }
    
    private var wakeUpButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonPressed = "wake"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                buttonPressed = nil
                onWakeUp()
            }
        } label: {
            HStack(spacing: 10) {
                Text("醒了")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text("QwQ")
                    .font(.system(size: 22))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.4), radius: 16, y: 4)
            )
        }
        .scaleEffect(buttonPressed == "wake" ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonPressed)
    }
    
    private var snoozeButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonPressed = "snooze"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                buttonPressed = nil
                onSnooze()
            }
        } label: {
            HStack(spacing: 10) {
                Text("再睡一会")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                Text("awa")
                    .font(.system(size: 20))
            }
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .scaleEffect(buttonPressed == "snooze" ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonPressed)
    }
    
    private var urgentWakeUpButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            // Double haptic for urgency
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let impact2 = UIImpactFeedbackGenerator(style: .rigid)
                impact2.impactOccurred()
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonPressed = "urgent"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                buttonPressed = nil
                onWakeUp()
            }
        } label: {
            HStack(spacing: 10) {
                Text("快起床!!!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 22))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .red.opacity(urgentPulse ? 0.6 : 0.3), radius: urgentPulse ? 24 : 12, y: 4)
            )
        }
        .scaleEffect(buttonPressed == "urgent" ? 0.95 : (urgentPulse ? 1.03 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonPressed)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: urgentPulse)
    }
    
    // MARK: - Animation Setup
    private func startAnimations() {
        // Entrance animation
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            showContent = true
        }
        
        // Breathing pulse for time
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.02
        }
        
        // Glow animation
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.7
        }
        
        // Ring pulse
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            ringScale = 1.08
            ringOpacity = 0.3
        }
        
        // Breathe
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            breatheScale = 1.1
        }
        
        // Gradient shift
        withAnimation(.linear(duration: 12.0).repeatForever(autoreverses: true)) {
            gradientPhase = .pi * 2
        }
        
        // Urgent pulse if already exhausted on appear
        if isSnoozeExhausted {
            urgentPulse = true
        }
    }
    
    private func triggerShake() {
        urgentPulse = true
        let shakeSequence: [(CGFloat, Double)] = [
            (-12, 0.0), (10, 0.06), (-8, 0.12), (6, 0.18),
            (-4, 0.24), (2, 0.30), (0, 0.36)
        ]
        for (offset, delay) in shakeSequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.3)) {
                    shakeOffset = offset
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Normal") {
    AlarmFiringView(
        onWakeUp: {},
        onSnooze: {},
        currentSnoozeCount: .constant(1),
        maxSnooze: .constant(3),
        isSnoozeExhausted: .constant(false)
    )
    .preferredColorScheme(.dark)
}

#Preview("Snooze Exhausted") {
    AlarmFiringView(
        onWakeUp: {},
        onSnooze: {},
        currentSnoozeCount: .constant(3),
        maxSnooze: .constant(3),
        isSnoozeExhausted: .constant(true)
    )
    .preferredColorScheme(.dark)
}
