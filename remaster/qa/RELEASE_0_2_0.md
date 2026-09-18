# 0.2.0 发布验收

QA：2026-09-18；最终发布包复核：2026-09-19（Asia/Shanghai）。按用户要求执行“QA 测试、发布、上传 Git”。这是可玩开发版，完整重制仍在进行。

## QA 结果

| 检查 | 结果 | 证据 |
|---|---|---|
| 世界、存档、交易、通道、复活、UI | 286 / 286，通过 | [revision_tests.log](revision_tests.log) |
| 实际伤害、掩体、弹药、连击、吸血、Boss 解锁 | 18 / 18，通过 | [revision_combat_tests.log](revision_combat_tests.log) |
| 新动作、30 个非 Boss 房间实际移动跳跃、强化、楼梯、暂停、新 Boss 招式 | 88 / 88，通过 | [revision_extended_tests.log](revision_extended_tests.log) |
| 实机画面 | 23 张逐张检查；捕获均成功，退出码 0，错误日志为空 | [revision_visual.log](revision_visual.log)、[revision_visual_errors.log](revision_visual_errors.log) |
| Windows release 导出 | 成功，退出码 0；文件版本 0.2.0.0，产品版本 0.2.0 | `Windows Desktop Remaster` 预设 |
| 发布目录的独立 EXE | 正常启动、截图、退出码 0；最终错误日志为空 | [published_0_2_0.log](published_0_2_0.log)、[published_0_2_0_errors.log](published_0_2_0_errors.log)、[画面](published_0_2_0.png) |
| ZIP 及发布完整性 | 六个 ZIP 条目逐项与构建文件校验一致；发布文件和 ZIP 的 SHA-256 与构建产物一致 | 发布目录 `SHA256SUMS.txt` |

合计 **392 项游戏逻辑检查通过，0 失败**。最后一次检查在截图退出清理修正后重新执行。测试使用隔离的数据目录及测试存档，不覆盖玩家正式进度。

23 张实机画面包含七个区域、七位 Boss、背包／技能／地图、拳击起手和命中、长刃／重锤／蒸汽炮攻击、楼梯通行。检查角色及武器位置、缺失材质、楼梯遮挡和 UI 裁切；本次未发现阻止该开发版发布的画面问题。

运行环境：Windows、Godot 4.7.rc 自定义构建、Vulkan / Forward+、NVIDIA RTX 5070 Laptop GPU。Headless 日志中的根证书库读取提示来自当前受限环境；没有脚本错误或游戏检查失败，最终独立 GPU 运行无错误。

## 本轮发布修正

- 快速截图直接退出曾报告资源仍在使用。现先释放游戏场景，再由独立 SceneTree 计时器结束进程；最终 EXE 复核已消除该提示。截图保存失败也会返回非零退出码。
- 发布目录原操作说明和校验文件仍为 0.1.0，现统一为 0.2.0。README 更新模型／动作／图标数量、强化说明、第三组回归命令及发布路径。
- 新增 `remaster/source/package_release.py`，打包固定的六个文件，生成 SHA-256 清单，并检查 ZIP 条目及内容。脚本只写工程 `build/`；正式目录复制后再次校验。

## 发布产物

- 游戏：`E:\Godot\release\暗影机械城重制版\ShadowMechCityReforged.exe`
- 资源：同目录 `ShadowMechCityReforged.pck`，必须与 EXE 放在一起。
- ZIP：`E:\Godot\release\暗影机械城重制版-0.2.0.zip`
- 包内另含 `开始前请读.txt`、`操作说明.md`、`RELEASE_NOTES.md`、`SHA256SUMS.txt`。
- 保留旧 `暗影机械城重制版-0.1.0.zip`；原 2D 发布目录未改动。

| 文件 | 字节数 | SHA-256 |
|---|---:|---|
| ShadowMechCityReforged.exe | 68143616 | `1c3a3609a76f51c84c822a8060ebbcad4071d8b173033731ee583efc9caff0cb` |
| ShadowMechCityReforged.pck | 53677440 | `4aa23bbd3cb276ef202be4bce5ced0adc99ffb66fa8c2051fb224f874ee2008e` |
| 暗影机械城重制版-0.2.0.zip | 79010907 | `6d45aa1a815e95fd3843e79353e2fe752d83ef3ef1ec2f8c64f6087230f846e2` |

## Git 交付范围与限制

本版本提交包括重制脚本、Blender 可编辑源文件、运行模型／音频／图标、导出配置、测试和 QA 证据；目标为 `Messyshadow/ShadowMechCity` 的 `main`，版本标签 `remaster-v0.2.0`。不加入构建 EXE/PCK/ZIP、玩家数据、引擎目录及原有无关未跟踪文件。同步前远端没有新增提交，本地已有 77 个历史提交待推送；普通快进推送保留这些历史，不强制覆盖远端。

自动化检查和截图不替代完整人工通关、长时间性能测试或人工听音验收。逐关谜题／探索节奏、动作细节、美术材质、召唤伙伴及更多旧技能仍待继续重制，详见 [开发验收记录](REVISION_0_2_0.md)。
