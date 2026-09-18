"""Original Blender meshes for expedition rewards and destructible seals."""
import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
import build_assets as a
life=a.material('Crimson life core',(.9,.025,.08),.2,.3,1.0)
green=a.material('Supply mint',(.07,.7,.3),.2,.3,1.0)

def chest(name, supply=False):
    a.begin()
    a.box('Riveted case',(0,0,0), (1.05,.65,.6),a.steel,bevel=.06)
    a.box('Hinged lid',(0,0,.34),(1.12,.71,.16),a.brass,bevel=.04)
    for x in [-.4,.4]:
        a.box('Reinforcement strap',(x,0,.03),(.09,.7,.68),a.edge,bevel=.01)
        for z in [-.2,.3]:a.sphere('Rivet',(x,-.365,z),(.035,.018,.035),a.brass)
    a.box('Lock',(0,-.385,.1),(.19,.08,.22),green if supply else a.orange)
    if supply:
        for x in [-.22,0,.22]:a.cyl('Ammo tubes',(x,0,.58),.085,.34,a.brass)
    a.export(name)

chest('loot_chest');chest('supply_crate',True)
a.begin()
a.sphere('Red crystal',(0,0,0),(.3,.18,.42),life)
for x in [-.18,.18]:a.sphere('Core lobes',(x,0,.25),(.25,.18,.23),life)
a.torus('Life containment ring',(0,0,0),.52,.055,a.brass,axis='Y')
a.export('life_shard')
a.begin()
a.sphere('Archive hologram',(0,0,0),(.25,.25,.38),a.violet)
for z in [-.4,.4]:a.cyl('Archive end cap',(0,0,z),.32,.12,a.edge)
for x in [-.32,.32]:a.box('Archive rail',(x,0,0),(.08,.1,.77),a.brass)
a.torus('Archive orbit',(0,0,0),.5,.025,a.violet)
a.export('memory_core')
a.begin()
a.box('Module cartridge',(0,0,0),(.63,.28,.7),a.edge)
a.box('Interface display',(0,-.16,.04),(.44,.03,.39),a.cyan)
for x in [-.21,-.07,.07,.21]:a.box('Gold connectors',(x,0,-.42),(.06,.14,.16),a.brass)
a.export('ability_module')
a.begin()
a.box('Frangible plate',(0,0,.76),(1.8,.22,1.9),a.brass)
for x in [-.82,.82]:a.box('Border rib',(x,-.16,.76),(.12,.13,1.95),a.edge)
for angle in [-.62,.62]:
    bar=a.box('Orange fracture line',(0,-.15,.78),(.08,.035,1.65),a.orange);bar.rotation_euler.y=angle
a.export('breakable_seal')
a.begin()
a.sphere('Pulse capsule',(0,0,0),(.16,.16,.20),a.dark)
a.torus('Fuse glow',(0,0,0),.165,.025,a.orange)
a.cyl('Fuse cap',(0,0,.2),.07,.10,a.brass)
a.export('pulse_bomb')
