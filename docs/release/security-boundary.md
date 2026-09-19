# Security Boundary（2.0.0-rc.1 · P0-11 DoD 32）

真源：`spec/security-boundary.json`。门禁 `node tooling/check-security-boundary.mjs`（release-check 的 `security-boundary`），向量表由四端各自的测试跑。

消息内容是别人写的。里面的每一个字符串——正文、链接、头像地址、链接卡片的标题——都是攻击者可以挑的。这份文档写明这条边界上**谁负责哪一段**。

## 1. 三层各管什么

| 层 | 负责 |
|---|---|
| SDK / 内容层 | 入站载荷的形状与深度校验。组件假定载荷结构良好，但绝不假定它安全。 |
| kit（组件） | 把消息文本当文本渲染；只在一个地方产出 HTML；**任何自己解析出来的 URL 都要过 URL 闸**；对外暴露 `safeExternalUrl` 让宿主用同一条规则。 |
| 宿主（应用） | **决定链接干什么**。kit 把 URL 通过事件报上来（`openLink` / `linkClick` / 媒体动作），接了事件的宿主就拥有这次跳转，判定同样用 `safeExternalUrl`。 |

这条边界的关键不是「谁跳转」，而是**「能不能打开」只有一个判断点**：四端同一张向量表、同一个 `safeExternalUrl`。组件放行、宿主拦截（或反过来）不会发生。

Round 5 之前这里写的是「kit 几乎从不自己跳转」。那条措辞在原生端会把边界**变弱**而不是变强：SwiftUI 与 Compose 的文本气泡里，宿主不接 `onOpenLink` 时链接根本点不动，于是每个 app 只能自己写一遍打开逻辑——判断点从一个变成 N 个，而且 kit 无从知道它们是不是过了闸。现在的规则是：

- **报给宿主**永远优先。接了 `onOpenLink` / `linkClick` 的宿主拿到的是原始 URL，自己判定。
- **宿主没接**时，kit 用平台打开器打开**经过闸门**的 http / https，其它协议不动作（§4c）。一个还没接线的 app 因此是「点不开」，不是「点开一个没验过的地址」。
- 无论哪条路径，进平台打开器的 URL 都过了同一个 `safeExternalUrl`。

## 2. HTML 只从一个地方出

`packages/vue-im-ui/src/utils/markdown.ts` 是 kit 里唯一产出 HTML 的模块，用 markdown-it 且 `html: false`——原始标签一律转义。门禁盯住两件事：这个 `html: false` 不许改，以及整个 Vue 包里 `v-html` / `innerHTML` 只许出现在登记过的三处：

| 文件 | 为什么 |
|---|---|
| `FlareTextMessage.vue` | 消息正文，经 `renderMarkdown` |
| `MarkdownPreview.vue` | 宿主写的 markdown，经 `renderMarkdown` |
| `MsgIcon.vue` | 一张本地静态的内联 SVG 表，没有任何输入进得来 |

新增一处 `v-html` 会让门禁直接红——这正是这条边界最容易在一个讲别的事情的 diff 里悄悄丢掉的方式。

渲染器唯一放行的原始标签是 `<u>`：markdown 本身没有下划线语法，所以转义后把**恰好是** `&lt;u&gt;` 的片段还原回去。带属性的 `<u onmouseover=…>` 不匹配这条精确替换，仍然是转义文本。`markdown.security.test.ts` 用真实恶意输入钉住这一点。

## 3. URL 闸（四端同一条规则）

`safeExternalUrl(raw)` 返回可跳转的规范化 URL，或者 null。规则：

- 只放行 `http` / `https`。`javascript:` 和 `data:` 在 href 上会在页面来源里执行，`file:` / `blob:` 会读本地状态。
- 先剥掉制表符与换行**再**判断——URL 解析器本来就会忽略它们，`java\tscript:` 会规范成 `javascript:`，只做字符串比较会被绕过。
- **不剥空格**。剥掉会把一句话（`just some text`）捏成一个合法主机名；反过来，带裸空格的字符串一律拒绝——真正的 URL 里没有裸空格。这条是四端靠**规则**对齐，而不是靠谁的解析器更严：Dart 的 `Uri` 会把空格百分号编码成一个合法主机，JS 的 `URL` 会直接抛。
- 完全不带 scheme 的按 https 读（用户打 `example.com` 就是这个意思），但只在真的一个 scheme 都没有时才补——`javascript:alert(1)` 绝不会被救成 `https://javascript:alert(1)`。
- 主机加端口（`example.com:8443`）在 RFC 3986 的语法里长得和 scheme 一样，所以冒号后跟数字读作端口。认错的最坏结果是一个主机名古怪的 https URL，无害；把真 scheme 认成主机才是不能发生的。

