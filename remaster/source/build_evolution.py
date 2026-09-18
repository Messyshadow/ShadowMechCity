"""Original Blender evolution silhouettes and temporary energy summons."""
import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
import build_assets as a

# Full-height accents use the hero model's origin, preserving its capsule and weapons.
a.begin()
for side in [-1,1]:
    for i in range(4):
        feather=a.box('Void mantle blade',(side*(.47+i*.14),.28+i*.19,1.5-i*.18),(.15,.15,.76-i*.06),a.dark,bevel=.04)
        feather.rotation_euler.y=side*(-.4-i*.11)
        vein=a.box('Violet mantle vein',(side*(.47+i*.14),.19+i*.19,1.5-i*.18),(.04,.035,.62-i*.06),a.violet,bevel=.01)
        vein.rotation_euler.y=feather.rotation_euler.y
a.torus('Night halo',(0,.15,1.91),.38,.035,a.violet,axis='Y')
a.sphere('Void heart',(0,-.39,1.29),(.12,.055,.12),a.violet)
a.export('evolution_shadow')

a.begin()
for side in [-1,1]:
    a.box('Exoframe shoulder',(side*.5,.05,1.60),(.46,.59,.32),a.edge,bevel=.07)
    for z in [1.52,1.64]:a.box('Cooling slit',(side*.5,-.255,z),(.3,.025,.035),a.orange,bevel=.008)
    a.cyl('Back thruster',(side*.29,.44,1.25),.13,.65,a.dark)
    a.torus('Thruster band',(side*.29,.44,1.19),.14,.035,a.orange)
a.box('Heavy chest shield',(0,-.32,1.22),(.58,.12,.49),a.brass,bevel=.055)
a.cyl('Core lens',(0,-.41,1.29),.19,.045,a.orange,axis='Y')
a.export('evolution_mechanical')

a.begin()
a.sphere('Spirit core',(0,0,.1),(.25,.18,.32),a.violet)
a.box('Wraith mask',(0,-.17,.27),(.39,.12,.29),a.dark,bevel=.06)
for x in [-.09,.09]:a.box('Wraith eye',(x,-.24,.3),(.065,.025,.03),a.violet,bevel=.006)
for side in [-1,1]:
    arm=a.box('Spectral scythe',(side*.4,0,-.02),(.09,.12,.70),a.edge,bevel=.025)
    arm.rotation_euler.y=side*.5
    a.box('Energy claw',(side*.51,-.03,-.25),(.09,.08,.27),a.violet,bevel=.01)
for i in range(3):
    tail=a.box('Tattered shadow',(i*.14-.14,.05,-.36),(.1,.05,.4),a.dark,bevel=.02)
    tail.rotation_euler.y=(i-1)*.2
a.torus('Spectral orbit',(0,.04,.1),.43,.025,a.violet,axis='Y')
a.export('summon_shadow')

a.begin()
a.sphere('Armored drone hull',(0,0,0),(.38,.3,.22),a.edge)
a.box('Drone face',(0,-.27,.02),(.33,.09,.15),a.dark,bevel=.03)
a.box('Amber sensor',(0,-.32,.035),(.2,.025,.05),a.orange,bevel=.01)
for side in [-1,1]:
    a.cyl('Floating turbine',(side*.48,0,.02),.22,.12,a.dark)
    a.torus('Engine field',(side*.48,0,.04),.23,.035,a.orange)
    a.cyl('Pulse barrel',(side*.2,-.36,-.13),.065,.47,a.brass,axis='Y')
    a.cyl('Pulse muzzle',(side*.2,-.605,-.13),.045,.025,a.orange,axis='Y')
a.export('summon_mechanical')
