# 重制持续开发交接

更新：2026-09-19，0.7.0 进化内容已实现、1004 项检查通过，Windows 包已生成并复制到发行目录。Git 实际提交/上传状态请用 git status/log/ls-remote 核对，不仅依赖本文件。

## 用户授权与目标

用户允许无人值守继续，明确要求继续开发、QA、Windows 试玩发布并上传既有 Git。目标是 9 月 19 日晚尽快完成更多可交付内容。不要反复询问已授权事项；仍须遵守工具权限。没有授权创建独立任务或派遣子代理。不要把大商业 GDD 的全部规模宣称已经完成。

本任务已创建每小时续做 heartbeat，截止 2026-09-19 22:00 上海时间。自动任务 ID：automation；仅在有可验证里程碑、失败或需用户处理时通知。电脑与 Codex 需可运行。先核对有无进行中工作，不覆盖编辑。

## 最新已完成：0.7.0

- 进化分页下设暗影/机械两条技能点路线，保留旧被动，新增变身、召唤、时长强化，总计 39 节点。
- Z / Xbox 上 + Y 变身，V / Xbox 上 + L3 召唤；10/12 秒，强化 14/16 秒，共享 30/22 秒冷却。
- 四个新增 Blender 资产；技能预览与 HUD 倒计时，死亡/切房清理、冷却保存和旧档兼容。
- 1004 项检查、15 张最终实机图已验；ZIP 已发布到既有本机发行目录。详见 remaster/qa/RELEASE_0_7_0.md。
- 用户最新追加：上下通道参考暗影火炬城，结合升降平台、楼梯、电梯、墙壁断层、墙壁边缘。已检查现有 lift/stairs/ladder/pipe；正在开始这批改造，0.7.0 尚未含改造。

## 此前完成：0.6.0

- 五个原模块、六生命碎片、七记忆核心与原七篇档案；模型与三页阅读界面。
- F / Xbox 下方向 + Y 炸弹：1.2 秒引信、3.5 秒冷却、60 范围伤害、3 米范围；三处封板永久破坏，无枪械弹药消耗。
- 七秘室使用原条件，旧档已访问秘室保持通行；已有身法技能满足相应门控。
- 八区域一次性补给箱：24 备弹 +1 药剂，双满保留；其余溢出不储存。
- 免费存档回满血和 8 发弹匣、备弹至少 24、药剂至少 3；商人 25 金币 24 发，普通敌人 1/技能后 3，Boss 6。现有蒸汽炮/弓弩共享弹药，没有独立手枪。
- 默认 PC，检测 Xbox 连接自动切换的 0.5.2 行为保留。

## 下一步优先

0. 用户最新 steering：先改上下通道（升降平台/楼梯/电梯/断墙及边缘），做真实碰撞与移动验收，不能只改装饰和名称。随后继续下列战斗优先项。

1. 战斗核心优先：先修玩家受击状态及攻击中断，接入现有 hurt 动画；再制作真正的多段空中连斩和收尾、强化各武器地面动作差异；实现玩家主动格挡和清晰的格挡/破防反馈，接入 PC/Xbox 提示。是否有精准弹反及其窗口须明确设计并验证，不能把盾卫减伤当作玩家格挡已完成。详见 docs/qa/remaster-0.6.0-combat-audit.md。当前地面有 3/4 段，空中重复同一 air 动画；玩家受击后实际播放 jump；盾卫减伤仍走普通受伤效果。这是 0.6.0 核查结论，0.7.0 只增进化，尚未修复这些反馈问题。
2. 原五名 NPC：炉心铸造师格里夫、雾酿术士塞菈、轨图解析师弥娅、遗物收藏家奥德里克、鸦眼赏金追踪者罗克。参考 scripts/dialogue_data.gd、quest_data.gd、quest_runtime.gd 与 docs/DEV_PLAN.md；本轮已复用 quest_data.gd 的七个记忆档案。
3. 原支线与四章节目标要接真实事实，奖励一次性持久化。武器家族目前全部初始开放，不能将初始七武器直接算作完成六武器探索任务，需明确真正完成条件并写入设计。
4. 复杂环境机关（符文/风场/激流）、Boss 阶段、量子升级、黑客、虚拟空间及美术动作精修，按 docs/REMASTER_ROADMAP.md 保持完成边界。
5. 新阶段 QA、截图、独立 EXE、打包再提交。实体手柄不可用，不能伪造人工通关。

## 与其他开发任务协同

用户睡前补充：VS Code 的 Codex 正在开发《诡异森林》。不要定时重启或关机；若以后确需电源操作，必须先核对该项目开发已完成且保存，不能中断另一任务。当前没有重启/关机授权，也不创建此类自动任务。

## 工程与验证

工程 E:\Godot\test-project\我的第一个godot游戏。Godot：E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe。Blender：D:\Blender\blender-4.2.9-windows-x64\blender.exe。Python：D:\Python\Python314\python.exe。

读 .claude/skills/godot-capture/SKILL.md，开工 pull、完工 push；全部 ERROR 行扫描，实际 GPU 图每张查看。当前测试及 GPU 日志只有本机证书读取限制 `Failed to read the root certificate store`，不要误写 stderr 为空。

APPDATA 定向项目 .godot-user，加 -- --remaster-test，避免真实存档。测试：--headless --path . --fixed-fps 60 --quit-after 24000 --script remaster/tests/test_*.gd。十组：remaster 287、combat_release 18、revision 88、experience 155、preview 38、arsenal 77、controller 59、device_switch 30、exploration 182、evolution 70。必须看到总结行，自动 quit 退出 0 不代表测试完成。

最终图：remaster/tests/capture_exploration.gd，QA 记录 docs/qa/remaster-0.6.0-review.md。七个新模型由 remaster/source/build_exploration.py 生成；不用额外低平台放奖励，它们会遮挡行走和伙伴视线，复用既有平台。

导出 Windows Desktop Remaster 到 build/Reforged，Python remaster/source/package_release.py；版本同步 project.godot 和 export_presets.cfg。build/release_manifest.json 校验六个文件和 ZIP。发行目录 E:\Godot\release\暗影机械城重制版，当前 ZIP 暗影机械城重制版-0.7.0.zip；复制需提权，保留旧 ZIP。Start-Process 一律 WindowStyle Hidden。

Git main -> git@github.com:Messyshadow/ShadowMechCity.git，已核验公共仓库。只 stage 本轮重制代码/资产/测试/文档，不加入根目录大量无关未跟踪日志、.godot-user、.superpowers、经典项目资源等。push 前核对 scoped diff、凭据模式扫描，正常 commit + annotated tag，atomic push main 与 tag；.git 写入及网络需工具提权。
