"""Testa o save e o script Lua com objetos simulados; não simula física Unity."""
from pathlib import Path
import json
import re
import xml.etree.ElementTree as ET
from lupa import LuaRuntime

root=Path(__file__).resolve().parents[1]
save=json.loads((root/'build/tabletop/Companion-Tabuleiro.json').read_text(encoding='utf-8'))
ref=json.loads((root/'docs/tabuleiro-referencia.json').read_text(encoding='utf-8-sig'))
assert len(ref['casas'])==len(save['SnapPoints'])==40
assert len({o['GUID'] for o in save['ObjectStates']})==21
all_cards=[c for o in save['ObjectStates'] for c in o.get('ContainedObjects',[])]
assert len(all_cards)==128
assert len({c['GUID'] for c in all_cards})==128
assert all(re.fullmatch('[a-f0-9]{6}',o['GUID']) for o in save['ObjectStates']+all_cards)
assert len([c for c in all_cards if c['GMNotes'].startswith('companion_news:')])==100
assert len([c for c in all_cards if c['GMNotes'].startswith('companion_title:')])==28
assert save['Hands']['Enable']
pawns=[o for o in save['ObjectStates'] if o['GUID'].startswith('aa')]
assert len(pawns)==8 and all(o['Name']=='Custom_Model' for o in pawns)
assert len({tuple(o['ColorDiffuse'].values()) for o in pawns})==8
assert all(o['ColorDiffuse']['a']==1 and o['CustomMesh']['MaterialIndex']==0 for o in pawns)
mesh=(root/'build/tabletop'/save['ObjectStates'][0]['CustomMesh']['MeshURL'].split('/')[-1]).read_text()
assert 'vt 1 0\nvt 0 0\nvt 0 1\nvt 1 1' in mesh
news=json.loads((root/'build/tabletop/noticias.json').read_text(encoding='utf-8'))
assert len(news)==100 and sum(n['amount'] for n in news)==0
assert ref['casas'][24]['nome']=='Notícias'
assert ref['casas'][23]['valor_indicado']==-2000
assert ref['casas'][16]['valor_indicado']==2000
assert ref['casas'][39]['nome']=='Av. Niemeyer'

lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
objects={} messages={} timers={} conditions={}
Global={}
Player=setmetatable({}, {__index=function() return {host=false} end})
Player.White={host=true,color='White'}
UI={setXml=function(xml) lastXml=xml end}
function getAllObjects() local a={} for _,o in pairs(objects) do table.insert(a,o) end return a end
function getObjectFromGUID(guid) return objects[guid] end
function broadcastToAll(text) table.insert(messages,text) end
function printToColor(text,color) table.insert(messages,color..': '..text) end
Wait={time=function(f) table.insert(timers,f) end,
 condition=function(done,test,timeout,fail) table.insert(conditions,{done=done,test=test,fail=fail}) end}
function flush()
 local queued=timers timers={}
 for _,f in ipairs(queued) do f() end
 local waiting=conditions conditions={}
 for _,c in ipairs(waiting) do if c.test() then c.done() else table.insert(conditions,c) end end
end
function fake(guid,x,z)
 local o={resting=true,value=1,moves=0,rolls=0,p={x=x,z=z},buttons={}}
 o.getPosition=function() return o.p end
 o.setPosition=function(p) o.p={x=p[1],z=p[3]} end
 o.setPositionSmooth=function(p) o.setPosition(p) o.moves=o.moves+1 end
 o.randomize=function() o.rolls=o.rolls+1 end
 o.getValue=function() return o.value end
 o.createButton=function(b) table.insert(o.buttons,b) end
 o.setName=function(n) o.name=n end
 o.setLock=function(v) o.locked=v end
 o.getGUID=function() return guid end
 o.getGMNotes=function() return o.notes or '' end
 o.shuffle=function() o.shuffled=true end
 objects[guid]=o return o
