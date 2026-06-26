# -*- coding: utf-8 -*-
"""暗黑机械风格素材生成: 钢铁瓦片 / 霓虹边 / 机械城背景 / 齿轮 / 武器"""
from PIL import Image, ImageDraw, ImageFilter
import os, math, random

A = r"E:\Godot\test-project\我的第一个godot游戏\assets"
def ensure(*p):
    d = os.path.join(A, *p); os.makedirs(d, exist_ok=True); return d
def sh(c, d): return tuple(max(0, min(255, int(x + d))) for x in c)

# ---------------- 钢铁瓦片 ----------------
def tiles():
    out = ensure("tiles"); TS = 64
    steel = (46, 50, 60)
    img = Image.new("RGBA", (TS, TS), steel + (255,))
    d = ImageDraw.Draw(img)
    # 面板分割线
    d.rectangle([0, 0, TS - 1, TS - 1], outline=sh(steel, -18) + (255,))
    d.line([0, TS // 2, TS, TS // 2], fill=sh(steel, -12) + (255,))
    d.line([TS // 2, 0, TS // 2, TS], fill=sh(steel, -12) + (255,))
    # 铆钉
    for (px, py) in [(8, 8), (TS - 10, 8), (8, TS - 10), (TS - 10, TS - 10),
                     (TS // 2 - 1, TS // 2 - 1)]:
        d.ellipse([px, py, px + 4, py + 4], fill=sh(steel, 26) + (255,))
        d.ellipse([px + 1, py + 1, px + 3, py + 3], fill=sh(steel, -20) + (255,))
    img.save(os.path.join(out, "metal.png"))

    # 顶部霓虹边条 (青色发光)
    neon = (60, 220, 255)
    g = Image.new("RGBA", (TS, 16), (0, 0, 0, 0))
    gd = ImageDraw.Draw(g)
    gd.rectangle([0, 6, TS, 16], fill=sh(steel, 8) + (255,))
    gd.rectangle([0, 4, TS, 7], fill=neon + (255,))            # 亮线
    gd.rectangle([0, 2, TS, 4], fill=neon + (120,))            # 辉光
    gd.rectangle([0, 0, TS, 2], fill=neon + (50,))
    g.save(os.path.join(out, "metal_top.png"))

    # 墙体 (更暗铆钉钢板)
    wsteel = (34, 37, 46)
    w = Image.new("RGBA", (TS, TS), wsteel + (255,))
    wd = ImageDraw.Draw(w)
    wd.rectangle([0, 0, TS - 1, TS - 1], outline=sh(wsteel, -14) + (255,))
    for yy in range(8, TS, 20):
        for xx in range(8, TS, 20):
            wd.ellipse([xx, yy, xx + 3, yy + 3], fill=sh(wsteel, 22) + (255,))
    wd.line([0, TS // 2, TS, TS // 2], fill=sh(wsteel, -10) + (255,))
    w.save(os.path.join(out, "metal_wall.png"))

    # 单向平台 (金属格栅 + 橙色警示边)
    warn = (255, 150, 40)
    p = Image.new("RGBA", (TS, 18), (0, 0, 0, 0))
    pd = ImageDraw.Draw(p)
    pd.rectangle([0, 2, TS, 18], fill=(54, 58, 68, 255))
    for xx in range(0, TS, 8):
        pd.line([xx, 4, xx, 16], fill=(38, 40, 48, 255))
    pd.rectangle([0, 0, TS, 3], fill=warn + (255,))
    p.save(os.path.join(out, "platform.png"))
    print("[tiles] 钢铁瓦片/霓虹边/警示平台")

# ---------------- 机械城背景 ----------------
def background():
    out = ensure("bg"); W, H = 480, 270
    sky = Image.new("RGB", (W, H))
    top = (8, 9, 16); bot = (26, 24, 42)
    for y in range(H):
        t = y / H
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(W):
            sky.putpixel((x, y), c)
    dd = ImageDraw.Draw(sky)
    random.seed(7)
    for _ in range(50):
        x, y = random.randint(0, W), random.randint(0, int(H * 0.5))
        b = random.randint(60, 130); dd.point((x, y), fill=(b, b, b + 10))
    sky.save(os.path.join(out, "sky.png"))

    # 远景机械城天际线 (塔楼 + 亮窗)
    def skyline(seed, col, wincol, hmin, hmax, ybase, win_p):
        im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(im); random.seed(seed); x = 0
        while x < W:
            bw = random.randint(34, 64); bh = random.randint(hmin, hmax)
            x0, y0 = x, H - bh - ybase
            d.rectangle([x0, y0, x0 + bw, H], fill=col + (255,))
            # 顶部天线/烟囱
            if random.random() < 0.5:
                ax = x0 + bw // 2
                d.rectangle([ax - 2, y0 - random.randint(8, 22), ax + 2, y0], fill=col + (255,))
            # 亮窗
            for wy in range(y0 + 6, H - 4, 10):
                for wx in range(x0 + 5, x0 + bw - 4, 9):
                    if random.random() < win_p:
                        d.rectangle([wx, wy, wx + 3, wy + 4], fill=wincol + (255,))
            x += bw + random.randint(2, 10)
        return im
    far = skyline(11, (24, 26, 40), (70, 90, 140), 60, 130, 30, 0.25)
    far.save(os.path.join(out, "hills_far.png"))
    near = skyline(23, (14, 15, 24), (255, 170, 70), 40, 100, 0, 0.30)
    near.save(os.path.join(out, "hills_near.png"))
    print("[bg] 暗黑机械城天际线")

# ---------------- 齿轮 (背景旋转) ----------------
def gear():
    out = ensure("bg"); S = 120; teeth = 12
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im); cx = cy = S / 2
    rO, rI, rH = S * 0.46, S * 0.34, S * 0.12
    col = (40, 43, 52, 255); edge = (66, 70, 82, 255)
    # 齿
    for i in range(teeth):
        a = TAU = 2 * math.pi * i / teeth
        for da in [-0.12, 0.12]:
            pass
    # 用多边形画齿轮
    pts = []
    steps = teeth * 2
    for i in range(steps):
        a = 2 * math.pi * i / steps
        r = rO if i % 2 == 0 else rI
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    d.polygon(pts, fill=col, outline=edge)
    d.ellipse([cx - rI * 0.7, cy - rI * 0.7, cx + rI * 0.7, cy + rI * 0.7], fill=(30, 32, 40, 255), outline=edge)
    d.ellipse([cx - rH, cy - rH, cx + rH, cy + rH], fill=(0, 0, 0, 0), outline=edge)
    im.save(os.path.join(out, "gear.png"))
    print("[bg] 齿轮")

# ---------------- 武器 ----------------
def weapons():
    out = ensure("weapons")
    # 铁剑: 竖直刀身, 青刃
    sw = Image.new("RGBA", (20, 56), (0, 0, 0, 0)); d = ImageDraw.Draw(sw)
    d.polygon([(10, 2), (14, 14), (13, 44), (7, 44), (6, 14)], fill=(150, 170, 190, 255))  # 刃
    d.line([(10, 3), (10, 43)], fill=(210, 245, 255, 255), width=1)                         # 高光
    d.rectangle([4, 44, 16, 48], fill=(70, 74, 84, 255))                                    # 护手
    d.rectangle([8, 48, 12, 56], fill=(40, 42, 50, 255))                                    # 柄
    sw.save(os.path.join(out, "sword.png"))
    # 重锤: 大锤头
    hm = Image.new("RGBA", (34, 60), (0, 0, 0, 0)); d = ImageDraw.Draw(hm)
    d.rectangle([4, 2, 30, 22], fill=(64, 68, 80, 255), outline=(90, 95, 110, 255))         # 锤头
    d.rectangle([6, 4, 12, 20], fill=(80, 86, 100, 255))
    for yy in [6, 12, 18]:
        d.ellipse([24, yy, 28, yy + 3], fill=(255, 150, 40, 255))                           # 橙铆钉
    d.rectangle([15, 22, 19, 60], fill=(46, 40, 34, 255))                                   # 柄
    hm.save(os.path.join(out, "hammer.png"))
    # 蒸汽炮: 横向炮管
    cn = Image.new("RGBA", (54, 30), (0, 0, 0, 0)); d = ImageDraw.Draw(cn)
    d.rectangle([2, 10, 14, 24], fill=(60, 64, 76, 255), outline=(90, 95, 110, 255))        # 握把/罐体
    d.rectangle([14, 8, 48, 20], fill=(54, 58, 70, 255), outline=(90, 95, 110, 255))        # 炮管
    d.ellipse([44, 6, 54, 22], fill=(40, 42, 50, 255), outline=(255, 150, 40, 255))         # 炮口
    d.ellipse([4, 4, 12, 12], fill=(255, 150, 40, 200))                                     # 压力表
    cn.save(os.path.join(out, "cannon.png"))
    print("[weapons] sword/hammer/cannon")

if __name__ == "__main__":
    tiles(); background(); gear(); weapons()
    print("=== 暗黑机械素材完成 ===")
