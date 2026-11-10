# Naive UI 配置工作台

`@flare-im/vue-ui/admin` 的 `FlareAdminSettings` 是配置类页面的共享框架，与 `FlareAdminList` 分工：列表仍使用列表框架，设置／策略不伪装成表格。

## 布局与接口

- `label`：工作区的可访问名称，不重复绘制面包屑标题。
- `scope`：范围条件，宿主使用 Naive `NForm`／独立 `NFormItem`／选择器。宽屏同行、窄屏换行，组织和应用不能堆成同一个条件。
- `navigation`／`compact-navigation`：可选分组导航与对应窄屏选择器。拥有导航时，容器小于760px切换为单列；正文实例不重挂载，草稿不丢失。路由、可见项和权限仍由宿主决定。
- `tools`：刷新等原业务工具；组件不自动增加读写请求。
- `help`：普通说明通过 Naive `NPopover` 的“配置说明”渐进展示。
- `notice`：错误、权限、冲突、未知写入及核对入口常驻，不藏进帮助。
- 默认插槽：表单、页签、卡片等业务组成；接收 `{ narrow }`，依据实际容器宽度小于640px选择表单标签布局，不重挂载输入或复制草稿。
- `footer`：底部固定操作，不随正文滚出视口。只有宿主提供插槽才渲染；权限、保存锁、确认和未知结果保护由原业务拥有。

范围栏、提示区、正文和底栏各有清晰滚动边界。没有大标题、副标题和嵌套卡片。浅／深主题复用设计库语义token；Console紧凑操作沿用32px小按钮，非紧凑策略卡的手机操作保留44px触控高度。

## 紧凑策略卡片

公开admin入口提供`FlareAdminPolicyCard`和`FlareAdminCardGrid`，前者复用真实Naive `NCard`。两者`density`默认`normal`，功能开关显式采用`compact`，不连带改变通知原卡片密度。

- 卡片`title`为名称，`control`插槽放开关／选择器；底部`source`／`sourceDetail`显示继承来源，`actions`插槽放原有操作。
- 紧凑模式不绘制`description`段落，保留名称上的原生悬停说明；页面范围及核心能力的普通说明放到既有“配置说明”。错误、只读、冲突及未知结果提示不能隐藏。
- `default`插槽仍可呈现必要技术标识或业务提示，不在组件内发请求、推断状态或新增保存动作。
- 紧凑网格按实际可用宽度自动排列，最小目标列宽260px；不足时收至容器宽度。长名称换行，控件与底部操作有界，手机单列。

业务页的`PolicyCard`／`PolicyGrid`仅适配插槽和属性，不再维护第二份卡片CSS。权限、继承、开关事件、确认、保存锁及未知结果由原业务控制器拥有。

## 当前采用

Console的系统配置、功能开关与通知页面。系统配置将应用／登录和域名分成页签，`display-directive="show"`保留未保存草稿；简单设置标签桌面同行、手机在上。继承值只读展示，自定义复用相同原输入和继承事件，多语言入口不再产生大段空白。功能开关采用紧凑小卡片，通知保留原密度；两者复用共享卡片，继承、抽屉、确认及控制器不变。

该框架不拥有应用规则、接口、角色、资源目录、保存／重试或强制改密逻辑。不能把源码／组件测试通过当作真实角色或完整系统验收。

## 紧凑工作区

`FlareAdminSettings` 的 `title` 可把工作区标题与 scope/tools 放在同一个工具栏，`density="compact"` 缩减垂直间距。宿主仍负责应用范围、权限和操作锁，窄屏自动换行，不隐藏应用范围或错误。插件筛选表单使用 `FlareFormField label-placement="left"` 的同行可见标签，保持标签关联、错误提示及键盘访问。

### 连续面板与两级导航

`body-layout="pane"` 将正文改为零内边距的弹性面板。范围／工具栏、左侧导航和正文共用工作区外框，导航只保留一条右侧分隔线；宿主在默认插槽中提供 `flex: 1; min-height: 0; overflow: auto` 的内容区并按需使用间距 token。窄屏 `compact-navigation` 保持固定内边距且不随内容滚动。默认 `body-layout="scroll"` 仍由框架正文滚动，适合普通设置表单。

`surface="integrated"` 用于已由宿主共享容器提供外框的组合，去除本组件的外边框和圆角。默认 `surface="card"` 保留现有独立工作区外框；不要让宿主与框架分别添加一层卡片。

`FlareAdminWorkspaceNavigation` 通过同一 admin 入口提供工作区两级菜单，复用 Naive `NMenu`。`groups` 使用 `{ key, label, icon?, disabled?, items: [{ key, label, disabled? }] }`；`icon` 为设计库语义图标名，所有 key 在一份导航内唯一。`value` 是受控的二级功能 key，`label` 是导航的可访问名称；`disabled` 禁用整个菜单。点击二级功能同时发出 `update:value` 与 `change`，组件不写入路由或推断权限。

一级菜单每次只展开一组，外部选中功能变化时自动打开对应组。鼠标、Enter／空格可展开一级或选择二级；上下方向键及 Home／End 移动焦点并跳过禁用项，左右方向键展开／收起一级或返回父级。选中功能使用 `aria-current="page"`，一级保留展开状态；空组不可操作。窄屏选择器由宿主放入 `compact-navigation` 插槽，沿用同一组目的地与权限数据。

### Message 宿主的持续错误内容

`FlareAdminList` 与 `FlareAdminAttachmentPreview` 支持 `error-presentation="neutral"`：列表保留无背景错误正文和 `error-actions` 重试插槽；附件预览保留中性失败状态和关闭入口。默认仍是内嵌错误横条。采用全局 Naive Message 的控制台应显式选择 neutral，由请求所属页面发出瞬时消息；持续失败内容不随消息过期而丢失，也不自动重试操作。
