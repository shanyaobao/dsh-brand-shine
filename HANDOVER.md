# dsh-brand-shine · 交接文档

> 交接时间：2026-10-29　｜　DSH 版本：桌面版 0.2.1-rc.3（Electron）
> 本文档面向**接手继续开发的新会话**：读完后应能独立继续，不需要回看原对话。

---

## 一、这个项目是什么

做一个 DSH（DeepSeek Harness）**客户端插件**，把侧边栏左上角的官方品牌
（`🐋 deepseek HARNESS`）替换成使用方自己的**公司名 + 公司 Logo**，
并提供一个**品牌设置面板**让非技术用户自己改名字、换图标、调字号。

生产方：闪耀吧教育科技。默认品牌为「鱼骨图标 + 闪耀吧教育科技」。

代码位置：

```
C:\Users\zhuza\Desktop\HTML\dsh-brand-shine\
```

已通过 `link:` 方式装进桌面版 profile：

```
C:\Users\zhuza\.dsh\profiles\desktop\
```

---

## 二、当前状态（最重要，请先看这张表）

| 能力 | 状态 | 说明 |
|---|---|---|
| 品牌替换（图标 + 名字） | ✅ **已验证可用** | 用户确认看到「🐟 闪耀吧教育科技」，图标 8px、文字 15px 常规体 |
| 官方品牌让位 | ✅ 已验证 | profile 里 `ui-brand-official: disabled: true` |
| 「更多」菜单出现「🎨 品牌设置」 | ✅ 已验证 | 用户确认菜单里能看到这一项 |
| 点击菜单项弹出设置面板 | ⚠️ **未验证（最后一版修复待测）** | 上一版是「闪一下就没」，最后一版改成常驻宿主，**尚未经用户确认** |
| 面板内改名 / 上传 Logo / 调字号 | ⚠️ 代码已写完，未验证 | 依赖上一条 |
| 保存后品牌立即更新 | ⚠️ 代码已写完，未验证 | 走 `dsh-brand-shine:changed` 事件 |
| 发布到 npm / GitHub / 插件市场 | ❌ 未开始 | 见第九节清单 |

**接手后的第一件事：让用户重启 DSH 并测试「更多 → 🎨 品牌设置」能否稳定弹出面板。**

---

## 三、文件清单与职责

| 文件 | 大小 | 作用 |
|---|---|---|
| `package.json` | 976 B | 包声明：`dsh.bundle.patch`、`dsh.client`、`engines.dsh` |
| `cordis.patch.yml` | 245 B | bundle 补丁：把 `brand-shine` 行插进 profile 图层栈 |
| `lib/index.js` | 2.6 KB | **宿主侧**：空 `apply`（激活 client bundle 的必要条件）+ 解析 `logoPath` 为 data URL |
| `lib/client.js` | 150 KB / 843 行 | **浏览器侧**：品牌组件 + 设置面板 + 菜单项，全部内联单文件 |
| `assets/logo.png` | 92 KB | 内置默认图标（蓝色鱼骨，515×202 PNG） |
| `scripts/build-logo.mjs` | 1.6 KB | 把 `assets/logo.png` 内联进 `lib/client.js` 的 `BUILTIN_LOGO` |
| `README.md` | 4.6 KB | 面向用户的文档（安装、如何改名、配置字段、卸载） |
| `LICENSE` | MIT | |

`lib/client.js` 内部结构（行号供速查）：

