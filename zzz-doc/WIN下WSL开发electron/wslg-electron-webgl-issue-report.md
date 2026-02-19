# WSLg + Electron + Live2D WebGL 问题报告

## 背景
- 开发环境: Windows 10 企业版 LTSC 21H2 (OS 19044.6937)
- 硬件: NVIDIA GeForce RTX 3080
- 运行方式: WSL2 + WSLg + Electron (electron-forge + Vite)
- 渲染库: pixi.js + pixi-live2d-display
- 现象: Live2D 模型不显示，控制台报 WebGL unsupported

## 关键症状
- 浏览器控制台报错:
  - `WebGL unsupported in this browser, use "pixi.js-legacy" for fallback canvas2d support.`
- DevTools 执行 `document.createElement('canvas').getContext('webgl')` 返回 `null`
- `chrome://gpu` 显示:
  - WebGL / OpenGL / GPU compositing 全部 Disabled
  - `GPU process was unable to boot`

## 排查过程 (简要)
1) 诊断 WSL GPU/图形链路
   - `nvidia-smi` 正常，说明 CUDA 可见
   - `glxinfo -B` 显示 `OpenGL renderer string: llvmpipe`，说明仍是软件渲染
   - 强制 D3D12:
     - `MESA_LOADER_DRIVER_OVERRIDE=d3d12 GALLIUM_DRIVER=d3d12 glxinfo -B`
     - 输出 `D3D12 (NVIDIA GeForce RTX 3080)`，说明 D3D12 路径可用

2) Electron GPU 侧验证
   - `chrome://gpu` 导出显示:
     - `GL implementation parts : (gl=disabled,angle=none)`
     - `GPU process was unable to boot`
   - 日志显示 GPU 进程初始化失败，常见错误:
     - `Requested GL implementation (gl=none,angle=none) not found in allowed implementations`
     - `drmGetDevices2() has not found any devices`
     - `Failed to find drm render node path`

3) 尝试的修复/配置
   - WSLg 环境变量:
     - `MESA_LOADER_DRIVER_OVERRIDE=d3d12`
     - `GALLIUM_DRIVER=d3d12`
     - `LIBGL_DRIVERS_PATH=/usr/lib/wsl/lib`
     - `LD_LIBRARY_PATH=/usr/lib/wsl/lib:$LD_LIBRARY_PATH`
   - Electron 启动参数:
     - `--ignore-gpu-blocklist`
     - `--enable-webgl` / `--enable-webgl2`
     - `--use-gl=egl-angle`
     - `--use-angle=opengl` / `opengles` / `vulkan` (多次尝试)
     - `--ozone-platform=wayland`
     - `--enable-features=UseOzonePlatform`
   - 结论: GPU 进程仍无法启动，WebGL 继续被禁用

## 结论与根因
### 结论
在当前 WSLg 环境中，Electron 的 GPU 进程无法成功初始化，导致 WebGL 被禁用，Live2D 无法显示。

### 根因
- WSLg 图形链路仍走软件渲染 (llvmpipe)
- Electron/Chromium 在 WSLg 下无法找到 DRM render node (`drmGetDevices2` 失败)
- GPU 进程启动失败 -> WebGL 被强制禁用

换句话说: CUDA/`nvidia-smi` 可用不代表 WSLg 图形加速可用，Electron 需要的 GPU 渲染通路仍未建立。

## 已做的改动/工具
### 代码改动
- `frontend/package.json`
  - 启动脚本添加 WSLg D3D12 环境变量
- `frontend/src/main.ts`
  - 添加 WSLg 相关环境变量
  - 强制 Wayland/Ozone
  - GPU 日志开关
  - `DEBUG_UI`/`OPEN_GPU_PAGE` 调试开关

### 新增脚本
- `frontend/scripts/wsl_gpu_check.py`
  - 用于检查 WSL GPU / OpenGL / Vulkan 可用性

## 解决方案建议
### 可行方案
1) 在 Windows 原生环境运行 Electron (最稳定，GPU 兼容性最好)
2) 使用 SwiftShader (CPU 软渲染) 或 `pixi.js-legacy` 作为降级方案

### 如果坚持 WSLg
- 必须让 `glxinfo -B` 显示 NVIDIA 而不是 llvmpipe
- 需要确认:
  - WSLg 组件版本正确
  - NVIDIA WSL 驱动已安装并生效
  - WSLg 能提供 DRM render node (否则 GPU 进程仍会失败)

## 当前状态
- WebGL 仍不可用 (`getContext('webgl') === null`)
- Electron GPU 进程无法启动
- Live2D 无法在 WSLg 中用 GPU 渲染
