# -*- coding: utf-8 -*-
"""
素材转换 / 生成工具
- 主角: 解压 Kenney Adventurer 姿势 PNG
- 敌人/特效: 冒险岛 GIF -> PNG 序列帧
- 瓦片/背景: 程序生成扁平风格 PNG
- 音频: 复制本地 mp3 + 合成缺失的 SFX(wav)
- 输出 manifest.json 供运行时构建 SpriteFrames
用法: python tools/convert_assets.py
"""
import os, io, json, zipfile, glob, math, struct, wave, shutil

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC  = r"E:\SourceCode\Games\engine\mini_engine\2D素材"
KZIP = r"E:\SourceCode\Games\engine\big_engine\godot\_tmp_preview\kenney_chars.zip"
MAPLE = os.path.join(SRC, "《冒险岛》特效和怪物角色GIF动态图_爱给网_aigei_com")

from PIL import Image, ImageDraw, ImageFilter

A = os.path.join(PROJ, "assets")
def ensure(*p):
    d = os.path.join(A, *p)
    os.makedirs(d, exist_ok=True)
    return d

manifest = {"player": {}, "enemies": {}, "effects": {}}

# ---------------------------------------------------------------- 主角
def do_player():
    out = ensure("player")
    z = zipfile.ZipFile(KZIP)
    poses = {}
    for n in z.namelist():
        if n.startswith("PNG/Adventurer/Poses/") and n.endswith(".png"):
            key = os.path.basename(n).replace("adventurer_", "").replace(".png", "")
            img = Image.open(io.BytesIO(z.read(n))).convert("RGBA")
            img.save(os.path.join(out, key + ".png"))
            poses[key] = img.size
    print(f"[player] 导出 {len(poses)} 个姿势")
    # 动画定义: 名称 -> (帧列表, fps, loop)
    manifest["player"] = {
        "poses": sorted(poses.keys()),
        "size": poses.get("idle", (80, 110)),
    }

# ------------------------------------------------------ GIF -> 帧序列
def gif_frames(path):
    im = Image.open(path)
    n = getattr(im, "n_frames", 1)
    durs, frames = [], []
    for i in range(n):
        im.seek(i)
        durs.append(im.info.get("duration", 100) or 100)
        frames.append(im.convert("RGBA"))
    fps = max(1.0, min(24.0, 1000.0 / (sum(durs) / len(durs))))
    return frames, round(fps, 1)

def export_gif(path, out_dir, trim=True):
    frames, fps = gif_frames(path)
    os.makedirs(out_dir, exist_ok=True)
    # 统一裁剪到所有帧并集的包围盒, 保持帧间对齐
    if trim:
        bbox = None
        for f in frames:
            b = f.getbbox()
            if b is None:
                continue
            bbox = b if bbox is None else (min(bbox[0], b[0]), min(bbox[1], b[1]),
                                           max(bbox[2], b[2]), max(bbox[3], b[3]))
        if bbox:
            frames = [f.crop(bbox) for f in frames]
    for i, f in enumerate(frames):
        f.save(os.path.join(out_dir, f"{i:02d}.png"))
    return len(frames), fps, frames[0].size

def do_enemies():
    mobs = sorted(glob.glob(os.path.join(MAPLE, "冒险岛小怪物GIF图", "*.gif")))
    picks = {"mushroom": 26, "furry": 7}
    for name, idx in picks.items():
        out = ensure("enemies", name)
        n, fps, size = export_gif(mobs[idx], out)
        manifest["enemies"][name] = {"frames": n, "fps": fps, "size": size}
        print(f"[enemy] {name}: {n} 帧 fps={fps} size={size}")

def do_effects():
    fx = sorted(glob.glob(os.path.join(MAPLE, "冒险岛特效", "*.gif")))
    # idx6 = 蓝色斩击(黑底,叠加发光)
    out = ensure("effects", "slash")
    n, fps, size = export_gif(fx[6], out, trim=True)
    manifest["effects"]["slash"] = {"frames": n, "fps": fps, "size": size, "blend": "add"}
    print(f"[fx] slash: {n} 帧 fps={fps} size={size}")