| 行 | 名称 | 作用 |
|---|---|---|
| 37 / 49 / 59 | `loadPrimitives` / `resolveMenuItemButton` / `resolveCreatePortal` | 从宿主共享模块取 `MenuItemButton`、`createPortal` |
| 75 | `DEFAULTS` | 默认配置（name / logo / fontSize=15 / fontWeight=400 / logoHeight=8） |
| 91 | `USER_FIELDS` | 允许用户覆盖的字段白名单 |
| 94 / 97 | `STORAGE_KEY` / `OPEN_EVENT` | localStorage 键、打开设置的事件名 |
| 107–160 | `mergeConfig` / `readUserSettings` / `writeUserSettings` / `clearUserSettings` | 配置合并与持久化 |
| 183 | `BrandMark` | 品牌图标（图片优先，退回字符 `mark`） |
| 234 | `BrandName` | 品牌名（纯文本展示，**不带任何交互**） |
| 261 | `S` | 面板的内联样式表 |
| 396 | `SettingsPanel` | 设置面板 UI（改名 / 上传 / 两个滑块 / 开关 / 预览 / 保存） |
| 667 | `SettingsHost` | **常驻弹窗宿主**：监听 `OPEN_EVENT`，用 portal 把面板挂到 `document.body` |
| 724 | `MoreMenuItem` | 「更多」菜单项，只负责派发 `OPEN_EVENT` |
| 761 | `apply` | 注册三个槽位：brand.mark / brand.name / panellist.actions |

---

## 四、必须知道的技术结论（都是踩坑换来的，别推翻重来）

### 1. 品牌槽位是 `single`，**先注册者胜**，`priority` 不参与排序

`sidebar.brand.mark` 与 `sidebar.brand.name` 都是单占位槽位。DSH 的
`entriesOfSlot()` 对 `single` 槽位**只取第一个未被 abdicate 的注册项**，
`priority` 只用于"同优先级重复注册"的冲突检测，**不是排序键**。

因此必须让官方品牌插件让位，否则我们的组件永远不会被渲染：

```yaml
# C:\Users\zhuza\.dsh\profiles\desktop\cordis.patch.yml 末尾
- id: ui-brand-official
  disabled: true
```

> 官方品牌行 id 是 `ui-brand-official`（定义在 `dsh-web-app/cordis.patch.yml` 第 336 行）。

### 2. 宿主侧**必须**导出 `apply`，否则 client bundle 根本不会被加载

`lib/index.js` 若只 `export const name` 而没有 `apply`，加载器不会为该条目建立 fiber，
`dsh-client-modules` 就不会为它服务 `/plugins/<name>/client.js`。
表现：插件"装了"，但浏览器里完全没有这段代码。

### 3. `peerDependencies` 里写 `@deepseek-ai/*` 会让整个 bundle 被**静默跳过**

`dsh-app-boot` 的 `unmetRequirements()`：没有 `engines.dsh` 时，所有以
`@deepseek-ai/dsh` 开头的 peer 都要匹配运行时版本，不匹配就 `skippedBundles.push(...)`，
**只在 stderr 打一行**，界面上看不出来。

✅ 正确写法（本插件已采用）：

```json
"engines": { "dsh": ">=0.2.1-rc.1" }
```

### 4. client bundle 必须**单文件自包含**

插件路由 `/plugins/<pkg>/client.js` 只服务入口文件；相对路径 `import './x.js'`
不会额外提供资源。本插件曾拆成 `client-store.js` / `client-settings-panel.js`，
后来全部内联合并回 `client.js`。

### 5. client bundle 的固定格式

```js
__ModuleLoader__.load({
  id: 'dsh-brand-shine',
  factory(require) {
    const React = require('react');
    return { inject: ['slots'], apply(ctx, config) { /* ... */ } };
  },
});
```

`inject` 与 `apply` 必须挂在 **factory 返回的对象**上。

### 6. 不要用 `useSyncExternalStore` 配一个"每次返回新对象"的 `getSnapshot`

曾用自定义 store + `useSyncExternalStore` 共享状态，`get()` 每次 `Object.assign({}, ...)`
返回新引用 → React 判定状态一直在变 → 无限重渲染 → 槽位组件崩溃并被标记 abdicate
→ **品牌整个消失**。

现在的做法：普通 `useState` + 自定义事件（`dsh-brand-shine:changed`）通知刷新。

### 7. 品牌区**外层**吃掉了点击事件，所以"点名字打开设置"做不成

`sidebar.brand.*` 外层是官方的"点击新建会话"按钮。在品牌组件里挂
`onClick` / `onPointerDown` / `stopPropagation` / `userSelect:none` **全部无效**
（表现为文字被选中变蓝、或者根本不触发）。**已放弃这条路**，设置入口改走「更多」菜单。

