# kit 分发设计：main 用发布版 / dev 用本地路径

面向 4 个平台的 UI kit（web / Android / iOS / Flutter）如何在两个分支下分发。

## 要解决的问题

两个诉求天然冲突：

| 分支 | 诉求 | 为什么 |
|---|---|---|
| **main** | 单独 `git clone` 一个 app 仓就能构建 | 外部集成者、CI、以及「我只想看看这个 app」的人不该被要求克隆 14 个同级仓 |
| **dev** | 改一处 kit 立刻在所有端生效 | 组件库的开发节奏是「改一行看一眼」，不该被发版流程打断 |

web 侧已解决（见工作区根的 `PLAN-branch-deps.md`：package.json 永远写 registry 版本，
vite alias 按同级仓存在与否自动判定，tsconfig 的 paths 解析不到时回落 node_modules——
**没有切换脚本**）。本文处理 Android / iOS / Flutter。

## 现状（实测，非推测）

| 平台 | dev 怎么引 | main 能不能引 | 缺什么 |
|---|---|---|---|
| **web** | registry 声明 + vite alias/tsconfig paths 自动判定 | ✅ 能，`@flare-im/vue-ui@1.0.9` 在 npm 上 | 已完成 |
| **Android** | `mavenLocal()` + `com.flare.im:im-ui-compose:1.0.6` | ❌ **不能** | 发布目标是注释掉的占位（build.gradle.kts:54），产物只进本机 `~/.m2` |
| **iOS** | `.package(path: "../../../../../flare-im-design/ios-im-ui")` | ⚠️ **半能** | 双清单（根 + ios-im-ui）已就位、tag 到 1.0.5，但消费方写死 path |
| **Flutter** | — | — | kit 是设计源，各 app 走接线而非依赖，不在本文范围 |

## Android：三个选项，各自的真实代价

`mavenLocal()` 只在开发者本机有效——**这是当前 main 分支的实际阻塞**。

### 选项 A：Maven Central

- ✅ 最标准，消费方零配置（`mavenCentral()` 本来就在）
- ❌ 需要 Sonatype OSSRH 账号 + GPG 签名 + 域名所有权证明（`com.flare.im` 要证明持有 flare.im）
- ❌ 发布不可撤回，且审核链路长
- ❌ **对当前阶段过重**：kit 版本号一天可能动几次

### 选项 B：GitHub Packages（推荐）

- ✅ 与代码同处一地，权限跟着仓库走（private 仓也能用）
- ✅ 无需域名证明、无需 GPG
- ✅ 发布可覆盖（同版本可重发，开发期很实用）
- ⚠️ 消费方要配 `credentials`（GitHub token）——**这是主要摩擦**
- ⚠️ 对完全外部的集成者不友好（要求他们有 token）

### 选项 C：GitHub Release 附件 AAR

- ✅ 完全无需认证，`curl` 就能下
- ❌ **没有 POM**，意味着传递依赖不会自动带过来
- ❌ 记忆里记过这个坑：**手动引入必须抄 8 个依赖，否则运行时崩**
- ❌ 版本管理靠人肉，Gradle 无法解析版本区间

### 选项 D：JitPack —— **仓库是公开仓，这才是最优解**

后来查实 `flare-im-design` 是 **PUBLIC** 仓，这改变了结论。JitPack 从 git tag
按需构建，**自动生成 POM**，且公开仓**消费方零认证**：

```kotlin
repositories { maven { url = uri("https://jitpack.io") } }
implementation("com.github.flare-im:flare-im-design:1.0.7")
```

| 方案 | 消费方要 token | 有 POM | 传递依赖 |
|---|---|---|---|
| Release 附件裸 AAR | 否 | **无** | **手抄 8 个，漏一个运行时崩** |
| GitHub Packages | **要**（公开仓也要） | 有 | 自动 |
| **JitPack** | **否** | **有** | 自动 |

