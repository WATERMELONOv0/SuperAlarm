import Foundation

// MARK: - 闹钟数据模型
/// 闹钟的核心数据结构，包含时间、重复日、贪睡设置等信息
struct Alarm: Codable, Identifiable {
    
    // MARK: - 属性
    
    let id: UUID
    var time: Date                      // 闹钟触发时间
    var isEnabled: Bool                 // 是否启用
    var label: String                   // 闹钟标签
    var repeatDays: Set<Int>            // 重复的星期 (1=周一 ... 7=周日)
    var maxSnooze: Int                  // 最大贪睡次数
    var snoozeInterval: TimeInterval    // 贪睡间隔（秒）
    var currentSnoozeCount: Int         // 当前已贪睡次数
    var greeting: String                // 自定义问候语
    var soundFileName: String?          // 自定义音频文件名
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        time: Date = Date(),
        isEnabled: Bool = true,
        label: String = "闹钟",
        repeatDays: Set<Int> = [],
        maxSnooze: Int = 2,
        snoozeInterval: TimeInterval = 300,   // 默认 5 分钟
        currentSnoozeCount: Int = 0,
        greeting: String = "",
        soundFileName: String? = nil
    ) {
        self.id = id
        self.time = time
        self.isEnabled = isEnabled
        self.label = label
        self.repeatDays = repeatDays
        self.maxSnooze = maxSnooze
        self.snoozeInterval = snoozeInterval
        self.currentSnoozeCount = currentSnoozeCount
        self.greeting = greeting
        self.soundFileName = soundFileName
    }
    
    // MARK: - 计算属性
    
    /// 格式化的时间字符串，如 "07:30"
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: time)
    }
    
    /// 重复日的可读文本
    /// 例如: "每天"、"周一 周三"、"不重复"
    var repeatDaysText: String {
        if repeatDays.isEmpty {
            return "不重复"
        }
        
        if repeatDays.count == 7 {
            return "每天"
        }
        
        // 工作日判断（周一到周五）
        let weekdays: Set<Int> = [1, 2, 3, 4, 5]
        if repeatDays == weekdays {
            return "工作日"
        }
        
        // 周末判断
        let weekends: Set<Int> = [6, 7]
        if repeatDays == weekends {
            return "周末"
        }
        
        // 星期名称映射
        let dayNames: [Int: String] = [
            1: "周一", 2: "周二", 3: "周三",
            4: "周四", 5: "周五", 6: "周六", 7: "周日"
        ]
        
        return repeatDays.sorted().compactMap { dayNames[$0] }.joined(separator: " ")
    }
    
    /// 是否还能继续贪睡
    var canSnooze: Bool {
        currentSnoozeCount < maxSnooze
    }
}

// MARK: - 预览用示例数据

extension Alarm {
    
    static let sampleAlarms: [Alarm] = [
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date(),
            isEnabled: true,
            label: "起床打原神",
            repeatDays: [1, 2, 3, 4, 5],
            maxSnooze: 2
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 8, minute: 30)) ?? Date(),
            isEnabled: true,
            label: "上班闹钟",
            repeatDays: [1, 2, 3, 4, 5],
            maxSnooze: 1
        ),
        Alarm(
            time: Calendar.current.date(from: DateComponents(hour: 10, minute: 0)) ?? Date(),
            isEnabled: false,
            label: "周末闹钟",
            repeatDays: [6, 7],
            maxSnooze: 3
        )
    ]
    
    static let sample = sampleAlarms[0]
}