18 条向量（14 条恶意 + 4 条放行）四端各跑一遍，门禁校验每一端都还在验每一条。

| 平台 | 实现 |
|---|---|
| Vue | `shared/contracts/url-safety.ts` |
| Flutter | `lib/src/models/url_safety.dart` |
| Compose | `ui/UrlSafety.kt` |
| SwiftUI | `Models/UrlSafety.swift` |

## 4. 自己跳转的组件

三个，都登记在契约里，门禁校验它们仍然过闸：

| 组件 | 怎么把关 |
|---|---|
| `LinkCardView.vue` | `safeExternalUrl(rawUrl)`，拿不到就不渲染 `<a>`，退化成不可点的卡片 |
| `LocationView.vue` | href 由经纬度拼出，不取用户字符串 |
| `FlareRichDocRuns.vue` | 富文本消息体的链接（Round 9）：文档里的 `href` 在读取时就要过 `safeExternalUrl` 才挂到行上，渲染时再过一次，拿不到就只画文字；`rel="noopener noreferrer"`，宿主接 `linkClick` 即 `preventDefault` 接管。三个原生 kit 同一规则（`spec/rich-doc-vectors.json`） |

其余一切——文本里的链接、独立的链接卡片消息体、小程序卡片——都是把 URL 通过事件报给宿主。

### 4c. 原生端的默认打开器（Round 5）

文本气泡里的链接在三个原生 kit 上贯通了 `onOpenLink`（`MessageList` → `MessageBubble` → `MessageContentView`）。宿主没接时的默认行为按平台的能力分三种，全部先过闸：

| 平台 | 宿主没接 `onOpenLink` 时 | 闸 |
|---|---|---|
| Vue | markdown-it 渲染出的是真 `<a>`，浏览器自己导航；宿主接 `linkClick` 即 `preventDefault` 接管 | markdown-it 的 `validateLink`（`javascript:` / `data:` / `vbscript:` 进不来 href） |
| SwiftUI | `openURL` 打开 http / https | `safeExternalURL` |
| Compose | `LocalUriHandler` 打开 http / https | `safeExternalUrl` |
| Flutter | **不动作**：kit 里没有 URL 启动器（锁文件冻结，本轮不引入 `url_launcher`） | 不适用（不打开） |

Flutter 的这一格是登记在案的平台缺口，不是遗漏：接 `onOpenLink` 的宿主行为与另外三端一致。四端各自的测试跑同一张 18 条向量表。

### 4b. 从脚本里跳转或下载

模板里的 `:href` 由上表管；在 TypeScript 里 `document.createElement("a")`、赋值 `href`、`window.open`、`location.assign` 的地方登记在 `spec/security-boundary.json#scriptedNavigation`，门禁要求它调用登记的闸函数。

| 模块 | 怎么把关 |
|---|---|
| `utils/browserDownload.ts` | `downloadableHref`：只放 http / https（含相对当前页面的路径）与本页创建的 blob；`javascript:` / `data:` / `vbscript:` / `file:` / `about:` / 外源 blob 一律拒绝，既不 fetch 也不点击 |

这一节是 2026-09-14 认证时补的：当时的门禁只读模板，多图消息的「下载」经这里把 `javascript:` 地址交给 `<a download>.click()`，在 Chromium 里实测执行（`download` 属性对该 scheme 不生效）。修复后同一探针不再执行；`browserDownload.test.ts` 用本契约的 14 条恶意向量逐条断言不 fetch、不点击，修复前的代码有 12 条红（空串与纯空白本来就被拒绝），外源 blob 用例也红。

## 5. 没覆盖的

- **图片与媒体地址**没有过闸。`<img src>` 上的 `javascript:` 在现代浏览器里是惰性的，但一个指向攻击者服务器的地址仍然会泄漏浏览时机与 IP。这属于宿主的 CSP / 媒体代理，不是组件能解决的，本轮没做。
- **原生端的 WebView**：三个原生端的 kit 不含 WebView，宿主若自己嵌一个，`safeExternalUrl` 只管到「要不要打开」，WebView 内部的策略要宿主自己定。
- **内容深度与大小**的校验在 SDK 层，本轮没有在 kit 侧重复验证。
