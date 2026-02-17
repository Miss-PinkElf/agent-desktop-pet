# Live2D 桌宠开发计划

## 项目概述

一个基于 Electron + React + Live2D 的桌面宠物应用，支持模型展示、拖动、悬浮菜单、窗口识别等功能。

---

## 技术栈

| 类别 | 选型 |
|------|------|
| 桌面框架 | Electron |
| 前端框架 | React + TypeScript |
| 构建工具 | Vite |
| 包管理器 | pnpm |
| Live2D 渲染 | pixi.js + pixi-live2d-display |
| 模型格式 | .model3.json (Live2D Cubism 3/4/5) |

---

## 项目结构

```
frontend/
├── src/
│   ├── main.ts              # Electron 主进程
│   ├── preload.ts           # 预加载脚本
│   ├── renderer.ts          # React 入口
│   ├── index.css            # 全局样式
│   ├── components/          # React 组件
│   │   ├── Live2DViewer/    # Live2D 查看器组件
│   │   │   ├── index.tsx
│   │   │   ├── Live2DViewer.tsx
│   │   │   └── useLive2DModel.ts
│   │   ├── DraggableWindow/ # 可拖动窗口组件
│   │   │   ├── index.tsx
│   │   │   └── DraggableWindow.tsx
│   │   ├── HoverMenu/       # 悬浮菜单组件
│   │   │   ├── index.tsx
│   │   │   ├── HoverMenu.tsx
│   │   │   └── MenuItem.tsx
│   │   ├── DialogBox/       # 对话框组件
│   │   │   ├── index.tsx
│   │   │   ├── DialogBox.tsx
│   │   │   └── Bubble.tsx
│   │   └── MiniBall/        # 全屏模式小球组件
│   │       ├── index.tsx
│   │       └── MiniBall.tsx
│   ├── hooks/               # 自定义 Hooks
│   │   ├── useWindowInfo.ts
│   │   ├── useDraggable.ts
│   │   └── useLive2DControl.ts
│   ├── services/            # 服务层
│   │   └── windowService.ts
│   ├── types/               # 类型定义
│   │   └── index.ts
│   └── utils/               # 工具函数
│       └── constants.ts
├── models/                  # Live2D 模型文件
│   └── jk-cat/
│       └── jk盐.model3.json
└── public/                  # 静态资源
```

---

## 阶段一：模型展示（当前）

### 目标
在透明无边框的 Electron 窗口中展示 Live2D 模型

### 实施步骤

#### Step 1: 安装依赖

```bash
pnpm add react react-dom
pnpm add -D @types/react @types/react-dom
pnpm add pixi.js pixi-live2d-display
```

#### Step 2: 配置 Vite 支持 React

修改 `vite.renderer.config.ts`：

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': '/src',
    },
  },
  publicDir: '../public',
  assetsInclude: ['**/*.moc3', '**/*.model3.json', '**/*.physics3.json', '**/*.exp3.json', '**/*.motion3.json'],
});
```

#### Step 3: 修改 Electron 主进程

修改 `src/main.ts`：

```typescript
const createWindow = () => {
  const mainWindow = new BrowserWindow({
    width: 400,
    height: 500,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    backgroundColor: '#00000000',
    skipTaskbar: true,
    resizable: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  // 加载应用
  if (MAIN_WINDOW_VITE_DEV_SERVER_URL) {
    mainWindow.loadURL(MAIN_WINDOW_VITE_DEV_SERVER_URL);
  } else {
    mainWindow.loadFile(path.join(__dirname, `../renderer/${MAIN_WINDOW_VITE_NAME}/index.html`));
  }

  // 开发环境打开 DevTools
  if (process.env.NODE_ENV === 'development') {
    mainWindow.webContents.openDevTools();
  }
};
```

#### Step 4: 修改全局样式

修改 `src/index.css`：

```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: transparent;
}

#root {
  width: 100%;
  height: 100%;
  background: transparent;
}
```

#### Step 5: 创建 Live2D React 组件

##### 5.1 创建 `src/components/Live2DViewer/useLive2DModel.ts`

```typescript
import { useEffect, useRef, useState } from 'react';
import * as PIXI from 'pixi.js';
import { Live2DModel } from 'pixi-live2d-display';

export interface Live2DModelOptions {
  modelPath: string;
  width?: number;
  height?: number;
  x?: number;
  y?: number;
  scale?: number;
}

