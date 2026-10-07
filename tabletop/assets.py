"""Cartas de Notícias e títulos: renderização determinística e metadados TTS."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont
from noticias import EVENTS

FONT=Path('C:/Windows/Fonts/segoeuib.ttf')
def f(size): return ImageFont.truetype(str(FONT),size)
def wrapped(d,text,y,size=25,width=340,color='#15364c'):
    words=text.split(); lines=[]; line=''
    for word in words:
        candidate=(line+' '+word).strip()
        if line and d.textlength(candidate,font=f(size))>width: lines.append(line); line=word
        else: line=candidate
    if line: lines.append(line)
    for line in lines:
        d.text((200,y),line,font=f(size),fill=color,anchor='mt'); y+=size+8
    return y

def generate(out,base,spaces,colors,obj):
    files=[]
    def asset(im,prefix):
        from io import BytesIO
        b=BytesIO(); im.save(b,format='PNG'); blob=b.getvalue()
        name=prefix+'-'+hashlib.sha256(blob).hexdigest()[:12]+'.png'
        (out/name).write_bytes(blob); files.append(name); return base+name
    def back(title,color):
        im=Image.new('RGB',(400,600),color); d=ImageDraw.Draw(im)
        d.rounded_rectangle((20,20,380,580),radius=26,outline='#ffffff',width=4)
        wrapped(d,title,210,40,color='white'); wrapped(d,'COMPANION',380,24,color='white')
        return im
    newsback=asset(back('NOTÍCIAS','#c5a347'),'noticias-verso')
    titleback=asset(back('TÍTULO DE POSSE','#17374f'),'titulos-verso')
    news=[]; faces=[]
    for i,(title,text,amount) in enumerate(EVENTS):
        news.append(dict(id=i+1,guid=f'cc{i+1:04}',title=title,text=text,amount=amount))
        im=Image.new('RGB',(400,600),'#f8f3e5'); d=ImageDraw.Draw(im)
        d.rectangle((0,0,400,68),fill='#a6812b')
        d.text((200,34),f'NOTÍCIAS · {i+1:03}',font=f(26),fill='white',anchor='mm')
        y=wrapped(d,title,95,32)
        wrapped(d,text,y+25,25)
        wrapped(d,('Receba R$ ' if amount>0 else 'Pague R$ ')+f'{abs(amount):,}'.replace(',','.'),390,32,color='#14724c' if amount>0 else '#a43b3b')
        wrapped(d,'do banco' if amount>0 else 'ao banco',437,24)
        wrapped(d,'Registre no Companion.',487,21)
        wrapped(d,'Carta original · regra de mesa',556,16)
        faces.append(im)
    definitions={}
    for group in range(2):
        sheet=Image.new('RGB',(4000,4200),'#f8f3e5')
        for i,face in enumerate(faces[group*50:(group+1)*50]): sheet.paste(face,((i%10)*400,(i//10)*600))
        sheet.paste(back('NOTÍCIAS','#c5a347'),(3600,3600))
        definitions[str(group+2)]=dict(FaceURL=asset(sheet,f'noticias-frente-{group+1}'),BackURL=newsback,NumWidth=10,NumHeight=7,BackIsHidden=True,UniqueBack=False)
    newsCards=[]
    for i,n in enumerate(news):
        key=2+i//50; cardId=key*100+i%50
        card=obj('Card',n['guid'],0,0,0,nick=n['title'])
        card.update(CardID=cardId,Hands=True,GMNotes=f"companion_news:{n['id']}",Description=n['text']+'\n'+('Receba ' if n['amount']>0 else 'Pague ')+str(abs(n['amount']))+' no Companion. Carta original, não oficial.',CustomDeck={str(key):definitions[str(key)]})
        newsCards.append(card)
    deck=obj('DeckCustom','ee0001',-8,1.7,3,nick='Notícias — 100 cartas originais')
    deck['Transform']['rotZ']=180
    deck.update(DeckIDs=[c['CardID'] for c in newsCards],ContainedObjects=newsCards,CustomDeck=definitions,GMNotes='companion_news_deck',Description='Embaralhe e compre uma carta. Pagamentos registrados no Companion.')
    titleFaces=[]; titleCards=[]
    for s in spaces:
        if s['tipo'] not in ('propriedade','acoes'): continue
        col=colors.get(s['numero'],'#335b73')
        im=Image.new('RGB',(400,600),'#f2f6f8'); d=ImageDraw.Draw(im)
        d.rectangle((0,0,400,65),fill='#17374f'); d.text((200,33),'TÍTULO DE POSSE',font=f(25),fill='white',anchor='mm')
        d.rectangle((0,65,400,225),fill=col); wrapped(d,s['nome'],85,31,color='white')
        wrapped(d,'Compra: R$ '+f"{s['valor_indicado']:,}".replace(',','.'),255,30)
        wrapped(d,'Aluguel: a definir',325,25)
        wrapped(d,'Casas / hotel: a definir' if s['tipo']=='propriedade' else 'Regra de rendimento: a definir',375,24)
        wrapped(d,'Hipoteca: a definir',435,24)
        wrapped(d,'Guarde na sua mão após registrar a compra no Companion.',498,19)
        titleFaces.append(im)
        card=obj('Card',f'ff{s["numero"]:04}',0,0,0,nick=s['nome'])
        card.update(Hands=True,CardID=100+len(titleCards),GMNotes=f'companion_title:{s["numero"]}',Description=f"Preço de compra: R$ {s['valor_indicado']}. Aluguéis, construção e hipoteca aguardam os títulos oficiais. Registre a posse no Companion.",LuaScript='function onLoad() self.addContextMenuItem("Guardar na minha mão", function(color) if Global.call("canReceiveTitle",{color=color}) then self.deal(1,color) else printToColor("Escolha uma cor ativa e inicie a mesa.",color) end end) end')
        titleCards.append(card)
    sheet=Image.new('RGB',(4000,1800),'#f2f6f8')
    for i,im in enumerate(titleFaces): sheet.paste(im,((i%10)*400,(i//10)*600))
    sheet.paste(back('TÍTULOS','#17374f'),(3600,1200))
    titleDef={'1':dict(FaceURL=asset(sheet,'titulos-frente'),BackURL=titleback,NumWidth=10,NumHeight=3,BackIsHidden=False,UniqueBack=False)}
    for card in titleCards: card['CustomDeck']=titleDef
    titleDeck=obj('DeckCustom','ee0002',8,1.7,3,nick=f'Títulos de posse — {len(titleCards)} cartas')
    titleDeck.update(DeckIDs=[c['CardID'] for c in titleCards],ContainedObjects=titleCards,CustomDeck=titleDef,Description='Botão direito → Search: escolha pelo nome. Retire o título e guarde na mão da sua cor após registrar a compra no Companion.')
    (out/'noticias.json').write_text(json.dumps(news,ensure_ascii=False,indent=2),encoding='utf-8'); files.append('noticias.json')
    # Amostra para revisão visual, sem precisar abrir uma folha de atlas inteira.
    preview=Image.new('RGB',(1200,600),'white')
    preview.paste(faces[0],(0,0)); preview.paste(faces[50],(400,0)); preview.paste(titleFaces[0],(800,0))
    preview.save(out/'cartas-preview.png'); files.append('cartas-preview.png')
    return [deck,titleDeck],news,files
