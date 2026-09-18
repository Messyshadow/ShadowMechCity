"""Package the already-exported Windows build and verify every ZIP entry.

Run from any working directory with Python 3. Uses only the standard library;
all output stays in the project's build directory. Publishing is a separate step.
"""
from pathlib import Path
import hashlib
import json
import re
import shutil
import zipfile


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "build" / "Reforged"


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    version = re.search(r'config/version="([0-9.]+)"',
                        (ROOT / "project.godot").read_text(encoding="utf-8")).group(1)
    payload = ["ShadowMechCityReforged.exe", "ShadowMechCityReforged.pck",
               "开始前请读.txt", "操作说明.md", "RELEASE_NOTES.md"]
    for name in payload[:2]:
        if not (BUILD / name).is_file() or (BUILD / name).stat().st_size == 0:
            raise RuntimeError(f"Export the Windows build first: {name}")
    shutil.copyfile(ROOT / "remaster" / "README.md", BUILD / "操作说明.md")
    shutil.copyfile(ROOT / "remaster" / "RELEASE_NOTES.md", BUILD / "RELEASE_NOTES.md")
    (BUILD / "开始前请读.txt").write_text(
        f"暗影机械城 · 重铸余烬 {version} 开发版\n\n"
        "先完整解压，再双击 ShadowMechCityReforged.exe。\n"
        "EXE 与同名 PCK 必须放在同一个文件夹，无需安装 Godot 或 Blender。\n\n"
        "A/D 移动；空格跳跃、二段跳、蹬墙；J 攻击；K 技能；Q 换武器；\n"
        "Shift 冲刺；R 装填；H 治疗；E 交互；I 背包；T 技能；M 地图。\n"
        "W/S 使用楼梯、梯井、升降机和排水管；Esc 暂停或关闭面板。\n\n"
        "首次与中央车站的商人赫克对话可领取吸血护符。\n"
        "在同步终端按 E 保存并补给；死亡回到最后激活的存档点。\n"
        "背包可强化装备，出售的装备可从商人回购栏买回。\n\n"
        "本版仍在重制中，尚未完成全部美术精修和完整人工通关测试。\n"
        "详细操作与变更见同目录的操作说明.md 和 RELEASE_NOTES.md。\n",
        encoding="utf-8-sig")
    hashes = {name: digest(BUILD / name) for name in payload}
    (BUILD / "SHA256SUMS.txt").write_text(
        "".join(f"{value}  {name}\n" for name, value in hashes.items()), encoding="utf-8")
    payload.append("SHA256SUMS.txt")
    archive = ROOT / "build" / f"ShadowMechCityReforged-{version}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        for name in payload:
            bundle.write(BUILD / name, name)
    with zipfile.ZipFile(archive) as bundle:
        if bundle.testzip() is not None or set(bundle.namelist()) != set(payload):
            raise RuntimeError("ZIP integrity or entry list mismatch")
        for name in payload:
            with bundle.open(name) as stream:
                if hashlib.file_digest(stream, "sha256").hexdigest() != digest(BUILD / name):
                    raise RuntimeError(f"ZIP content mismatch: {name}")
    manifest = {"version": version, "files": [
        {"name": name, "bytes": (BUILD / name).stat().st_size,
         "sha256": digest(BUILD / name)} for name in payload],
        "archive": {"name": archive.name, "bytes": archive.stat().st_size,
                    "sha256": digest(archive)}, "zip_verified": True}
    (ROOT / "build" / "release_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(manifest, ensure_ascii=True, indent=2))


if __name__ == "__main__":
    main()