export const useLive2DModel = (options: Live2DModelOptions) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const appRef = useRef<PIXI.Application | null>(null);
  const modelRef = useRef<Live2DModel | null>(null);
  const [isLoaded, setIsLoaded] = useState(false);

  useEffect(() => {
    if (!canvasRef.current) return;

    const init = async () => {
      await PIXI.init({
        canvas: canvasRef.current,
        backgroundAlpha: 0,
        resizeTo: window,
      });

      const app = new PIXI.Application();
      appRef.current = app;

      const model = await Live2DModel.from(options.modelPath);
      modelRef.current = model;

      model.scale.set(options.scale || 1);
      model.x = options.x || 0;
      model.y = options.y || 0;

      app.stage.addChild(model);
      setIsLoaded(true);
    };

    init();

    return () => {
      if (modelRef.current) {
        modelRef.current.destroy();
      }
      if (appRef.current) {
        appRef.current.destroy(true);
      }
    };
  }, [options.modelPath]);

  return { canvasRef, isLoaded, model: modelRef.current };
};
```

##### 5.2 创建 `src/components/Live2DViewer/Live2DViewer.tsx`

```typescript
import React from 'react';
import { useLive2DModel } from './useLive2DModel';

interface Live2DViewerProps {
  modelPath: string;
  width?: number;
  height?: number;
  scale?: number;
}

export const Live2DViewer: React.FC<Live2DViewerProps> = ({
  modelPath,
  width = 400,
  height = 500,
  scale = 1,
}) => {
  const { canvasRef, isLoaded } = useLive2DModel({
    modelPath,
    width,
    height,
    scale,
  });

  return (
    <div
      style={{
        width,
        height,
        position: 'relative',
        background: 'transparent',
      }}
    >
      <canvas
        ref={canvasRef}
        style={{
          width: '100%',
          height: '100%',
          display: 'block',
        }}
      />
      {!isLoaded && (
        <div
          style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            color: '#fff',
          }}
        >
          加载中...
        </div>
      )}
    </div>
  );
};
```

##### 5.3 创建 `src/components/Live2DViewer/index.tsx`

```typescript
export { Live2DViewer } from './Live2DViewer';
export { useLive2DModel } from './useLive2DModel';
```

#### Step 6: 创建 App 组件

创建 `src/App.tsx`：

```typescript
import React from 'react';
import { Live2DViewer } from './components/Live2DViewer';

const App: React.FC = () => {
  return (
    <div style={{ width: '100%', height: '100%', background: 'transparent' }}>
      <Live2DViewer
        modelPath="/models/jk-cat/jk盐.model3.json"
        width={400}
        height={500}
        scale={1}
      />
    </div>
  );
};

export default App;
```

#### Step 7: 修改入口文件集成 React

修改 `src/renderer.ts`：

```typescript
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

const root = ReactDOM.createRoot(document.getElementById('root') as HTMLElement);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

修改 `index.html`：

```html
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Agent Desktop Pet</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/renderer.ts"></script>
  </body>
</html>
```

#### Step 8: 配置模型资源路径

在项目根目录创建 `frontend/public/models` 符号链接或复制模型文件：

```bash
# Windows (PowerShell)
New-Item -ItemType SymbolicLink -Path "frontend\public\models" -Target "frontend\models"
```

#### Step 9: 运行测试

```bash
cd frontend
pnpm start
```

### 预期效果

- 启动后显示一个 **透明无边框** 的窗口
- 窗口中央展示 **jk-cat** Live2D 模型
- 模型会有 **眨眼** 等默认动画
- 窗口 **始终置顶**

---

## 阶段二：交互功能

### 目标
实现拖动、悬浮菜单、对话框等基础交互

### 功能清单

| 功能 | 说明 | 组件 |
|------|------|------|
| 拖动移动 | 鼠标拖动模型自由移动 | `DraggableWindow` |
| 悬浮菜单 | hover 模型时显示设置选项 | `HoverMenu` |
| 对话框 | 底部对话框 + 对话气泡 | `DialogBox` + `Bubble` |

### 实施步骤

#### Step 1: 创建可拖动窗口组件

创建 `src/components/DraggableWindow/DraggableWindow.tsx`：

