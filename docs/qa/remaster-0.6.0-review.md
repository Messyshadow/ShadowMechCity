# 重制版 0.6.0 探索画面验收

2026-09-19。按 godot-capture 要求逐张检查实际 Vulkan 渲染，不以 headless 成功替代画面检查。

## 最终截图

| 截图 | 检查结果 |
|---|---|
| [模块拾取](../../remaster/qa/exploration_modules_world.png) | 熔岩腔穴出现模块盒、生命碎片和独立装备箱；平台主路保留 |
| [封板](../../remaster/qa/exploration_sealed_heart.png) | 橙色叉形封板遮住奖励，F 炸开提示可见 |
| [破坏后](../../remaster/qa/exploration_unsealed_heart.png) | 封板实体消失，红色生命核心和 +10 说明出现 |
| [秘室档案](../../remaster/qa/exploration_archive_world.png) | 紫色具名记忆核心与两只旧装备箱区分；没有用普通金币代替档案 |
| [补给箱](../../remaster/qa/exploration_supply_world.png) | 有弹筒的独立补给箱落在平台地面，避开敌人出生点；绿色名称可读 |
| [记忆页](../../remaster/qa/exploration_archive_page.png) | 已同步显示原版短篇档案，未同步显示寻找位置；列表不越出面板 |
| [模块页](../../remaster/qa/exploration_modules_page.png) | 状态、用法和房名分行，缺失模块仍说明位置 |
| [补给页](../../remaster/qa/exploration_supply_page.png) | 五项计数、免费保底、购买价格和库存溢出规则可完整阅读 |
| [Xbox 模块页](../../remaster/qa/exploration_controller_modules.png) | 炸弹为下方向 + Y、攀墙为左摇杆上、滑翔为 A；PC F11 不被误替换 |
| [Xbox 滚动](../../remaster/qa/exploration_controller_scroll.png) | 焦点可到第五模块，列表自动滚动，金色框完整可见 |
| [地图](../../remaster/qa/exploration_map.png) | 40 房间、秘室条件和房间收集计数；全图小字需放大阅读，缩放功能保留 |
| [发布 EXE 标题](../../remaster/qa/published_0_6_0_title.png) | 独立运行，显示 0.6.0 开发试玩版 |
| [发布 EXE 档案](../../remaster/qa/published_0_6_0_collection.png) | 打包的新档案脚本和中文字体正常显示 |

## 修正

- 初版追加台阶挡住地面角色，也遮挡修复伙伴视线。最终奖励复用既有跳跃台，原速度和治疗回归通过。
- 初版生命核心发光过曝，改用较低强度的红色材质；封板文字移至表面前方。
- 初版补给箱浮在敌人出生位，改为地面放置并绕开敌人。
- 初版长列表只能滚轮翻到底，改为可获得焦点的档案卡，手柄和键盘均能滚动查看。

共 934 项自动检查通过；[发布记录](../../remaster/qa/RELEASE_0_6_0.md)。完整日志包含本机证书存储读取限制，未出现其他脚本/资源/物理错误。没有连接实体 Xbox 手柄；检查使用模拟输入，不能声称实体 USB/蓝牙或全游戏人工通关已验收。
