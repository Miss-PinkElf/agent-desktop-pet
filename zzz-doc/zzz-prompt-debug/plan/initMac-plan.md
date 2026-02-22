# initMac 实施计划（M4 Mac mini，256G）

## 目标
为新 Mac 提供可重复执行的一键初始化方案，完成开发环境与常用软件安装、国内镜像配置、轻量终端增强，以及 Windows 键盘使用适配。

## 设备约束与默认策略
- 设备：Apple Silicon（M4 Mac mini）
- 存储：256G（优先轻量、实用）
- 默认仅安装 Xcode Command Line Tools（CLT），不安装完整 Xcode
- 键盘映射优先使用系统自带设置，`Karabiner-Elements` 仅作为可选项

## 需求范围
1. 编写 macOS 安装脚本
2. 安装：`brew`、`python 3.11`、最新版 `node`、`git`、`pnpm`、`npm`、`opencode`、`claudecode`（后两者使用 npm 安装）
3. 安装 GUI 软件：`VS Code`、`Chrome`、`Edge`、`Trae`
4. 升级命令行体验并支持 Windows 键盘习惯
5. 提供 Mac 上 Clash 的使用路径
6. 安装 `QQ`、`微信`
7. 配置国内镜像（淘宝源/`npmmirror`）

## 交付物
- `scripts/init-mac.sh`：主安装脚本（可重复执行）
- `scripts/post-config.sh`：终端与键盘相关后置配置脚本
- `scripts/verify-init.sh`：版本与安装结果校验脚本
- `scripts/reset-init-mac.sh`：环境还原脚本（卸载本方案安装内容并清理配置）
- `zzz-doc/zzz-prompt-debug/plan/initMac-checklist.md`：验收清单

## 执行计划

### 阶段 1：预检查与引导
- 检测系统与架构，确认为 macOS + Apple Silicon
- 创建本地日志目录（`~/init-mac-logs`）用于保留安装输出
- 如未安装 CLT，执行 `xcode-select --install`
- 如未安装 Homebrew，完成安装并初始化 shell 环境

### 阶段 2：镜像配置（优先）
- npm 源：`https://registry.npmmirror.com`
- pnpm 源：`https://registry.npmmirror.com`
- pip 源：清华或阿里镜像（脚本中给默认值并支持切换）
- brew 镜像仅作为可选开关（网络慢时启用）

### 阶段 3：CLI 工具安装
- 通过 brew 安装：`python@3.11`、`node`、`git`、`pnpm`、`starship`、`zoxide`、`fzf`
- 通过 npm 全局安装：`opencode`、`claudecode`
- 安装完成后统一进行命令与版本校验

### 阶段 4：GUI 软件安装
- 通过 cask 安装：`visual-studio-code`、`google-chrome`、`microsoft-edge`、`qq`、`wechat`
- `trae` 优先尝试 cask；若仓库无包，输出手动下载安装指引

### 阶段 5：终端与键盘映射
- 保持系统默认 `zsh`
- 增强终端体验（轻量组合）：
  - `starship`：提示符增强
  - `zoxide`：智能目录跳转
  - `fzf`：历史命令/文件模糊搜索
- 键盘映射方案：
  - 主方案：macOS「修饰键」设置适配外接 Windows 键盘
  - 可选方案：仅在需要高级重映射时安装 `karabiner-elements`

### 阶段 6：Clash 方案
- 推荐 `Clash Verge Rev`（备用 `ClashX`）
- 文档提供订阅导入步骤，不写入任何私有配置

### 阶段 7：验收与交接
- 执行 `scripts/verify-init.sh`
- 生成通过/失败清单
- 保留日志与排障说明，便于二次执行

### 阶段 8：还原脚本（重装前清理）
- 提供 `scripts/reset-init-mac.sh`，可一键卸载本方案安装的软件与配置
- 默认清理：npm 全局包、brew 安装的公式与 cask、zsh 增量配置、镜像配置
- 可选深度清理：移除 Homebrew 与 CLT（单独参数触发）

## 验收标准
- 所有要求的 CLI 工具可在终端直接调用
- npm/pnpm 源正确指向 `npmmirror`
- 所需 GUI 软件在应用程序目录可见
- 终端增强生效且不破坏现有 zsh 使用
- Windows 键盘可通过系统映射正常使用
- 未安装完整 Xcode（除非明确提出）
- 还原脚本执行后可重新运行安装脚本，不依赖手工清理

## 风险与回退
- 个别 cask 在不同地区或版本下可能不可用：提供手动安装回退
- 网络不稳定：镜像配置提前，关键安装步骤支持重试
- npm 全局安装可能遇到权限问题：回退到用户级 prefix 方案

## 下一步实施顺序
先实现 `scripts/init-mac.sh`，并同步实现 `scripts/reset-init-mac.sh`，再补 `post-config` 与 `verify` 脚本，最后输出验收清单文档。
