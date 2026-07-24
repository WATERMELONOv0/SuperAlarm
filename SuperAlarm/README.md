# SuperAlarm ⏰ (超级闹钟)

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English

**SuperAlarm** is a modern, AI-powered alarm clock application for iOS built with SwiftUI. It goes beyond the traditional alarm clock by incorporating AI personas to wake you up with a personalized morning briefing, custom audio libraries, and a beautiful glassmorphism design.

### ✨ Key Features

*   **🤖 AI Personas**: Wake up to a personalized greeting! Choose between distinct AI personas (e.g., a sweet Catgirl or a strict Toxic Butler).
*   **🌅 AI Schedule Briefing**: Upon waking up, the AI will generate a tailored morning briefing based on your daily schedule and weather to kickstart your day.
*   **🎵 Custom Audio Library**: Import your own local audio files and manage them directly within the app. Say goodbye to boring default ringtones!
*   **🗓️ Smart Schedule Management**: Easily add one-time or repeating schedules. The app automatically cleans up expired one-time schedules at 4:00 AM the next day.
*   **🔔 Anti-Oversleep Mechanism**: Uses a high-frequency notification burst (Spam Notifications) to ensure you don't sleep through the alarm, even if the app is in the background.
*   **🎨 Glassmorphism UI**: A gorgeous, ultra-modern dark theme utilizing translucency, blurs, and gradient borders to deliver a premium user experience.

### 🛠️ Tech Stack

*   **Platform**: iOS 15.0+
*   **Framework**: SwiftUI
*   **Architecture**: MVVM
*   **AI Integration**: External LLM APIs (Gemini, Kimi, DeepSeek, etc.) via network requests.
*   **Local Storage**: `UserDefaults` & `FileManager` for robust schedule and audio persistence.

### 🚀 Getting Started

1. Clone the repository to your local machine.
2. Open `SuperAlarm.xcodeproj` in Xcode.
3. Configure your Apple Developer Team in the **Signing & Capabilities** tab.
   * *Note: The "Time Sensitive Notifications" capability is disabled by default for personal (free) developer accounts. If you have a paid account, you can add this entitlement back to bypass iOS Sleep Focus mode.*
4. Add your LLM API Key in `SuperAlarmApp.swift` or `SettingsView.swift` (depending on configuration).
5. Build and run on your iOS device or simulator.

---

<a name="中文"></a>
## 中文 (Chinese)

**SuperAlarm (超级闹钟)** 是一款基于 SwiftUI 开发的现代化 AI 智能闹钟 iOS 应用。它打破了传统闹钟的枯燥，通过引入 AI 角色扮演（Persona）、每日行程播报、专属音频库和极具现代感的毛玻璃（Glassmorphism）UI 设计，为你带来前所未有的起床体验。

### ✨ 核心功能

*   **🤖 AI 角色伴醒**：抛弃冰冷的铃声，让 AI 角色唤醒你！应用内置不同性格的 AI 角色（如：香软小猫娘、毒舌管家），为你提供情绪价值拉满的专属问候。
*   **🌅 AI 行程简报**：当你点击“起床”后，AI 会根据你当天的日程安排和天气情况，实时生成一段早安简报，帮你清晰规划一天的生活。
*   **🎵 专属音频库**：支持直接导入本地的自定义音频文件（.mp3, .wav 等），并在应用内集中管理和删除，随时更换你最喜欢的唤醒语音。
*   **🗓️ 智能日程管理**：轻松设置一次性或周期性日程。系统极具人性化地在第二天凌晨 4:00 自动清理已过期的一次性日程，无需手动打理。
*   **🔔 防赖床连发机制**：通过在短时间内高频次发送通知（夺命连环 Call），确保你在锁屏或后台状态下也能被准时叫醒。
*   **🎨 毛玻璃视觉美学**：采用极其精致的暗黑模式毛玻璃 UI 设计，配合微发光渐变边框和高斯模糊背景，视觉体验极佳。

### 🛠️ 技术栈

*   **运行平台**：iOS 15.0+
*   **UI 框架**：SwiftUI
*   **架构模式**：MVVM
*   **AI 接入**：通过原生网络请求接入大语言模型 API（如 Gemini, Kimi, DeepSeek 等）。
*   **数据持久化**：使用 `UserDefaults` 和原生 `FileManager` 高效管理日程与本地音频文件。

### 🚀 快速运行

1. 将项目 Clone 到本地。
2. 使用 Xcode 打开 `SuperAlarm.xcodeproj`。
3. 在项目的 **Signing & Capabilities** 中配置你的开发者证书。
   * *注意：免费的个人开发者账号不支持苹果的“时效性通知 (Time Sensitive Notifications)”。如果你有付费的开发者账号，可以重新添加此权限，以便在“睡眠模式”下强制穿透静音。*
4. 在设置页填入你的 LLM API Key。
5. 编译 (`Cmd + R`) 并运行在你的 iPhone 或模拟器上。
