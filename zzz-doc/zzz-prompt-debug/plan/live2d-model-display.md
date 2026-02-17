# 桌宠 Live2D 模型展示与随机表情播放实现计划

## 目标
1. 展示 Live2D 模型
2. 实现随机播放表情功能

## 当前项目状态
- 已有 Electron + Vite + TypeScript 基础结构
- 已有 Live2D 模型文件 (`frontend/models/jk-cat/`)
- 模型包含多个表情文件 (`.exp3.json`)
- **尚未安装** React 和 `pixi-live2d-display`

## 表情文件列表（可用于随机播放）
| 文件名 | 描述 |
|--------|------|
| 脸红.exp3.json | 脸红表情 |
| 眼-星星眼.exp3.json | 星星眼 |
| 眼-爱心眼.exp3.json | 爱心眼 |
| 眼-哭哭.exp3.json | 哭泣 |
| 眼-生气.exp3.json | 生气 |
| 眼-泪眼汪汪.exp3.json | 泪眼汪汪 |
| 眼-眩晕流汗.exp3.json | 眩晕流汗 |
| 吐舌.exp3.json | 吐舌 |
| 脸黑.exp3.json | 脸黑 |

---

## 实现步骤

### 阶段一：环境准备与依赖安装

#### 1.1 安装 React 相关依赖
```bash
cd frontend
pnpm add react react-dom
pnpm add -D @types/react @types/react-dom @vitejs/plugin-react
```

#### 1.2 安装 Live2D 渲染依赖
```bash
pnpm add pixi.js pixi-live2d-display
```

#### 1.3 安装 SCSS 依赖
```bash
pnpm add -D sass
```

#### 1.4 配置 Vite 支持 React
- 修改 `vite.renderer.config.ts` 添加 React 插件
- 修改 `tsconfig.json` 添加 JSX 支持

> **样式方案**：使用 **SCSS + CSS Module（仅最外层）**
> - **最外层**：`App.module.scss` 使用 CSS Module
> - **内层组件**：样式写在 `global.scss` 中，用 `:global{}` 包裹
> - Vite 原生支持 CSS Module，无需额外配置

---

### 阶段二：Electron 窗口配置

#### 2.1 修改 `main.ts` - 透明无边框窗口
- 设置 `transparent: true` 实现透明背景
- 设置 `frame: false` 移除窗口边框
- 设置 `alwaysOnTop: true` 保持窗口置顶
- 调整窗口大小适应模型（建议 400x500）
- 设置 `hasShadow: false` 移除阴影

---

### 阶段三：前端组件开发

#### 3.1 目录结构
```
frontend/src/
├── components/
│   └── Live2DWidget/
│       ├── index.tsx              # 主组件
│       ├── index.scss             # 组件样式（:global{} 包裹）
│       ├── Live2DCanvas.tsx       # Canvas 渲染组件
│       ├── useLive2DModel.ts      # 模型加载 Hook
│       └── useRandomExpression.ts # 随机表情 Hook
├── styles/
│   └── global.scss                # 全局样式（body、#root 等）
├── utils/
│   └── expressionManager.ts       # 表情管理工具
├── App.tsx
├── App.module.scss                # 最外层 CSS Module
├── main.tsx
└── vite-env.d.ts
```

> **样式方案说明**：
> - **全局样式** (`global.scss`)：body、#root 等基础样式
> - **最外层** (`App.module.scss`)：使用 CSS Module，`className={styles.xxx}`
> - **内层组件** (`index.scss`)：与组件同级，用 `:global{}` 包裹，使用普通 className
>
> ```tsx
> // App.tsx - 最外层使用 CSS Module
> import styles from './App.module.scss';
> <div className={styles.container}>
>   <Live2DWidget />
> </div>
>
> // Live2DWidget/index.tsx - 内层使用普通 className + 导入样式
> import './index.scss';
> <div className="live2d-widget">
>   <canvas className="live2d-canvas" />
> </div>
>
> // Live2DWidget/index.scss - 内层样式用 :global{} 包裹
> :global {
>   .live2d-widget { ... }
>   .live2d-canvas { ... }
> }
> ```

#### 3.2 组件职责划分

