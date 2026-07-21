# Flare 图标库使用说明

一套**跨端语义化图标**:业务只写一个语义名(如 `send`、`chats`),各端把同名映射到自己**最合适的原生字形源**。风格统一走**细线(Feishu 风)**。

| 端 | 组件 | 包 | 字形源 |
|---|---|---|---|
| Vue(Web / Tauri) | `FlareIcon` | `flare-core-vue-im-ui` | **Lucide**(细线,经 shim) |
| Flutter | `FlareIcon` | `flare_im_ui` | Material **Outlined** |
| iOS(SwiftUI) | `IconView` | `FlareIMUI` | **SF Symbols** |
| Android(Compose) | `FlareIcon` | `com.flare.im:im-ui-compose` | Material **Outlined** |

> 为什么不用"一套 SVG 打全端"?各端用各自原生字形能拿到最佳清晰度、动态字重与无障碍支持,且体积更小。语义名是唯一的稳定契约,底层字形可各自演进。

---

## 一、语义名(59 个,契约,四端一致)

```
search  send  more  back  close  check  add  remove  edit  delete
heart  heart-filled  comment  chats  moments  share  camera  image
location  mic  phone  video  settings  person  people  person-add
star  bookmark  download  link  emoji  file  folder  notification  mute
copy  forward  reply  refresh  chevron-down  chevron-right  arrow-down
warning  info  success  error  calendar  clock  eye  eye-off  lock  qr
block  tag  announcement  theme  language  devices  logout
```

- 这份清单是**跨端契约**,四端的 `flareIconNames` 必须**逐字一致**(数量、拼写、顺序)。改动要四端同步。
- `chats`(会话/消息 tab)与 `moments`(圈子/发现)是社交场景新增;`comment` 是单条评论气泡,别混用。
- `block`(拉黑)/`tag`(标签)/`announcement`(公告)/`theme`(深色)/`language`(语言)/`devices`(多设备)/`logout`(退出)服务于通讯录/设置页。

---

## 二、各端用法

### Vue(Web / Tauri)

```vue
<script setup lang="ts">
import { FlareIcon } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareIcon name="send" :size="22" />
  <FlareIcon name="moments" :size="20" />
</template>
```

- `name` 有 `FlareIconName` 类型约束,拼错会被 TS 拦下。
- `size` 默认 20;颜色继承 `currentColor`(父级 `color` 或 token)。
- 也可 `import { flareIconNames } from "flare-core-vue-im-ui/shared/icons"` 遍历全集(画廊/选择器)。

**组件的 `icon?: string` 属性走 `FlareGlyph`**:凡是接受开放 `icon` 字符串的 kit 组件(`FlareEmptyState`、`FlareSettingsRow`/`FlareProfilePanel` 行、`FlareAppShell` 导航项…)内部用 `<FlareGlyph :icon="...">` 渲染 —— 传**语义名**出线性图标,传其它字符串(emoji/单字)则原样回退。业务只需把 `icon` 传成语义名(如 `icon="settings"`)即可,不必自己引图标。

```vue
<FlareEmptyState icon="chats" title="暂无会话" />
<!-- settings item -->
{ key: "theme", label: "深色模式", icon: "theme", kind: "toggle" }
```

### Flutter

```dart
import 'package:flare_im_ui/flare_im_ui.dart';

FlareIcon('send', size: 22);
FlareIcon('moments', size: 20, color: Colors.grey);
```

未知名兜底 `Icons.help_outline`(可见而非空白)。

### iOS(SwiftUI)

```swift
import FlareIMUI

IconView("send", size: 22)
IconView("moments", size: 20, color: .secondary)
```

未知名兜底 `questionmark`。

### Android(Compose)

```kotlin
import com.flare.im.ui.FlareIcon

FlareIcon(name = "send", size = 22.dp)
FlareIcon(name = "moments", tint = MaterialTheme.colorScheme.onSurfaceVariant)
```

未知名兜底 `Icons.AutoMirrored.Outlined.HelpOutline`。

---

## 三、Web 字形源:Lucide + 中央 shim(重要)

Web 端**不直接**从 `@vicons/ionicons5` 取图标了。所有 kit 组件统一从**中央 shim** 导入:

```
vue-im-ui/src/shared/icon-glyphs.ts
```

