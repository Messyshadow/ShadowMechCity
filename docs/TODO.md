# 待办 / 当前状态（速览）

> 完整分阶段计划以 **[DEV_PLAN.md](DEV_PLAN.md)** 为准（约35-40小批次到商业成品，做完打勾）。
> 总设计：[GAME_DESIGN.md](GAME_DESIGN.md)。权威GDD：[design/暗影机械城_GDD(2).md](design/暗影机械城_GDD(2).md)。

## 已完成
阶段 0–7 + 8.1 + 8.2（见 DEV_PLAN.md 勾选项）。要点：
- 战斗/3武器(J普攻+K各异重攻)/rvros剑士真实攻击动画/判定框已加大
- 技能树(T) + 经验金币 + 装备背包(U,稀有度/强化/词条)
- 银河城8房间 + 四向门/钥匙门/存档塔/地图M；中央车站=新手村(不刷怪)
- 2个多阶段Boss(蒸汽机甲泰坦/岩核机甲巨兽-会召唤)
- 游戏外壳(开始/暂停/设置/存读档/键盘导航)
- 能力门控：冲刺(初始,穿能量门) + 炸弹(F,熔岩腔穴拾取,落地弹两下/撞墙引爆,炸开可破坏墙)

## 下一批次
**8.3 二段跳/攀墙/水下推进/滑翔 能力门**（均"找到才解锁"，回溯解锁旧区域）。

## 运行 / 发布
- 开发：编辑器 F5，或 play_game.bat
- 发布：`E:\Godot\release\暗影机械城\ShadowMechCity.exe`（每次只更新同目录 pck）
- 验证流程：`godot --headless --path <proj> res://main.tscn --quit-after 180` 抓 ERROR/SCRIPT → `--export-pack` 更新 pck
