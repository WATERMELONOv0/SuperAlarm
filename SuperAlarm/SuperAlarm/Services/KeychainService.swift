import Foundation
import Security

// MARK: - Keychain 服务
/// 安全存储 API Key 等敏感信息
/// 避免在代码中硬编码密钥（对应 Python 中的 input() 获取 API_KEY）
enum KeychainService {
    
    // MARK: - 常量
    
    /// Keychain 服务标识符
    static let serviceIdentifier = "com.superalarm.keys"
    
    /// DeepSeek API Key 的存储键
    static let apiKeyIdentifier = "deepseek_api_key"
    
    /// API Base URL 的存储键
    static let baseURLIdentifier = "api_base_url"
    
    // MARK: - 保存
    
    /// 将字符串数据保存到 Keychain
    /// - Parameters:
    ///   - key: 存储键名
    ///   - data: 要存储的字符串
    /// - Returns: 是否保存成功
    @discardableResult
    static func save(key: String, data: String) -> Bool {
        guard let dataBytes = data.data(using: .utf8) else {
            print("❌ Keychain: 数据编码失败")
            return false
        }
        
        // 先尝试删除已有项，避免重复
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: dataBytes,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Keychain: 已保存 [\(key)]")
            return true
        } else {
            print("❌ Keychain: 保存失败 [\(key)], 状态码: \(status)")
            return false
        }
    }
    
    // MARK: - 读取
    
    /// 从 Keychain 读取字符串数据
    /// - Parameter key: 存储键名
    /// - Returns: 存储的字符串，不存在则返回 nil
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    // MARK: - 删除
    
    /// 从 Keychain 删除指定键的数据
    /// - Parameter key: 存储键名
    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - 便捷方法
    
    /// 检查是否已设置 API Key
    static var hasAPIKey: Bool {
        load(key: apiKeyIdentifier) != nil
    }
    
    /// 保存 DeepSeek API Key
    @discardableResult
    static func saveAPIKey(_ key: String) -> Bool {
        save(key: apiKeyIdentifier, data: key)
    }
    
    /// 读取 DeepSeek API Key
    static func loadAPIKey() -> String? {
        load(key: apiKeyIdentifier)
    }
    
    /// 保存自定义 Base URL
    @discardableResult
    static func saveBaseURL(_ url: String) -> Bool {
        save(key: baseURLIdentifier, data: url)
    }
    
    /// 读取自定义 Base URL
    static func loadBaseURL() -> String? {
        load(key: baseURLIdentifier)
    }
}
