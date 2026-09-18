"""Deterministic original layered mechanical Foley. Python standard library only."""
import math, random, wave, struct, os
random.seed(815)
ROOT=os.path.join(os.path.dirname(os.path.dirname(__file__)),'assets','audio')
os.makedirs(ROOT,exist_ok=True)
RATE=44100
def write(name,duration,fn):
    data=[]; low=0.0
    for i in range(int(duration*RATE)):
        t=i/RATE; n=random.uniform(-1,1); low=low*.93+n*.07
        data.append(fn(t,n,low))
    peak=max(.01,max(abs(x) for x in data)); amp=.78/peak
    with wave.open(os.path.join(ROOT,name+'.wav'),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,v*amp))*32767)) for v in data))
sin=lambda hz,t:math.sin(math.tau*hz*t)
write('jump',.32,lambda t,n,l:(sin(200+t*700,t)*.4+n*.15)*math.exp(-t*14))
write('wall_jump',.4,lambda t,n,l:(sin(470-t*500,t)*.3+n*.4)*math.exp(-t*17))
write('land',.25,lambda t,n,l:(sin(75,t)*.5+l*2+n*.15)*math.exp(-t*25))
write('step',.11,lambda t,n,l:(sin(135,t)*.4+n*.45)*math.exp(-t*48))
write('climb',.18,lambda t,n,l:(sin(760,t)*.12+sin(350,t)*.12+n*.25)*math.exp(-t*32))
write('slash',.24,lambda t,n,l:(n-l)*math.sin(math.pi*t/.24)**2*math.exp(-t*6))
write('hit',.32,lambda t,n,l:(sin(130,t)*.6+sin(743,t)*.24+n*.48)*math.exp(-t*24))
write('hurt',.42,lambda t,n,l:(sin(95-t*90,t)*.5+sin(151,t)*.2+l*1.2+n*.3)*math.exp(-t*13))
write('punch',.22,lambda t,n,l:(sin(65,t)*.8+l*2+n*.15)*math.exp(-t*23))
write('shot',.44,lambda t,n,l:(sin(120-t*130,t)*.6+n*.6+sin(1300,t)*.1)*math.exp(-t*20))
write('empty',.12,lambda t,n,l:(sin(1400,t)+n)*math.exp(-t*60))
write('reload',.7,lambda t,n,l:(n*.4+sin(850,t)*.15)*(math.exp(-t*45)+math.exp(-abs(t-.36)*65)+math.exp(-abs(t-.6)*50)))
write('explosion',1.3,lambda t,n,l:(l*3+sin(42-t*12,t)*.4+n*.28)*math.exp(-t*4.5))
write('splash',.8,lambda t,n,l:(n*.22+l*2+sin(400-t*230,t)*.13)*math.exp(-t*6))
write('dash',.28,lambda t,n,l:(n*.26+sin(180+t*500,t)*.2)*math.sin(math.pi*t/.28))
write('save',1.1,lambda t,n,l:sum(sin(f,t)*.2*math.exp(-max(0,t-j*.12)*4) if t>=j*.12 else 0 for j,f in enumerate([440,550,660,880])))
write('warning',.65,lambda t,n,l:(sin(240,t)+sin(245,t))*.3*math.sin(math.pi*t/.65))
write('gear',4,lambda t,n,l:(sin(67,t)*.15+sin(134,t)*.06+l*.3)*(0.7+.3*sin(3,t)))
write('lift',3,lambda t,n,l:(sin(93,t)*.2+sin(186,t)*.12+l*.6)*(.7+.3*sin(1,t)))
write('ambience',8,lambda t,n,l:(sin(41.25,t)*.14+sin(55,t)*.08+sin(82.5,t)*.04+l*.14)*(.8+.2*math.cos(math.tau*t/8)))
print('Built 20 original audio clips')
