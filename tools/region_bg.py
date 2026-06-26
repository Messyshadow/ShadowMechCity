# -*- coding: utf-8 -*-
"""按区域生成暗黑主题背景: sky + 远/近剪影 (各区域不同配色与剪影风格)"""
from PIL import Image, ImageDraw
import os, random, math

A = r"E:\Godot\test-project\我的第一个godot游戏\assets\bg"
W, H = 480, 270

def grad(top, bot):
    im = Image.new("RGB", (W, H))
    for y in range(H):
        t = y / H
        im.putpixel  # noqa
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(W):
            im.putpixel((x, y), c)
    return im

def stars(im, color, n, seed):
    d = ImageDraw.Draw(im); random.seed(seed)
    for _ in range(n):
        x, y = random.randint(0, W), random.randint(0, int(H * 0.55))
        d.point((x, y), fill=color)

def towers(seed, col, win, hmin, hmax, ybase, winp):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    random.seed(seed); x = 0
    while x < W:
        bw = random.randint(34, 64); bh = random.randint(hmin, hmax)
        x0, y0 = x, H - bh - ybase
        d.rectangle([x0, y0, x0 + bw, H], fill=col + (255,))
        if random.random() < 0.5:
            ax = x0 + bw // 2
            d.rectangle([ax - 2, y0 - random.randint(8, 22), ax + 2, y0], fill=col + (255,))
        for wy in range(y0 + 6, H - 4, 10):
            for wx in range(x0 + 5, x0 + bw - 4, 9):
                if random.random() < winp:
                    d.rectangle([wx, wy, wx + 3, wy + 4], fill=win + (255,))
        x += bw + random.randint(2, 10)
    return im

def stalactites(seed, col, ybase, accent):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    random.seed(seed)
    # 顶部钟乳石
    x = 0
    while x < W:
        bw = random.randint(20, 48); bh = random.randint(30, 90)
        d.polygon([(x, 0), (x + bw, 0), (x + bw // 2, bh)], fill=col + (255,))
        x += bw + random.randint(0, 12)
    # 底部岩丘
    pts = [(0, H)]; x = 0
    while x < W:
        pts.append((x, H - random.randint(20, 70) - ybase)); x += random.randint(30, 60)
    pts.append((W, H)); d.polygon(pts, fill=col + (255,))
    for _ in range(20):
        gx, gy = random.randint(0, W), random.randint(int(H * 0.6), H)
        d.point((gx, gy), fill=accent)
    return im

def arches(seed, col, ybase):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    random.seed(seed); x = 0
    base = H - ybase
    while x < W:
        bw = random.randint(50, 90)
        d.rectangle([x, base - 60, x + 10, H], fill=col + (255,))
        d.rectangle([x + bw - 10, base - 60, x + bw, H], fill=col + (255,))
        d.arc([x, base - 110, x + bw, base - 10], 180, 360, fill=col + (255,), width=10)
        # 管道
        d.line([x, base - 30, x + bw, base - 30], fill=col + (255,), width=6)
        x += bw + random.randint(6, 20)
    return im

def pillars(seed, col, ybase):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    random.seed(seed); x = 6
    base = H - ybase
    while x < W:
        bw = random.randint(26, 40); h = random.randint(80, 160)
        top = base - h
        d.rectangle([x, top, x + bw, H], fill=col + (255,))
        d.rectangle([x - 4, top, x + bw + 4, top + 10], fill=col + (255,))      # 柱头
        d.rectangle([x - 4, base - 10, x + bw + 4, base], fill=col + (255,))    # 柱础
        x += bw + random.randint(24, 50)
    return im

def factory(seed, col, ybase, glow):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    random.seed(seed); x = 0
    base = H - ybase
    while x < W:
        bw = random.randint(40, 70); bh = random.randint(60, 130)
        d.rectangle([x, H - bh - ybase, x + bw, H], fill=col + (255,))
        # 烟囱
        if random.random() < 0.6:
            sx = x + random.randint(6, bw - 14)
            d.rectangle([sx, H - bh - ybase - random.randint(20, 50), sx + 12, H - bh - ybase], fill=col + (255,))
        # 发光通风口
        for _ in range(random.randint(1, 3)):
            vy = random.randint(H - bh - ybase + 8, H - 10)
            vx = x + random.randint(6, bw - 12)
            d.rectangle([vx, vy, vx + 8, vy + 5], fill=glow + (255,))
        x += bw + random.randint(4, 12)
    # 大齿轮剪影
    for _ in range(2):
        gx, gy, r = random.randint(40, W - 40), random.randint(30, 120), random.randint(24, 40)
        d.ellipse([gx - r, gy - r, gx + r, gy + r], outline=col + (255,), width=8)
    return im

THEMES = {
    "city":    dict(sky=((8,9,16),(26,24,42)), star=(90,90,110),
                    far=lambda: towers(11,(24,26,40),(70,90,140),60,130,30,0.25),
                    near=lambda: towers(23,(14,15,24),(255,170,70),40,100,0,0.30)),
    "mine":    dict(sky=((14,9,6),(40,24,16)), star=(120,80,50),
                    far=lambda: stalactites(31,(40,26,18),24,(255,150,60)),
                    near=lambda: stalactites(37,(22,14,9),0,(255,120,40))),
    "water":   dict(sky=((6,16,18),(14,34,38)), star=(80,140,140),
                    far=lambda: arches(41,(20,40,42),24),
                    near=lambda: arches(47,(10,24,26),0)),
    "temple":  dict(sky=((12,8,20),(30,20,46)), star=(140,110,180),
                    far=lambda: pillars(51,(34,24,52),24),
                    near=lambda: pillars(57,(20,14,32),0)),
    "factory": dict(sky=((16,10,6),(42,26,14)), star=(160,110,60),
                    far=lambda: factory(61,(40,28,16),24,(255,150,40)),
                    near=lambda: factory(67,(24,16,10),0,(255,120,30))),
}

for name, th in THEMES.items():
    d = os.path.join(A, name); os.makedirs(d, exist_ok=True)
    sky = grad(th["sky"][0], th["sky"][1]); stars(sky, th["star"], 50, hash(name) & 0xffff)
    sky.save(os.path.join(d, "sky.png"))
    th["far"]().save(os.path.join(d, "far.png"))
    th["near"]().save(os.path.join(d, "near.png"))
    print(f"[bg] {name}: sky/far/near")
print("=== 区域背景生成完成 ===")
