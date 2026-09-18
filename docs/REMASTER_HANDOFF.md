# 重制持续开发交接

更新：2026-09-19，0.6.0 内容已实现、934 项检查通过，Windows 包已生成并复制到发行目录。Git 实际提交/上传状态请用 git status/log/ls-remote 核对，不仅依赖本文件。

## 用户授权与目标

用户已睡觉，明确要求继续开发、QA、Windows 试玩发布并上传既有 Git。目标是 9 月 19 日晚尽快完成更多可交付内容。不要反复询问已授权事项；仍须遵守工具权限。没有授权创建独立任务或派遣子代理。不要把大商业 GDD 的全部规模宣称已经完成。

本任务已创建每小时续做 heartbeat，截止 2026-09-19 22:00 上海时间。自动任务 ID：automation；仅在有可验证里程碑、失败或需用户处理时通知。电脑与 Codex 需可运行。先核对有无进行中工作，不覆盖编辑。

## 本轮完成

- 五个原模块、六生命碎片、七记忆核心与原七篇档案；模型与三页阅读界面。
- F / Xbox 下方向 + Y 炸弹：1.2 秒引信、3.5 秒冷却、60 范围伤害、3 米范围；三处封板永久破坏，无枪械弹药消耗。
- 七秘室使用原条件，旧档已访问秘室保持通行；已有身法技能满足相应门控。
- 八区域一次性补给箱：24 备弹 +1 药剂，双满保留；其余溢出不储存。
- 免费存档回满血和 8 发弹匣、备弹至少 24、药剂至少 3；商人 25 金币 24 发，普通敌人 1/技能后 3，Boss 6。现有蒸汽炮/弓弩共享弹药，没有独立手枪。
- 默认 PC，检测 Xbox 连接自动切换的 0.5.2 行为保留。

## 下一步优先

1. 原五名 NPC：炉心铸造师格里夫、雾酿术士塞菈、轨图解析师弥娅、遗物收藏家奥德里克、鸦眼赏金追踪者罗克。参考 scripts/dialogue_data.gd、quest_data.gd、quest_runtime.gd 与 docs/DEV_PLAN.md；本轮已复用 quest_data.gd 的七个记忆档案。
2. 原支线与四章节目标要接真实事实，奖励一次性持久化。武器家族目前全部初始开放，不能将初始七武器直接算作完成六武器探索任务，需明确真正完成条件并写入设计。
3. 复杂环境机关（符文/风场/激流）、Boss 阶段、量子升级、黑客、虚拟空间及美术动作精修，按 docs/REMASTER_ROADMAP.md 保持完成边界。
4. 新阶段 QA、截图、独立 EXE、打包再提交。实体手柄不可用，不能伪造人工通关。

## 工程与验证

工程 E:\Godot\test-project\我的第一个godot游戏。Godot：E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe。Blender：D:\Blender\blender-4.2.9-windows-x64\blender.exe。Python：D:\Python\Python314\python.exe。

读 .claude/skills/godot-capture/SKILL.md，开工 pull、完工 push；全部 ERROR 行扫描，实际 GPU 图每张查看。当前测试及 GPU 日志只有本机证书读取限制 `Failed to read the root certificate store`，不要误写 stderr 为空。

APPDATA 定向项目 .godot-user，加 -- --remaster-test，避免真实存档。测试：--headless --path . --fixed-fps 60 --quit-after 24000 --script remaster/tests/test_*.gd。九组：remaster 287、combat_release 18、revision 88、experience 155、preview 38、arsenal 77、controller 59、device_switch 30、exploration 182。必须看到总结行，自动 quit 退出 0 不代表测试完成。

最终图：remaster/tests/capture_exploration.gd，QA 记录 docs/qa/remaster-0.6.0-review.md。七个新模型由 remaster/source/build_exploration.py 生成；不用额外低平台放奖励，它们会遮挡行走和伙伴视线，复用既有平台。

导出 Windows Desktop Remaster 到 build/Reforged，Python remaster/source/package_release.py；版本同步 project.godot 和 export_presets.cfg。build/release_manifest.json 校验六个文件和 ZIP。发行目录 E:\Godot\release\暗影机械城重制版，当前 ZIP 暗影机械城重制版-0.6.0.zip；复制需提权，保留旧 ZIP。Start-Process 一律 WindowStyle Hidden。

Git main -> git@github.com:Messyshadow/ShadowMechCity.git，已核验公共仓库。只 stage 本轮重制代码/资产/测试/文档，不加入根目录大量无关未跟踪日志、.godot-user、.superpowers、经典项目资源等。push 前核对 scoped diff、凭据模式扫描，正常 commit + annotated tag，atomic push main 与 tag；.git 写入及网络需工具提权。
