# 管理操作按钮与危险确认

列表工具栏、保留键 `actions` 的操作列及 `row-actions` 插槽，由 Kit `FlareAdminActions` 统一组合。普通 `action` 审计字段仍为数据，不添加按钮语义。按钮实际使用 Naive `NButton`，宿主继续拥有回调、权限、disabled／loading和二次确认；组件不合成操作，不自动提交，不猜测危险性。

- 行内普通操作使用 `text`／`type="primary"`／`size="small"`；暂停、冻结等状态风险明确使用warning；删除、撤销、停用组织等使用error。颜色之外必须有明确动词，不能只靠图标或色彩传达后果。
- 共享按钮组按语义spacing tokens排布并允许换行，避免多按钮文字连在一起。按本轮紧凑反馈，桌面和手机统一Naive `small`规格（当前主题32px），按钮组间距8px；不再在手机工具栏强制48px高度／宽度，也不压缩文字来塞入固定列宽。
- 原生Naive文字按钮通过 `NConfigProvider` 的Button主题属性使用Kit warning/error text tokens，跟随明暗主题；不是覆盖按钮内部样式或另建调色板。禁用色和原生键盘语义仍由Naive负责。
- 工具栏保留创建／批量操作在左、说明／列设置在右；新增／编辑抽屉继续使用共享footer，不挪动确认后的业务调用。

危险操作仍走现有 `useWorkspaceConfirmation`／`WorkspaceConfirmation`，展示层统一Kit `FlareAdminPopconfirm`（真实Naive `NPopconfirm`），不再给Console二次确认加全屏遮罩或底部模态。先展示目标及影响，再明确确认；取消／Esc不得写入，等待中不得重复执行，确认时继续重验主体、组织／应用、权限版本及资源快照。

共享组件捕获实际触发控件，通过Naive公开的manual／x／y控制定位；键盘触发支持当前焦点备用，触发点无效时不自动提交。支持原有可选／必填原因、长度／UTF-8字节限制、失败保留输入；新问题才清空原因。确认／取消携带原问题代次，由Console适配器拒绝过期事件。

在已有抽屉中，气泡挂入同一焦点边界；默认焦点给取消，Esc捕获优先于抽屉并只取消气泡。关闭时恢复原控件焦点，不另建模态栈或重挂载触发按钮。非管理端的通用 `FlareDangerConfirm` 不受此Console呈现调整影响。

当前Console补齐敏感词状态变更与员工密码重置的提交前确认；密码确认不展示或序列化口令。后者确认通过后仍执行原有写入、清除口令、未知结果锁与读回流程。规则／域名编辑器仅移除未保存草稿项不算持久删除，最终保存保留原确认和保护。Kit不负责业务权限或资源危险级别判断。

本轮只涉及Vue管理端共享组合，未改变原生Kit、Core或Core SDK的业务边界。

## 管理端剩余操作区收口

管理页面、内嵌工作区和编辑抽屉的原生按钮显式使用 `size="small"`，包括重试／只读核对、复制、取消与底部保存按钮，不只规范列表工具栏。纯操作组复用 `FlareAdminActions` 的8px列间距／4px换行间距；需要靠右时用 `justify="end"`，不要再套一层NSpace制造第二份间距。包含标签、表单或说明的业务布局仍使用原NSpace，不按按钮组强行改写。

Console的38个抽屉显式启用 `FlareDrawer footer-density="compact"`，避免手机页脚又把small按钮撑为大触控尺寸。该能力默认 `comfortable`，其他通信客户端的手机目标保持原规则；抽屉关闭／返回控件和导航图标不因此缩小。登录／恢复／入驻入口也不属于此管理操作规范的批量范围。

持久危险动作继续由宿主 `useWorkspaceConfirmation` 拥有权限、快照、未知结果与写锁，单一 `WorkspaceConfirmation` 映射到真实Naive Popconfirm；不重复套确认、不在Kit猜测“删除”按钮是否操作远端。删除尚未保存的规则／域名草稿不会直接产生持久副作用，保留最终保存时原有确认。
