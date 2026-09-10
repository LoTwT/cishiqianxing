# 09｜技术基线

状态：**Godot 4.7.2 Standard、强类型 GDScript 与 Forward+ 已冻结为当前生产基线**\
选型日期：**2026-08-24**\
适用范围：引擎、脚本、渲染、UI、输入、数据、存档、本地化、音频、无障碍、测试和双平台构建。

本文记录技术选择和验证边界，不改变产品、剧情、玩法、内容量或视听方向。任何候选无法满足核心规则时，应更换技术方案，不得删减已经锁定的游戏要求。

## 1. 决策结论

- 首选引擎为 **Godot 4.7.2 Standard**，不使用 .NET 版本。
- 脚本统一使用**强类型 GDScript**，不建立 GDScript 与 C# 双栈。
- 正式工程使用 **Forward+** 渲染器。不得在静默降级到 Compatibility 后继续进行生产验收。
- **Unity 6.3 LTS＋URP** 是唯一后备，只在 Godot 触发淘汰条件后验证。
- Unreal、Defold、Bevy 和 Stride 不作为本项目的并行生产方案。
- Godot 已冻结为生产基线；发行候选必须补齐Windows原生运行、Direct3D 12、Windows原生音频和NVDA实测，编辑器运行或其他平台模拟不能替代。

选用 Godot 的主要原因是单人＋AI 工作流的维护成本较低，工程与资产格式大多可以文本化，也不要求账号、订阅或专有构建服务。Unity 的 C#、测试和 3D 工具链更成熟，但编辑器体量、许可证约束、构建机管理和序列化资产维护会增加长期成本。

## 2. 固定技术基线

| 领域 | 生产基线 | 约束 |
|---|---|---|
| 引擎 | Godot 4.7.2 Standard | 精确锁定补丁版本；升级前跑完整回归 |
| ASCII项目标识 | `cishiqianxing` | 用于仓库名与稳定的`user://`目录；平台包名和组织限定应用ID另行确定 |
| 脚本 | 强类型 GDScript | 警告视为错误；不混用 C# |
| 渲染 | Forward+ | Windows x64 使用 Direct3D 12；macOS 使用系统支持的原生 Metal 3 或 Metal 4，并记录实际 API 版本；禁止静默降级后继续验收 |
| 平台技术底线 | Windows 10 x64、Apple Silicon macOS 13 | 只记录引擎对简单导出项目的技术底线；最终最低配置继续延期到代表切片实测后 |
| 权威规则 | 普通强类型类与 `RefCounted` | 不依赖 Node、物理、动画、帧时间或音频状态 |
| 世界坐标 | `int` 与 `Vector3i` | 一次逻辑移动始终是一格；浮点只用于表现 |
| UI | Godot `Control` | 菜单、字幕、历史、设置和无障碍语义均由 Control 构建 |
| 输入 | `InputMap` | 全部动作可重绑；设置以 `ConfigFile` 独立保存 |
| 静态内容 | 自定义 `.tres` Resource | `Resource` 按只读输入处理、稳定 ID、显式清单引用、启动全量校验与快照隔离 |
| 场景 | `.tscn` | 负责空间和表现，不保存权威玩法状态 |
| 3D 运行资产 | glTF 2.0 `.glb` | Blender 等源文件进入 LFS，但 CI 不直接依赖源格式导入 |
| 文本本地化 | gettext `.po` | 使用语言无关键；正式映射为 `zh_CN` 与 `ja_JP` |
| 配音本地化 | 语言无关事件 ID＋语言资源映射 | 文本 Locale 与语音 Locale 独立 |
| 存档 | 版本化二进制 DTO | `FileAccess.store_var(..., false)`；不序列化 Node、脚本对象或 Resource |
| 动态音乐 | `AudioStreamInteractive` 与 `AudioStreamSynchronized` | 按拍或小节切换；计划边界到实际可闻起点的误差不超过 100 毫秒 |
| 混音 | Godot Audio Bus | 固定八组用户音量，不引入 FMOD 或 Wwise |
| 无障碍 | `Control` 语义、AccessibilityServer、系统屏幕阅读器 | Windows 用 NVDA，macOS 用 VoiceOver 实测 |
| 自动化 | Godot CLI＋正式工程自建的 headless 测试运行器 | 首个生产垂直切片前落地唯一权威入口；测试失败必须返回非零退出码 |
| 版本控制 | Git＋Git LFS | `.gd`、`.tscn`、`.tres`、`.po` 保持文本；大型二进制进入 LFS |

## 3. 架构边界

```text
键鼠输入 → 领域命令 → 权威规则服务 → 新状态＋领域事件
                           │          ├→ 快照／撤销／存档
                           │          ├→ 3D表现
                           │          ├→ UI／无障碍
                           │          └→ 音频调度
                           │
.tres定义 → 内容注册与校验服务 → 内容校验结果
```

### 3.1 权威规则层

