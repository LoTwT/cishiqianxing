# 此世千形

正式日文标题：**この世界、千のかたち**

一款童话二次元气质的单人方格冒险游戏。玩家将通过路线规划、机关解谜和实地调查，使用有限的功能方块帮助同一个世界安全地变化。

本仓库是《此世千形》的正式生产仓库。历史可行性原型、测试运行和验收证据在独立验证仓库中维护，不复制到这里。

当前仓库正在建立正式工程与内容生产基线，尚无可运行的正式版本。

## 开发环境

- Godot **4.7.2 Standard**；其他补丁版本、开发版和 .NET/Mono 构建不属于当前生产基线。
- Git 与 [Git LFS](https://git-lfs.com/)；视觉、音频、模型和字体等二进制资源通过 LFS 管理。

首次克隆后执行：

```bash
git lfs install
git lfs pull
git lfs fsck --objects --pointers HEAD
godot --headless --path game --script res://tools/verify_environment.gd
```

最后一条命令只检查引擎版本、Standard 构建、Forward+ 配置和 Compatibility 自动回退，不替代后续正式测试入口。若本机 Godot 可执行文件使用其他名称，请只替换命令中的 `godot`。

GitHub 生成的 ZIP 或 tar.gz 源码归档可能只包含 LFS 指针而不包含实际资源。正式制作与复审应使用安装了 Git LFS 的 Git clone，并以上述 `git lfs fsck --objects --pointers HEAD` 结果为准。

GitHub Actions 的 `Baseline / verify` 检查会在 pull request 与 `main` 更新时重新验证 LFS、官方 Godot 4.7.2 Standard 发行包、Forward+／Vulkan 启动和编辑器导入。它是生产环境与工程导入门禁，不替代后续随正式规则代码建立的项目测试入口。

## 文档

从 [文档索引](docs/index.md) 开始。
