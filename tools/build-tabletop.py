"""Gera mesa importável, tabuleiro legível e pacote público. Python + Pillow."""
from pathlib import Path
import hashlib
import json
import textwrap
import zipfile
import sys
import math
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tabletop'))
from assets import generate as generate_cards
OUT = ROOT / 'build' / 'tabletop'
OUT.mkdir(parents=True, exist_ok=True)
spaces = json.loads((ROOT / 'docs/tabuleiro-referencia.json').read_text(encoding='utf-8-sig'))['casas']
assert len(spaces) == 40
S, C = 3600, 540
W = (S - 2*C)/9
FONT = Path('C:/Windows/Fonts/segoeuib.ttf')
def font(size): return ImageFont.truetype(str(FONT), size)
img = Image.new('RGB', (S,S), '#10273b')
draw = ImageDraw.Draw(img)
draw.rounded_rectangle((585,585,3015,3015), radius=105, fill='#17374f', outline='#42647b', width=5)
def center(text,y,size,color='#ffffff'):
    draw.text((S/2,y*1.5),text,font=font(round(size*1.5)),fill=color,anchor='mm')
center('COMPANION',800,110)
center('BANCO IMOBILIÁRIO',925,76)
center('40 casas · dados e peões',1040,40,'#bed6e8')
center('Dinheiro, posses e prisão no aplicativo',1760,34,'#bed6e8')
center('100 Notícias originais · títulos de posse',1820,30,'#bed6e8')
center('INÍCIO: +R$ 2.000 por volta',1890,30,'#7ae5b0')
colors = {2:'#19945a',3:'#19945a',5:'#19945a',6:'#cf424d',8:'#cf424d',10:'#cf424d',13:'#2985ba',14:'#2985ba',16:'#2985ba',18:'#d44b9b',19:'#d44b9b',20:'#8051b0',22:'#8051b0',26:'#19945a',27:'#19945a',29:'#19945a',32:'#e47727',34:'#e47727',35:'#e47727',36:'#d7ac28',38:'#d7ac28',40:'#d7ac28'}
world=[]
for idx,s in enumerate(spaces):
    side,k=divmod(idx,10)
    corner=k==0
    width=C if corner else round(W)
    tile=Image.new('RGB',(width,C),'#167eae')
    d=ImageDraw.Draw(tile)
    col=colors.get(idx+1,'#335b73')
    name=s['nome']
    if corner: name={'inicio':'INÍCIO ←','prisao':'PRISÃO / VISITANTE','feriado':'FERIADO','ir_prisao':'VÁ PARA A PRISÃO'}[s['tipo']]
    is_property=s['tipo']=='propriedade'
    lines=textwrap.wrap(name,width=19 if corner else 14,break_long_words=False)
    fs=42 if corner else 29
    header=200 if is_property else 240
    d.rectangle((0,0,width-1,header),fill=col)
    for j,line in enumerate(lines): d.text((width/2,28+j*(fs+7)),line,font=font(fs),fill='white',anchor='mt')
    d.text((18,header+15),f'{idx+1:02}',font=font(22),fill='#ceeaf7')
    if is_property:
        # Edifícios vetoriais simples na área azul, como a disposição do tabuleiro físico.
        for b in range(3):
            bx=35+b*(width-65)/3; bw=(width-85)/3; top=290+(b%2)*25
            d.rectangle((bx,top,bx+bw,450),fill='#d4e5ee',outline='#53778e',width=3)
            for yy in range(top+12,440,24):
                for xx in range(round(bx+9),round(bx+bw-5),16): d.rectangle((xx,yy,xx+7,yy+12),fill='#4b7892')
    elif s['tipo']=='noticias':
        d.rounded_rectangle((width*.17,285,width*.83,435),radius=10,fill='#f4eac7',outline='#bfa663',width=4)
        d.text((width/2,320),'NOTÍCIAS',font=font(25),fill='#6c572a',anchor='mm')
        for yy in range(350,420,17): d.line((width*.24,yy,width*.76,yy),fill='#bfa663',width=3)
    elif corner:
        d.ellipse((width/2-60,295,width/2+60,415),outline='#e9d78b',width=9)
        d.text((width/2,355),{ 'inicio':'←','prisao':'11','feriado':'☀','ir_prisao':'→'}[s['tipo']],font=font(56),fill='white',anchor='mm')
    else:
        d.ellipse((width/2-55,310,width/2+55,420),fill='#dcebf0',outline='#bdd9e7',width=4)
        d.text((width/2,365),'$' if s['tipo']=='acoes' else ('+' if s['tipo']=='receber_banco' else '−'),font=font(65),fill='#1c5370',anchor='mm')
    value=s['valor_indicado']
    if value is not None:
        amount='R$ '+f'{abs(value):,}'.replace(',','.')
        if s['tipo']=='receber_banco': amount='+ '+amount
        elif s['tipo']=='pagar_banco': amount='− '+amount
        elif s['tipo']=='inicio': amount='+ '+amount
        d.rectangle((0,465,width-1,C-1),fill=col)
        d.text((width/2,502),amount,font=font(39),fill='white',anchor='mm')
    d.rectangle((0,0,width-1,C-1),outline='#17374f',width=3)
    if side==0:
        x=S-C if corner else round(S-C-k*W); y=S-C; angle=0
    elif side==1:
        x=0; y=S-C if corner else round(S-C-k*W); angle=270
    elif side==2:
        x=0 if corner else round(C+(k-1)*W); y=0; angle=180
    else:
        x=S-C; y=0 if corner else round(C+(k-1)*W); angle=90
    tile=tile.rotate(angle,expand=True)
    img.paste(tile,(x,y))
    px,py=x+tile.width/2,y+tile.height/2
    world.append(dict(x=round((px/S-.5)*40,5),z=round((.5-py/S)*40,5),name=s['nome'],kind=s['tipo'],price=s['valor_indicado'] or 0))
