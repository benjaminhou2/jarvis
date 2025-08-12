## Jarvis — SwiftUI Multiplatform To‑Do App (iOS 17+ / macOS 14+)

Jarvis 是一个与 Microsoft To Do 功能对齐的个人待办应用，使用 Swift + SwiftUI + Combine + Core Data 实现，多端（iOS、macOS）单一代码库（>95% 共享）。支持本地持久化、导入导出（JSON 备份），可选 iCloud 私有库同步（CloudKit）。

### 功能概览
- 任务：创建/编辑/完成/撤销/删除；标题、备注、子任务（步骤）、截止日期、提醒、重要、重复规则
- 清单：创建/重命名/删除；任务在清单间移动
- 智能列表：我的一天（My Day）、已计划（Planned）、重要（Important）、已完成（Completed）
- 搜索：按标题/备注（若开启 Tag，也支持 #标签）
- 通知：到期/提前提醒（本地通知）
- 数据：本地 Core Data；导出/导入 JSON 备份（去重）
- 可选：iCloud 同步（仅个人、非协作），使用 NSPersistentCloudKitContainer

### 目录结构
```
jarvis/
  Shared/
    App/
    Common/
      Components/
      Notifications/
      Theme/
      Utils/
    Data/
      Entities/
      Repositories/
      Schema/
      Model.xcdatamodeld/Model.xcdatamodel/contents
    Features/
      Home/ Lists/ Tasks/ MyDay/ Planned/ Important/ Completed/ Search/ Settings/
  iOS/
    AppIntents/ Widgets/ Notifications/
  macOS/
    Menu/
  Tests/
    JarvisTests/
```

### 准备与运行
1) 使用 Xcode 15+ 新建 Multiplatform → App，命名为 `Jarvis`，勾选 Core Data。
2) 在 Finder 中将本项目 `Shared/`, `iOS/`, `macOS/`, `Tests/` 整体拖入 Xcode 工程（勾选两个平台目标）。
3) 将 `Shared/Data/Model.xcdatamodeld/Model.xcdatamodel/contents` 替换默认模型（右键 Show in Finder 拖入覆盖）。确保模型名为 `Model`。
4) Targets → Signing & Capabilities：
   - iCloud（若启用同步）：勾选 iCloud、CloudKit，Containers: `iCloud.<your.bundle.id>`；
   - Background Modes（可选）：Remote notifications（若后续扩展）。
5) 若要 Widgets 和 App Intents：在 Xcode 添加 Widget Extension / AppIntents Extension 目标，将 `iOS/Widgets/*`、`iOS/AppIntents/*` 对应添加到扩展目标（主 App 不编译这些文件亦可，文件内部已做条件编译）。
6) 运行（⌘R）。首次运行会请求通知权限。

首启种子数据：自动创建 `Personal` 与 `Work` 两个示例清单。

### 切换 iCloud 同步
- 设置页中 `iCloudSyncEnabled` 开关（默认关闭）。
- 开启后需使用相同 Apple ID；仅个人私有库，不支持协作共享。

### 导出/导入（备份/恢复）
- 设置页提供导出全部数据到 App 文档目录的 JSON 文件；
- 导入时会做 Schema 校验与去重（按 id）。

### 测试
- 在 Xcode 的 Test 目标中包含 `Tests/JarvisTests/*`：
  - DateRulesTests：重复规则推算（月底/闰年/周切换）
  - SmartListFilterTests：智能列表筛选
  - ImportValidationTests：导入校验与去重
- 运行测试（⌘U）。

### 可运行指令（命令行构建可选）
- iOS: `xcodebuild -scheme Jarvis -destination 'platform=iOS Simulator,name=iPhone 15' build`
- macOS: `xcodebuild -scheme Jarvis -destination 'platform=macOS' build`

### 演示动图录制脚本建议
1) 启动 App，展示首页：iOS Tab（或 macOS 侧栏+列表+详情）。
2) 在 `Personal` 清单使用快速录入创建 2 条任务，标记其中一条为重要；
3) 为第一条任务设置截止日期和重复规则（每周一、四），返回可见 `已计划`；
4) 切换到 `我的一天`，手动将一条任务标记 myDay（或通过详情页开关），展示列表；
5) 搜索页输入关键词匹配；
6) 设置页切换 iCloud 同步（提示重启后生效），执行一次导出备份；
7) 返回 `已完成` 将一条任务完成，若设有重复规则，自动生成下一条（演示日期变化）。

### 打包
- 使用 Xcode Archive（⌘⇧B 触发构建验证，或 Product → Archive）。
- 若使用 iCloud：需在 App Store Connect 中为相同容器配置权限。

### 设计与交互
- iOS：Tab 栏（我的一天、已计划、重要、清单、搜索、设置）。
- macOS：`NavigationSplitView`，侧栏展示系统/自定义清单，中间任务列表，右侧详情。
- 快速录入条：输入标题后回车即创建，落入当前清单。
- “我的一天”：每天 0 点自动清空 `myDay` 标记（任务不删除）。

### 约束与声明
- 本项目不与 Outlook/Microsoft 365 集成；不做多人协作/共享清单；
- 同步仅限个人 iCloud 私有库；
- 代码已提供可编译骨架与关键实现；如需生产发布请补充更多边界处理和 UI 微调。


