# initMac 验收清单（M4 Mac mini）

## 1) 执行顺序
1. 安装初始化：`bash scripts/init-mac.sh`
2. 校验结果：`bash scripts/verify-init.sh`
3. 如需重置环境：`bash scripts/reset-init-mac.sh --yes`
4. 深度重置（含 Homebrew + CLT）：`bash scripts/reset-init-mac.sh --yes --remove-bootstrap`

## 2) CLI 工具验收
- `brew --version`
- `python3.11 --version`
- `node --version`
- `npm --version`
- `pnpm --version`
- `git --version`
- `opencode --version`
- `claudecode --version`

全部命令可执行即通过。

## 3) 镜像配置验收
- `npm config get registry` 结果应为 `https://registry.npmmirror.com/` 或无尾斜杠同值
- `pnpm config get registry` 结果应为 `https://registry.npmmirror.com/` 或无尾斜杠同值
- `~/.pip/pip.conf` 中应包含国内镜像 `index-url`

## 4) GUI 软件验收
应用程序目录应存在以下应用：
- `Visual Studio Code.app`
- `Google Chrome.app`
- `Microsoft Edge.app`
- `QQ.app`
- `WeChat.app`
- `Trae.app`（若 cask 不可用，按手动安装回退）

## 5) 终端与键盘验收
- 打开新终端后，`starship` 提示符可见
- `zoxide` 可用（执行 `zoxide --version`）
- `fzf` 可用（执行 `fzf --version`）
- 外接 Windows 键盘在系统设置中完成修饰键调整（按个人习惯）

## 6) Clash 说明
- 脚本默认不强制安装 Clash
- 需要时可安装 `Clash Verge Rev` 或 `ClashX`
- 导入订阅/配置请使用你自己的私有配置，不写入仓库

## 7) 失败回退
- 单个 cask 失败：可手动安装后继续执行 `verify`
- npm 全局权限问题：脚本会自动回退到用户级 prefix（`~/.npm-global`）
- 环境异常：先执行 `reset-init-mac.sh` 后再重新安装
