from PIL import Image,ImageDraw
from pathlib import Path
im=Image.new('RGB',(720,660),'#334155');d=ImageDraw.Draw(im)
for i in range(132):
 t=Image.open(f'assets/kenney-dungeon/Tiles/tile_{i:04}.png').convert('RGBA').resize((40,40),Image.Resampling.NEAREST)
 x=(i%12)*60;y=(i//12)*60
 im.paste(t,(x+10,y),t);d.text((x+20,y+41),str(i),fill='white')
im.save('.test-data/contact.png')

