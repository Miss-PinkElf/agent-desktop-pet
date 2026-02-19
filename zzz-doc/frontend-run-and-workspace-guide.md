# Frontend 启动与 npm workspace 初学者说明

## 1. 背景：为什么你之前必须 `cd frontend`

你项目当前是一个混合仓库：

- `frontend/` 是 Node + npm（Electron/React）
- `backend/` 是 Python

在 npm 里，命令（比如 `npm start`）会读取**当前目录**的 `package.json`。

之前的情况是：

- 根目录没有可用的前端脚本
- 前端脚本只在 `frontend/package.json` 里

所以你在根目录执行 `npm start` 时，npm 找不到前端脚本，只能先进入 `frontend/` 再运行。

---

## 2. 我们已经做了什么（方案 2）

我们已经在仓库根目录新增了 `package.json`，内容核心是：

- `start` -> `npm --prefix frontend run start`
- `frontend:start` -> `npm --prefix frontend run start`

这相当于在根目录做了一个“命令转发器”：

- 你在根目录执行 `npm run start`
- 实际调用的是 `frontend` 里的 `start` 脚本

### 结果

你现在不需要再 `cd frontend` 才能启动前端。

---

## 3. 为什么根目录 `npm i` 还是“看起来没用”

这是很多初学者都会踩的点，逻辑如下：

1. `npm run start` 能成功，是因为你写了“转发脚本”
2. 但 `npm i` 不是脚本，它默认只安装**当前目录** `package.json` 的依赖
3. 根目录 `package.json` 目前没有前端依赖
4. 所以根目录直接 `npm i` 不会帮你安装 `frontend` 依赖

### 你现在正确的前端安装方式

- 在 `frontend/` 执行：`npm i`
- 或在根目录执行：`npm --prefix frontend i`

这两种是等价的。

---

## 4. workspace 是什么，解决了什么问题

`npm workspaces` 是 npm 官方功能（npm v7+），用于管理一个仓库里的多个 Node 子项目。

你可以把它理解为：

- 以前：你手动告诉 npm 去 `frontend` 做事
- 现在（workspace）：你在根目录声明“`frontend` 是我的子项目”，npm 就会统一管理

### 它能解决什么

- 根目录 `npm i` 可以安装 workspace 子项目依赖（包含前端）
- 根目录可运行子项目命令：`npm run -w frontend start`
- 根目录可安装指定子项目依赖：`npm i axios -w frontend`

### 不用 workspace 会怎样

不会出错，也能开发；只是你需要持续使用：

- `cd frontend` 或
- `npm --prefix frontend ...`

也就是说，不用 workspace 不是“错”，只是“统一性和效率没那么高”。

---

## 5. Node + Python 混合项目会不会冲突

不会。

- npm workspace 只管 Node 子项目（例如 `frontend`）
- Python 后端继续用自己的工具（`pip` / `venv` / `poetry` / `uv`）

关键原则：

- 不要把 `backend` 写进 npm `workspaces`

这样两套生态互不影响。

---

## 6. 方案分类与适用场景

| 方案 | 技术类型 | 学习成本 | 使用体验 | 适合谁 |
| --- | --- | --- | --- | --- |
| `cd frontend && npm ...` | 手动目录切换 | 最低 | 一般 | 刚开始、临时用 |
| 根脚本转发（当前） | npm 脚本代理 | 低 | 好（启动方便） | 单前端项目，先快用起来 |
| npm workspace | npm 官方多包管理 | 中 | 更统一（安装/运行都在根） | 想长期规范、可能扩展多个 Node 子项目 |
| monorepo 工具（turbo/nx） | 工程化平台 | 较高 | 大项目更强 | 多团队、多子包、CI 优化需求明显 |

---

## 7. 给你当前项目的推荐路线

### 阶段 A（你现在）

先保持当前方案（根脚本转发），马上可用：

- 启动：`npm run start`（根目录）
- 装前端包：`npm --prefix frontend i <pkg>`

### 阶段 B（你觉得安装命令不够顺手时）

升级到 workspace：

- 好处是根目录 `npm i` 也会照顾到前端依赖
- 前端命令也能统一成 `npm run -w frontend ...`

---

## 8. 常用命令速查（按当前方案）

- 启动前端：`npm run start`
- 显式启动前端：`npm run frontend:start`
- 安装前端全部依赖：`npm --prefix frontend i`
- 给前端安装包：`npm --prefix frontend i axios`
- 给前端安装开发依赖：`npm --prefix frontend i -D eslint`
- 前端打包：`npm --prefix frontend run package`

---

## 9. 一句话总结

你现在的问题本质不是“命令错了”，而是“npm 默认只看当前目录”。

我们已经通过根脚本解决了“启动必须进子目录”的痛点；
如果你还想解决“根目录 `npm i` 没装到前端”的痛点，再升级到 npm workspace 就是下一步。
