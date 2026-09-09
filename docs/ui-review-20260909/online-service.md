# 线上服务联调记录

日期：2026-09-09（Asia/Shanghai）。服务：https://118-107-9-221.sslip.io 。通过浏览器真实 UI 操作，无后台数据库写入。

## 隔离数据

账号 A：codex-ui-plan-a-20260909；账号 B：codex-ui-plan-b-20260909。仅使用这两个新测试身份；未操作已有用户会话。

## 已观察结果

1. A 登录 ready，创建与 B 的会话，发送 `Flare 组件验收 search-marker-20260909 文本消息`。
2. A 搜索：全部/文本找到 seq 1，文件为 0。期间观察到 disconnected 后搜索成功、状态恢复 connected；未进行受控断网注入，不能据此断言所有重连场景通过。
3. B 登录 ready，从服务同步到 A 的消息及 1 条未读。回复最初显示发送中；前台恢复并刷新后，回复仍存在，未读变为 0。未把气泡出现本身当作发送完成。
4. B 经“更多 → 文件”选择临时生成的 58 B 文本文件 `flare-ui-search-marker-20260909.txt`，说明为 `search-marker-20260909 附件筛选测试`。上传进度消失、发送弹窗关闭，消息获得 seq 8。
5. 同一关键词搜索：全部 2 条（文字 seq 1、文件 seq 8）；文件 1 条（仅 seq 8）；文本 1 条（仅 seq 1）。附件说明不会使文件进入文本类型。

## 验证边界

这是现有线上部署的服务联调；本轮组件修改尚未部署到服务器。未完成真实 RTC 媒体、屏幕共享、硬件设备切换、受控弱网长时间循环、物理设备键盘/读屏测试。初次直接点击底层文件 input 没有进入正确附件工作流，随后通过可见菜单完成；该次无响应不作为上传失败结论。

## 原生接入配置

该部署通过 `/api` 代理 HTTP Gateway。原生客户端填写：

- WebSocket：`wss://118-107-9-221.sslip.io/ws`
- Gateway：`https://118-107-9-221.sslip.io/api`
- 协议选择 WebSocket；QUIC 端口尚未核实。

iOS 首次使用站点根地址作为 Gateway 时，`/api/v1/auth/tokens` 返回 404；这属于缺少反向代理前缀。Web 的 sameOriginEndpoints 已明确使用站点 `/api`，原生应填写相同 Gateway 基址，SDK 不应猜测任意部署的代理前缀。

## iOS 原生往返

iPhone 17 / iOS 26.4 模拟器，账号 `codex-ui-plan-ios-20260909` 使用上述 `/api` Gateway 登录“就绪”。创建与 B 的会话后发送 `IOS search-marker-20260909 native roundtrip`；Web B 出现新会话与该消息。Web 回复 `Web to iOS native-ack-20260909`，iOS 显示回复，原发送消息显示“已读”。验证通过，未使用真实个人账号。

## 本地新版本联调

当前源码通过 `http://127.0.0.1:1431` 连接该服务时，直接跨域请求 token 被服务端 CORS 拒绝（缺少 Access-Control-Allow-Origin）；这不属于消息搜索或 WebSocket ready 错误。使用现有开发代理进行本地联调：

```sh
VITE_FLARE_WS_URL=wss://118-107-9-221.sslip.io/ws \
VITE_FLARE_HTTP_URL=http://127.0.0.1:1431/__flare-media-api \
VITE_MEDIA_API_PROXY_TARGET=https://118-107-9-221.sslip.io/api \
npm run dev:web -- --host 127.0.0.1 --port 1431
```

该配置不更改线上服务器 CORS，也不进入发布包。最新源码登录 ready 后，同一查询返回文字与文件 2 条，文件筛选仅 seq8。真实验证发现示例 Web/Tauri 自带 WorkbenchLayout/ChatView，没有自动采用共享页面的定位改动；已接入共享 `locateTimelineMessage`、搜索代次保护与危险确认。

再次测试：对文字 seq1 搜索结果按 Enter，搜索面板关闭；DOM 的 `message-row--locating` 精确高亮 `Flare 组件验收 search-marker-20260909 文本消息`，data-message-id 为 `ed0b5630def267d91fff5a3d69f77ff4`，未打开预览弹窗。目标已在本地窗口，因此真实服务测试不代表远端多页历史定位全部通过；48 页上限与取消由本地测试覆盖。

清空记录入口显示目标 `codex-ui-plan-a-20260909` 和确认/取消，点击取消后保留消息。未对测试服务执行清空或删除。搜索结果已移除覆盖按钮语义的 listitem role，读屏可识别为按钮。
