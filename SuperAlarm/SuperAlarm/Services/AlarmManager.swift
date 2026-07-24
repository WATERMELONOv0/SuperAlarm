import Foundation
import UserNotifications
import AVFoundation

// MARK: - 闹钟管理器
/// 负责调度本地通知、管理贪睡逻辑、配置音频会话
/// 对应 Python 脚本中的 WAKEUP() 流程
final class AlarmManager {
    
    // MARK: - 单例
    
    static let shared = AlarmManager()
    
    // MARK: - 通知动作标识符
    
    /// 贪睡动作标识（对应 Python 中 choice=="1"）
    static let snoozeActionIdentifier = "SNOOZE_ACTION"
    /// 起床动作标识（对应 Python 中 choice=="0"）
    static let wakeActionIdentifier = "WAKE_ACTION"
    /// 通知类别标识
    static let alarmCategoryIdentifier = "ALARM_CATEGORY"
    
    // MARK: - UserDefaults 键
    
    private let scheduledAlarmsKey = "com.superalarm.scheduledAlarms"
    
    // MARK: - 属性
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - 初始化
    
    private init() {
        registerNotificationCategories()
    }
    
    // MARK: - 权限请求
    
    /// 请求通知权限（弹窗、角标、声音）
    func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("⚠️ 通知权限请求失败: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// async 版本的权限请求
    @available(iOS 15.0, *)
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("⚠️ 通知权限请求失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 注册通知类别和动作
    
    /// 注册带有「贪睡」和「起床」两个按钮的通知类别
    private func registerNotificationCategories() {
        // 贪睡按钮 - 对应 Python 中输入 "1"
        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionIdentifier,
            title: "再睡一会 😴",
            options: []
        )
        
        // 起床按钮 - 对应 Python 中输入 "0"
        let wakeAction = UNNotificationAction(
            identifier: Self.wakeActionIdentifier,
            title: "醒了 🌅",
            options: [.foreground]  // 点击后打开 App
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: Self.alarmCategoryIdentifier,
            actions: [snoozeAction, wakeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([alarmCategory])
    }
    
    // MARK: - 调度闹钟
    
    /// 根据 Alarm 模型调度一个本地通知
    func scheduleAlarm(alarm: Alarm) {
        guard alarm.isEnabled else { return }
        
        let defaultGreeting = "早上好狗修金，今天也要开开心心啊"
        let baseGreeting = alarm.greeting.isEmpty ? defaultGreeting : alarm.greeting
        let soundName = alarm.soundFileName ?? "cyber_alarm.wav"
        let userInfo = ["alarmId": alarm.id.uuidString]
        
        // 从闹钟时间提取小时和分钟
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: alarm.time)
        dateComponents.minute = calendar.component(.minute, from: alarm.time)
        

        let spamSeconds = [0, 2, 4, 6, 8, 10, 15, 20, 25]
        

        let spamMessages = [
            baseGreeting,
            "快点起床不然要迟到了",
            "还在赖床吗快睁开眼睛",
            "不要再拖延了立刻起床",
            "时间在流逝快点起来吧",
            "最后通牒马上从床上起来",
            "再睡真的要来不及了",
            "这是认真的快给我起来",
            "太阳都晒屁股了快起快起"
        ]
        
        if alarm.repeatDays.isEmpty {
            for (index, sec) in spamSeconds.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = alarm.label
                content.body = spamMessages[index % spamMessages.count]
                content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
                content.categoryIdentifier = Self.alarmCategoryIdentifier
                content.userInfo = userInfo
                if #available(iOS 15.0, *) {
                    content.interruptionLevel = .timeSensitive
                }
                
                dateComponents.second = sec
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: false
                )
                
                let request = UNNotificationRequest(
                    identifier: "\(alarm.id.uuidString)_sec\(sec)",
                    content: content,
                    trigger: trigger
                )
                
                addNotificationRequest(request, alarmId: alarm.id)
            }
        } else {
            // 有重复日：为每个星期几分别创建通知
            for day in alarm.repeatDays {
                var repeatingComponents = dateComponents
                repeatingComponents.weekday = day == 7 ? 1 : day + 1
                
                for (index, sec) in spamSeconds.enumerated() {
                    let content = UNMutableNotificationContent()
                    content.title = alarm.label // 移除 ⏰ emoji
                    content.body = spamMessages[index % spamMessages.count]
                    content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
                    content.categoryIdentifier = Self.alarmCategoryIdentifier
                    content.userInfo = userInfo
                    if #available(iOS 15.0, *) {
                        content.interruptionLevel = .timeSensitive
                    }
                    
                    repeatingComponents.second = sec
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: repeatingComponents,
                        repeats: true
                    )
                    
                    let requestId = "\(alarm.id.uuidString)_day\(day)_sec\(sec)"
                    let request = UNNotificationRequest(
                        identifier: requestId,
                        content: content,
                        trigger: trigger
                    )
                    
                    addNotificationRequest(request, alarmId: alarm.id)
                }
            }
        }
        
        // 持久化闹钟调度信息
        saveScheduledAlarmId(alarm.id)
    }
    
    /// 添加通知请求到通知中心
    private func addNotificationRequest(_ request: UNNotificationRequest, alarmId: UUID) {
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 闹钟调度失败 [\(alarmId)]: \(error.localizedDescription)")
            } else {
                print("✅ 闹钟已调度 [\(alarmId)]")
            }
        }
    }
    
    // MARK: - 取消闹钟
    
    /// 取消指定 ID 的闹钟（包括所有重复日的通知）
    func cancelAlarm(id: UUID, completion: @escaping () -> Void = {}) {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            
            // 找到所有以该闹钟 ID 开头的通知请求（单次、重复、贪睡等）
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(id.uuidString) }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            
            // 同样清理已送达的锁屏通知
            self.notificationCenter.getDeliveredNotifications { delivered in
                let deliveredIds = delivered
                    .filter { $0.request.identifier.hasPrefix(id.uuidString) }
                    .map { $0.request.identifier }
                
                self.notificationCenter.removeDeliveredNotifications(withIdentifiers: deliveredIds)
                
                self.removeScheduledAlarmId(id)
                print("🗑️ 闹钟已取消 [\(id)]")
                
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    // MARK: - 贪睡处理
    
    /// 处理贪睡逻辑
    /// 对应 Python 中 choice=="1" 时的 time.sleep(5) 流程
    /// - Parameter alarmId: 闹钟的 UUID
    /// - Parameter snoozeInterval: 贪睡间隔（秒），默认 300（5分钟）
    func handleSnooze(alarmId: UUID, snoozeInterval: TimeInterval = 300) {
        let content = UNMutableNotificationContent()
        content.title = "还在赖床吗" // 移除 emoji 避免乱码
        content.body = "啊，那好吧再睡一会哦"  // 对应 Python 中的贪睡提示
        content.sound = UNNotificationSound(named: UNNotificationSoundName("cyber_alarm.wav"))
        content.categoryIdentifier = Self.alarmCategoryIdentifier
        content.userInfo = ["alarmId": alarmId.uuidString]
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // 使用时间间隔触发器
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: snoozeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(alarmId.uuidString)_snooze",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 贪睡调度失败: \(error.localizedDescription)")
            } else {
                print("😴 贪睡已设定，\(Int(snoozeInterval / 60)) 分钟后再次提醒")
            }
        }
    }
    
    // MARK: - 音频会话配置
    
    /// 配置 AVAudioSession 以支持后台播放
    func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, options: .mixWithOthers)
            try audioSession.setActive(true)
            print("🔊 音频会话已配置")
        } catch {
            print("⚠️ 音频会话配置失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - UserDefaults 持久化
    
    /// 保存已调度的闹钟 ID
    private func saveScheduledAlarmId(_ id: UUID) {
        var ids = loadScheduledAlarmIds()
        ids.insert(id.uuidString)
        UserDefaults.standard.set(Array(ids), forKey: scheduledAlarmsKey)
    }
    
    /// 移除已取消的闹钟 ID
    private func removeScheduledAlarmId(_ id: UUID) {
        var ids = loadScheduledAlarmIds()
        ids.remove(id.uuidString)
        UserDefaults.standard.set(Array(ids), forKey: scheduledAlarmsKey)
    }
    
    /// 加载所有已调度的闹钟 ID
    func loadScheduledAlarmIds() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: scheduledAlarmsKey) ?? []
        return Set(array)
    }
}
