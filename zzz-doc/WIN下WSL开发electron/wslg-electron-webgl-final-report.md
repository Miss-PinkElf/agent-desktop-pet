# WSLg + Electron + Live2D WebGL 问题总结与最终解决方案

## 背景与目标
- 目标: 在 WSL2/WSLg 下让 Electron 使用 GPU 渲染 WebGL，以显示 Live2D 模型。
- 环境:
  - Windows 10 企业版 LTSC 21H2 (OS 19044.6937)
  - WSL2 + WSLg
  - NVIDIA RTX 3080
  - Electron (electron-forge + Vite)
  - 渲染库: pixi.js + pixi-live2d-display

## 问题现象
- Live2D 不显示，控制台报错:
  - `WebGL unsupported in this browser, use "pixi.js-legacy" for fallback canvas2d support.`
- DevTools 中 `document.createElement('canvas').getContext('webgl')` 返回 `null`
- `chrome://gpu` 显示 WebGL / OpenGL / GPU compositing 全部禁用
- GPU 进程启动失败（GPU process was unable to boot）

## 排查过程核心结论
1) WSL 中 CUDA 可见，但图形栈默认走软件渲染
   - `nvidia-smi` 正常只代表 CUDA 可用
   - `glxinfo -B` 显示 `OpenGL renderer: llvmpipe` 说明是 CPU 渲染

2) 强制 Mesa 使用 D3D12 可启用 GPU 渲染链路
   - `MESA_LOADER_DRIVER_OVERRIDE=d3d12 GALLIUM_DRIVER=d3d12 glxinfo -B`
   - 输出 `D3D12 (NVIDIA GeForce RTX 3080)` 说明 D3D12 路径可用

3) Electron 强行指定 GL/ANGLE 反而导致 GPU 进程失败
   - `chrome://gpu` 多次出现:
     - `Requested GL implementation (gl=none,angle=none) not found in allowed implementations`
     - `GPU process was unable to boot`
   - 说明强制参数把 GPU 初始化搞崩，导致 WebGL 被禁用

## 根因总结
- WSLg 默认图形链路落到 llvmpipe（软件渲染）
- Electron 强制 `use-gl/use-angle` 触发 GPU 进程初始化失败
- WebGL2 目前仍受 WSLg/ANGLE/Mesa D3D12 限制不可用

## 最终解决方案（可复用）
核心思路: **只强制 Mesa 走 D3D12，保持 Electron 的 GL/ANGLE 自动选择**，让 WebGL1 正常可用。

### 1) 启动环境变量（关键）
在启动 Electron 时注入:

```bash
MESA_LOADER_DRIVER_OVERRIDE=d3d12 GALLIUM_DRIVER=d3d12 LIBGL_ALWAYS_SOFTWARE=0
```

### 2) Electron 主进程中同步设置环境变量
在 `frontend/src/main.ts` 中设置:

```ts
if (process.platform === 'linux') {
  process.env.MESA_LOADER_DRIVER_OVERRIDE = 'd3d12';
  process.env.GALLIUM_DRIVER = 'd3d12';
  process.env.LIBGL_ALWAYS_SOFTWARE = '0';
  process.env.LIBGL_DRIVERS_PATH = '/usr/lib/wsl/lib';
  const ldLibraryPath = process.env.LD_LIBRARY_PATH ?? '';
  if (!ldLibraryPath.includes('/usr/lib/wsl/lib')) {
    process.env.LD_LIBRARY_PATH = `/usr/lib/wsl/lib${ldLibraryPath ? `:${ldLibraryPath}` : ''}`;
  }
}
```

### 3) 去掉强制 GL/ANGLE 参数
避免 `use-gl` / `use-angle` 强制值导致 GPU 进程失败。

## 实际验证结果
- 在 DevTools 中执行:

```js
document.createElement('canvas').getContext('webgl')
```

- 返回 `WebGLRenderingContext`，表示 WebGL1 成功启用。
- Live2D 在 WSLg 中可正常显示。

## 仍有限制
- WebGL2 仍不可用（当前 WSLg + Mesa D3D12 的限制）
- 若强行切换 `use-angle`/`use-gl`，GPU 进程可能再次失败

## 文件改动摘要
- `frontend/package.json`
  - `start` 脚本加入 D3D12 环境变量
- `frontend/src/main.ts`
  - 添加 D3D12 环境变量注入
  - 移除强制 GL/ANGLE 配置

## 推荐后续维护策略
- 保持 WebGL1 路径稳定，不要强行切换 ANGLE 后端
- 如需 WebGL2 或更稳定 GPU，建议直接在 Windows 原生环境运行 Electron

## 仅在 WSL 生效的启动方式
为避免影响 Windows 原生运行，启动脚本已改为自动检测 WSL，只在 WSL 注入 D3D12 环境变量。

实现方式:
- `frontend/scripts/start.js` 检测 WSL 环境
- 仅当 WSL 时注入以下变量:
  - `MESA_LOADER_DRIVER_OVERRIDE=d3d12`
  - `GALLIUM_DRIVER=d3d12`
  - `LIBGL_ALWAYS_SOFTWARE=0`

Windows 原生运行时不会注入这些变量，不影响本机 GPU/驱动配置。
