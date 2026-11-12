# ReauthSheet

验证码身份确认表单。SDK 宿主提供验证方式的不透明 ID、脱敏标签和全部状态；组件只发出选择、输入、发送、确认与取消事件，不访问网络，不保存凭据，也不接收 PIN 或 proof。

```vue
<FlareReauthSheet
  :open="verification.open" :destinations="verification.destinations"
  :selected-id="verification.selectedId" :code="verification.code"
  :sending="verification.sending" :submitting="verification.submitting"
  :can-send="verification.canSend" :can-submit="verification.canSubmit"
  :resend-in-seconds="verification.resendInSeconds" :error="verification.error"
  @select-destination="verification.selectDestination" @change-code="verification.changeCode"
  @send="verification.send" @submit="verification.submit" @cancel="verification.cancel"
/>
```

Vue 的组件自带 Kit BottomSheet；Flutter `FlareReauthSheet`、SwiftUI `ReauthSheetView`、Compose `ReauthSheet` 提供表单内容，宿主使用现有 Kit 容器展示。原生使用 `FlareReauthDestination(id, label, detail?)`；SwiftUI 的 `selectedId` 和 `code` 为 Binding，其他端使用受控值与回调。

`title/subtitle` 可说明用途；省略标题时使用 Kit 的身份验证文案。`resendInSeconds`、`canSend`、`canSubmit` 均由 SDK 给出，组件不启动倒计时、不推断业务资格。发送或提交时选择器与输入框停用，取消始终可用。宿主在取消、换用户、换页及请求完成后清除临时验证码；人机验证沿宿主已有入口执行。

The form accepts opaque destination IDs and masked display copy only. All OTP effects, human verification, cooldown policy and lifecycle cancellation belong to the SDK host. The Kit neither receives nor stores PINs, credentials, challenges or proofs.