### 8. 「更多」菜单是 portal，选择后整个子树卸载

所以**弹窗的 open 状态不能放在菜单组件里**，否则就是"闪一下就没"。
正确做法：菜单项只 `dispatchEvent(OPEN_EVENT)`，真正的状态放在
**常驻组件** `SettingsHost`（挂在 `sidebar.brand.name` 槽位的组件里）中，
再用 `ReactDOM.createPortal` 挂到 `document.body`。

### 9. 菜单项必须用 DSH 的 `MenuItemButton`

自绘 `<button>` 在 portal 菜单里点不到。从
`@deepseek-ai/dsh-client-ui-primitives` 取 `MenuItemButton`，事件是 `onSelect`。
`package.json` 里要声明：

```json
"dsh": { "client": {
  "inject": ["@deepseek-ai/dsh-client-ui-primitives", "@deepseek-ai/dsh-client-ui-renderer", "@deepseek-ai/dsh-client-ui-sidebar"],
  "external": ["react-dom"],
  "platform": "web"
} }
```

### 10. 图标必须内联成 data URL

`/plugins` 路由不提供任意静态资源。`scripts/build-logo.mjs` 把 PNG 读成 base64
写进 `client.js` 的 `BUILTIN_LOGO`，保持单文件、零额外请求。

### 11. 已验证的视觉参数（用户逐轮确认过）

| 参数 | 值 | 备注 |
|---|---|---|
| `logoHeight` | **8px** | 从 24→16→8，用户最终认可 8 |
| `fontSize` | **15px** | 18→15 |
| `fontWeight` | **400** | 用户明确要求"不要加粗" |
| 字符标志字重 | 400 + `font-style: normal` | 防止继承粗体 |

### 12. `sidebar.footer.action` 试过但不好用

类型是 `list`、作用域 `root`，但按钮会**单独占一行**悬在头像上方，视觉很差，
已放弃，不要再往那里放东西。

---

## 五、安装与验证

### 安装（当前已装好，重新装时用）

```powershell
& "C:\Users\zhuza\AppData\Local\Programs\DeepSeek Harness\resources\runtime\cli\bin\dsh.cmd" `
  plugin --profile desktop add "link:C:/Users/zhuza/Desktop/HTML/dsh-brand-shine"
```

> 这个命令会同时写 `dependencies` 与 `dsh.profile.bundles`。
> 若手动改 `package.json`，**两处都要写**，否则不会被加载。

### 修改后的生效方式（超重要，能省很多来回）

| 改了什么 | 怎么生效 |
|---|---|
| `lib/client.js`、`package.json` 等插件文件 | **重启 DSH**（client bundle 在启动时构建） |
| 只有浏览器端状态（localStorage） | **`Ctrl + Shift + R` 强刷页面**即可 |
| `cordis.patch.yml` | 重启 |

**踩过的坑**：改完一直不生效，是因为只刷新了页面、没重启 DSH。

### 冒烟检查

```powershell
$node = "C:\Program Files\nodejs\node.exe"
& $node --input-type=module -e "
const fs = await import('node:fs');
const src = fs.readFileSync('C:/Users/zhuza/Desktop/HTML/dsh-brand-shine/lib/client.js','utf8');
let cap = null;
new Function('__ModuleLoader__', src)({ load(m) { cap = m } });
const fakeReact = { Fragment:'F', createElement:(t,p,...c)=>({t,p,c}), useState:(v)=>[typeof v==='function'?v():v,()=>{}], useEffect:()=>{} };
const mod = cap.factory((n) => n === 'react' ? fakeReact : (n === 'react-dom' ? { createPortal:(x)=>x } : { MenuItemButton: function(){} }));
console.log('apply:', typeof mod.apply, '| inject:', JSON.stringify(mod.inject));
"
```

**浏览器侧排查**：控制台执行

```js
document.querySelector('style[data-plugin="dsh-brand-shine"]')   // 目前不注入样式，恒为 null
document.querySelectorAll('[data-brand-shine]').length           // 品牌元素数量，正常 ≥1
```

---

## 六、配置方式（两种，用户优先 localStorage）

### 图形界面

`更多 → 🎨 品牌设置`（待验证）→ 改名 / 上传 / 滑块 → 保存 → 侧边栏立即更新。

### 配置文件

```yaml
- id: brand-shine
  name: dsh-brand-shine
  config:
    name: 闪耀吧教育科技
    logoPath: C:/path/to/logo.png   # 宿主读成 data URL
    logoHeight: 8
    fontSize: 15
    fontWeight: 400