image_bytes_path=OUT/'tabuleiro.png'
img.save(image_bytes_path)
tag=hashlib.sha256(image_bytes_path.read_bytes()).hexdigest()[:12]
image_name=f'tabuleiro-{tag}.png'
image_bytes_path.replace(OUT/image_name)
# O importador OBJ do TTS espelha X. U invertido corrige o texto mostrado no print.
mesh='''o CompanionBoard
v -20 0 -20
v 20 0 -20
v 20 0 20
v -20 0 20
v -20 0.3 -20
v 20 0.3 -20
v 20 0.3 20
v -20 0.3 20
vt 1 0
vt 0 0
vt 0 1
vt 1 1
f 5/1 8/4 7/3 6/2
f 1/1 2/2 3/3 4/4
f 1/1 5/1 6/2 2/2
f 2/2 6/2 7/3 3/3
f 3/3 7/3 8/4 4/4
f 4/4 8/4 5/1 1/1
'''
mesh_name='tabuleiro-'+hashlib.sha256(mesh.encode()).hexdigest()[:12]+'.obj'
(OUT/mesh_name).write_text(mesh,encoding='utf-8')
# Peões próprios: malha branca recebe exatamente o tint de cada jogador.
pawn_vertices=[]; pawn_faces=[]
rings=[(0,.42),(.1,.5),(.25,.5),(.4,.33),(1,.18),(1.2,.27),(1.4,.36),(1.6,.29),(1.8,.01)]
for y,radius in rings:
    for segment in range(24):
        a=2*math.pi*segment/24
        pawn_vertices.append(f'v {radius*math.cos(a):.6f} {y:.6f} {radius*math.sin(a):.6f}')
for ring in range(len(rings)-1):
    for segment in range(24):
        a=ring*24+segment+1; b=ring*24+(segment+1)%24+1; c=a+24; d=b+24
        pawn_faces.extend([f'f {a} {c} {d}',f'f {a} {d} {b}'])
