import SwiftUI

/// Schedule management view with editable list, glassmorphism cards, and drag-to-reorder.
struct ScheduleView: View {

    @ObservedObject var viewModel: AlarmViewModel
    @State private var showAddSheet = false
    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var isRepeating = false
    @State private var repeatDays: Set<Int> = []
    @State private var editMode: EditMode = .inactive

    // MARK: - Theme

    private let gradientStart = Color(red: 0.04, green: 0.086, blue: 0.157)
    private let gradientEnd = Color(red: 0.102, green: 0.04, blue: 0.18)
    private let accentCyan = Color(red: 0.0, green: 0.87, blue: 0.87)
    private let weekdayLabels = ["一", "二", "三", "四", "五", "六", "日"]

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

                if viewModel.schedule.isEmpty {
                    emptyState
                } else {
                    scheduleList
                }
            }
            .navigationTitle("日程安排")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .foregroundColor(accentCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showAddSheet) {
                addScheduleSheet
            }
        }
    }

    // MARK: - Schedule List

    private var scheduleList: some View {
        List {
            ForEach(viewModel.schedule) { item in
                scheduleRow(item: item)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func scheduleRow(item: ScheduleItem) -> some View {
        HStack(spacing: 14) {
            // Time-slot icon
            let icon = iconForTime(date: item.date)
            let color = colorForTime(date: item.date)
            
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
                Text(item.isRepeating ? item.repeatDaysText : item.dateString)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Time-slot tag
            Text(item.timeString)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(color.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(accentCyan.opacity(0.5))

            Text("还没有日程安排")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            Text("点击右上角 + 添加日程")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.3))

            Button(action: { showAddSheet = true }) {
                Label("添加日程", systemImage: "plus.circle.fill")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accentCyan)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button(action: { showAddSheet = true }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(accentCyan)
        }
    }

    // MARK: - Add Schedule Sheet

    private var addScheduleSheet: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("日程标题")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(accentCyan)

                        TextField("例如：玩原神", text: $newTitle)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(accentCyan.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }

                    // Type Segmented Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("日程类型")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(accentCyan)
                            
                        Picker("日程类型", selection: $isRepeating) {
                            Text("一次性").tag(false)
                            Text("周期性").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Date & Time pickers
                    VStack(alignment: .leading, spacing: 8) {
                        Text("时间设置")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(accentCyan)

                        VStack(spacing: 16) {
                            if isRepeating {
                                DatePicker("提醒时间", selection: $newDate, displayedComponents: .hourAndMinute)
                                    .colorScheme(.dark)
                                    .foregroundColor(.white)
                                    
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("重复星期")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    HStack(spacing: 6) {
                                        ForEach(1...7, id: \.self) { day in
                                            weekdayButton(day: day)
                                        }
                                    }
                                }
                            } else {
                                DatePicker("日期和时间", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                                    .colorScheme(.dark)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(accentCyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("添加日程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        resetAddForm()
                        showAddSheet = false
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addNewItem()
                    }
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundColor(newTitle.isEmpty ? accentCyan.opacity(0.3) : accentCyan)
                    .disabled(newTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func weekdayButton(day: Int) -> some View {
        let isSelected = repeatDays.contains(day)
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    repeatDays.remove(day)
                } else {
                    repeatDays.insert(day)
                }
            }
        } label: {
            Text(weekdayLabels[day - 1])
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .black : .white.opacity(0.5))
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? accentCyan : Color.white.opacity(0.1))
                )
        }
    }

    // MARK: - Actions

    private func deleteItems(at offsets: IndexSet) {
        viewModel.schedule.remove(atOffsets: offsets)
        viewModel.saveSchedule()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        viewModel.schedule.move(fromOffsets: source, toOffset: destination)
        viewModel.saveSchedule()
    }

    private func addNewItem() {
        guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let item = ScheduleItem(
            title: newTitle.trimmingCharacters(in: .whitespaces),
            date: newDate,
            isRepeating: isRepeating,
            repeatDays: repeatDays
        )
        viewModel.schedule.append(item)
        // Sort schedule by time
        viewModel.schedule.sort {
            let h1 = Calendar.current.component(.hour, from: $0.date)
            let m1 = Calendar.current.component(.minute, from: $0.date)
            let h2 = Calendar.current.component(.hour, from: $1.date)
            let m2 = Calendar.current.component(.minute, from: $1.date)
            if h1 != h2 { return h1 < h2 }
            return m1 < m2
        }
        viewModel.saveSchedule()
        resetAddForm()
        showAddSheet = false
    }

    private func resetAddForm() {
        newTitle = ""
        newDate = Date()
        isRepeating = false
        repeatDays = []
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
        default: return accentCyan
        }
    }
}

// MARK: - Preview

#Preview {
    ScheduleView(viewModel: AlarmViewModel())
        .preferredColorScheme(.dark)
}
