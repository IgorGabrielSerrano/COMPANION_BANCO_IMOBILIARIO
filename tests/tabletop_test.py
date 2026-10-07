"""Testa o save e o script Lua com objetos simulados; não simula física Unity."""
from pathlib import Path
import json
from lupa import LuaRuntime

root=Path(__file__).resolve().parents[1]
save=json.loads((root/'build/tabletop/Companion-Tabuleiro.json').read_text(encoding='utf-8'))
ref=json.loads((root/'docs/tabuleiro-referencia.json').read_text(encoding='utf-8-sig'))
assert len(ref['casas'])==len(save['SnapPoints'])==40
assert len({o['GUID'] for o in save['ObjectStates']})==11
assert ref['casas'][24]['nome']=='Notícias'
assert ref['casas'][23]['valor_indicado']==-2000
assert ref['casas'][16]['valor_indicado']==2000
assert ref['casas'][39]['nome']=='Av. Niemeyer'

lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
objects={} messages={} timers={} conditions={}
Global={}
Player=setmetatable({}, {__index=function() return {host=false} end})
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
 objects[guid]=o return o
end
''')
for o in save['ObjectStates']:
    lua.globals().fake(o['GUID'],o['Transform']['posX'],o['Transform']['posZ'])
lua.execute(save['LuaScript'])
lua.execute('''
onLoad()
assert(#objects.bb0001.buttons==3)
objects.dd0001.value=3 objects.dd0002.value=4
rollDice(nil,'Red') flush()
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
objects.dd0001.resting=true rollDice(nil,'Blue') flush() advancePawn(nil,'Blue')
assert(objects.aa0003.moves==1)
-- Sem peão/fora do tabuleiro não consome resultado nem cria movimento.
rollDice(nil,'Red') flush() objects.aa0002.p={x=100,z=100}
advancePawn(nil,'Red') assert(objects.aa0002.moves==moves)
discardRoll(nil,'Red')
''')
print('OK: save de 40 casas; rolagem, autorização, consumo único, movimento manual, volta, espera e timeout.')