# --------------------------------------------------------- 瓦片/背景
def do_tiles():
    out = ensure("tiles")
    TS = 64
    def shade(c, d):
        return tuple(max(0, min(255, int(x + d))) for x in c)
    # 地面块: 草顶 + 土身
    grass = (110, 180, 90); dirt = (104, 78, 56)
    img = Image.new("RGBA", (TS, TS), dirt + (255,))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, TS, 14], fill=grass + (255,))
    d.rectangle([0, 14, TS, 18], fill=shade(grass, -40) + (255,))
    # 土块纹理点
    for (px, py) in [(14, 34), (40, 28), (48, 50), (22, 52), (33, 42)]:
        d.ellipse([px, py, px + 6, py + 6], fill=shade(dirt, -22) + (255,))
    d.rectangle([0, 0, TS - 1, TS - 1], outline=shade(dirt, -30) + (255,))
    img.save(os.path.join(out, "ground.png"))
    # 实心石砖块(墙)
    stone = (96, 102, 120)
    img2 = Image.new("RGBA", (TS, TS), stone + (255,))
    d2 = ImageDraw.Draw(img2)
    d2.rectangle([0, 0, TS, 4], fill=shade(stone, 30) + (255,))
    d2.rectangle([0, TS - 4, TS, TS], fill=shade(stone, -30) + (255,))
    d2.line([TS // 2, 0, TS // 2, TS], fill=shade(stone, -18) + (255,), width=2)
    d2.rectangle([0, 0, TS - 1, TS - 1], outline=shade(stone, -40) + (255,))
    img2.save(os.path.join(out, "stone.png"))
    # 单向平台(细木板)
    wood = (150, 110, 70)
    img3 = Image.new("RGBA", (TS, 20), (0, 0, 0, 0))
    d3 = ImageDraw.Draw(img3)
    d3.rectangle([0, 0, TS, 18], fill=wood + (255,))
    d3.rectangle([0, 0, TS, 5], fill=shade(wood, 28) + (255,))
    d3.rectangle([0, 14, TS, 18], fill=shade(wood, -34) + (255,))
    img3.save(os.path.join(out, "platform.png"))
    print("[tiles] ground/stone/platform 生成完成")

def do_background():
    out = ensure("bg")
    W, H = 480, 270
    # 远景天空渐变
    sky = Image.new("RGB", (W, H))
    top = (28, 30, 54); bot = (78, 64, 96)
    for y in range(H):
        t = y / H
        col = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(W):
            sky.putpixel((x, y), col)
    # 点缀星星
    import random
    random.seed(7)
    dd = ImageDraw.Draw(sky)
    for _ in range(70):
        x, y = random.randint(0, W), random.randint(0, int(H * 0.6))
        b = random.randint(120, 220)
        dd.point((x, y), fill=(b, b, b))
    sky.save(os.path.join(out, "sky.png"))
    # 中景远山剪影 (带透明)
    far = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(far)
    col = (46, 44, 74, 255)
    pts = [(0, H)]
    x = 0
    random.seed(11)
    while x < W:
        pts.append((x, H - random.randint(50, 120)))
        x += random.randint(40, 70)
    pts.append((W, H))
    fd.polygon(pts, fill=col)
    far.save(os.path.join(out, "hills_far.png"))
    # 近景山剪影
    near = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    nd = ImageDraw.Draw(near)
    col2 = (32, 30, 52, 255)
    pts = [(0, H)]
    x = 0
    random.seed(21)
    while x < W:
        pts.append((x, H - random.randint(20, 80)))
        x += random.randint(30, 55)
    pts.append((W, H))
    nd.polygon(pts, fill=col2)
    near.save(os.path.join(out, "hills_near.png"))
    print("[bg] sky/hills 生成完成")

# --------------------------------------------------------------- 音频
def do_audio():
    out = ensure("audio")
    pick = {
        "bgm": "游戏BOSS战-紧张电子乐_爱给网_aigei_com.mp3",
        "attack": "刀剑攻击、挥动刀、刀剑摩擦、刀剑碰撞、刀劈音效、挥剑、_爱给网_aigei_com.mp3",
        "hit": "爆炸声效-攻击-爆破_爱给网_aigei_com.mp3",
        "ui": "点击按钮-游戏ui(Button32)_爱给网_aigei_com.mp3",
    }
    sd = os.path.join(SRC, "音效")
    for k, fn in pick.items():
        src = os.path.join(sd, fn)
        if os.path.exists(src):
            shutil.copy(src, os.path.join(out, k + ".mp3"))
            print(f"[audio] {k} <- {fn}")
        else:
            print(f"[audio] 缺失: {fn}")
    # 合成缺失的 SFX
    synth_jump(os.path.join(out, "jump.wav"))
    synth_dash(os.path.join(out, "dash.wav"))
    synth_land(os.path.join(out, "land.wav"))
    print("[audio] 合成 jump/dash/land wav")

def _write_wav(path, samples, rate=44100):
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples))

def synth_jump(path, rate=44100):
    n = int(0.18 * rate); s = []
    for i in range(n):
        t = i / rate; env = math.exp(-7 * t)
        f = 420 + 520 * t          # 上滑
        s.append(0.6 * env * math.sin(2 * math.pi * f * t))
    _write_wav(path, s, rate)

def synth_dash(path, rate=44100):
    import random
    n = int(0.22 * rate); s = []
    random.seed(3)
    for i in range(n):
        t = i / rate; env = math.exp(-9 * t)
        noise = random.uniform(-1, 1)
        tone = math.sin(2 * math.pi * (180 + 60 * math.sin(40 * t)) * t)
        s.append(env * (0.5 * noise + 0.5 * tone))
    _write_wav(path, s, rate)

def synth_land(path, rate=44100):
    import random
    n = int(0.14 * rate); s = []
    random.seed(5)
    for i in range(n):
        t = i / rate; env = math.exp(-22 * t)
        s.append(env * (0.7 * random.uniform(-1, 1) + 0.3 * math.sin(2 * math.pi * 90 * t)))
    _write_wav(path, s, rate)

if __name__ == "__main__":
    do_player()
    do_enemies()
    do_effects()
    do_tiles()
    do_background()
    do_audio()
    with open(os.path.join(A, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("\n=== 完成. manifest.json 已写出 ===")
    print(json.dumps(manifest, ensure_ascii=False, indent=2))
