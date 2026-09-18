"""Original looped score: seven exploration arrangements and one boss arrangement.
No samples or external recordings. Stereo PCM, 24 kHz, deterministic synthesis.
"""
import math, os, wave, array
RATE=24000
ROOT=os.path.join(os.path.dirname(os.path.dirname(__file__)),'assets','audio')
TAU=math.tau
SCORES={
    'city':(78,45,[0,7,10,7,3,7,12,10],.16),
    'temple':(66,43,[0,7,12,10,3,5,7,2],.09),
    'mine':(92,38,[0,0,7,0,3,0,5,2],.26),
    'water':(72,40,[0,7,3,10,12,10,7,5],.10),
    'factory':(108,38,[0,7,0,10,0,5,3,2],.31),
    'void':(84,42,[0,6,10,13,12,6,3,1],.17),
    'castle':(82,38,[0,7,12,10,8,7,3,2],.18),
    'boss':(132,38,[0,0,7,10,12,7,3,1],.40),
}

def hz(midi):return 440*2**((midi-69)/12)
def note(freq,t,damp=3):
    return (math.sin(TAU*freq*t)+.30*math.sin(TAU*freq*2*t)+.12*math.sin(TAU*freq*3*t))*math.exp(-t*damp)*(1-math.exp(-t*60))

os.makedirs(ROOT,exist_ok=True)
for name,(bpm,root,melody,drive) in SCORES.items():
    beat=60/bpm;duration=beat*16;n=round(duration*RATE)
    left=array.array('f',[0])*n;right=array.array('f',[0])*n
    # Write every voice additively with wrapped tails, for sample-continuous loops.
    def voice(start,length,fn,pan=0):
        offset=round(start*RATE)
        for j in range(round(length*RATE)):
            k=(offset+j)%n;v=fn(j/RATE)
            left[k]+=v*(.70-.22*pan);right[k]+=v*(.70+.22*pan)
    for b in range(16):
        degree=melody[(b//2)%8]
        voice(b*beat,beat*2.8,lambda t,f=hz(root+12+degree):note(f,t,3.3)*.19,math.sin(b*.9)*.7)
        if b%2==0:
            bass=hz(root+([0,0,3,5][b//4]))
            voice(b*beat,beat*2.4,lambda t,f=bass:note(f,t,1.8)*.25,-.2)
        # Mechanical percussion: low kick, inharmonic iron ticks and muted clanks.
        voice(b*beat,.22,lambda t:math.sin(TAU*(53*t-18*t*t))*math.exp(-t*27)*drive)
        voice((b+.5)*beat,.12,lambda t:(math.sin(TAU*2371*t)+math.sin(TAU*3917*t))*.055*math.exp(-t*55),.6 if b%2 else -.6)
        if b%4==2:
            voice(b*beat,.37,lambda t:(math.sin(TAU*173*t)+.4*math.sin(TAU*419*t))*math.exp(-t*18)*drive*.55,-.3)
    for chord in range(4):
        degree=[0,3,5,0][chord]
        for interval in [0,7,15]:
            voice(chord*beat*4,beat*5,lambda t,f=hz(root+degree+interval):note(f,t,.75)*.065,interval/15-.5)
    peak=max(max(map(abs,left)),max(map(abs,right)),.001);gain=.69/peak
    pcm=array.array('h')
    for l,r in zip(left,right):pcm.extend((round(l*gain*32767),round(r*gain*32767)))
    with wave.open(os.path.join(ROOT,'score_'+name+'.wav'),'wb') as f:
        f.setparams((2,2,RATE,n,'NONE','not compressed'));f.writeframes(pcm.tobytes())
    print('SCORE',name,n,'frames',flush=True)