```

优先级：**localStorage（用户点过保存）> profile 配置 > 内置默认**。

---

## 七、未完成 / 待验证清单

1. ⚠️ **验证「更多 → 品牌设置」弹窗能否常驻**（`SettingsHost` 这一版）
   - 成功后：进入发布
   - 仍"闪一下就没"：检查 `resolveCreatePortal()` 是否拿到 `react-dom`；
     或退一步直接把面板做成**侧边栏内嵌页**（不再用浮层）
2. ⚠️ 验证面板内：改名保存后品牌立即变、上传图片能预览、恢复默认生效
3. ❌ 弹窗打开时没有做焦点管理 / Esc 之外的点击拦截（面板内已处理 Esc 与遮罩点击）
4. ❌ 多标签页同步只监听了 `storage` 事件，未实测
5. ❌ 没有 i18n（面板文案写死中文）

---

## 八、已知限制（写进 README 了，但仍需注意）

- 只替换侧边栏品牌，不改启动加载画面的 `HARNESS` 字样
- 设置存 localStorage，换浏览器 / 换电脑要重填
- 依赖 `sidebar.brand.*` 与 `sidebar.panellist.actions` 两个槽位名，
  DSH 大版本改动时需跟着改
- 点击品牌名仍是官方"新建会话"行为（这是有意保留的）

---

## 九、发布清单（尚未开始）

1. **npm 包名**：`dsh-brand-shine`（需先 `npm view dsh-brand-shine` 确认没被占；
   被占则改用作用域，如 `@shanqiba/dsh-brand-shine`）
2. **package.json 补全**：`repository`、`homepage`、`bugs`、`author`、`files`（含 assets/scripts）
3. **GitHub 仓库**：公开仓库 + topic `dsh-plugin`（awesome-dsh-plugin 收录要求）
4. **README**：安装 / 卸载 / 配置 / 已知限制（现有版本已覆盖，补仓库链接即可）
5. **提 PR** 到 `awesome-dsh-plugin` 的登记清单
6. **可选**：自建 market index JSON（DSH 的插件市场只认索引 JSON，**没有付费机制**）

> 收费结论（已与用户确认）：DSH 插件市场没有价格/授权字段，
> 1 元收费只能自建商店或做授权校验，成本高于收益；建议先免费发布、做口碑，
> 真有人要定制再谈服务费。

---

## 十、回滚

profile 备份（安装插件前创建）：

```
C:\Users\zhuza\.dsh\profiles\desktop.bak-20261028-000039
```

回滚命令：

```powershell
Copy-Item "C:\Users\zhuza\.dsh\profiles\desktop.bak-20261028-000039\*" `
          "C:\Users\zhuza\.dsh\profiles\desktop\" -Recurse -Force
```

只停用插件（保留安装）：

```yaml
- id: brand-shine
  disabled: true
```

恢复官方品牌：把 `ui-brand-official` 的 `disabled: true` 改回 `false`。

---

## 十一、给接手者的建议

1. **先确认弹窗问题**，这是唯一卡点；品牌显示本身已经很稳，别去动它。
2. 改 `client.js` 前先跑第五节的冒烟脚本，能省掉一轮重启。
3. 每次只改一件事，**一次改多处会很难定位**（本项目已经吃过这个亏）。
4. 用户偏好：**结论先行、中文、少用"首先/其次"**；改完用一句话说明"改了什么 / 怎么生效"。
5. 用户对视觉细节要求明确（字号、粗细都逐轮校准过），改动前先问，不要自行放大加粗。
