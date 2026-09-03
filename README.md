# 此世千形

正式日文标题：**この世界、千のかたち**

一款童话二次元气质的单人方格冒险游戏。玩家将通过路线规划、机关解谜和实地调查，使用有限的功能方块帮助同一个世界安全地变化。

本仓库是《此世千形》的正式生产仓库。历史可行性原型、测试运行和验收证据在独立验证仓库中维护，不复制到这里。

当前仓库正在建立正式工程与内容生产基线，尚无可试玩的正式内容；权威规则层、内容清单 v5、五阶段代表路线合同、12 个敌人家族的基础／强化 24 份中央档案与项目级自动化测试已经可以无头运行。权威规则层已具备内存中的永久成长领取事务、敌人运行时实例解析、敌人世界编目与格位生命周期，以及确定性接触战结算候选评价内核：同一个稳定实例 ID 同时作为敌人记录与格网投影的规范 actor ID，复合状态保留 `ACTIVE`／`RESOLVED` 生命周期、`space_id`＋整数三维格位和 `world_step` 前态；敌人数值、行为、特性与视觉仍只从已封印的中央注册表解析。当前仍未接入完整七阶段世界步、接触锁定或原子提交、背包中的临时效果生命周期、六种行为执行、地图 Resource 与正式摆放、UI、动画、场景、撤销历史或存档 DTO。

## 开发环境

- Godot **4.7.2 Standard**；其他补丁版本、开发版和 .NET/Mono 构建不属于当前生产基线。
- Git 与 [Git LFS](https://git-lfs.com/)；视觉、音频、模型和字体等二进制资源通过 LFS 管理。

首次克隆后执行：

```bash
git lfs install
git lfs pull
git lfs fsck --objects --pointers HEAD
"${GODOT_BIN:-godot}" --headless --path game --script res://tools/verify_environment.gd
```

最后一条命令只检查引擎版本、Standard 构建、Forward+ 配置和 Compatibility 自动回退，不替代下方正式测试入口。若本机 Godot 可执行文件使用其他名称，可通过 `GODOT_BIN` 环境变量指定完整路径。

GitHub 生成的 ZIP 或 tar.gz 源码归档可能只包含 LFS 指针而不包含实际资源。正式制作与复审应使用安装了 Git LFS 的 Git clone，并以上述 `git lfs fsck --objects --pointers HEAD` 结果为准。

GitHub Actions 的 `Baseline / verify` 检查会在 pull request 与 `main` 更新时重新验证 LFS、官方 Godot 4.7.2 Standard 发行包、Forward+／Vulkan 启动和编辑器导入，然后调用与本地相同的正式测试命令。

## 自动化测试

在仓库根目录执行唯一的项目级 headless 测试命令：

```bash
bash game/tools/run_headless_tests.sh
```

- `game/src/rules/` 保存不依赖场景树、渲染、物理或输入设备的权威规则类型，包括整数格规则、永久成长的纯运行时领取事务、敌人实例档案解析、敌人世界编目与格位生命周期，以及确定性接触战候选内核。
- `game/src/content/` 保存强类型 `Resource` 内容定义，以及不依赖场景树的 `RefCounted` 注册、校验和快照查询类型；蓝图、配方、全局永久成长、代表路线合同与敌人档案共用同一注册职责和内容封印。
- `game/content/` 保存正式 `.tres` 内容；`res://content/content_manifest.tres` 是唯一规范清单入口，并显式引用永久成长、五阶段代表路线合同与敌人档案目录，内容发现不扫描目录。
- `game/tests/` 保存显式注册的灰盒夹具、规则测试与唯一测试运行器，不扫描目录发现测试。
- `game/tools/` 保存环境检查与测试命令门面，不承载玩法规则。
- 静态解析失败、Godot 未处理错误、零测试、单项零断言、缺失汇总或任意测试失败都会返回非零退出码；成功日志会列出测试名称、通过数、失败数和断言数。
- 新增测试套件时必须在 `game/tests/run_tests.gd` 中显式注册；敌人世界测试覆盖规范排序、跨空间格位、生命周期矛盾、孤儿格网 actor、内容漂移、派生类型和输入／输出篡改，但不把格位投影测试声称为完整世界步或地图验收。在建立隔离测试数据根以前，自动化测试不得直接读写正式 `user://` 数据。

## 文档

从 [文档索引](docs/index.md) 开始。
