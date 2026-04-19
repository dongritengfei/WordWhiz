# WordWhiz

一款 macOS 原生轻量级文案优化工具，常驻菜单栏，通过全局快捷键一键调用 LLM 大语言模型优化剪贴板文本。

![Platform](https://img.shields.io/badge/platform-macOS%2014.0+-blue)
![Language](https://img.shields.io/badge/language-Swift%205.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 功能特性

- **全局快捷键触发** - 默认 `⌃Z` 一键唤出优化面板，无需切换应用
- **实时流式输出** - LLM 响应逐字呈现，无需等待完整响应
- **多 LLM 服务商支持** - 支持 OpenAI、Anthropic Claude、DeepSeek、通义千问及自定义 OpenAI 兼容接口
- **自定义指令** - 内置 6 种默认指令（润色、翻译、摘要、扩写、正式化、口语化），支持自定义 Prompt
- **历史记录** - 自动保存优化记录，支持搜索和复用
- **锚定模式** - 面板可锚定在当前位置，拖动后记住自定义位置
- **安全存储** - API Key 使用 macOS Keychain 加密存储

## 系统要求

- macOS 14.0+
- Apple Silicon 或 Intel 芯片

## 安装

### 从源码构建

```bash
git clone https://github.com/dongritengfei/WordWhiz.git
cd WordWhiz
xcodebuild -project WordWhiz.xcodeproj -scheme WordWhiz -configuration Release build
```

构建完成后，应用位于 `build/Build/Products/Release/WordWhiz.app`，将其拖入应用程序文件夹即可。

## 使用说明

### 首次配置

1. 启动应用后，在菜单栏点击 WordWhiz 图标
2. 选择"偏好设置..."
3. 在"API 配置"页选择 LLM 服务商并填写 API Key
4. 点击"测试连接"验证配置

### 日常使用

1. **复制文本** - 在任意应用中选中需要优化的文本，按 `⌘ C` 复制
2. **触发优化** - 按 `⌃Z`（默认快捷键）唤出优化面板
3. **查看结果** - 面板实时显示优化后的文本，支持直接编辑
4. **复制使用** - 点击"复制结果"或按 `⌘ ⇧ C`，然后 `⌘ V` 粘贴到目标位置

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌃Z` | 触发优化/显示面板 |
| `⌘ ⇧ C` | 复制结果 |
| `⌘ R` | 重新生成 |
| `⌘ 1-9` | 快速切换指令 |
| `Esc` | 关闭面板 |
| `⌘ ⇧ ,` | 打开设置 |

## 技术栈

- **UI 框架**: SwiftUI
- **数据持久化**: SwiftData
- **全局快捷键**: HotKey (Carbon API)
- **网络请求**: URLSession + AsyncBytes (SSE 流式响应)
- **安全存储**: Keychain Services

## 项目结构

```
WordWhiz/
├── App/                    # 应用入口和生命周期
├── Views/                  # SwiftUI 视图
│   ├── Panel/             # 优化面板相关视图
│   ├── Settings/          # 设置窗口视图
│   └── MenuBar/           # 菜单栏视图
├── ViewModels/            # 视图模型
├── Models/                # 数据模型
├── Services/              # 业务服务
│   ├── LLM/              # LLM API 集成
│   └── ...
├── Utilities/             # 工具类和常量
└── Resources/             # 资源文件
```

## 支持的 LLM 服务商

- [OpenAI](https://openai.com/)
- [Anthropic Claude](https://www.anthropic.com/)
- [DeepSeek](https://www.deepseek.com/)
- [通义千问 (Alibaba)](https://tongyi.aliyun.com/)
- 自定义 OpenAI 兼容接口

## 隐私说明

- API Key 仅存储在本地 macOS Keychain 中，不会上传到任何服务器
- 优化历史记录仅保存在本地 SwiftData 数据库
- 文本优化请求直接发送至用户配置的 LLM 服务商 API

## 开发计划

- [ ] 快捷键绑定到特定指令
- [ ] 批量优化功能
- [ ] 本地 LLM 支持 (Ollama)
- [ ] 浏览器扩展
- [ ] 原地替换文本 (Accessibility API)

## 贡献

欢迎提交 Issue 和 Pull Request。

## 许可证

MIT License

---

**注意**: 本应用需要 macOS 辅助功能权限以注册全局快捷键。首次使用时系统会弹出权限请求对话框，请在"系统设置 > 隐私与安全性 > 辅助功能"中授权。
