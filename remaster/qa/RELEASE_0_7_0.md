# 0.7.0 Windows 开发试玩版验收

2026-09-19。进化分页下设暗影与机械两个技能点分支；六个新增节点、两种限时变身及两种临时召唤。六个旧被动和存档兼容，技能总数 39，新增四个 Blender 模型及源文件。

## 自动验证

1004 项检查，0 失败：基础 287、战斗 18、动作关卡 88、体验 155、存档伤害 38、武器伙伴 77、手柄 59、设备切换 30、探索 182、进化 70。日志为本目录 evolution_test_*.log，每份均有完成总结。存档重定向至项目 .godot-user 并使用 --remaster-test，不改真实玩家存档。

进化专项验证学习前置和扣点、重复学习拒绝、真实近战增伤及玩家减伤、实际召唤伤害、不耗弹药、实体墙遮挡、同时存在/防叠加、暂停计时、到期清理、死亡/切房清理、共享冷却、防切路线刷新、保存/读取、旧档缺省迁移、异常字段、PC 输入、模拟 Xbox 组合键与菜单输入隔离。

墙体测试首轮受到此前已发射弹体影响，最终隔离旧弹体并增加视线阻挡断言；真实运行逻辑未放宽。所有测试复测通过。发行验证后只增加用于选择技能分页的命令行参数，实际 EXE 已验证该路径。

## 画面与资源

65 个 Blender 模型。13 张开发截图、2 张实际发行 EXE 截图全部分别查看，见 [画面验收](../../docs/qa/remaster-0.7.0-review.md)。生成脚本 source/build_evolution.py；运行脚本 tests/capture_evolution.gd。

扫描全部 ERROR / SCRIPT ERROR：开发用 Godot 导入、导出、headless 和 GPU 日志只有本机 Failed to read the root certificate store；本次独立发行 EXE 两份 stderr 为空。Blender stderr 有 TBBmalloc 运行库提示，四个模型均正常导出。

## Windows 本机发行

六文件 ZIP 已逐项验哈希，复制到既有发行目录后再次核对；旧 ZIP 保留。实际发行 EXE 分别显示标题及新进化树，取得两次 REMASTER_CAPTURE 0。

- EXE：E:/Godot/release/暗影机械城重制版/ShadowMechCityReforged.exe
- ZIP：E:/Godot/release/暗影机械城重制版-0.7.0.zip
- ZIP 大小：99,897,112 字节
- ZIP SHA256：5f248bd1c357238f0ca34b1f82412769f56c90746032a66e746da6ba0293c4e7
- EXE SHA256：a4d46408369bbddf655d56a6181124c83b308029923a8d7b65b2c49ac97b1006
- PCK SHA256：5bd5f6903d5d3330325c407b5111749f2d59efdb44262843455c4f4b5d431a83

[标题](published_0_7_0_title.png) / [日志](published_0_7_0_title.log)；[进化树](published_0_7_0_evolution.png) / [日志](published_0_7_0_evolution.log)。

本版未上架 itch.io。完整空中连斩、玩家受击状态、主动格挡与破防、NPC/任务及原特色系统仍待完成。最新追加要求：上下通道参考暗影火炬城的探索方式，结合升降平台、楼梯、电梯、墙壁断层和边缘；此 0.7.0 包尚未进行这批通道改造。
