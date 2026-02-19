# WSL2 Electron WebGL GPU 渲染验证报告

## 目标
在 WSL2 中使用 GPU 进行 WebGL 渲染，并通过 Electron 展示 Live2D 模型（WebGL 渲染）。

## 环境信息
- 平台: WSL2 / Linux 6.6.87.2-microsoft-standard-WSL2
- 显示会话: DISPLAY=:0, WAYLAND_DISPLAY=wayland-0
- Node.js: v24.11.0, npm: 11.6.1
- GPU: NVIDIA GeForce RTX 3080（nvidia-smi 可见）

## 前因与问题表现
1. WSL2 内默认 OpenGL 渲染走 llvmpipe（软件渲染）。
   - `glxinfo -B` 显示 `OpenGL renderer string: llvmpipe`，`Accelerated: no`。
2. EGL 侧同样落在 llvmpipe，并提示缺少 DRI3/DRM 设备：
   - `eglinfo -B` 提示 `failed to create dri2 screen`、`Ensure your X server supports DRI3`。
   - `/dev/dri` 不存在。
3. Electron 初始运行时 WebGL 被 blocklist：
   - WebGL1/2 均 `supported: false`。
   - GPU_FEATURE_STATUS 中 `webgl: unavailable_off`。

结论：WSL2 能看到 GPU，但默认图形栈未使用 D3D12/ANGLE 导致 WebGL 被禁用或落到软件渲染。

## 排查与验证过程
1. 确认 WSL2 能访问 GPU
   - `/dev/dxg` 存在。
   - `/usr/lib/wsl/lib/nvidia-smi` 正常返回 RTX 3080。

2. 验证 Mesa 驱动可用性
   - `/usr/lib/x86_64-linux-gnu/dri` 存在 `d3d12_dri.so`。

3. 强制 Mesa 走 D3D12 并验证 GL 加速
   - `GALLIUM_DRIVER=d3d12 glxinfo -B`
   - 结果：`Vendor: Microsoft Corporation`、`Device: D3D12 (NVIDIA GeForce RTX 3080)`、`Accelerated: yes`。

4. Electron WebGL 自检程序
   - 创建了最小 Electron 项目，Renderer 里请求 WebGL1/2 并打印 renderer/vendor。
   - 初始运行：WebGL1/2 均不可用。
   - 试过强制 Wayland/EGL/Ozone：由于缺少 DRM 设备，GPU 进程初始化失败。

5. 在 Electron 启动时注入 D3D12 环境变量
   - `GALLIUM_DRIVER=d3d12 MESA_LOADER_DRIVER_OVERRIDE=d3d12 LIBGL_ALWAYS_SOFTWARE=0`
   - 结果：WebGL1 可用，renderer 为 D3D12 (RTX 3080)。
   - WebGL2 仍为 `supported: false`。

## 解决方法（可复用）
核心是强制 Mesa 使用 D3D12 驱动，以避免 llvmpipe 回退。

### 运行方式（已写入 npm script）
在 `/home/mobius/wsl2-webgl-check` 中执行：

```bash
npm run start
```

对应的启动命令实际是：

```bash
GALLIUM_DRIVER=d3d12 MESA_LOADER_DRIVER_OVERRIDE=d3d12 LIBGL_ALWAYS_SOFTWARE=0 electron .
```

### 关键结果（成功判断）
日志中出现以下关键 renderer 表示 WebGL1 已走 GPU：

```text
renderer: ANGLE (Microsoft Corporation, D3D12 (NVIDIA GeForce RTX 3080), OpenGL 4.6)
```

WebGL 自检输出：
- WebGL1: `supported: true`
- WebGL2: `supported: false`

## 现状结论
1. WSL2 中 Electron WebGL1 已可通过 D3D12 使用 RTX 3080 渲染。
2. WebGL2 当前仍不可用（可能受 WSLg/ANGLE/Mesa D3D12 限制）。
3. GPU_FEATURE_STATUS 显示 WebGL/WEBGPU 开启，说明 GPU 通道已打通。

## 工程位置与文件
- 项目目录: `/home/mobius/wsl2-webgl-check`
- 主进程入口: `/home/mobius/wsl2-webgl-check/main.js`
- 自检页面: `/home/mobius/wsl2-webgl-check/index.html`
- 启动脚本: `/home/mobius/wsl2-webgl-check/package.json`

## 注意事项
- Electron 日志中的 DBus 报错是 WSL 常见现象，不影响 GPU/WebGL 使用。
- 如果不设置 D3D12 环境变量，通常会退回 llvmpipe，WebGL 被禁用或走软件渲染。

## 复现步骤（最短路径）
1. 进入项目目录：
   - `cd /home/mobius/wsl2-webgl-check`
2. 启动：
   - `npm run start`
3. 观察终端输出中的 `WEBGL_INFO` 和 renderer 信息。

## 后续可选方向
1. 继续尝试开启 WebGL2（切换 ANGLE 后端或更新 Mesa/WSLg 版本）。
2. 直接把 Live2D 模型接入该 Electron 项目，验证实际渲染链路。
