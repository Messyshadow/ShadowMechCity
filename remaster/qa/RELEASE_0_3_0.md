# 0.3.0 发布验收

2026-09-19（Asia/Shanghai）。本轮按用户要求持续重制，并完成 QA、Windows 发布和 Git 交付。0.3.0 仍为开发版。

## 结果

| 项目 | 结果 |
|---|---|
| 四组游戏检查 | 287 + 18 + 88 + 155 = **548 项通过，0 失败**，四组退出码均为 0 |
| 源工程 GPU 检查 | 26 张实际渲染截图；全屏/窗口模式检查通过，退出码 0，错误日志为空 |
| Windows release 导出 | `Windows Desktop Remaster`，退出码 0；EXE 文件版本 0.3.0.0，产品版本 0.3.0 |
| 发布目录独立 EXE | 主菜单及晨曦温室各一次实际 GPU 启动，截图成功，退出码均为 0，两个错误日志为空 |
| 打包校验 | ZIP 六个条目逐项校验通过；六个发布文件与 ZIP 的 SHA-256 均和构建产物一致 |
| 旧版本 | 0.2.0 ZIP 保留；正式目录更新到 0.3.0 |

测试和截图使用独立 APPDATA 与禁用正式保存的测试模式，不覆盖玩家正式存档。Headless/导出日志唯一 ERROR 为受限环境读取根证书库失败；未出现脚本或游戏资源错误，GPU 测试没有错误日志。

## 产物

- `E:\Godot\release\暗影机械城重制版\ShadowMechCityReforged.exe`，与同目录 `.pck` 一起运行。
- `E:\Godot\release\暗影机械城重制版-0.3.0.zip`，85,468,725 字节；包含 EXE、PCK、开始前请读、操作说明、版本说明、SHA256SUMS。
- EXE SHA-256：`3eb2a720afee7eed45737cc53e2cf23610277ea472d95ec5368779a42b8d9bb2`
- PCK SHA-256：`8ea9a461b9e0e693412e1fa040f27bfa7f82e84969f349a41777b4a7708f67fc`
- ZIP SHA-256：`776554cb428abd5fecda9016509893ac9dc79537f0411623d48b6bf0385aad47`
- 源码版本标签：`remaster-v0.3.0`。二进制在本机发布目录，源码和 Blender 源资产保存在 Git；没有将 EXE/ZIP 提交到源码仓库。

## 证据

- [开发与画面验收](EXPERIENCE_0_3_0.md)
- [发布文件清单](published_0_3_0_manifest.json)
- [主菜单启动日志](published_0_3_0_title.log)、[错误日志](published_0_3_0_title_errors.log)、[截图](published_0_3_0_title.png)
- [晨曦温室启动日志](published_0_3_0_dawn.log)、[错误日志](published_0_3_0_dawn_errors.log)、[截图](published_0_3_0_dawn.png)

尚未进行完整人工通关、长时间多硬件稳定性测试或人工混音验收。旧武器/召唤伙伴迁移及美术动作精修仍未完成，不能将本版理解为整个重制项目完成。
