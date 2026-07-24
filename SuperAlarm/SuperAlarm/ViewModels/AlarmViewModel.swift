import Foundation
import Combine

/// ViewModel managing alarm lifecycle, schedule data, and AI wake-up responses.
/// Persists alarms and schedule to UserDefaults as JSON.
@MainActor
final class AlarmViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var alarms: [Alarm] = []
    @Published var firingAlarm: Alarm?
    @Published var showFiringView: Bool = false
    @Published var aiResponse: String = ""
    @Published var isLoadingAI: Bool = false
    @Published var showAIResponse: Bool = false
    @Published var isSnoozeExhausted: Bool = false
    @Published var schedule: [ScheduleItem] = []
    
    // To prevent spam notifications from triggering the UI repeatedly when we already interacted
    private var recentlyHandledAlarms: [UUID: Date] = [:]

    // MARK: - Private

    private let alarmManager = AlarmManager.shared
    private let aiService = AIService()
    private let alarmsKey = "superalarm.alarms"
    private let scheduleKey = "superalarm.schedule"

    // MARK: - Init

    init() {
        loadAlarms()
        loadSchedule()
    }

    // MARK: - Alarm CRUD

    /// Add a new alarm, schedule its notification, and persist.
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        alarmManager.scheduleAlarm(alarm: alarm)
        saveAlarms()
    }

    /// Delete alarms at the given offsets, cancel their notifications, and persist.
    func deleteAlarm(at offsets: IndexSet) {
        let alarmsToDelete = offsets.map { alarms[$0] }
        for alarm in alarmsToDelete {
            alarmManager.cancelAlarm(id: alarm.id)
        }
        alarms.remove(atOffsets: offsets)
        saveAlarms()
    }

    /// Toggle an alarm's enabled state. Schedules or cancels accordingly.
    func toggleAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        if alarms[index].isEnabled {
            alarmManager.cancelAlarm(id: alarms[index].id) {
                self.alarmManager.scheduleAlarm(alarm: self.alarms[index])
            }
        } else {
            alarmManager.cancelAlarm(id: alarms[index].id)
        }
        saveAlarms()
    }

    /// Update an existing alarm in-place, reschedule, and persist.
    func updateAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index] = alarm
        if alarm.isEnabled {
            alarmManager.cancelAlarm(id: alarm.id) {
                self.alarmManager.scheduleAlarm(alarm: alarm)
            }
        } else {
            alarmManager.cancelAlarm(id: alarm.id)
        }
        saveAlarms()
    }

    // MARK: - Alarm Firing Handlers

    /// User chose to wake up — stop the alarm and fetch AI schedule briefing.
    func handleWakeUp() {
        guard let alarm = firingAlarm,
              let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        
        recentlyHandledAlarms[alarm.id] = Date()
        
        // 先保存状态和关闭界面，然后在取消通知的回调里重新调度
        var updatedAlarm = alarm
        updatedAlarm.currentSnoozeCount = 0
        
        if updatedAlarm.repeatDays.isEmpty {
            updatedAlarm.isEnabled = false
        }
        
        alarms[index] = updatedAlarm
        saveAlarms()
        
        showFiringView = false
        firingAlarm = nil
        isSnoozeExhausted = false
        
        alarmManager.cancelAlarm(id: alarm.id) {
            if updatedAlarm.isEnabled {
                self.alarmManager.scheduleAlarm(alarm: updatedAlarm)
            }
        }

        // Fetch AI response
        Task {
            await fetchAIResponse()
        }
    }

    /// User chose to snooze. Increments snooze count and reschedules if allowed.
    func handleSnooze() {
        guard let alarm = firingAlarm,
              let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }

        if alarm.currentSnoozeCount < alarm.maxSnooze {
            recentlyHandledAlarms[alarm.id] = Date()
            
            var updatedAlarm = alarm
            updatedAlarm.currentSnoozeCount += 1
            alarms[index] = updatedAlarm
            saveAlarms()

            // Cancel old spam notifications for this occurrence
            alarmManager.cancelAlarm(id: alarm.id) {
                // Re-schedule the main alarm so it rings next week/tomorrow at the CORRECT original time
                if updatedAlarm.isEnabled {
                    self.alarmManager.scheduleAlarm(alarm: updatedAlarm)
                }
                
                // Schedule the temporary one-time snooze alarm
                self.alarmManager.handleSnooze(alarmId: alarm.id, snoozeInterval: alarm.snoozeInterval)
            }

            showFiringView = false
            firingAlarm = nil
        } else {
            // Snooze exhausted — force wake up
            isSnoozeExhausted = true
        }
    }

    /// Called when a notification fires to present the alarm UI.
    func triggerAlarm(id: UUID) {
        // 如果一分钟内已经处理过该闹钟（比如刚刚点了起床或贪睡），忽略连发的通知
        if let lastHandled = recentlyHandledAlarms[id], Date().timeIntervalSince(lastHandled) < 60 {
            return
        }
        
        guard let alarm = alarms.first(where: { $0.id == id }) else { return }
        firingAlarm = alarm
        showFiringView = true
        isSnoozeExhausted = false
    }

    /// Check if an alarm was recently interacted with (to filter out concurrent spam notifications)
    func isRecentlyHandled(id: UUID) -> Bool {
        if let lastHandled = recentlyHandledAlarms[id], Date().timeIntervalSince(lastHandled) < 60 {
            return true
        }
        return false
    }

    // MARK: - AI Integration

    /// Fetch a motivational wake-up message from the AI service.
    func fetchAIResponse() async {
        isLoadingAI = true
        showAIResponse = true
        aiResponse = ""

        // Filter today's schedule
        cleanupPastSchedules()
        
        let today = Date()
        let todayWeekday = Calendar.current.component(.weekday, from: today)
        // Convert iOS weekday (1=Sun, 2=Mon) to our model (1=Mon...7=Sun)
        let ourWeekday = todayWeekday == 1 ? 7 : todayWeekday - 1
        
        let todaysSchedule = schedule.filter { item in
            if item.isRepeating {
                return item.repeatDays.contains(ourWeekday)
            } else {
                return Calendar.current.isDate(item.date, inSameDayAs: today)
            }
        }.sorted {
            let h1 = Calendar.current.component(.hour, from: $0.date)
            let m1 = Calendar.current.component(.minute, from: $0.date)
            let h2 = Calendar.current.component(.hour, from: $1.date)
            let m2 = Calendar.current.component(.minute, from: $1.date)
            if h1 != h2 { return h1 < h2 }
            return m1 < m2
        }

        let response = await aiService.generateWakeUpMessage(schedule: todaysSchedule)
        aiResponse = response
        isLoadingAI = false
    }

    // MARK: - Persistence

    func saveAlarms() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: alarmsKey)
        }
    }

    func loadAlarms() {
        guard let data = UserDefaults.standard.data(forKey: alarmsKey),
              let decoded = try? JSONDecoder().decode([Alarm].self, from: data) else {
            alarms = []
            return
        }
        alarms = decoded
    }

    func saveSchedule() {
        if let data = try? JSONEncoder().encode(schedule) {
            UserDefaults.standard.set(data, forKey: scheduleKey)
        }
    }

    func loadSchedule() {
        guard let data = UserDefaults.standard.data(forKey: scheduleKey),
              let decoded = try? JSONDecoder().decode([ScheduleItem].self, from: data) else {
            schedule = ScheduleItem.defaultSchedule
            return
        }
        schedule = decoded
        cleanupPastSchedules()
    }
    
    private func cleanupPastSchedules() {
        let now = Date()
        let calendar = Calendar.current
        
        // 我们以凌晨 4:00 作为一天的逻辑分界线
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        let currentHour = components.hour ?? 0
        
        // 如果现在是凌晨 0点~4点，说明逻辑上还是“昨天”，清理线应该往前推一天
        if currentHour < 4 {
            components.day! -= 1
        }
        
        components.hour = 4
        components.minute = 0
        components.second = 0
        
        guard let cutoffDate = calendar.date(from: components) else { return }
        
        let originalCount = schedule.count
        schedule.removeAll { item in
            !item.isRepeating && item.date < cutoffDate
        }
        if schedule.count < originalCount {
            saveSchedule()
        }
    }
}