```typescript
import React, { useRef, useState, useCallback } from 'react';

interface DraggableWindowProps {
  children: React.ReactNode;
  onDragStart?: () => void;
  onDragEnd?: () => void;
}

export const DraggableWindow: React.FC<DraggableWindowProps> = ({
  children,
  onDragStart,
  onDragEnd,
}) => {
  const windowRef = useRef<HTMLDivElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (e.button !== 0) return;
    
    setIsDragging(true);
    setDragOffset({
      x: e.clientX - position.x,
      y: e.clientY - position.y,
    });
    onDragStart?.();
  }, [position, onDragStart]);

  const handleMouseMove = useCallback((e: MouseEvent) => {
    if (!isDragging) return;

    setPosition({
      x: e.clientX - dragOffset.x,
      y: e.clientY - dragOffset.y,
    });
  }, [isDragging, dragOffset]);

  const handleMouseUp = useCallback(() => {
    if (isDragging) {
      setIsDragging(false);
      onDragEnd?.();
    }
  }, [isDragging, onDragEnd]);

  React.useEffect(() => {
    if (isDragging) {
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
    }

    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging, handleMouseMove, handleMouseUp]);

  return (
    <div
      ref={windowRef}
      style={{
        position: 'absolute',
        left: position.x,
        top: position.y,
        cursor: isDragging ? 'grabbing' : 'grab',
        userSelect: 'none',
      }}
      onMouseDown={handleMouseDown}
    >
      {children}
    </div>
  );
};
```

#### Step 2: 创建悬浮菜单组件

创建 `src/components/HoverMenu/HoverMenu.tsx`：

```typescript
import React, { useState } from 'react';
import { MenuItem } from './MenuItem';

interface MenuOption {
  label: string;
  icon?: string;
  onClick: () => void;
}

interface HoverMenuProps {
  options: MenuOption[];
  position?: 'top' | 'bottom' | 'left' | 'right';
}

export const HoverMenu: React.FC<HoverMenuProps> = ({
  options,
  position = 'top',
}) => {
  const [isVisible, setIsVisible] = useState(false);

  const getPositionStyles = () => {
    const base = { position: 'absolute' as const, zIndex: 1000 };
    switch (position) {
      case 'top':
        return { ...base, bottom: '100%', left: '50%', transform: 'translateX(-50%)' };
      case 'bottom':
        return { ...base, top: '100%', left: '50%', transform: 'translateX(-50%)' };
      case 'left':
        return { ...base, right: '100%', top: '50%', transform: 'translateY(-50%)' };
      case 'right':
        return { ...base, left: '100%', top: '50%', transform: 'translateY(-50%)' };
    }
  };

  return (
    <div
      style={{ position: 'relative', display: 'inline-block' }}
      onMouseEnter={() => setIsVisible(true)}
      onMouseLeave={() => setIsVisible(false)}
    >
      {isVisible && (
        <div style={getPositionStyles()}>
          <div
            style={{
              background: 'rgba(255, 255, 255, 0.95)',
              borderRadius: '8px',
              boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
              padding: '8px 0',
              minWidth: '120px',
            }}
          >
            {options.map((option, index) => (
              <MenuItem
                key={index}
                label={option.label}
                icon={option.icon}
                onClick={() => {
                  option.onClick();
                  setIsVisible(false);
                }}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
```

创建 `src/components/HoverMenu/MenuItem.tsx`：

```typescript
import React from 'react';

interface MenuItemProps {
  label: string;
  icon?: string;
  onClick: () => void;
}

export const MenuItem: React.FC<MenuItemProps> = ({ label, icon, onClick }) => {
  return (
    <div
      onClick={onClick}
      style={{
        padding: '8px 16px',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        transition: 'background 0.2s',
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.background = 'rgba(0, 0, 0, 0.05)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.background = 'transparent';
      }}
    >
      {icon && <span>{icon}</span>}
      <span style={{ fontSize: '14px', color: '#333' }}>{label}</span>
    </div>
  );
};
```

#### Step 3: 创建对话框组件

创建 `src/components/DialogBox/DialogBox.tsx`：

