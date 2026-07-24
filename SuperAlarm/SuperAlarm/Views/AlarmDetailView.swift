import SwiftUI
import UniformTypeIdentifiers

struct AlarmDetailView: View {
    @ObservedObject var viewModel: AlarmViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Editing state
    @State private var selectedTime: Date
    @State private var label: String
    @State private var repeatDays: Set<Int> // 1=周一 ... 7=周日 (matches Alarm model)
    @State private var maxSnooze: Int
    @State private var snoozeIntervalMinutes: Int // 用分钟表示，保存时转换为秒
    @State private var greeting: String
    @State private var soundFileName: String?
    
    // File Importer (Removed)
    
    private let existingAlarm: Alarm?
    private let isEditing: Bool
    
    private let weekdayLabels = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    private let snoozeIntervals = [1, 3, 5, 10]
    
    // MARK: - Initializers
    
    init(viewModel: AlarmViewModel, alarm: Alarm? = nil) {
        self.viewModel = viewModel
        self.existingAlarm = alarm
        self.isEditing = alarm != nil
        
        if let alarm = alarm {
            _selectedTime = State(initialValue: alarm.time)
            _label = State(initialValue: alarm.label)
            _repeatDays = State(initialValue: alarm.repeatDays)
            _maxSnooze = State(initialValue: alarm.maxSnooze)
            _snoozeIntervalMinutes = State(initialValue: Int(alarm.snoozeInterval / 60))
            _greeting = State(initialValue: alarm.greeting)
            _soundFileName = State(initialValue: alarm.soundFileName)
        } else {
            _selectedTime = State(initialValue: Date())
            _label = State(initialValue: "")
            _repeatDays = State(initialValue: [])
            _maxSnooze = State(initialValue: 2)
            _snoozeIntervalMinutes = State(initialValue: 5)
            _greeting = State(initialValue: "")
            _soundFileName = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "0A1628"), Color(hex: "1A0A2E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Time Picker
                        timePickerSection
                        
                        // MARK: - Label
                        labelSection
                        
                        // MARK: - Greeting
                        greetingSection
                        
                        // MARK: - Sound File
                        soundSection
                        
                        // MARK: - Repeat Days
                        repeatDaysSection
                        
                        // MARK: - Snooze Settings
                        snoozeSection
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(isEditing ? "编辑闹钟" : "新建闹钟")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveAlarm()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
                }
            }
        }
    }
    
    // MARK: - Time Picker Section
    private var timePickerSection: some View {
        GlassCard {
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipped()
        }
    }
    
    // MARK: - Label Section
    private var labelSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("标签", systemImage: "tag.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan)
                
                TextField("闹钟名称", text: $label)
                    .font(.system(size: 17, design: .rounded))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                    )
            }
        }
    }
    
    // MARK: - Greeting Section
    private var greetingSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("问候语", systemImage: "message.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan)
                
                TextField("早上好狗修金，今天也要开开心心啊", text: $greeting)
                    .font(.system(size: 17, design: .rounded))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                    )
            }
        }
    }
    
    // MARK: - Sound Section
    private var soundSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("闹铃声音", systemImage: "music.note")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    NavigationLink(destination: AudioSelectionView(selectedSoundFileName: $soundFileName)) {
                        Text("进入音频库")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.cyan.opacity(0.2))
                            .foregroundColor(.cyan)
                            .clipShape(Capsule())
                    }
                }
                
                if let fileName = soundFileName {
                    Text("当前: \(fileName)")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("当前: 系统默认音效 (cyber_alarm)")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text("⚠️ 注意: 苹果系统限制本地通知自定义铃声最长 30 秒，过长将播放默认提示音。")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow.opacity(0.8))
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Repeat Days Section
    private var repeatDaysSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("重复", systemImage: "repeat")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan)
                
                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { day in
                        weekdayButton(day: day)
                    }
                }
            }
        }
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
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            Text(weekdayLabels[day - 1])
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(Color.clear)
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.clear : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Snooze Section
    private var snoozeSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("贪睡设置", systemImage: "bed.double.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan)
                
                // Max snooze count
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最大贪睡次数")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        Text(maxSnooze == 0 ? "关闭贪睡" : "\(maxSnooze) 次")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    Stepper("", value: $maxSnooze, in: 0...5)
                        .labelsHidden()
                        .tint(.cyan)
                }
                
                if maxSnooze > 0 {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Snooze interval
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("贪睡间隔")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                            Text("\(snoozeIntervalMinutes) 分钟")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        Picker("", selection: $snoozeIntervalMinutes) {
                            ForEach(snoozeIntervals, id: \.self) { interval in
                                Text("\(interval) 分钟")
                                    .tag(interval)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.cyan)
                    }
                }
            }
        }
    }
    
    // MARK: - Save
    private func saveAlarm() {
        let snoozeIntervalSeconds = TimeInterval(snoozeIntervalMinutes * 60)
        
        if let existingAlarm = existingAlarm {
            var updated = existingAlarm
            updated.time = selectedTime
            updated.label = label
            updated.repeatDays = repeatDays
            updated.maxSnooze = maxSnooze
            updated.snoozeInterval = snoozeIntervalSeconds
            updated.greeting = greeting
            updated.soundFileName = soundFileName
            viewModel.updateAlarm(updated)
        } else {
            let newAlarm = Alarm(
                time: selectedTime,
                label: label.isEmpty ? "闹钟" : label,
                repeatDays: repeatDays,
                maxSnooze: maxSnooze,
                snoozeInterval: snoozeIntervalSeconds,
                greeting: greeting,
                soundFileName: soundFileName
            )
            viewModel.addAlarm(newAlarm)
        }
    }
}