end
''')
for o in save['ObjectStates']:
    fake=lua.globals().fake(o['GUID'],o['Transform']['posX'],o['Transform']['posZ'])
    fake['notes']=o.get('GMNotes','')
def from_lua(v):
    if hasattr(v,'items'): return {k:from_lua(val) for k,val in v.items()}
    return v
lua.globals().JSON=lua.table_from({'encode':lambda v:json.dumps(from_lua(v)), 'decode':lambda v:lua.table_from(json.loads(v),recursive=True)})
lua.execute(save['LuaScript'])
lua.execute('''
onLoad()
assert(string.find(lastXml,'Jogadores e peões',1,true))
rollDice(nil,'Red') assert(objects.dd0001.rolls==0)
morePlayers({host=false})
editName({host=false},'Intruso','name_White')
startGame(Player.White) assert(not canReceiveTitle({color='White'}))
editName(Player.White,'Ana & Igor','name_White')
editName(Player.White,'Rui','name_Red')
morePlayers(Player.White)
editName(Player.White,'Rui','name_Blue')
startGame(Player.White) assert(not canReceiveTitle({color='Blue'}))
editName(Player.White,'Bia','name_Blue')
startGame(Player.White)
passTurn({color='Blue',host=false})
assert(string.find(lastXml,'VEZ DE Ana &amp; Igor',1,true))
passTurn(Player.White) flush()
assert(string.find(lastXml,'VEZ DE Rui',1,true))
assert(canReceiveTitle({color='Blue'})) assert(not canReceiveTitle({color='Green'}))
assert(objects.aa0004.locked) assert(objects.aa0002.name=='Rui — Vermelho')
assert(objects.ee0001.shuffled)
objects.dd0001.value=3 objects.dd0002.value=4
rollDice(nil,'Red') flush()
assert(string.find(lastXml,'3 + 4 = 7',1,true))
advancePawn(nil,'Blue') assert(objects.aa0003.moves==0)
advancePawn(nil,'Red') assert(objects.aa0002.moves==1)
assert(math.abs(objects.aa0002.p.x-(SPACES[8].x+OFFSETS.Red.x))<0.001)
advancePawn(nil,'Red') assert(objects.aa0002.moves==1)
-- Resultado bloqueia rolagem de outra pessoa e pode ser descartado só pelo dono/host.
rollDice(nil,'Red') flush()
local count=objects.dd0001.rolls
rollDice(nil,'Blue') assert(objects.dd0001.rolls==count)
discardRoll(nil,'Blue') rollDice(nil,'Blue') assert(objects.dd0001.rolls==count)
discardRoll(nil,'Red')
-- Movimento manual é a fonte da posição; volta pelo Início.
objects.aa0002.p={x=SPACES[39].x,z=SPACES[39].z}
objects.dd0001.value=1 objects.dd0002.value=2
rollDice(nil,'Red') flush() advancePawn(nil,'Red')
assert(math.abs(objects.aa0002.p.x-(SPACES[2].x+OFFSETS.Red.x))<0.001)
local sawStart=false
for _,m in ipairs(messages) do if string.find(m,'Passou pelo Inicio',1,true) then sawStart=true end end
assert(sawStart)
-- Os dados não podem ser lidos enquanto estão em movimento.
objects.dd0001.resting=false
rollDice(nil,'Red') flush()
local moves=objects.aa0002.moves
advancePawn(nil,'Red') assert(objects.aa0002.moves==moves)
objects.dd0001.resting=true flush() discardRoll(nil,'Red')
-- Timeout libera nova tentativa.
objects.dd0001.resting=false rollDice(nil,'Red') flush()
conditions[1].fail() conditions={}
passTurn({color='Red',host=false}) flush()
objects.dd0001.resting=true rollDice(nil,'Blue') flush() advancePawn(nil,'Blue')
assert(objects.aa0003.moves==1)
-- Sem peão/fora do tabuleiro não consome resultado nem cria movimento.
passTurn({color='Blue',host=false}) flush() passTurn(Player.White) flush()
rollDice(nil,'Red') flush() objects.aa0002.p={x=100,z=100}
advancePawn(nil,'Red') assert(objects.aa0002.moves==moves)
discardRoll(nil,'Red')
-- Duplas e rolagem manual aparecem no painel e alimentam um único avanço.
passTurn({color='Red',host=false}) flush()
objects.dd0001.value=4 objects.dd0002.value=4
onObjectRandomized(objects.dd0001,'Blue')
onObjectRandomized(objects.dd0002,'Blue') flush()
assert(string.find(lastXml,'4 + 4 = 8',1,true))
assert(string.find(lastXml,'DADOS IGUAIS',1,true))
advancePawn(nil,'Blue') assert(objects.aa0003.moves==2)
-- Cartas são reveladas no painel e o script não aplica dinheiro automaticamente.
passTurn({color='Blue',host=false}) flush() passTurn(Player.White) flush()
local card=fake('cc0001',-8,3) card.notes='companion_news:1'
objects.ee0001.takeObject=function(params) params.callback_function(card) end
drawNews(nil,'Red')
assert(string.find(lastXml,'Bônus de produtividade',1,true))
assert(string.find(lastXml,'Receba R$',1,true))
local saved=onSave()
onLoad(saved)
assert(canReceiveTitle({color='Blue'}))
assert(string.find(lastXml,'Ana &amp; Igor',1,true))
assert(string.find(lastXml,'VEZ DE Rui',1,true))
-- Passar durante uma rolagem não muda o turno; pending é eliminado ao passar.
objects.dd0001.resting=false
rollDice(nil,'Red') passTurn({color='Red',host=false})
assert(string.find(lastXml,'VEZ DE Rui',1,true))
flush() objects.dd0001.resting=true flush()
passTurn({color='Red',host=false})
passTurn(Player.White) -- clique duplicado não pula Bia
assert(string.find(lastXml,'VEZ DE Bia',1,true))
local before=objects.aa0003.moves
advancePawn(nil,'Red') assert(objects.aa0003.moves==before)
local savedTurn=onSave() onLoad(savedTurn)
assert(string.find(lastXml,'VEZ DE Bia',1,true))
''')
ET.fromstring('<root>'+lua.globals().lastXml+'</root>')
print('OK: save de 40 casas; rolagem, autorização, consumo único, movimento manual, volta, espera e timeout.')
print('OK: 100 Notícias, 28 títulos, 8 mãos, configuração host, nomes, persistência, soma e aviso de duplas.')