```typescript
import React from 'react';
import { Bubble } from './Bubble';

interface DialogBoxProps {
  message: string;
  speaker?: string;
  avatar?: string;
  onSendMessage?: (message: string) => void;
}

export const DialogBox: React.FC<DialogBoxProps> = ({
  message,
  speaker = '🐱',
  onSendMessage,
}) => {
  const [inputValue, setInputValue] = React.useState('');

  const handleSend = () => {
    if (inputValue.trim() && onSendMessage) {
      onSendMessage(inputValue);
      setInputValue('');
    }
  };

  return (
    <div
      style={{
        position: 'absolute',
        bottom: '20px',
        left: '50%',
        transform: 'translateX(-50%)',
        width: '300px',
      }}
    >
      <Bubble message={`${speaker}: ${message}`} />
      {onSendMessage && (
        <div
          style={{
            marginTop: '10px',
            display: 'flex',
            gap: '8px',
          }}
        >
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
            placeholder="输入消息..."
            style={{
              flex: 1,
              padding: '8px 12px',
              borderRadius: '20px',
              border: '1px solid #ddd',
              outline: 'none',
              fontSize: '14px',
            }}
          />
          <button
            onClick={handleSend}
            style={{
              padding: '8px 16px',
              borderRadius: '20px',
              border: 'none',
              background: '#4CAF50',
              color: '#fff',
              cursor: 'pointer',
              fontSize: '14px',
            }}
          >
            发送
          </button>
        </div>
      )}
    </div>
  );
};
```

创建 `src/components/DialogBox/Bubble.tsx`：

```typescript
import React from 'react';

interface BubbleProps {
  message: string;
}

export const Bubble: React.FC<BubbleProps> = ({ message }) => {
  return (
    <div
      style={{
        background: 'rgba(255, 255, 255, 0.95)',
        borderRadius: '12px',
        padding: '12px 16px',
        boxShadow: '0 2px 8px rgba(0, 0, 0, 0.1)',
        fontSize: '14px',
        color: '#333',
        lineHeight: '1.5',
      }}
    >
      {message}
    </div>
  );
};
```

#### Step 4: 更新 App 组件

更新 `src/App.tsx`：

```typescript
import React, { useState } from 'react';
import { Live2DViewer } from './components/Live2DViewer';
import { DraggableWindow } from './components/DraggableWindow';
import { HoverMenu } from './components/HoverMenu';
import { DialogBox } from './components/DialogBox';

const App: React.FC = () => {
  const [message, setMessage] = useState('你好！我是你的桌宠～');

  const menuOptions = [
    { label: '设置', icon: '⚙️', onClick: () => console.log('设置') },
    { label: '语音', icon: '🎤', onClick: () => console.log('语音') },
    { label: '对话', icon: '💬', onClick: () => console.log('对话') },
    { label: '退出', icon: '❌', onClick: () => console.log('退出') },
  ];

  return (
    <DraggableWindow>
      <div style={{ width: '100%', height: '100%', background: 'transparent' }}>
        <HoverMenu options={menuOptions} position="top">
          <Live2DViewer
            modelPath="/models/jk-cat/jk盐.model3.json"
            width={400}
            height={500}
            scale={1}
          />
        </HoverMenu>
        <DialogBox
          message={message}
          onSendMessage={(msg) => setMessage(msg)}
        />
      </div>
    </DraggableWindow>
  );
};

export default App;
```

---

## 阶段三：窗口管理

### 目标
实现窗口识别、贴边停靠、全屏模式等功能

### 功能清单

| 功能 | 说明 | 实现方式 |
|------|------|----------|
| 窗口识别 | 自动识别当前活动窗口 | Windows API + IPC |
| 贴边停靠 | 在当前窗口边缘贴边 | 计算窗口位置 |
| 随机窗口 | 多窗口时随机选择 | 随机算法 |
| 全屏模式 | 全屏时变成下拉小球 | 监听全屏事件 |

### 实施步骤

#### Step 1: 创建窗口服务

创建 `src/services/windowService.ts`：

```typescript
interface WindowInfo {
  title: string;
  bounds: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
  isFullscreen: boolean;
}

export const windowService = {
  async getActiveWindow(): Promise<WindowInfo | null> {
    return new Promise((resolve) => {
      window.electronAPI?.getActiveWindow?.().then(resolve);
    });
  },

  async getAllWindows(): Promise<WindowInfo[]> {
    return new Promise((resolve) => {
      window.electronAPI?.getAllWindows?.().then(resolve);
    });
  },

  dockToWindow(windowInfo: WindowInfo): { x: number; y: number } {
    const petWidth = 400;
    const petHeight = 500;

    return {
      x: windowInfo.bounds.x + windowInfo.bounds.width - petWidth,
      y: windowInfo.bounds.y + windowInfo.bounds.height - petHeight,
    };
  },
};
```

#### Step 2: 创建自定义 Hook

创建 `src/hooks/useWindowInfo.ts`：