for segment in range(1,23):
    pawn_faces.append(f'f 1 {segment+1} {segment+2}')
    top=(len(rings)-1)*24+1
    pawn_faces.append(f'f {top} {top+segment+1} {top+segment}')
pawn_faces=['f '+' '.join(v+'/1' for v in face.split()[1:]) for face in pawn_faces]
pawn_mesh='o CompanionPawn\n'+'\n'.join(pawn_vertices+['vt 0.5 0.5']+pawn_faces)+'\n'
pawn_mesh_name='peao-'+hashlib.sha256(pawn_mesh.encode()).hexdigest()[:12]+'.obj'
(OUT/pawn_mesh_name).write_text(pawn_mesh,encoding='utf-8')
Image.new('RGB',(32,32),'white').save(OUT/'peao-branco.png')
palette={'White':(0.95,0.95,0.95),'Red':(.9,.15,.2),'Blue':(.15,.4,.95),'Green':(.1,.7,.3),'Yellow':(.95,.8,.1),'Orange':(1,.4,.1),'Purple':(.65,.25,.9),'Pink':(1,.4,.7)}
offsets={name:dict(x=(i%4-1.5)*.65,z=(i//4-.5)*.9) for i,name in enumerate(palette)}
def lua(v):
    if isinstance(v,str): return json.dumps(v,ensure_ascii=False)
    if isinstance(v,dict): return '{'+','.join('['+lua(k)+']='+lua(val) for k,val in v.items())+'}'
    if isinstance(v,list): return '{'+','.join(lua(val) for val in v)+'}'
    return str(v)
def obj(name,guid,x,y,z,scale=1,color=(1,1,1),nick=''):
    return dict(Name=name,GUID=guid,Nickname=nick,Transform=dict(posX=x,posY=y,posZ=z,rotX=0,rotY=0,rotZ=0,scaleX=scale,scaleY=scale,scaleZ=scale),ColorDiffuse=dict(zip(('r','g','b','a'),[*color,1])),Locked=False,Grid=False,Snap=True,Autoraise=True,Sticky=False,Tooltip=True,Hands=False)
base='https://igorgabrielserrano.github.io/COMPANION_BANCO_IMOBILIARIO/tabletop/'
board=obj('Custom_Model','bb0001',0,1,0,nick='Tabuleiro Companion — 40 casas')
board.update(Locked=True,CustomMesh=dict(MeshURL=base+mesh_name,DiffuseURL=base+image_name,NormalURL='',ColliderURL='',Convex=True,MaterialIndex=3,TypeIndex=4,CastShadows=True))
objects=[board]
for i,(name,color) in enumerate(palette.items()):
    off=offsets[name]
    pawn=obj('Custom_Model',f'aa{i+1:04}',world[0]['x']+off['x'],2,world[0]['z']+off['z'],.75,color,f'Peão {name}')
    pawn['CustomMesh']=dict(MeshURL=base+pawn_mesh_name,DiffuseURL=base+'peao-branco.png',NormalURL='',ColliderURL='',Convex=True,MaterialIndex=0,TypeIndex=1,CastShadows=True)
    objects.append(pawn)
for i in range(2): objects.append(obj('Die_6',f'dd{i+1:04}',-2+i*4,2,5,.9,nick=f'Dado {i+1}'))
decks,news,card_files=generate_cards(OUT,base,spaces,colors,obj)
objects.extend(decks)
# Áreas físicas de posse cabem nas laterais da mesa RPG, fora do tabuleiro.
area_positions=[(-25,-13.5),(-25,-4.5),(-25,4.5),(-25,13.5),(25,-13.5),(25,-4.5),(25,4.5),(25,13.5)]
area_mesh=mesh.replace('-20','-4.5').replace('20','4.5').replace('0.3','0.08')
area_mesh_lines=[]
for line in area_mesh.splitlines():
    if line.startswith('v '):
        fields=line.split(); fields[3]=str(float(fields[3])*4.1/4.5); line=' '.join(fields)
    area_mesh_lines.append(line)
area_mesh='\n'.join(area_mesh_lines)+'\n'
area_mesh_name='area-posses-'+hashlib.sha256(area_mesh.encode()).hexdigest()[:12]+'.obj'
(OUT/area_mesh_name).write_text(area_mesh,encoding='utf-8')
area_image=Image.new('RGB',(900,820),'#ffffff')
area_draw=ImageDraw.Draw(area_image)
area_draw.rounded_rectangle((12,12,888,808),radius=30,outline='#a5a5a5',width=8)
area_draw.line((30,175,870,175),fill='#aaaaaa',width=4)
for column in range(3):
    for row in range(2):
        x=40+column*280; y=205+row*290
        area_draw.rounded_rectangle((x,y,x+255,y+265),radius=12,outline='#bdbdbd',width=3)
area_image_name='area-posses.png'
area_image.save(OUT/area_image_name)
areas={}
for i,(name,color) in enumerate(palette.items()):
    x,z=area_positions[i]
    areas[name]=dict(guid=f'ac{i+1:04}',x=x,z=z)
    area=obj('Custom_Model',f'ac{i+1:04}',x,1,z,color=color,nick='Área de posses '+name)
    area.update(Locked=True,Description='Cartas deste jogador. O host controla todas as áreas no single player.',CustomMesh=dict(MeshURL=base+area_mesh_name,DiffuseURL=base+area_image_name,NormalURL='',ColliderURL='',Convex=True,MaterialIndex=3,TypeIndex=4,CastShadows=True))
    objects.append(area)
hand_positions=[(-12,-24,0),(12,-24,0),(-24,-12,90),(-24,12,90),(-12,24,180),(12,24,180),(24,12,270),(24,-12,270)]
for i,(name,color) in enumerate(palette.items()):
    x,z,angle=hand_positions[i]
    hand=obj('HandTrigger',f'ab{i+1:04}',x,3,z,color=color,nick='Área de posses '+name)
    hand.update(FogColor=name,Locked=True,Tooltip=False)
    hand['Transform'].update(rotY=angle,scaleX=10,scaleY=6,scaleZ=4)
    objects.append(hand)
script='SPACES='+lua(world)+'\nOFFSETS='+lua(offsets)+'\nNEWS='+lua(news)+'\nAREAS='+lua(areas)+'\n'+(ROOT/'tabletop/mesa.lua').read_text(encoding='utf-8')
save=dict(SaveName='Companion Banco Imobiliário — Mesa v2',GameMode='',Table='Table_RPG',Sky='Sky_Downtown',Note='Configure os jogadores no painel inicial. Pagamentos e prisão no Companion. Notícias originais, não oficiais.',Rules='40 casas conforme referência confirmada por Igor. 100 Notícias originais para regras de mesa. Aluguéis, construção e hipoteca dos títulos aguardam confirmação. Sem sincronização automática com o banco.',LuaScript=script,LuaScriptState='',ObjectStates=objects,SnapPoints=[dict(Position=dict(x=p['x'],y=1.3,z=p['z'])) for p in world],Hands=dict(Enable=True,DisableUnused=False,Hiding=0),Turns=dict(Enable=False,Type=0,TurnOrder=[],Reverse=False,SkipEmpty=True,DisableInteractions=False,PassTurns=True),Grid=dict(Type=0,Lines=False,Snapping=False,Offset=False,xSize=2,ySize=2),TabStates={'0':dict(title='Como jogar',body='Use o Companion: '+base.replace('tabletop/','')+'\nO anfitrião escolhe a quantidade e os nomes no painel inicial. Cada jogador deve sentar na cor do seu peão.\nO painel mostra a soma e avisa dados iguais. Rolar > Avançar ou Passar vez.\nNotícias: comprar no botão, seguir a carta e registrar valores no Companion.\nTítulos: Comprar posse retira a carta da casa atual e registra o dono no Tabletop. Registre também no Companion. Aluguéis a definir.\nLayout: ajuste X/Y, largura, altura e fonte de cada botão/painel. Salve a partida para manter os ajustes.\nPrisão e terceiro par: marcar no Companion e mover manualmente para casa 11.',visibleColor=dict(r=1,g=1,b=1),id=0)})
(OUT/'Companion-Tabuleiro.json').write_text(json.dumps(save,ensure_ascii=False,indent=2),encoding='utf-8')
img.resize((600,600)).save(OUT/'Companion-Tabuleiro.png')
(OUT/'index.html').write_text('''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Companion — mesa para Tabletop Simulator</title><style>body{margin:0;background:#10273b;color:#edf4f8;font:17px/1.6 system-ui}main{max-width:760px;margin:auto;padding:24px}h1{line-height:1.2}a{color:#86e6c0}img{width:100%;height:auto;border-radius:14px}.download{display:inline-block;padding:12px 20px;border-radius:10px;background:#7ae5b0;color:#10273b;font-weight:700}code{overflow-wrap:anywhere}</style><main><h1>Companion no Tabletop Simulator</h1><p>40 casas, até oito jogadores com peões nomeados, dois dados, 100 Notícias originais e 28 títulos de posse. A parte bancária continua no Companion.</p><p><a class="download" href="Companion-Tabletop.zip">Baixar mesa para Tabletop</a></p><img src="Companion-Tabuleiro.png" alt="Tabuleiro com 40 casas e grupos de propriedades coloridos"><h2>Como abrir</h2><ol><li>Extraia o ZIP.</li><li>Copie <code>Companion-Tabuleiro.json</code> e <code>Companion-Tabuleiro.png</code> para <code>Documentos/My Games/Tabletop Simulator/Saves</code>.</li><li>No Tabletop, abra Games → Save &amp; Load e escolha Companion Banco Imobiliário — Mesa v2.</li><li>Configure a quantidade e os nomes antes de iniciar. Cada jogador escolhe a cor do seu peão. O painel mostra a soma dos dados e avisa quando saem números iguais.</li></ol><p>Para multiplayer, crie uma sala e convide seus amigos no Tabletop. É necessária conexão para carregar o tabuleiro. Turnos, duplas, prisão e pagamentos são controlados pelos jogadores e registrados no aplicativo. O painel mostra a casa atual, preço e dono. Comprar posse retira o título do banco. Layout permite ajustar tamanho e posição dos botões. Registre o pagamento no Companion. Áreas físicas com nomes e cores funcionam sem jogadores conectados. Botão direito → Visualizar carta centraliza a câmera; Visão de cima retorna. Notícias são apresentadas automaticamente. Aluguéis, construção e hipoteca aguardam os valores oficiais.</p><h2>Novidades da mesa v2</h2><p>Layout azul e faixas coloridas como a referência, texto maior, correção do espelhamento, configuração de jogadores e painel de dados.</p><img src="cartas-preview.png" alt="Duas Notícias originais e um título de posse"><p>A importação, física e orientação corrigida ainda precisam de validação dentro do Tabletop. A mesa não sincroniza automaticamente o dinheiro com o aplicativo.</p><p><a href="../">Abrir o Companion bancário</a> · <a href="https://github.com/IgorGabrielSerrano/COMPANION_BANCO_IMOBILIARIO/blob/main/tabletop/README.md">Instruções completas</a></p></main></html>''',encoding='utf-8')
with zipfile.ZipFile(OUT/'Companion-Tabletop.zip','w',zipfile.ZIP_DEFLATED) as z:
    for f in ['Companion-Tabuleiro.json','Companion-Tabuleiro.png',image_name,mesh_name,pawn_mesh_name,'peao-branco.png',area_mesh_name,area_image_name]+card_files:
        z.write(OUT/f,f)
    z.write(ROOT/'tabletop/README.md','LEIA-ME.md')
print('Gerado:',OUT)
