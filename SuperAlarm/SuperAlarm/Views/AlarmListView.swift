import SwiftUI

struct AlarmListView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    @State private var showingAddAlarm = false
    @State private var hasAppeared = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "0A1628"), Color(hex: "1A0A2E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.alarms.isEmpty {
                    emptyStateView
                } else {
                    alarmList
                }
                
                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 100)
            }
            .navigationTitle("闹钟")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingAddAlarm) {
                AlarmDetailView(viewModel: viewModel)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan.opacity(0.6), .blue.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating)
            
            Text("还没有闹钟")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            
            Text("点击 + 添加你的第一个闹钟")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
        }
        .offset(y: hasAppeared ? 0 : 30)
        .opacity(hasAppeared ? 1 : 0)
    }
    
    // MARK: - Alarm List
    private var alarmList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(Array(viewModel.alarms.enumerated()), id: \.element.id) { index, alarm in
                    NavigationLink(destination: AlarmDetailView(viewModel: viewModel, alarm: alarm)) {
                        AlarmCardView(alarm: alarm) { isEnabled in
                            viewModel.toggleAlarm(alarm)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if let idx = viewModel.alarms.firstIndex(where: { $0.id == alarm.id }) {
                                    viewModel.deleteAlarm(at: IndexSet(integer: idx))
                                }
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .offset(y: hasAppeared ? 0 : 40)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.08),
                        value: hasAppeared
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
    }
    
    // MARK: - Add Button
    private var addButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            showingAddAlarm = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .cyan.opacity(0.4), radius: 12, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(hasAppeared ? 1 : 0.5)
        .opacity(hasAppeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: hasAppeared)
    }
}

// MARK: - Alarm Card View
struct AlarmCardView: View {
    let alarm: Alarm
    let onToggle: (Bool) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Time and info
            VStack(alignment: .leading, spacing: 6) {
                Text(alarm.timeString)
                    .font(.system(size: 42, weight: .light, design: .rounded))
                    .foregroundColor(alarm.isEnabled ? .white : .white.opacity(0.35))
                    .monospacedDigit()
                
                if !alarm.label.isEmpty {
                    Text(alarm.label)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(alarm.isEnabled ? .cyan.opacity(0.8) : .white.opacity(0.25))
                }
                
                if !alarm.repeatDaysText.isEmpty {
                    Text(alarm.repeatDaysText)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(alarm.isEnabled ? 0.45 : 0.2))
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle(!alarm.isEnabled) }
            ))
            .tint(.cyan)
            .labelsHidden()
            .scaleEffect(0.9)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        alarm.isEnabled
                            ? Color.white.opacity(0.06)
                            : Color.white.opacity(0.02)
                    )
                
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                alarm.isEnabled ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    AlarmListView()
        .environmentObject(AlarmViewModel())
        .preferredColorScheme(.dark)
}
