import SwiftUI
import ServiceManagement

@Observable
@MainActor
final class SettingsViewModel {
    // General settings
    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Constants.launchAtLoginKey)
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // SMAppService may fail in debug/unsigned builds; preference is still saved
                NSLog("[WordWhiz] SMAppService error: \(error.localizedDescription)")
            }
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
        didSet { UserDefaults.standard.set(apiBaseURL, forKey: Constants.apiBaseURLKey(provider: llmProvider.rawValue)) }
    }

    var modelName: String {
        didSet { UserDefaults.standard.set(modelName, forKey: Constants.modelNameKey(provider: llmProvider.rawValue)) }
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
        self.launchAtLogin = UserDefaults.standard.object(forKey: Constants.launchAtLoginKey) as? Bool ?? true
        self.showDockIcon = UserDefaults.standard.object(forKey: Constants.showDockIconKey) as? Bool ?? false
        self.autoCopy = UserDefaults.standard.object(forKey: Constants.autoCopyKey) as? Bool ?? true
        self.keepHistory = UserDefaults.standard.object(forKey: Constants.keepHistoryKey) as? Bool ?? true

        let posRaw = UserDefaults.standard.string(forKey: Constants.panelPositionKey) ?? PanelPosition.screenRight.rawValue
        self.panelPosition = PanelPosition(rawValue: posRaw) ?? .screenRight

        let providerRaw = UserDefaults.standard.string(forKey: Constants.llmProviderKey) ?? LLMProviderConfig.qwen.rawValue
        let providerConfig = LLMProviderConfig(rawValue: providerRaw) ?? .qwen
        self.llmProvider = providerConfig

        // One-time migration of pre-0.0.3 flat keys into per-provider storage
        Self.migrateLegacySettings(providerRawValue: providerConfig.rawValue)

        self.apiBaseURL = UserDefaults.standard.string(forKey: Constants.apiBaseURLKey(provider: providerConfig.rawValue)) ?? ""
        self.modelName = UserDefaults.standard.string(forKey: Constants.modelNameKey(provider: providerConfig.rawValue)) ?? ""

        self.hotkeyEnabled = UserDefaults.standard.object(forKey: Constants.hotkeyEnabledKey) as? Bool ?? true

        // Load API key from Keychain
        let apiKeyKey = "apikey.\(self.llmProvider.rawValue)"
        self.apiKey = KeychainService.shared.loadOrNil(key: apiKeyKey) ?? ""

        // Init complete, enable didSet side effects
        isInitializing = false
    }

    // MARK: - Migration

    /// Moves values stored under the legacy flat keys (`apiBaseURL`, `modelName`)
    /// to the per-provider keys of the currently selected provider, then removes
    /// the legacy entries. No-op for fresh installs.
    private static func migrateLegacySettings(providerRawValue: String) {
        let defaults = UserDefaults.standard

        let urlKey = Constants.apiBaseURLKey(provider: providerRawValue)
        if defaults.string(forKey: urlKey) == nil,
           let legacyURL = defaults.string(forKey: Constants.legacyApiBaseURLKey) {
            defaults.set(legacyURL, forKey: urlKey)
        }
        defaults.removeObject(forKey: Constants.legacyApiBaseURLKey)

        let modelKey = Constants.modelNameKey(provider: providerRawValue)
        if defaults.string(forKey: modelKey) == nil,
           let legacyModel = defaults.string(forKey: Constants.legacyModelNameKey) {
            defaults.set(legacyModel, forKey: modelKey)
        }
        defaults.removeObject(forKey: Constants.legacyModelNameKey)
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
                let provider = try LLMService.shared.createProvider(
                    config: llmProvider,
                    apiKey: apiKey,
                    baseURL: apiBaseURL.isEmpty ? nil : apiBaseURL,
                    modelName: modelName.isEmpty ? nil : modelName
                )

                let success = try await provider.testConnection()
                await MainActor.run {
                    isTestingConnection = false
                    connectionTestResult = success ? .success : .failure("连接失败")
                }
            } catch LLMError.apiKeyMissing {
                await MainActor.run {
                    isTestingConnection = false
                    connectionTestResult = .failure("API Key 未配置")
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
        // 优先恢复该服务商已保存的配置，否则预填默认值（让用户看到默认值并可修改）
        apiBaseURL = UserDefaults.standard.string(forKey: Constants.apiBaseURLKey(provider: llmProvider.rawValue))
            ?? llmProvider.defaultBaseURL
        modelName = UserDefaults.standard.string(forKey: Constants.modelNameKey(provider: llmProvider.rawValue))
            ?? llmProvider.defaultModel
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
