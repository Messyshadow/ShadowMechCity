"""Blender source for the Dawn Conservatory cast and living garden module."""
import sys
from pathlib import Path
import math

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_cast as cast

a = cast.a
original_humanoid = cast.humanoid


def humanoid(kind):
    original_humanoid({"warden": "sentry", "stalker": "hero", "surveyor": "merchant"}[kind])
    if kind == "warden":
        a.box("Tower shield", (-.5, -.18, 1.05), (.67, .22, 1.35), a.edge, "foreL", .09)
        a.box("Luminous shield slit", (-.5, -.31, 1.05), (.07, .035, 1.05), a.cyan, "foreL", .008)
        a.box("Shield cross brace", (-.5, -.32, 1.15), (.58, .04, .12), a.brass, "foreL", .015)
        for x in [-.23, .23]:cast.cone("Guard crest", (x, .04, 2.24), .095, .45, a.brass, "head")
    elif kind == "stalker":
        for side, sign in [("L", -1), ("R", 1)]:
            a.box("Retractable wrist blade", (.40 * sign, -.18, .60), (.08, .13, .68), a.violet, "fore"+side, .018)
            cast.cone("Shoulder spur", (.46 * sign, .03, 1.86), .10, .5, a.edge, "arm"+side)
        a.box("Charged spine pack", (0, .36, 1.30), (.38, .25, .68), a.violet, "torso", .07)
    elif kind == "surveyor":
        a.cyl("Survey antenna", (.28, .39, 2.15), .025, .80, a.edge, "torso")
        a.sphere("Antenna lamp", (.28, .39, 2.60), (.08, .08, .08), a.cyan, "torso")
        a.box("Route chart case", (-.48, -.19, .95), (.33, .18, .35), a.cyan, "foreL", .035)
        a.cyl("Lantern housing", (.43, -.09, .57), .15, .31, a.brass, "foreR")
        a.cyl("Lantern glow", (.43, -.09, .59), .11, .23, a.cyan, "foreR")


cast.humanoid = humanoid
for role in ["warden", "stalker", "surveyor"]:
    cast.build(role)

a.begin()
leaf = a.material("Conservatory sage foliage", (.16, .32, .17), .05, .8)
stem = a.material("Conservatory stems", (.14, .22, .085), .1, .8)
a.box("Raised iron planter", (0, 0, .34), (2.1, 1.15, .68), a.edge, bevel=.09)
a.box("Planter soil", (0, 0, .70), (1.92, 1.01, .07), a.dark, bevel=.02)
for i in range(5):
    x = -.8+i*.4
    cast.rod("Living stem", (x, 0, .7), (x+.1, 0, 1.85+(i%2)*.34), .036, stem, None)
    for j in range(3):
        z = .95+j*.32
        for sign in [-1, 1]:
            part = a.sphere("Sage leaf", (x+sign*.22, -.02, z), (.35, .11, .16), leaf)
            part.rotation_euler.y = sign*.42
a.export("garden_planter")
a.begin()
a.cyl("Lighthouse pedestal", (0,0,.26), .92, .52, a.edge, verts=16)
a.cyl("Fluted signal column", (0,0,2.12), .36, 3.75, a.steel, verts=12)
for z in [.62,1.9,3.65,4.15]:a.cyl("Brass collar", (0,0,z), .5, .15, a.brass, verts=16)
a.cyl("Signal chamber floor", (0,0,4.24), .9, .16, a.brass, verts=16)
for i in range(8):
    angle=i*math.tau/8
    a.cyl("Lantern cage strut", (math.cos(angle)*.73,math.sin(angle)*.73,4.78), .045, 1.12, a.edge)
a.cyl("Signal chamber roof", (0,0,5.37), .94, .15, a.brass, verts=16)
cast.cone("Beacon crown", (0,0,5.67), .9, .51, a.edge, None, tip=.12)
a.export("beacon_tower")
print("EXPERIENCE ASSETS COMPLETE", flush=True)