- 权威规则层只接收不可变命令和显式状态，输出新状态与领域事件；具体类名在正式实现落地时确定，不以验证原型标识作为生产契约。
- 格位、生命、攻击、防御、速度、资源、步数、所有权和机关状态使用整数。
- 规则结果不得读取 `Transform3D`、碰撞结果、Tween 进度、渲染帧、系统时间或音频播放位置。
- 相同状态和命令必须得到相同结果。参与规则的集合按稳定 ID 显式排序，不依赖文件遍历或 Dictionary 顺序。
- 动画中断、窗口失焦、切换场景和不同帧率不得改变已经提交的逻辑结算。
- 永久成长的纯运行时领取事务使用 `RefCounted`，以 `profile_id`、`content_schema_version`、`content_version`、`current_health` 和按稳定ID规范化的已领取原子奖励ID作为权威状态。`content_schema_version` 绑定内容注册表的 `schema_version`，不表示存档架构版本。生命上限、攻击、防御和速度均从已封印的内容注册表与已领取ID重建，不接受另一份可独立漂移的四维属性状态。
- 事务只接受清单中的30个原子奖励ID，结果分为 `APPLIED`、`ALREADY_CLAIMED` 和 `REJECTED`。重复领取保持幂等；当前生命为0时拒绝新的领取；生命上限增加时，当前生命增加同值并保持原有生命缺口；只有 `APPLIED` 结果形成撤销提交边界。
- 内存中的 `EnemyInstanceState` 是敌人个体的最小权威动态状态，只保存稳定且语言无关的 ASCII `instance_id`、中央 `profile_id`、`content_schema_version`、`content_version`、当前耐久、当前 `PRIMARY`／`ALTERNATE` 状态及护盾是否完整。实例 ID 最长 128 个字符，只接受 ASCII 字母、数字及 `-`、`.`、`:`、`_`，且至少含一个字母或数字；显示文本不得充当实例身份。它不复制最大耐久、攻击、防御、速度、行为、战斗特性或视觉绑定；这些字段由 `EnemyInstanceResolver` 每次通过已封印 `ContentRegistry.lookup_enemy_profile()` 重新取得。初始实例固定为基础状态、满耐久，护盾由中央特性决定；重建可保留受损、破盾和零耐久，未声明替代状态或护盾的档案不能伪造对应状态。空值、错误／派生脚本、无效注册表、内容版本漂移、未知档案、非法状态和耐久／护盾组合按稳定优先级返回结构化失败，不暴露部分结果。
- 成功解析产生可丢弃的 `EnemyInstanceSnapshot` 防御快照，其中包含所选状态的精确四维以及行为、战斗特性和视觉绑定。快照只能通过精确类型的封印 `ContentRegistry` 构造，且不直接暴露战斗桥；只有已完成注册表溯源复验的 `EnemyInstanceResolutionResult` 才按需创建现有精确类型 `ContactCombatOpponentState`。该桥接保留 `instance_id`，不执行六种行为，不产生领域事件，也不是提交边界。确定性接触战候选内核继续复用永久成长事务的派生入口，从 `PlayerProgressionState` 与已封印的内容注册表重建玩家权威四维和当前生命；零耐久敌人可以被实例解析器准确重建，但由接触战内核判为已失活。
- 内存中的 `EnemyWorldState` 是敌人编目、格位与生命周期的复合权威状态。它以同一个 `instance_id` 直接关联 `EnemyWorldRecord`、`EnemyInstanceState` 和格网投影 actor，不维护第二份 actor 身份映射；记录按 `instance_id` 规范排序，格位只保存稳定 ASCII `space_id` 与整数 `Vector3i`，不保存场景路径、`Node`、`Transform3D` 或碰撞对象。`space_id` 与实例 ID 一样最长 128 个字符，只接受 ASCII 字母、数字及 `-`、`.`、`:`、`_`，且至少含一个字母或数字；负坐标仍是合法整数坐标。同一空间内的活动敌人格位唯一，不同空间可以复用相同局部坐标。`ACTIVE` 敌人必须耐久大于零并恰有一个格位；`RESOLVED` 敌人必须耐久为零且不占格，但稳定记录继续保留，重建和空间投影不得调用初始创建入口使其刷新。世界解析逐条复用 `EnemyInstanceResolver` 和已封印 `ContentRegistry`，因此复合状态仍不复制最大耐久、四维、行为、战斗特性或视觉绑定。结构合法的 `EnemyWorldState` 仍只是待解析候选；解析器以精确类型的已封印注册表建立单向依赖的 `EnemyWorldReadSnapshot`，再由成功的 `EnemyWorldResolutionResult` 统一公开无歧义的规范 ID、记录与地址防御列举、结构化查询、指定空间敌人 actor 投影及精确前态比较。失败结果保留结构化原因，不能用裸空集合冒充合法空世界；查询与投影结果只能从完整只读快照派生，不能把未知档案、内容漂移候选、孤立记录或裸 actor 字典直接投影为世界事实。外层与元素类型、`world_step`、生命周期、地址、重复 ID、按规范实例 ID 选择的单体解析失败、孤儿 actor、耐久矛盾、占格矛盾、同空间重复格位和结果完整性依次按稳定优先级整体拒绝，不发布部分编目。
- 内存中的 `PortableInventoryState` 只覆盖进入全局背包的便携成品方块子域，不把蓝图、材料、方币、通行方块、任务物品、现场配备、固定设施或常用补给伪装成同一数据类型。状态绑定 `content_schema_version`、`content_version`、12／16／20／24中的一个容量值和非负 `revision`；每个槽由一个规范排序且稳定的 ASCII `stack_id` 表示，数量为1—9，并保存中央 `blueprint_id`。可拆解的制作成品额外保存其中央配方ID并复验配方产出蓝图，不可拆解赠品必须没有配方ID；相同蓝图的不同来源可以占用不同堆叠，避免未来拆解时丢失来源语义。`PortableInventoryResolver` 只接受精确类型和已封印 `ContentRegistry`，按稳定优先级整体拒绝非法容量、revision、集合／堆叠、重复ID、满槽溢出、内容漂移、未知蓝图／配方、配方产出错配和非法选择，并通过 `PortableInventoryReadSnapshot` 与 `PortableInventoryResolutionResult` 提供防御性列举和精确前态比较。
- `TemporaryEffectSelectionCommand` 以期望 revision 和稳定堆叠ID请求选择下一场接触战的临时属性。`TemporaryEffectSelectionKernel` 只把中央蓝图20—24映射到现有五种 `ContactCombatCommand.TemporaryEffect`；首次选择产生 revision 加一的新状态候选，重复选择保持幂等，改选不同堆叠在命令未显式确认时返回 `CONFIRMATION_REQUIRED` 且状态不变，陈旧 revision 和非属性堆叠结构化拒绝。选择只保留具体来源堆叠并驱动战斗预览投影，不扣除数量、不发布战后消费事件，也不是提交边界；只有下述接触战提交子事务可以按既有战斗结果中的消费意图原子扣除并清除选择。
- 接触战命令显式提供主动方、已选临时属性投影和存活支援数量。内核以整数完成 `max(攻击－防御, 0)`、速度首击、同速主动方先手、交替攻击、首次有效攻击护盾抵消、每名存活支援成员攻击＋1，且上限为＋2，以及五种临时属性的＋2 投影。结果分为 `EVALUATED`、`BLOCKED` 和 `REJECTED`：0 伤害返回不改变状态且不产生事件的阻断预览；可结算结果返回玩家与敌方的候选新状态、完整分解和单个非提交型候选领域事件。结果构造时使用同一已封印注册表重新派生前后玩家快照，拒绝虽内部自洽但脱离权威成长状态的候选；公开的玩家候选状态使用独立值类型，不能直接作为其他权威事务的 `PlayerProgressionState` 输入。临时属性的结果字段只记录结算后应消费的意图，不表示背包状态已经改变。
- `ContactCombatTransactionCommand` 把目标 `instance_id`、接触 `EnemyWorldAddress`、按稳定ID规范排序的0—2名支援成员和主动方绑定为一次接触意图。`ContactCombatTransactionKernel.prepare()` 先用同一封印注册表解析玩家成长、敌人世界和背包，再验证目标仍为该地址的活动敌人；显式支援成员必须仍活动、位于目标同一 `space_id`，且目标与支援成员都由中央档案声明支援联动特性。准备阶段从具体已选堆叠投影临时属性，只调用一次既有 `ContactCombatKernel`，并把其已验证的可结算结果连同三份完整前态封入防御性 `ContactCombatTransactionCandidate`；0伤害仍只返回 `BLOCKED`，不建立候选。
- `ContactCombatTransactionKernel.commit()` 只接受完整的 `PREPARED` 结果，以固定的玩家→敌人世界→背包顺序复验当前三份权威状态；任一状态无效、内容漂移或与候选前态不等都会整体拒绝，不发布部分新状态或事件。提交路径不再调用接触战公式；它只在前态复验成功后，依据候选中的已评价非提交战斗结果派生并原子发布新 `PlayerProgressionState`、`EnemyWorldState`、`PortableInventoryState` 和单个提交事件。目标归零时转为 `RESOLVED` 并释放地址，目标存活时保留 `ACTIVE` 与地址；已选临时属性按候选消费意图只扣一个，数量归零则移除堆叠，随后清空选择并把 revision 增加一次。准备候选只携带绑定前态与非提交战斗结果，不携带三份权威替换状态；Candidate、Result 与 Event 数据对象均不提供可调用的准备／提交构造工厂，只有 `prepare()` 能产生 `PREPARED`，只有 `commit()` 能产生 `COMMITTED`。`PREPARED`、`BLOCKED`、`REJECTED` 和裸候选都不是提交边界，只有完整 `COMMITTED` 结果及其事件是提交边界。
- `WorldStepContactCommand` 以固定权威玩家 actor `actor.loer` 为另一参与方，只允许调用方提供选定 `space_id`、移动 actor、期望起点、正交单位方向和期望 `world_step`，不接受外部直接指定目标、目标地址或主动方。`WorldStepContactKernel.prepare()` 复用现有 `GridRuleState` 作为当前空间全部 actor 的唯一格位来源，解析玩家成长与敌人世界，要求格网和敌人世界的步数与命令完全一致，并要求选定空间内每个活动敌人的规范 actor 投影与格网逐项相等；其他空间或已解除敌人的 ID 不得泄漏进本地格网。移动 actor 尝试进入对方占用格时，内核从占格事实推导唯一敌方目标、敌方现址和主动方，产生防御性 `WorldStepContactLock`；玩家与敌人仍保留各自相邻格位，锁定只表达双方在本步余下移动阶段不可再次位移。空格或非敌方 actor 只返回 `NO_CONTACT`，不表示移动已获批准；越界、阻挡、陈旧起点、步数或投影不一致均结构化拒绝。
- `WorldStepContactKernel.revalidate()` 只接受完整的 `LOCKED` 结果，并在周期环境之后重新解析当前格网、玩家和敌人世界。玩家生命归零时以稳定优先级返回 `PLAYER_INACTIVE` 取消，目标已转为 `RESOLVED` 时返回 `ENEMY_INACTIVE` 取消；取消结果保留历史锁定快照用于诊断，但不再报告任何 actor 仍被锁定。双方仍活动时，步数、格位或敌方地址漂移都会失败关闭，而不是静默改写接触。复验不重查目标格的 blocked／越界状态：锁定双方始终留在各自原格位，锁定与取消路径从不提交进入对方格位的位移，目标格可走性由后续世界步提交 Gate 在实际执行位移时重新判定。`NO_CONTACT`、`LOCKED`、`CANCELLED` 和 `REJECTED` 均不发布状态或领域事件，不是提交边界，也不推进 `world_step`；锁定／取消结果只能由内核构造。
- `WorldStepState` 聚合选定 `space_id`、格网、玩家成长、敌人世界、便携背包和 `WorldStepStageInputs`，所有构造输入及查询输出均为防御快照。阶段输入保存阶段2—6的完整来源清单与 `complete` 声明。静态地图调用方通过下述初始化入口自动获得来源清单，无须手写 `complete=true`；直接构造规则夹具时仍须提供完整声明，缺省实例或不完整清单不能证明空阶段。v1 只接受全部清单为空、所有活动敌人均为中央 `enemy.behavior.shield` 且无非护盾特性的情况；巡逻、环境、构造、周期／替代状态、支援、多空间、非水平格网和未知 actor 均明确拒绝。已解除且不占格的历史敌人记录不触发行为。
- `StaticMapInitializer.initialize(map_id, player_candidate, inventory_candidate, registry)` 是创建新世界的公开入口，输入有效的精确 `PlayerProgressionState`、`PortableInventoryState` 和封印 `ContentRegistry`，返回 `StaticMapInitializationResult`。`succeeded()` 为真时 `world_state()` 返回独立 `WorldStepState`；失败通过 `failure_reason()` 返回无效注册表、非法／未知地图、无效成长／背包、内容版本不匹配、无效地图定义或初态构造失败，且不返回部分世界。每次同步初始化在既有验封读取作用域内取得地图与敌档，发布前复验来源及副本封印。
- 初始化从已校验地图创建 `GridRuleState`、`EnemyWorldState` 和 `WorldStepStageInputs`，格网及敌人世界步数均为0，玩家采用既有固定权威 actor ID；敌人复用 `EnemyInstanceResolver.create_initial()`，基础状态、满耐久、中央初始护盾和 `ACTIVE` 生命周期均按档案生成。成长、当前生命（包括合法的0生命）、已领取奖励、背包容量／revision／来源／数量／选择均原值复制，不恢复生命、赠送物品或消费选择。只有地图全部非敌人来源为空、每份敌人行为通过共享的 `WorldStepStaticScenario.has_no_pending_enemy_effects()` 判定，才构造完整空阶段清单；世界步内核继续用同一判定复验活动敌人。
- 初始化不执行接触、不推进世界步，`is_commit_boundary()` 恒为假、`domain_events()` 为空；同输入产生相同初态，输入 Resource、注册表、成长／背包和各次返回快照之间互相隔离。它不接受进行中世界，不负责读档、跨空间切换、复活或重置；调用方持有的旧世界不会被替换。
- `WorldStepCommand.create(kind, expected_world_step, expected_from_cell, direction)` 只支持 `MOVE` 与 `WAIT`；玩家身份固定，目标与主动方仍由接触内核推导。`WorldStepTransactionKernel.prepare(state, command, registry)` 验证封印内容、完整状态和空阶段条件，复用格网／接触／战斗验证；准备候选只保存完整前态、命令、接触锁定和既有战斗候选，不带权威后态。移动预检调用现有 `GridRuleKernel.execute()`，只使用其合法性和目的格；其内部已加一步的格网结果被丢弃，不传给后续阶段或发布。等待不调用格网移动。
- `WorldStepTransactionKernel.commit(current_state, prepared_result, registry)` 复验完整前态和内容封印，调用 `validate_contact_binding()` 将玩家移动方、目标、地址、方向、主动方和同一步数绑定战斗候选及其三份前态，再由现有战斗子事务提交同一个候选。无接触移动在提交时重新验证格网合法性；战斗提交不调用评价。统一发布点才将格网和敌人世界的 `world_step` 同时增加一次，发布一份聚合后态和一个 `WorldStepTransactionEvent`；其中嵌套战斗事件保留第7阶段原步数，外层事件显式记录前后步数。后态复验失败则隐藏全部后态及事件。成功结果也只返回副本；不提供公开成功结果／事件构造工厂。
- 世界步 `PREPARED` 与 `BLOCKED` 不发布后态或领域事件；`REJECTED` 整体无修改。对已推进当前状态再次提交同一候选会因完整前态不等而拒绝；对相同未变前态重复调用则产生相同结果，不记录可变的“已使用”标记。战后站位权威定义见[04第4节](04-gameplay-systems.md#4-世界步与确定性结算)。接触战子事务仍不自行推进步数；本 v1 在没有阶段2—6效果的前提下消费接触锁定，因此不会产生周期取消，外部在 prepare 与 commit 之间失活属于陈旧前态。既有 `WorldStepContactKernel.revalidate()` 的 `CANCELLED` 契约和回归保持不变，未来阶段执行器必须保留真实周期取消前的有效结果。
- 当前运行时实现覆盖内存永久成长、敌人档案／世界编目、背包与临时属性选择、接触评价／提交子事务、接触锁定，上述单空间静态世界步提交 v1，以及静态地图加载与初始化 v1。内容由清单 v6 的中央注册表提供。尚未实现构造响应、环境带动、敌人巡逻、周期环境／时序轮替、支援拓扑重算、其他玩家世界动作、常用补给／仓库、完整实体占格、正式章节地图／最终摆放、跨地图交通、可玩场景、UI、动画、音频、撤销历史或存档系统；阶段2—6仅可证明为空，不代表完整七阶段、六种敌人行为或完整 SYS-004／SYS-011 已验收。
- **脆弱假设：** `EnemyInstanceState` 继续故意不拥有网格坐标；当前由 `EnemyWorldState` 以稳定 `instance_id` 持有敌人编目、格位和 `ACTIVE`／`RESOLVED` 生命周期；静态新世界的生成由 `StaticMapInitializer` 负责，复活、动态阶段和存档迁移策略仍未实现。这些类型都是纯内存规则状态，不等于完整存档 DTO。未来切换基础／替代状态时还必须由世界事务明确当前耐久如何映射到所选状态最大耐久；当前四份替代档案两套最大耐久恰好相等，不能把这种内容巧合固化为规则。
- **脆弱假设：** 当前每个可拆解制作堆叠用中央配方ID表达实际投入，因为现有及已规划等价配方的材料数量都由版本化配方完整决定；若未来同一配方ID可以产生不同实际投入、品质或折扣，配方ID将不足以无损拆解，届时必须在制作事务落地前升级堆叠来源合同并提供显式迁移，不能从当前数量反推历史投入。

### 3.2 表现层

- 角色坐标、方块动画、敌人反馈和镜头只是整数状态的投影。
- `GridMap` 只用于静态格网、灰盒和可重复的场景装配。功能方块、机关和敌人由权威状态生成表现代理。
- 物理碰撞可用于鼠标拾取和视觉辅助，不得决定格位、推移、战斗或机关结果。
- 跨场景交通由持久状态管理器保留权威状态和音频状态，场景载入不能自动重置外出段。

### 3.3 内容层

- `res://content/content_manifest.tres` 是静态内容的唯一规范清单入口。启动时只加载清单显式引用的 Resource，禁止扫描目录发现内容。
- 当前清单的 `schema_version` 与 `content_version` 均为6，旧版v5及更早版本结构化拒绝，不建立兼容或存档迁移层；既有蓝图、配方、成长、路线合同和敌档的数值及语义保持不变。清单强类型显式引用 `res://content/progression/global_progression_catalog.tres`、`res://content/routes/representative_route_contract_catalog.tres`、`res://content/enemies/enemy_profile_catalog.tres` 与 `res://content/maps/static_map_catalog.tres`。前两者分别定义30个单属性永久成长奖励、9个主线组与4个M01—M04可选组，以及五份阶段末代表路线合同；敌人目录保持12个家族、24份档案。`contract:v6` 封印覆盖全部既有内容及地图目录ID、地图／空间／章节、普通格／阻挡格／出生点、敌人实例与中央档案引用、格位和未实现来源声明；集合按稳定顺序编码。运行时状态透传 v6 内容版本，不表示存档架构版本。
- `StaticMapCatalogResource` 是清单显式引用的唯一地图目录。`StaticMapDefinitionResource` 保存 `map_id`、单个 `space_id`、`chapter`、水平整数 `grid_cells`、`blocked_cells`、`player_spawn_cell` 及敌人摆放；`MapEnemyPlacementResource` 只保存 `instance_id`、中央 `profile_id` 和 `Vector3i cell`，不含敌人四维、行为、特性或护盾覆写。地图ID采用与空间／实例相同的稳定 ASCII 规则，最长128字符；目录内地图ID、空间ID和敌人实例ID分别全局唯一，敌人实例不得占用固定玩家ID。普通格／阻挡格以外的 `terrain_effect_ids`、`dynamic_behavior_ids`、`other_entity_ids` 声明均必须为空；未实现行为、替代状态或非护盾特性明确拒绝。
- 三个来源字段由 Godot 原生 `_get_property_list()`／`_get()`／`_set()` 接收序列化声明，`Variant` 只位于该边界；校验后保存为 `Array[StringName]`，通过 `terrain_effect_ids_snapshot()`、`dynamic_behavior_ids_snapshot()` 和 `other_entity_ids_snapshot()` 返回强类型副本。字段必须各声明一次；缺失、重复、标量、错误容器或非 `StringName` 元素均产生字段级 `map.sources.invalid`，合法但非空的来源仍按 `map.content.unsupported` 拒绝。接受显式 `Array[StringName]([])` 及原生保存产生的 `[]`；规范 v6 资源、数值和指纹保持不变。
- 原生资源加载可能在属性赋值前按当前 getter 的数组类型转换输入，因此序列化 getter 在未声明／无效时返回空值，在有效时返回不带数组类型约束的独立副本；实际 ID 数组始终强类型保存。声明有效性与 ID 一起深拷贝，并在中央验封和初始化发布前复验；错误声明不能被后续重复赋值、快照或原生保存／重载洗成有效空清单。该入口只处理资源属性，不自行解析文件。
- `StaticMapValidator` 在发布注册结果前拒绝空值、错误／派生 Resource、非法／重复身份、空格网、重复格、非水平格、阻挡越界、出生越界／阻挡／重复占格及未知敌档。格网校验复用现有整数规则；章节不得早于中央 `balance_contract_id` 的阶段起始章，并通过 `EnemyProfileValidator.validate_profile_at_chapter()` 按声明章的累计主线最低成长重验实际档案，复用既有成长推导与同一战斗平衡检查，不复制公式或放宽阈值。地图按ID、格位及实例ID规范排序，问题按中央稳定排序发布。`ContentRegistry.static_map_ids()`、`static_map_catalog()`、`lookup_static_map(map_id)` 提供防御列举和结构化查询；未知地图与未封印注册表不能用空地图冒充成功。
- `map.technical.static_initialization` 是第6章上下文的技术验收地图，含普通格、阻挡格及中央 F03／F09 强化护盾敌档。测试从实际清单加载至初始化，再使用生成状态提交移动、等待和连续接触；本样例不绑定正式 R 编号，不表示首次剧情登场、正式章节地图、最终摆放或完整路线阈值已冻结。玩法与战后站位仍以[04玩法规格](04-gameplay-systems.md)为唯一权威来源。
- `.tres` Resource 只承载创作定义，注册器把它们当作只读输入。Godot Resource 本身可变且可能由缓存共享，注册器必须逐字段生成内部快照，不保留输入 Resource 引用。
- 注册器先验证清单脚本、版本与既有内容的冻结条目数；条目数不是预期值时在表头阶段有界失败。数量正确时，再对清单声明的全部内容取快照并完成全量校验。只在零错误时一次性创建并发布完整注册表；任一错误都不得返回部分可用注册表，按 `fail-closed` 处理。
- 24 张蓝图、24 份敌人档案与技术静态地图已由同一内容注册、校验和内容封印职责统一管理；后续任务、经济和关卡引用接入时必须继续使用该职责，不得建立目录扫描或旁路数值表。
- 每项内容使用稳定、语言无关的 ID。显示名称、字幕和配音通过 ID 解析，不把中文或日文正文当主键。注册表的对外列举按稳定 ID 排序，校验问题按稳定字段排序，不依赖清单顺序、文件遍历或 Dictionary 顺序。
- 未知 ID 查询必须返回结构化结果，其中包含稳定错误码、请求 ID 和字段路径等定位信息，不得返回默认对象，也不得只用断言处理。
- 查询得到的定义、ID 列表和校验问题均以新快照或防御性副本返回，不暴露注册表的内部数组、Dictionary 或共享 Resource 引用。
- 普通注册表的可用状态由完整版本化内容封印重新推导，不依赖可从脚本写入的布尔“已初始化”标记；内部状态一旦偏离封印，后续查询和构建结果立即按未初始化处理。
- 接触战 `prepare()`／`commit()` 每次同步操作可在私有作用域内复用独占内容深拷贝的完整验封结果，避免按敌人数反复计算全量内容指纹。来源注册表不进入快速路径；副本通过既有快照与封印构造协议建立并独立验封，作用域内仍只返回防御副本。作用域不得跨 `await`、外部回调或结果发布；返回前统一关闭作用域并复验副本与来源，内容漂移时拒绝结果。副本只弱引用作用域，正常关闭或作用域释放后均恢复普通验封；候选、提交结果与读快照不保存该注册表。
- 当前信任边界防御不受信的内容 Resource 与公开查询返回值；同一工程内的 GDScript 仍属于可信代码，不把下划线成员当作插件或 Mod 沙箱。若未来开放第三方脚本，必须另建不可变桥接与隔离执行边界。
- 内容校验器对规则层的引用是刻意的设计意图：`enemy_profile_validator` 以规则层接触战算术作为敌人档案平衡校验的 oracle，形成内容层→规则层的包级引用；规则层各内核同样以 preload 引用内容注册表与内容定义类型。这是同一工程内可信代码之间的复用方向声明，不是分层违例；上述信任边界条款仍约束对外部输入的防御，两条并存。
- 内容校验至少覆盖重复 ID、缺失引用、非法解锁章、资源闭环、不可达知识条件和地图边界。
- 3D 制作源文件和运行资产分离。Blender 源文件保留在 LFS，进入游戏的代表资产显式导出为 glTF 2.0 `.glb`，避免 CI 依赖外部 DCC 软件版本。

## 4. 存档与设置

### 4.1 权威存档

权威存档不使用普通 JSON。JSON 会丢失 Godot 整数和 `Vector3i` 等类型语义，也不适合直接保存复杂状态。

每份存档包含：

- 固定魔数；
- 存档架构版本、游戏版本和内容版本；
- 角色、世界、任务、知识、方块、机关、敌人和经济 DTO；
- 当前入口快照、自动存档类型和受保护存档标记；
- 负载校验值。

写入流程固定为“临时文件写入、完整读取校验、替换正式文件、保留上一成功版本”。不启用 `full_objects`，不反序列化脚本对象。每次结构升级提供单向迁移器，并保留旧版本样本作为回归夹具。

当前状态、入口基线和房间检查点必须分别保存完整的“世界＋玩家知识＋章节进度”事务组。章节进度独立于世界状态，至少包含段落／步骤、对白游标、已看台词、材料、蓝图、任务旗标、地区与累计游玩时间；旧档迁移不得猜测或自动推进任务。

读档是显式提交边界。世界步撤销历史仅存在于当前运行会话，不属于权威存档 DTO，也不参与保存或迁移；读档成功后必须清空撤销历史，并把载入状态设为新的撤销基线，不能撤销回读档前状态。

### 4.2 用户设置

键位、文字语言、配音语言、字幕、辅助选项、音量和显示设置使用独立 `ConfigFile`。设置损坏时恢复默认值，不影响游戏存档。文本语言和配音语言切换不改变任务、资源或世界状态。

## 5. UI、本地化与无障碍

- 菜单、字幕、对话历史、战斗预览、方块预览、机关提示和存档界面统一使用 `Control`。
- UI 必须支持中文与日文极限长度、100%、150% 和 200% 缩放，以及键鼠焦点导航。
- 开发与测试字体必须具备相应使用许可并覆盖完整CJK字符集；正式字体在采购前由用户确认。
- 所有可交互 Control 设置可读名称、描述、角色和值，并保持稳定、合乎逻辑的焦点顺序。
- 3D 格网建立独立的虚拟焦点和状态摘要，使屏幕阅读器能读取当前格位、相邻格、对象、合法性、预计结果和失败原因。
- Windows 必须用 NVDA、macOS 必须用 VoiceOver 完成核心路径。只在编辑器中查看可访问树不算通过。
- 屏幕阅读器语义路径与系统 TTS 是两项独立能力：前者负责焦点、名称、角色、值和状态通知，后者只负责可选朗读文本。
- 必须分别测试系统存在中文／日文语音和语音列表为空的情况。空列表不得崩溃、卡住流程或吞掉信息，并应明确显示朗读不可用。
- 当前不承诺随游戏捆绑中文或日文 TTS 引擎；关键信息始终保留文本、视觉和功能音路径。若后续实测证明系统语音不足以满足已锁定的可选朗读要求，应重新打开相关技术基线决策，并由用户确认离线语音方案。

## 6. 音频基线

八组用户音量固定为：

1. `Master`：总音量；
2. `Music`：音乐；
3. `Voice`：角色语音；
4. `Ambience`：环境声；
5. `World`：世界交互与方块；
6. `UI`：界面与功能反馈；
7. `Navigation`：辅助导航；
8. `Narration`：无障碍朗读。

其中 `Narration` 用户设置同时控制游戏内 Narration 总线和 `DisplayServer.tts_speak()` 的音量参数；系统 TTS 不经过 Godot Audio Bus，屏幕阅读器自身音量仍由操作系统管理。

动态音乐使用四个同步层和三个区段状态，在下一拍或下一小节切换。交通和场景切换期间，音乐时间轴、环境状态和优先级仲裁不中断。长音乐和配音使用流送；生产回归分别记录请求到计划边界的预期等待，以及计划边界到实际可闻起点的同步误差、峰值内存、首次播放延迟和跨场景卡顿。

## 7. 自动化与内容验证

Godot 官方命令行支持 headless 脚本、资源导入和导出，但官方内建单元测试用于引擎本身，不是项目级 GDScript 测试框架。因此正式工程维护一个小型测试运行器，并以 [仓库 README](../../README.md#自动化测试) 记录的命令作为本地与持续集成共用的唯一权威入口。该入口先静态解析同一脚本依赖图，再执行显式注册的测试；两段均成功才算通过。

测试运行器负责：

- 规则单元测试与固定命令回放；
- 快照、撤销、存档和迁移测试；
- 内容 ID、引用、经济和知识状态校验；
- 地图连通、边界、占格和资源闭环检查；
- 文本 ID、字幕 ID、配音 ID 和双语覆盖差分；
- 失败时输出可定位日志并返回非零退出码。

测试与构建命令必须能在本地重复执行；后续持续集成只能调用同一权威入口，不维护语义不同的第二套流程。

自动化测试的递归清理只能作用于规范化后的 `user://` 严格子目录；根或子项若为符号链接、目录联接或reparse point，只能处理链接本身，禁止进入目标。存档实现同样只接受无链接祖先的 `user://` 子目录，并在每次读、写和替换代文件前拒绝链接叶节点；路径安全失败必须fail-closed，不能退化为普通损坏存档或静默继续。

## 8. 淘汰与后备切换

后续实测若确认下列任一问题来自引擎约束，或只能通过长期维护双语言、专有插件或自制基础设施解决，必须重新打开技术基线决策并评估淘汰 Godot 或切换后备方案：

1. 相同命令在双平台产生不同权威状态；
2. 快照、撤销或跨平台存档不能逐字段还原；
3. NVDA 或 VoiceOver 无法稳定操作核心路径；
4. 强类型 GDScript 与 headless 测试无法在提交前可靠发现规则和 DTO 错误；
5. 动态音乐的计划边界到实际可闻起点无法稳定达到 100 毫秒同步要求；
6. CJK 字体、版面或重绑定提示出现无法规避的跨平台差异；
7. Forward+ 在目标平台无法稳定运行，且更换渲染器会破坏已确认的视觉职责；
8. 单人＋AI 内容生产必须长期直接修改不可验证的二进制或引擎内部格式。

触发后停止扩展 Godot 正式工程，保留同一输入夹具、数据集和验收脚本，在 Unity 6.3 LTS＋URP 中复现同一代表技术切片。不得同时维护两套正式工程。

## 9. 已排除方案

| 方案 | 不作为生产方案的原因 |
|---|---|
| Unreal Engine | 3D 与音频能力充足，但对单人＋AI 项目过重；macOS 游戏运行时屏幕阅读路径缺少足够明确的官方保证 |
| Defold | 适合 2D 和轻量 3D，但复杂 3D、存档、桌面无障碍和动态音频需要较多自建能力 |
| Bevy | 整数规则层和 Rust 测试很好，但编辑器、内容生产、UI、本地化和音频工具不足以承担九章制作 |
| Stride | 当前 macOS 支持仍不适合作为 Apple Silicon 双首发的生产承诺 |

Godot 内部同时排除 .NET／C# 双栈、以 `GridMap`／物理／动画作为权威规则、普通 JSON 权威存档、外部音频中间件和无证据的 Compatibility 回退。这些不是平行实现候选。

## 10. 继续延期的事项

| 事项 | 处理门槛 | 负责人 |
|---|---|---|
| Logo、字标和商店主视觉 | 正式视觉方案形成后 | 用户＋品牌设计 |
| 最低配置和性能档位 | 双平台代表切片实测后 | 技术实现 |
| 最终 CJK 字体 | CJK 版面原型通过、采购前 | UI／本地化＋用户 |
| 正式音频格式、响度和压缩参数 | 双平台生产样本实测后 | 音频实现 |
| 正式人物与地区模型生产规格 | 代表资产技术验证与联合复审后 | 技术美术 |
| Windows／macOS 目标平台构建与原生自动化 | 代表切片进入双平台验证时 | 用户＋技术实现 |
| 发布渠道、签名、公证和商店功能 | Gate I | 用户＋发行 |
| 随游戏捆绑的离线 TTS 引擎 | 系统朗读无法满足验收且产品要求不允许降级时 | 无障碍设计＋用户 |

## 11. 版本、许可与升级规则

- 当前生产基线精确锁定Godot 4.7.2 Standard；出现更高版本不会自动升级，开发版不得用于生产工程。开始制作或验收前运行 `godot --headless --path game --script res://tools/verify_environment.gd` 检查实际引擎版本、Standard构建、Forward+配置和Compatibility自动回退；该命令是环境前置检查，不替代第7节已经建立的正式测试入口，两者都必须通过。
- Godot 使用 MIT 许可证。发行包必须保留 Godot 和第三方组件的版权与许可文本，游戏内容无需因此开源。
- Godot 的 MIT 许可证不自动决定本项目源码许可证；在用户另行确认前，不为项目源码声明 MIT 或其他开放源码许可证。
- 当前技术底线暂记为 Windows 10 x64 与 Apple Silicon macOS 13；这是 Godot 对简单 Forward+ 导出项目的最低要求，不是本作最终最低配置承诺。
- 任何补丁升级先在独立分支执行完整规则、存档、CJK、无障碍、音频和双平台回归。
- 次版本或大版本升级必须单独记录决策与兼容影响，不与内容批量制作同时进行。
- 外部插件默认不进入基线。确需插件时，必须记录许可证、维护状态、源码可用性、替代方案和移除成本。

## 12. 官方依据

- [Godot 4.7.2 发布说明](https://godotengine.org/article/maintenance-release-godot-4-7-2/)
- [Godot 发布归档](https://godotengine.org/download/archive/)
- [Godot 许可证](https://godotengine.org/license/)
- [脚本语言选择](https://docs.godotengine.org/en/4.7/getting_started/step_by_step/scripting_languages.html)
- [渲染器比较](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)
- [编辑器与导出项目系统要求](https://docs.godotengine.org/en/4.7/about/system_requirements.html)
- [Resource](https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html)
- [导入 3D 场景](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/index.html)
- [命令行与 headless](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [macOS 导出](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html)
- [屏幕阅读集成](https://docs.godotengine.org/en/latest/tutorials/ui/creating_applications.html#screen-reader-integration)
- [交互音乐](https://docs.godotengine.org/en/4.7/classes/class_audiostreaminteractive.html)
- [运行时文件读写](https://docs.godotengine.org/en/4.7/tutorials/io/runtime_file_loading_and_saving.html)