| 组件/文件 | 职责 |
|-----------|------|
| `Live2DWidget/index.tsx` | 主容器，组合 Canvas 和控制逻辑 |
| `Live2DCanvas.tsx` | 负责 PIXI.js Canvas 初始化和渲染 |
| `useLive2DModel.ts` | 加载模型、管理模型实例 |
| `useRandomExpression.ts` | 随机表情定时器逻辑 |
| `expressionManager.ts` | 表情列表配置、随机选择算法 |

---

### 阶段四：核心功能实现

#### 4.1 Live2D 模型加载
```typescript
// 使用 pixi-live2d-display 加载模型
import * as PIXI from 'pixi.js';
import { Live2DModel } from 'pixi-live2d-display';

// 注册 Live2D 模型
Live2DModel.registerTicker(PIXI.Ticker);

// 加载模型
const model = await Live2DModel.from('../models/jk-cat/jk盐.model3.json');
```

#### 4.2 随机表情播放逻辑
```typescript
// 表情配置
const EXPRESSIONS = [
  '脸红',
  '眼-星星眼',
  '眼-爱心眼',
  '眼-哭哭',
  '眼-生气',
  // ... 更多表情
];

// 随机选择并播放表情
const playRandomExpression = () => {
  const randomExpr = EXPRESSIONS[Math.floor(Math.random() * EXPRESSIONS.length)];
  model.expression(randomExpr);
};

// 定时随机播放（如每 5-10 秒）
setInterval(playRandomExpression, 5000 + Math.random() * 5000);
```

---

### 阶段五：样式与交互

#### 5.1 全局样式 (`styles/global.scss`)
```scss
// 真正的全局样式
:global {
  body {
    background: transparent;
    margin: 0;
    overflow: hidden;
  }

  #root {
    width: 100vw;
    height: 100vh;
    background: transparent;
  }
}
```

#### 5.2 最外层样式 (`App.module.scss`)
```scss
.container {
  width: 100vw;
  height: 100vh;
  background: transparent;
}
```

#### 5.3 组件样式 (`components/Live2DWidget/index.scss`)
```scss
:global {
  .live2d-widget {
    width: 100%;
    height: 100%;
    position: relative;
  }

  .live2d-canvas {
    width: 100%;
    height: 100%;
  }

  // 预留拖动区域
  .drag-area {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 60px;
    -webkit-app-region: drag;
  }
}
```

#### 5.3 模型拖动（预留）
- 通过 Electron IPC 实现窗口拖动
- 或使用 `-webkit-app-region: drag`

---

## 文件修改清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `package.json` | 修改 | 添加 React、pixi、sass 依赖 |
| `vite.renderer.config.ts` | 修改 | 添加 React 插件 |
| `tsconfig.json` | 修改 | JSX 配置 |
| `src/main.ts` | 修改 | 透明窗口配置 |
| `src/main.tsx` | 新增 | React 入口 |
| `src/App.tsx` | 新增 | 根组件（使用 CSS Module） |
| `src/App.module.scss` | 新增 | 最外层样式 |
| `src/styles/global.scss` | 新增 | 全局样式（body、#root） |
| `src/components/Live2DWidget/index.tsx` | 新增 | 主组件 |
| `src/components/Live2DWidget/index.scss` | 新增 | 组件样式（:global{}） |
| `src/components/Live2DWidget/Live2DCanvas.tsx` | 新增 | Canvas 渲染组件 |
| `src/components/Live2DWidget/useLive2DModel.ts` | 新增 | 模型加载 Hook |
| `src/components/Live2DWidget/useRandomExpression.ts` | 新增 | 随机表情 Hook |
| `src/utils/expressionManager.ts` | 新增 | 表情管理工具 |
| `src/vite-env.d.ts` | 新增 | CSS Module 类型声明 |
| `index.html` | 新增/修改 | HTML 模板 |

---

## 风险与注意事项

1. **CORS 问题**：本地文件加载可能需要配置 `webSecurity: false`
2. **模型路径**：生产环境需要正确配置模型资源路径
3. **性能**：Live2D 模型渲染需要一定 GPU 资源
4. **表情过渡**：`pixi-live2d-display` 会自动处理表情过渡

---

## 预期效果

1. 启动应用后显示透明窗口，只有 Live2D 模型可见
2. 模型会每隔 5-10 秒随机切换一个表情
3. 窗口可以自由拖动（基础实现）
