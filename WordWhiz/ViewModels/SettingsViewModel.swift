import SwiftUI
import ServiceManagement

@Observable
@MainActor
final class SettingsViewModel {
    // General settings
    var launchAtLogin: Bool {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = oldValue
            }
            UserDefaults.standard.set(launchAtLogin, forKey: Constants.launchAtLoginKey)
        }
    }

    var showDockIcon: Bool {
        didSet {
            NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
            UserDefaults.standard.set(showDockIcon, forKey: Constants.showDockIconKey)
        }
    }

    var autoCopy: Bool {
        didSet { UserDefaults.standard.set(autoCopy, forKey: Constants.autoCopyKey) }
    }

    var keepHistory: Bool {
        didSet { UserDefaults.standard.set(keepHistory, forKey: Constants.keepHistoryKey) }
    }

    var panelPosition: PanelPosition {
        didSet { UserDefaults.standard.set(panelPosition.rawValue, forKey: Constants.panelPositionKey) }
    }

    // API settings
    var llmProvider: LLMProviderConfig {
        didSet { UserDefaults.standard.set(llmProvider.rawValue, forKey: Constants.llmProviderKey) }
    }

    var apiBaseURL: String {
        didSet { UserDefaults.standard.set(apiBaseURL, forKey: Constants.apiBaseURLKey) }
    }

    var modelName: String {
        didSet { UserDefaults.standard.set(modelName, forKey: Constants.modelNameKey) }
    }

    // API Key (not stored in this object — use KeychainService directly)
    var apiKey: String = "" {
        didSet {
            guard !isInitializing else { return }
            let key = "apikey.\(llmProvider.rawValue)"
            if apiKey.isEmpty {
                try? KeychainService.shared.delete(key: key)
            } else {
                try? KeychainService.shared.save(key: key, value: apiKey)
            }
        }
    }

    // Hotkey
    var hotkeyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hotkeyEnabled, forKey: Constants.hotkeyEnabledKey)
            NotificationCenter.default.post(name: Notification.Name("hotkeyEnabledChanged"), object: nil)
        }
    }

    // Connection test state
    var isTestingConnection: Bool = false
    var connectionTestResult: ConnectionTestResult?

    enum ConnectionTestResult {
        case success
        case failure(String)
    }

    // Settings window selected tab
    var selectedSettingsTab: SettingsTab = .general

    // Flag to prevent Keychain writes during init
    private var isInitializing: Bool = true

    init() {
        self.launchAtLogin = UserDefaults.standard.object(forKey: Constants.launchAtLoginKey) as? Bool ?? false
        self.showDockIcon = UserDefaults.standard.object(forKey: Constants.showDockIconKey) as? Bool ?? false
        self.autoCopy = UserDefaults.standard.object(forKey: Constants.autoCopyKey) as? Bool ?? false
        self.keepHistory = UserDefaults.standard.object(forKey: Constants.keepHistoryKey) as? Bool ?? true

        let posRaw = UserDefaults.standard.string(forKey: Constants.panelPositionKey) ?? PanelPosition.screenRight.rawValue
        self.panelPosition = PanelPosition(rawValue: posRaw) ?? .screenRight

        let providerRaw = UserDefaults.standard.string(forKey: Constants.llmProviderKey) ?? LLMProviderConfig.openAI.rawValue
        self.llmProvider = LLMProviderConfig(rawValue: providerRaw) ?? .openAI

        self.apiBaseURL = UserDefaults.standard.string(forKey: Constants.apiBaseURLKey) ?? ""
        self.modelName = UserDefaults.standard.string(forKey: Constants.modelNameKey) ?? ""

        self.hotkeyEnabled = UserDefaults.standard.object(forKey: Constants.hotkeyEnabledKey) as? Bool ?? true

        // Load API key from Keychain
        let apiKeyKey = "apikey.\(self.llmProvider.rawValue)"
        self.apiKey = KeychainService.shared.loadOrNil(key: apiKeyKey) ?? ""

        // Init complete, enable didSet side effects
        isInitializing = false
    }

    // MARK: - Actions

    func loadAPIKeyForCurrentProvider() {
        let key = "apikey.\(llmProvider.rawValue)"
        apiKey = KeychainService.shared.loadOrNil(key: key) ?? ""
    }

    func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil

        Task {
            do {
                guard let provider = LLMService.shared.createProvider(
                    config: llmProvider,
                    apiKey: apiKey,
                    baseURL: apiBaseURL.isEmpty ? nil : apiBaseURL,
                    modelName: modelName.isEmpty ? nil : modelName
                ) else {
                    await MainActor.run {
                        isTestingConnection = false
                        connectionTestResult = .failure("API Key 未配置")
                    }
                    return
                }

                let success = try await provider.testConnection()
                await MainActor.run {
                    isTestingConnection = false
                    connectionTestResult = success ? .success : .failure("连接失败")
                }
            } catch {
                await MainActor.run {
                    isTestingConnection = false
                    connectionTestResult = .failure(error.localizedDescription)
                }
            }
        }
    }

    func updateDefaultBaseURLAndModel() {
        if apiBaseURL.isEmpty {
            apiBaseURL = llmProvider.defaultBaseURL
        }
        if modelName.isEmpty {
            modelName = llmProvider.defaultModel
        }
    }
}

enum SettingsTab: String, CaseIterable {
    case general
    case api
    case prompts
    case history
    case shortcuts
    case about

    var displayName: String {
        switch self {
        case .general: return "通用"
        case .api: return "模型配置"
        case .prompts: return "指令管理"
        case .history: return "历史记录"
        case .shortcuts: return "快捷键"
        case .about: return "关于"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .api: return "key"
        case .prompts: return "text.badge.star"
        case .history: return "clock"
        case .shortcuts: return "keyboard"
        case .about: return "info.circle"
        }
    }
}