- 该 shim 把 kit 用到的 **106 个 ionicons 名**逐一映射到 **Lucide**(`lucide-vue-next`)字形。
- 每个导出是函数式组件:渲染 Lucide 图标 `size:"1em"`(兼容 naive `<n-icon>` 的字号缩放)、`stroke-width:1.75`(细线)、填充变体(heart/star/success/error/info)加 `fill:"currentColor"`。
- 组件里照旧写 `import { SendOutline } from ".../shared/icon-glyphs"`,**调用点无需改动** —— shim 是切换 web 图标集的**唯一接缝**。

```ts
// FlareIcon 语义层(shared/icons.ts)也走 shim:
search: SearchOutline,   // ← 实为 Lucide "Search"
send:   SendOutline,     // ← Lucide "Send"
```

---

## 四、如何新增一个语义图标

要四端同步,顺序如下:

**1. Web 语义层** — `vue-im-ui/src/shared/icons.ts`:在 `flareIcons` 加 `名: 某Outline`(从 `./icon-glyphs` 导入;若 shim 没有该 ionicons 名,先在 shim 里加映射,或直接映一个 Lucide 名)。

**2. iOS** — `ios-im-ui/Sources/FlareIMUI/Components/IconLibrary.swift`:`flareIconNames` 加名 + `flareIconMap` 加 SF Symbol 名。

**3. Flutter** — `flutter-im-ui/lib/src/components/flare_icon.dart`:`flareIconNames` 加名 + `flareIconMap` 加 `Icons.xxx_outlined`。

**4. Android** — `android-im-ui/.../IconLibrary.kt`:加 `import androidx.compose.material.icons.outlined.Xxx` + `flareIconMap` 加 `"名" to Icons.Outlined.Xxx` + `flareIconNames` 加名。

**5. 校验**:四端 `flareIconNames` 逐字一致;各端字形名真实存在(见"坑")。

> 若只是给 **kit 组件**换/加一个**非语义**的原生图标(不进 52 契约),Web 侧改 `icon-glyphs.ts` 的映射即可,别再直接从 `@vicons` 导入。

---

## 五、坑 / 注意

- **不能 `npm install`**:kit 依赖 `flare-im-design-tokens@^0.1.0` 未发布到 registry,任何 `npm install <pkg>` 都会 404。新增前端依赖(如 lucide)需 `npm pack` 下 tarball 解压进 `node_modules` + 手写 `package.json` 依赖行。`node_modules` 被 gitignore。
- **Web app 走 symlink**:`flare-social-web-app` 以 `file:` 依赖消费 kit,故 `lucide-vue-next` 从 **kit 自己的 `node_modules`** 解析,web app 无需单独装。
- **Lucide 改名频繁**:如 `PlusCircle→CirclePlus`、`AlertCircle→CircleAlert`、`MoreHorizontal→Ellipsis`、`AlertTriangle→TriangleAlert`。加映射时**对着实际导出集验名**(`node_modules/lucide-vue-next/dist/*.d.ts` 的 `declare const`),别凭记忆。当前锁定 `lucide-vue-next@0.577.0`(0.x,避 1.0 改名潮)。
- **1em 尺寸**:shim 组件必须以 `size:"1em"` 渲染,`<n-icon>` 才能用 `font-size` 控制大小;若直接用 Lucide 组件会固定 24px。
- **SF Symbol 名运行时解析**:iOS 端名字写错不会编译报错,只会渲染 `questionmark`。改 iOS 映射后要跑一次模拟器/预览确认字形正确。
- **Android 需 material-icons-extended**:非基础图标(Forum/Explore/EmojiEmotions 等)来自扩展包,`build.gradle.kts` 已含该依赖。

---

## 六、底部导航图标(相关)

`FlareAppShell` 的 nav item `icon` 支持传**语义名**(走 `FlareIcon` 渲染细线图标),也兼容传 emoji/单字符(纯文本回退)。例:

```ts
navItems = [
  { key: "chats",    label: "消息",   icon: "chats" },
  { key: "contacts", label: "通讯录", icon: "people" },
  { key: "moments",  label: "圈子",   icon: "moments" },
  { key: "me",       label: "我",     icon: "person" },
];
```

手机端进入会话可传 `:hide-bottom-nav="true"` 隐藏底部栏,让聊天占满全高(侧边 rail 不受影响)。

---

## 参考

- 在线画廊(全 52 图标):文档站 `Components → Icon`。
- 生成/校验脚本:切换整套 web 图标集时,用 `icon-glyphs.ts` 的映射表(可脚本重生成)。
