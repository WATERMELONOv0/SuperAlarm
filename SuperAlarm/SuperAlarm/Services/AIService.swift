import Foundation

// MARK: - DeepSeek AI 服务
/// 对应 Python 脚本中的 wakingup1() 函数
/// 调用 DeepSeek API 生成每日叫醒话术
final class AIService {
    
    // MARK: - 属性
    
    /// API 基础地址（默认 DeepSeek）
    var baseURL: String
    
    /// 模型名称
    var modelName: String
    
    // MARK: - 初始化
    
    init(
        baseURL: String = "https://api.deepseek.com",
        modelName: String = "deepseek-chat"
    ) {
        self.baseURL = baseURL
        self.modelName = modelName
    }
    
    // MARK: - 获取 API Key
    
    /// 从 Keychain 读取 API Key
    private var apiKey: String? {
        KeychainService.load(key: KeychainService.apiKeyIdentifier)
    }
    
    /// 从 Keychain 读取自定义 Base URL（如有）
    private var customBaseURL: String? {
        KeychainService.load(key: KeychainService.baseURLIdentifier)
    }
    
    /// 最终使用的 Base URL
    private var effectiveBaseURL: String {
        customBaseURL ?? baseURL
    }
    
    // MARK: - 生成叫醒消息

    /// - Parameter schedule: 今日日程列表
    /// - Returns: AI 生成的叫醒消息文本
    func generateWakeUpMessage(schedule: [ScheduleItem]) async -> String {
        // 构建日程标题数组，与 Python 的 str(Schedule) 对应
        let scheduleTitles = ScheduleItem.titlesArray(from: schedule)
        let scheduleString = String(describing: scheduleTitles)
        

        let appLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "zh-Hans"
        let languageInstruction = appLanguage == "en" ? "Please reply in English." : "请用中文（简体）回复。"
        
        let aiPersona = UserDefaults.standard.string(forKey: "aiPersona") ?? "catgirl"
        
        let userPrompt: String
        let systemMessage: String
        
        if aiPersona == "butler" {
            userPrompt = "你现在是一个毒舌、傲娇的赛博管家。请根据用户今天的日程：\(scheduleString)。写一段不超过 90 字的清晨叫醒话术，要用嘲讽但不失关心的语气叫他起床！并列出今日简明 To-Do 列表。\(languageInstruction)"
            systemMessage = "你是一个毒舌赛博管家清晨叫醒导师。"
        } else {
            userPrompt = "你现在是一个贴心的管家，人设为香香软软的小猫娘。请根据用户今天的日程：\(scheduleString)。写一段不超过 90 字的清晨贴心叫醒话术，要非常甜美可爱地叫他起床！并列出今日简明 To-Do 列表。\(languageInstruction)"
            systemMessage = "你是一个可爱贴心、香香软软的小猫娘清晨叫醒导师。"
        }
        
        // 确保有 API Key
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return fallbackMessage(scheduleTitles: scheduleTitles, reason: "未设置 API Key")
        }
        
        // 构建请求 URL
        guard let url = URL(string: "\(effectiveBaseURL)/chat/completions") else {
            return fallbackMessage(scheduleTitles: scheduleTitles, reason: "无效的 API 地址")
        }
        
        // 构建请求体 - 与 Python 的 client.chat.completions.create() 对应
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": systemMessage],
                ["role": "user", "content": userPrompt]
            ],
            "stream": false
        ]
        
        // 序列化 JSON
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return fallbackMessage(scheduleTitles: scheduleTitles, reason: "请求构建失败")
        }
        
        // 配置 HTTP 请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = httpBody
        request.timeoutInterval = 30
        
        // 发送请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查 HTTP 状态码
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                return fallbackMessage(
                    scheduleTitles: scheduleTitles,
                    reason: "HTTP \(httpResponse.statusCode)"
                )
            }
            
            // 解析响应 JSON
            // 对应 Python: response.choices[0].message.content
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return fallbackMessage(scheduleTitles: scheduleTitles, reason: "响应解析失败")
            }
            
            return content
            
        } catch {
            // 对应 Python 中的 except Exception as e: 分支
            return fallbackMessage(scheduleTitles: scheduleTitles, reason: error.localizedDescription)
        }
    }
    
    // MARK: - 降级消息
    
    /// 连接失败时的降级消息
    /// 对应 Python: f"連接失敗，但别想赖床！今日日程提示：{str(Schedule)}"
    private func fallbackMessage(scheduleTitles: [String], reason: String? = nil) -> String {
        let scheduleText = scheduleTitles.joined(separator: "、")
        let reasonSuffix = reason.map { " (\($0))" } ?? ""
        return "連接失敗，但别想赖床！今日日程提示：\(scheduleText)\(reasonSuffix)"
    }
}