GitHub Packages 的关键劣势是**即使仓库公开，它的 Maven 端点仍要求认证**——
对外部集成者是实打实的摩擦。

**本地已验证 JitPack 路线可行**：模拟其构建流程（`cd android-im-ui &&
./gradlew publishToMavenLocal`）产出 AAR + POM + sources，且 POM 里
**9 个传递依赖全在**（compose-bom / material3 / coil 等）——正是裸 AAR 方案要手抄的那批。

monorepo 需要 `jitpack.yml` 指定子目录构建（仓库根没有 Gradle 工程）。

### 结论

**选 D（JitPack）为主，B（GitHub Packages）作为私有分发的备选，A（Central）留作正式发布的升级路径。**

三条不冲突：JitPack 配置在 `jitpack.yml`，GitHub Packages 配置在
`android-im-ui/build.gradle.kts` 的 repositories 块，各自独立。

理由：当前阶段 kit 还在快速迭代，A 的审核与不可撤回是真实阻力；C 的无 POM 缺陷已经吃过一次亏（8 个依赖手抄）。B 的 token 摩擦只影响外部集成者，而现在没有外部集成者——等有了再上 A，那时版本也稳定了。

**关键设计**：消费方的 `settings.gradle.kts` 同时声明两个仓库源，
`mavenLocal()` 放在 GitHub Packages **之前**。这样

- dev：本地 `publishToMavenLocal` 后立刻命中本机产物
- main：本机没有该版本 → 自动回落到 GitHub Packages

**一份配置同时满足两个分支，不需要切换脚本**——这与 Rust 侧
`{ version, path }` 双写是同一个思路：让解析顺序表达优先级，而不是维护两套清单。

## iOS：改消费方声明即可

SPM 天然支持两种形式，且双清单已就位：

```swift
// dev
.package(path: "../../../../../flare-im-design/ios-im-ui")

// main
.package(url: "https://github.com/flare-im/flare-im-design.git", from: "1.0.6")
```

⚠️ **两个已知坑**（记忆里记过，别再踩）：

1. **SPM 只认仓库根的 `Package.swift`**。这是 monorepo，所以根清单是必需的，
   且**必须与 `ios-im-ui/Package.swift` 保持同步**——两份清单漂移时，
   走 path 的 dev 分支正常、走 url 的 main 分支拿到旧定义，
   而且**本地完全测不出来**。
2. **iOS 的版本靠 git tag，必须与 Android 一起升**。tag 落后于 Android 版本时，
   main 分支的 iOS 会拿到旧组件，表现是「同一个版本号两端 UI 不一致」。

对应两条防线：

- `scripts/check-spm-manifests.mjs`：校验根清单与子清单的 target/platform 定义一致
- `scripts/check-kit-versions.mjs`：校验 Android version、npm version、git tag 三者一致

这两条是**门禁**而非文档约定——记忆里的教训是「双清单要同步」这句话写在文档里没人看，
必须让 CI 报红。

## Flutter 为什么不在范围内

`flutter-im-ui` 是 kit 的**设计源**（其他端对齐它），各 app 走接线与 token 层
而非包依赖。它没有「发布版 vs 本地」的问题——改了就是改了。

## 落地顺序

1. Android：build.gradle.kts 加 GitHub Packages 发布目标 + 消费方加仓库源（解析顺序）
2. iOS：消费方声明改为可切换 + 两条门禁脚本
3. 版本一致性门禁接进 CI
4. 各仓 README 写明分支约定

## 不做什么（以及为什么）

- **不做 Android 的切换脚本**。Gradle 的仓库解析顺序已经能表达优先级，
  引入脚本等于把一个声明式问题变成有状态的问题。
- **不上 Maven Central**。等有外部集成者、且版本稳定下来再上；
  现在上只会让每次改 kit 都要走一遍审核。
- **不用 GitHub Release AAR**。无 POM 导致的手抄 8 个依赖已经踩过一次。