// MARK: - Glass Card Component
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.04))
                    
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            )
    }
}

#Preview {
    AlarmDetailView(viewModel: AlarmViewModel())
        .preferredColorScheme(.dark)
}
struct AudioSelectionView: View {
    @Binding var selectedSoundFileName: String?
    @Environment(\.dismiss) var dismiss
    
    @State private var customAudios: [String] = []
    @State private var isImportingAudio = false
    @State private var showDeleteAlert = false
    @State private var audioToDelete: String? = nil
    
    let defaultSound = "cyber_alarm.wav"
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Default Sounds Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("系统默认")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.leading, 4)
                        
                        audioRow(name: "Cyber Alarm", fileName: defaultSound, isDefault: true)
                    }
                    
                    // Custom Sounds Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("我的音频库")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 4)
                            
                            Spacer()
                            
                            Button(action: {
                                isImportingAudio = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("上传音频")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.cyan.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                        
                        if customAudios.isEmpty {
                            Text("尚未上传任何自定义音频\n(支持上传你的小猫娘/管家定制语音)")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                )
                        } else {
                            VStack(spacing: 8) {
                                ForEach(customAudios, id: \.self) { audio in
                                    audioRow(name: audio, fileName: audio, isDefault: false)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("选择闹铃声音")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCustomAudios()
        }
        .fileImporter(isPresented: $isImportingAudio, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let url):
                if let copiedFileName = AudioStorageManager.shared.copyAudioFileToSoundsDirectory(from: url) {
                    selectedSoundFileName = copiedFileName
                    loadCustomAudios()
                }
            case .failure(let error):
                print("Failed to import audio: \(error.localizedDescription)")
            }
        }
        .alert("删除音频", isPresented: $showDeleteAlert, presenting: audioToDelete) { file in
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if AudioStorageManager.shared.deleteAudioFile(named: file) {
                    if selectedSoundFileName == file {
                        selectedSoundFileName = defaultSound
                    }
                    loadCustomAudios()
                }
            }
        } message: { file in
            Text("确定要从本地库中删除 \(file) 吗？")
        }
    }
    
    private func loadCustomAudios() {
        customAudios = AudioStorageManager.shared.listSavedAudioFiles()
    }
    
    private func audioRow(name: String, fileName: String, isDefault: Bool) -> some View {
        let isSelected = (selectedSoundFileName == fileName) || (isDefault && (selectedSoundFileName == nil || selectedSoundFileName == defaultSound))
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(isSelected ? .cyan : .white)
                
                if !isDefault {
                    Text("自定义音频")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.cyan)
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.cyan.opacity(0.1) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedSoundFileName = fileName
        }
        .contextMenu {
            if !isDefault {
                Button(role: .destructive) {
                    audioToDelete = fileName
                    showDeleteAlert = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}

// Extension to allow swipe actions directly on a view by utilizing a hidden list (or we can just keep the contextMenu which works well everywhere).
// Since we used VStack and ForEach, swipeActions won't work natively unless it's in a List.
// So contextMenu (long press) is provided as an alternative above. Let's wrap inside a custom modifier or just rely on contextMenu/swipeActions if embedded in List.
// To fix the swipe action issue inside ScrollView/VStack, we can build a simple custom swipe or just keep it simple with long press (Context Menu). I'll keep the Context Menu for now.
