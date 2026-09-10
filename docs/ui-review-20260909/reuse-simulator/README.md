# 共享组件改造与模拟器验证

日期：2026-09-09。未执行真实账号登录、注册、发送消息、评论、删除或拉黑操作。

## 本轮改造

- Android 设计库新增 `FormDialog`：最大宽度 480dp、可滚动内容、可换行的底部操作、忙碌态阻止返回 / 点击外部关闭、共享危险按钮。
- Social Android 好友备注、好友描述、拉黑、删除好友、动态评论和删除动态共六个弹窗改为共享 `FormDialog`；空白评论的发送按钮直接禁用。SDK 回调留在应用。
- Social iOS 登录 / 注册字段改为 `FormFieldView` + `InputView`，密码显隐改为 `IconButtonView`，提交改为 `ButtonView`，删除玻璃输入框及按钮重复绘制逻辑。
- 模拟器发现登录页固定深色背景与根页面主题不一致；现明确设置登录页局部颜色环境，共享输入框正确呈现深色。
- iOS / Android 共享输入框最小高度 44，iOS 登录表单明确滚动容器高度并裁剪至安全区域。
- 防回退脚本增加上述 Android 弹窗页面和 iOS 登录表单检查。

## 实际验证

| 目标 | 环境 | 结果 |
| --- | --- | --- |
| Social iOS | iPhone 17 Pro / iOS 26.4 | 最新代码构建、安装、启动成功。手动操作验证账号输入、空表单禁用、填写后按钮可用、密码显隐、注册密码不一致提示。没有点击最终提交。 |
| Android 共享组件 | Pixel 9 / API 35 | `SharedFormInteractionTest` 两项真实设备仪器测试全部通过：空值禁用 / 填写 / 提交回调 / 忙碌禁用 / 取消回调，以及设置行整行切换 / 禁用。均使用本地状态，无 SDK 网络动作。 |
| Social Android | Pixel 9 / API 35 | 最新安装包构建、安装与启动成功，AndroidRuntime 错误日志无输出。登录页截图用于记录仍待迁移的界面。 |
| Social Flutter | iPhone 17 Pro / iOS 26.4 | `flutter build ios --simulator --debug --no-pub` 成功，安装并启动看到实际 Flutter 登录页。未将启动成功等同于登录后业务验收。 |

Android 最初因磁盘不足无法启动，空间恢复后已重试成功并完成测试。

## 截图与限制

- [iOS 软键盘](flare-reuse-ios-keyboard.png)：确认输入框能获得焦点；键盘弹起后底部操作需要收起键盘才能直接看到，长表单聚焦后的自动滚动体验仍需继续优化。
- [Android 应用启动](flare-reuse-android-launch.png)：登录页仍有自绘输入 / 按钮和技术说明标签窄屏换行，尚未统一到本轮 iOS 登录表单。
- [Flutter iOS 启动](flare-reuse-flutter-ios-launch.png)：真实 Flutter 运行截图；登录页仍有自绘样式，登录后已迁移的资料 / 评论弹窗未做真实账号端到端测试。

本轮覆盖一个手机尺寸。iPad、横屏、超大字体、九端完整聊天 / 录音生命周期尚未全部完成模拟器验收。

## 复现

从 Social Android 示例目录：

```sh
./gradlew :android-im-ui:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.flare.im.ui.SharedFormInteractionTest --offline
./gradlew :app:installDebug --offline
```

从 Social iOS 示例目录：

```sh
xcodebuild -project FlareSocialApp.xcodeproj -scheme FlareSocialExampleApp -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/social-composer-ios ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

从 Social Flutter 示例目录：

```sh
flutter build ios --simulator --debug --no-pub
```
