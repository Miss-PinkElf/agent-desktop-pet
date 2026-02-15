# Windows + WSL Claude Code 配置共享方案

## 🚀 快速开始（一键配置）

### 前提条件
- ✅ 已安装 Windows 版 cc-switch
- ✅ 已安装 WSL2 (Ubuntu)
- ✅ WSL 中已安装 Claude Code CLI

### 一键配置脚本

在 Windows PowerShell 中运行以下命令：

```powershell
# 1. 备份 WSL 中现有的 Claude 配置
wsl cp -r ~/.claude ~/.claude.backup

# 2. 删除 WSL 中的旧配置目录
wsl rm -rf ~/.claude

# 3. 创建软链接到 Windows 配置目录
wsl ln -s /mnt/c/Users/$env:USERNAME/.claude ~/.claude

# 4. 验证配置
wsl cat ~/.claude/settings.json
```

**配置完成！** 🎉

现在你可以：
- 在 Windows 上使用 cc-switch 管理所有配置
- 在 WSL 中直接使用 `claude` 命令，自动读取 Windows 配置

---

## 📖 详细说明

### 为什么需要这个方案？

#### 问题背景
1. **cc-switch 是 GUI 应用**
   - 提供图形界面、系统托盘等完整功能
   - 只能在 Windows/macOS/Linux 桌面环境运行
   - 在 WSL 中运行需要 WSLg 支持，体验不佳

2. **WSL 中需要 CLI 工具**
   - 开发者习惯在 WSL 中使用命令行工具
   - Claude Code CLI 是命令行版本
   - 需要配置 API Key、端点等信息

3. **配置重复问题**
   - Windows 和 WSL 各自维护配置
   - 切换供应商需要两边都改
   - 容易出现配置不一致

#### 解决方案
```
Windows 环境
├── cc-switch (GUI 应用)
├── 管理所有供应商配置
└── 写入配置到 C:\Users\用户名\.claude\settings.json

WSL 环境
├── Claude Code CLI
├── 通过软链接读取 Windows 配置
└── ~/.claude → /mnt/c/Users/用户名/.claude
```

### 工作原理

#### 1. WSL 文件系统挂载
WSL2 自动将 Windows 文件系统挂载到 `/mnt/c/`：
```
C:\Users\Mobius\.claude  →  /mnt/c/Users/Mobius/.claude
```

#### 2. 软链接技术
```bash
# 在 WSL 中创建软链接
ln -s /mnt/c/Users/Mobius/.claude ~/.claude

# 效果
~/.claude  →  /mnt/c/Users/Mobius/.claude  →  C:\Users\Mobius\.claude
```

#### 3. 配置同步流程
```
Windows cc-switch 切换供应商
    ↓
写入 C:\Users\Mobius\.claude\settings.json
    ↓
WSL 通过软链接自动读取
    ↓
Claude Code CLI 使用新配置
```

### 有什么用？

#### ✅ 优势

1. **统一配置管理**
   - 所有配置在 Windows cc-switch 中管理
   - 图形界面操作，直观便捷
   - 支持多供应商、多配置预设

2. **自动同步**
   - Windows 切换供应商，WSL 立即生效
   - 无需手动复制配置文件
   - 避免配置不一致问题

3. **完整功能体验**
   - 享受 cc-switch 的所有 GUI 功能
   - 系统托盘快速切换
   - 速度测试、导入导出等高级功能

4. **开发效率提升**
   - WSL 中直接使用 `claude` 命令
   - 无需在 WSL 中重复配置
   - 专注于开发工作

#### 📊 对比方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **推荐方案** | 统一管理、自动同步、完整功能 | 需要配置软链接 |
| WSL 中安装 cc-switch | 独立运行 | GUI 体验差、系统托盘不可用 |
| 分别配置 | 简单直接 | 配置重复、容易不一致 |
| 手动复制配置 | 灵活 | 需要手动同步、容易遗忘 |

### 配置文件结构

#### Windows 配置目录
```
C:\Users\Mobius\.claude\
├── settings.json          # 主配置文件（API Key、端点等）
├── history.jsonl          # 历史记录
├── cache/                 # 缓存目录
├── plugins/               # 插件目录
└── ...
```

#### settings.json 示例
```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your-api-key",
    "ANTHROPIC_BASE_URL": "https://api.example.com",
    "ANTHROPIC_MODEL": "claude-3-5-sonnet"
  },
  "includeCoAuthoredBy": false
}
```

### 常见问题

#### Q1: 软链接创建失败？
**A:** 确保 Windows 上存在 `.claude` 目录，cc-switch 会自动创建。

#### Q2: 配置不生效？
**A:** 检查软链接是否正确：
```bash
wsl readlink ~/.claude
# 应该输出：/mnt/c/Users/Mobius/.claude
```

#### Q3: 如何恢复原始配置？
**A:** 使用备份恢复：
```bash
wsl rm ~/.claude
wsl mv ~/.claude.backup ~/.claude
```

#### Q4: 支持其他 CLI 工具吗？
**A:** 支持！可以为 Codex、Gemini 等创建类似的软链接：
```bash
# Codex
wsl ln -s /mnt/c/Users/Mobius/.codex ~/.codex

# Gemini
wsl ln -s /mnt/c/Users/Mobius/.gemini ~/.gemini
```

### 高级用法

#### 多用户配置
如果 Windows 和 WSL 使用不同用户名，需要调整路径：
```bash
# 假设 Windows 用户是 Mobius，WSL 用户是 ubuntu
wsl ln -s /mnt/c/Users/Mobius/.claude ~/.claude
```

#### 云同步配置
在 cc-switch 中设置自定义配置目录到云同步文件夹：
```
C:\Users\Mobius\OneDrive\.claude
```
然后在 WSL 中创建软链接：
```bash
wsl ln -s /mnt/c/Users/Mobius/OneDrive/.claude ~/.claude
```

#### 团队协作
将配置目录放到共享文件夹，团队成员可以共享配置：
```bash
# 共享配置目录
\\server\shared\.claude

# WSL 挂载后创建软链接
wsl ln -s /mnt/server/shared/.claude ~/.claude
```

### 总结

这个方案通过软链接技术，实现了 Windows GUI 应用和 WSL CLI 工具之间的配置共享，既享受了 cc-switch 的完整功能，又保持了 WSL 开发环境的便捷性。

**核心价值：**
- 🎯 统一管理 - 一处配置，处处生效
- 🔄 自动同步 - 切换即生效
- 💪 完整功能 - 享受所有 GUI 特性
- ⚡ 高效开发 - 专注于代码编写

---

**配置完成后，你就可以在 Windows 上使用 cc-switch 管理所有配置，WSL 中的 Claude Code 会自动使用这些配置！** 🎉
