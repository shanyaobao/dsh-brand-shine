# dsh-brand-shine

替换DSH侧边栏品牌标识为自定义公司名+Logo，支持到更多-品牌设置调整。

装好之后，从「更多」菜单进入「🎨 品牌设置」就能改名、换 Logo、调整字号图标大小，改完立即生效，不用重启。

## 长什么样

安装前：

```
🐋  deepseek [HARNESS]
```

安装后：

```
🐟  闪耀吧教育科技
```

## 安装后第一件事：填上你自己的公司名

> **安装时默认显示的是「闪耀吧教育科技」和内置图标，请改成你自己的。**

装好并重启 DSH 后：

1. 看侧边栏左上角，会显示「🐟 闪耀吧教育科技」
2. 点侧边栏的 **「更多」** 菜单
3. 选 **「🎨 品牌设置」**
4. 在弹出的窗口里填：
   - **公司名称** —— 改成你的
   - **公司 Logo** —— 点「上传图片」，选一张 PNG / JPG / WebP，建议透明背景、不超过 1MB
   - 用滑块调整**图标高度**和**文字大小**
5. 点「保存」，左上角立即变成你的品牌

设置保存在本机浏览器里，重启、刷新都不会丢。换台电脑需要重新填一次。

## 安装

### 方式一：从 npm

```bash
dsh plugin --profile desktop add dsh-brand-shine
```

### 方式二：从本地目录（开发用）

```bash
dsh plugin --profile desktop add "link:C:/path/to/dsh-brand-shine"
```

安装后**重启 DSH**。

### 还必须做一步：让出官方品牌槽位

侧边栏的品牌位置同一时间只显示一个注册者。官方品牌插件默认先占位，需要禁用它，本插件才能显示。

在你 profile 的 `cordis.patch.yml` 里加上：

```yaml
- id: ui-brand-official
  disabled: true
```

想恢复官方品牌，把 `true` 改回 `false` 即可。

## 品牌设置里能改什么

| 项目 | 说明 |
|---|---|
| 公司名称 | 显示在侧边栏的名字，最多 24 字 |
| 公司 Logo | 上传本地图片，PNG / JPG / WebP / GIF / SVG，≤ 1MB |
| 用内置 | 一键恢复插件自带的图标 |
| 图标高度 | 6 ~ 32px |
| 文字大小 | 12 ~ 20px |
| 显示图标 | 关掉就只显示文字 |
| 恢复默认 | 填回安装时的默认值（保存后生效） |

面板里带实时预览，改什么都立刻能看到效果。

## 也可以写进配置文件（高级）

不想用图形界面、要批量部署时，可以把默认值写在 profile 的 `cordis.patch.yml` 里：

```yaml
- id: brand-shine
  name: dsh-brand-shine
  config:
    name: 你的公司名
    logoPath: C:/path/to/your-logo.png
    logoHeight: 8
    fontSize: 15
    fontWeight: 400
    letterSpacing: "0.02em"
```

| 字段 | 默认值 | 说明 |
|---|---|---|
| `name` | `闪耀吧教育科技` | 品牌名 |
| `logoUrl` | 空 | 图标 URL（http/https 或 data URL） |
| `logoPath` | 空 | **本地图片路径**，PNG/JPG/WebP/GIF/SVG，≤2MB；由宿主读成 data URL，浏览器不能直接读本地文件 |
| `logoHeight` | `8` | 图标高度（px），宽度按原图比例 |
| `mark` | `✦` | 没有图标时使用的字符标志 |
| `showMark` | `true` | 是否显示标志 |
| `nameColor` | 跟随主题 | 品牌名颜色 |
| `markColor` | 跟随主题 | 字符标志颜色（用图片时不生效） |
| `fontSize` | `15` | 字号（px） |
| `fontWeight` | `400` | 字重，`400` 不加粗 |
| `letterSpacing` | `0.02em` | 字间距 |
| `cascade` | `80` | 槽位优先级，一般不需要改 |

**图形界面里的设置优先于配置文件**：用户点过「保存」之后，以浏览器里存的值优先。

## 换内置图标

把新图保存为 `assets/logo.png`，重新内联一次：

```sh
node scripts/build-logo.mjs
```

然后重启 DSH。图标被内联进 `lib/client.js`，插件仍然是单文件、零额外请求。

## 兼容性

- 需要 DSH `0.2.1-rc.1` 或更新版本（依赖 `sidebar.brand.mark` / `sidebar.brand.name` 槽位）
- 纯**客户端插件**：不往模型上下文写入任何内容，**不消耗 token**
- 不修改任何 DSH 程序文件

## 已知限制

- 只替换**侧边栏品牌**，不替换启动加载画面上的 `HARNESS` 字样
- 设置存在**浏览器 localStorage**，换浏览器或换电脑需要重新设置
- 点击品牌名仍保留官方原有的「新建会话」行为，品牌设置入口在侧边栏「更多」菜单中
- 若未来 DSH 改动槽位名称，需要跟着更新

## 卸载

```bash
dsh plugin --profile desktop remove dsh-brand-shine
```

并删掉 `cordis.patch.yml` 里的 `ui-brand-official: disabled: true`，恢复官方品牌。

只临时关掉插件的话：

```yaml
- id: brand-shine
  disabled: true
```

## 开发

接手继续开发请看：[HANDOVER.md](./HANDOVER.md)，里面记录了所有踩过的坑、关键函数位置、待验证清单和发布步骤。

## 许可证

MIT
