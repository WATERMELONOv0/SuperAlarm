import Foundation

// MARK: - 日程项目模型
/// 对应 Python 脚本中的 Schedule 列表项
struct ScheduleItem: Codable, Identifiable {
    
    let id: UUID
    var title: String
    var date: Date
    var isRepeating: Bool
    var repeatDays: Set<Int> // 1=Mon ... 7=Sun
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        isRepeating: Bool = false,
        repeatDays: Set<Int> = []
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.isRepeating = isRepeating
        self.repeatDays = repeatDays
    }
    
    // MARK: - Computed Properties
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var repeatDaysText: String {
        if !isRepeating || repeatDays.isEmpty {
            return "一次性"
        }
        
        if repeatDays.count == 7 {
            return "每天"
        }
        
        let weekdays: Set<Int> = [1, 2, 3, 4, 5]
        if repeatDays == weekdays {
            return "工作日"
        }
        
        let weekends: Set<Int> = [6, 7]
        if repeatDays == weekends {
            return "周末"
        }
        
        let dayNames: [Int: String] = [
            1: "周一", 2: "周二", 3: "周三",
            4: "周四", 5: "周五", 6: "周六", 7: "周日"
        ]
        
        return repeatDays.sorted().compactMap { dayNames[$0] }.joined(separator: " ")
    }
}

// MARK: - 默认日程

extension ScheduleItem {
    
    static let defaultSchedule: [ScheduleItem] = [
        ScheduleItem(
            title: "早会",
            date: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
            isRepeating: true,
            repeatDays: [1, 2, 3, 4, 5]
        ),
        ScheduleItem(
            title: "吃午饭",
            date: Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date(),
            isRepeating: true,
            repeatDays: [1, 2, 3, 4, 5, 6, 7]
        )
    ]
    
    /// 将日程列表转换为标题数组（用于 AI prompt 构建）
    static func titlesArray(from items: [ScheduleItem]) -> [String] {
        items.map { "\($0.timeString) \($0.title)" }
    }
}