```typescript
import { useState, useEffect } from 'react';
import { windowService } from '../services/windowService';

export const useWindowInfo = () => {
  const [activeWindow, setActiveWindow] = useState<any>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);

  useEffect(() => {
    const updateWindowInfo = async () => {
      const window = await windowService.getActiveWindow();
      setActiveWindow(window);
      setIsFullscreen(window?.isFullscreen || false);
    };

    updateWindowInfo();
    const interval = setInterval(updateWindowInfo, 1000);

    return () => clearInterval(interval);
  }, []);

  return { activeWindow, isFullscreen };
};
```

#### Step 3: 创建全屏模式小球组件

创建 `src/components/MiniBall/MiniBall.tsx`：

```typescript
import React from 'react';

interface MiniBallProps {
  onClick: () => void;
}

export const MiniBall: React.FC<MiniBallProps> = ({ onClick }) => {
  return (
    <div
      onClick={onClick}
      style={{
        position: 'absolute',
        top: '20px',
        right: '20px',
        width: '40px',
        height: '40px',
        borderRadius: '50%',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: '0 4px 12px rgba(0, 0, 0, 0.3)',
        transition: 'transform 0.2s',
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.transform = 'scale(1.1)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'scale(1)';
      }}
    >
      <span style={{ fontSize: '20px' }}>🐱</span>
    </div>
  );
};
```

---

## 阶段四：高级功能

### 目标
实现表情/动作控制、用户行为识别等高级功能

### 功能清单

| 功能 | 说明 | 实现方式 |
|------|------|----------|
| 表情控制 | 代码控制模型表情 | Live2D InternalModel API |
| 动作控制 | 播放指定动作 | Motion 管理 |
| 用户行为识别 | 识别用户当前活动 | 多模态模型 + Windows API |

### 实施步骤

#### Step 1: 创建 Live2D 控制 Hook

创建 `src/hooks/useLive2DControl.ts`：

```typescript
import { useRef } from 'react';

export const useLive2DControl = (model: any) => {
  const setExpression = (expressionName: string) => {
    if (!model) return;
    model.internalModel.motionManager.expressionManager?.setExpression(expressionName);
  };

  const playMotion = (groupName: string, motionIndex: number) => {
    if (!model) return;
    model.motion(groupName, motionIndex);
  };

  const setParameter = (paramName: string, value: number) => {
    if (!model) return;
    model.internalModel.coreModel.setParameterValueById(paramName, value);
  };

  return {
    setExpression,
    playMotion,
    setParameter,
  };
};
```

#### Step 2: 集成后端多模态识别

通过 IPC 与后端 Python 服务通信，获取用户行为识别结果。

---

## 文件修改清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `package.json` | 修改 | 添加 React、pixi.js 等依赖 |
| `vite.renderer.config.ts` | 修改 | 配置 React 插件和资源路径 |
| `src/main.ts` | 修改 | 窗口透明、无边框、置顶 |
| `src/index.css` | 修改 | 背景透明、无边距 |
| `src/renderer.ts` | 修改 | React 入口 |
| `index.html` | 修改 | 添加 root 容器 |
| `src/App.tsx` | 新增 | 主应用组件 |
| `src/components/Live2DViewer/` | 新增 | Live2D 查看器组件 |
| `src/components/DraggableWindow/` | 新增 | 可拖动窗口组件 |
| `src/components/HoverMenu/` | 新增 | 悬浮菜单组件 |
| `src/components/DialogBox/` | 新增 | 对话框组件 |
| `src/components/MiniBall/` | 新增 | 全屏小球组件 |
| `src/hooks/` | 新增 | 自定义 Hooks |
| `src/services/` | 新增 | 服务层 |
| `src/types/` | 新增 | 类型定义 |
| `src/utils/` | 新增 | 工具函数 |

---

## 开发命令

```bash
# 安装依赖
pnpm install

# 开发模式
pnpm start

# 构建
pnpm package

# 打包
pnpm make

# Lint
pnpm lint
```

---

## 注意事项

1. **模型路径**：确保模型文件在 `public/models` 目录下可访问
2. **窗口透明**：Windows 下需要禁用 DWM 加速才能完全透明
3. **性能优化**：Live2D 模型较大，注意内存管理
4. **组件拆分**：保持组件单一职责，便于后期维护
5. **类型安全**：充分利用 TypeScript 类型检查

---

## 后续扩展

- [ ] 支持多模型切换
- [ ] 添加主题系统
- [ ] 集成语音合成
- [ ] 添加插件系统
- [ ] 支持自定义动作脚本
