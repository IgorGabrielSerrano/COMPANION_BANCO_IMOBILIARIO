-- Dados físicos e avanço opcional. Dinheiro e prisão continuam no Companion.
local pawnIds = {White='aa0001',Red='aa0002',Blue='aa0003',Green='aa0004',Yellow='aa0005',Orange='aa0006',Purple='aa0007',Pink='aa0008'}
local diceIds = {'dd0001','dd0002'}
local pending = nil
local rolling = false
local rollSerial = 0

function onLoad()
    local board = getObjectFromGUID('bb0001')
    if not board then return end
    board.createButton({label='ROLAR DADOS',click_function='rollDice',function_owner=Global,position={-5,0.3,0},rotation={0,0,0},width=2300,height=650,font_size=240,color={0.12,0.32,0.48},font_color={1,1,1}})
    board.createButton({label='AVANCAR PEAO',click_function='advancePawn',function_owner=Global,position={5,0.3,0},rotation={0,0,0},width=2300,height=650,font_size=240,color={0.1,0.42,0.3},font_color={1,1,1}})
    board.createButton({label='DESCARTAR RESULTADO',click_function='discardRoll',function_owner=Global,position={0,0.3,-3},rotation={0,0,0},width=2600,height=500,font_size=180,color={0.25,0.29,0.34},font_color={1,1,1}})
    broadcastToAll('Companion: escolha a cor do seu peao. Pagamentos, duplas e prisao sao registrados no aplicativo.',{0.6,0.85,1})
end

function rollDice(_, color)
    if not pawnIds[color] then printToColor('Escolha uma das oito cores de peao.',color) return end
    if rolling or pending then printToColor('Avance ou descarte o resultado anterior antes de rolar novamente.',color) return end
    local a,b = getObjectFromGUID(diceIds[1]),getObjectFromGUID(diceIds[2])
    if not a or not b then printToColor('Um dado esta ausente. Recarregue a mesa ou restaure os dados.',color) return end
    rolling = true
    rollSerial = rollSerial + 1
    local serial = rollSerial
    a.setPosition({-2,4,5}) b.setPosition({2,4,5})
    a.randomize() b.randomize()
    -- Espera inicial evita ler os dados antes de o impulso começar.
    Wait.time(function()
        Wait.condition(function()
            if serial ~= rollSerial then return end
            rolling = false
            local x,y = tonumber(a.getValue()),tonumber(b.getValue())
            if not x or not y or x<1 or x>6 or y<1 or y>6 then
                printToColor('Resultado invalido. Role novamente.',color) return
            end
            pending = {color=color,total=x+y}
            broadcastToAll(color..': '..x..' + '..y..' = '..(x+y)..(x==y and ' | DADOS IGUAIS: marque no Companion.' or ''),{1,1,1})
        end,function() return a.resting and b.resting end,15,function()
            if serial ~= rollSerial then return end
            rolling=false
            printToColor('Os dados nao pararam. Tente novamente.',color)
        end)
    end,1)
end

function discardRoll(_,color)
    if pending and (pending.color==color or Player[color].host) then pending=nil end
end

function advancePawn(_,color)
    if not pending or pending.color~=color then printToColor('Role os dados da sua cor primeiro.',color) return end
    local pawn = getObjectFromGUID(pawnIds[color])
    if not pawn then printToColor('Seu peao esta ausente.',color) return end
    local p = pawn.getPosition()
    local nearest,distance = 1,math.huge
    for i,space in ipairs(SPACES) do
        local d = (p.x-space.x)^2+(p.z-space.z)^2
        if d<distance then nearest,distance=i,d end
    end
    if distance>12 then printToColor('Coloque seu peao em uma casa do tabuleiro antes de avancar.',color) return end
    local steps=pending.total
    local target=(nearest-1+steps)%40+1
    pending=nil -- consome antes de animar: um clique extra nao movimenta duas vezes
    local space=SPACES[target]
    local offsets=OFFSETS[color]
    pawn.setPositionSmooth({space.x+offsets.x,2,space.z+offsets.z},false,false)
    broadcastToAll(color..' chegou a '..target..': '..space.name,{0.7,0.9,1})
    if nearest-1+steps>=40 then printToColor('Passou pelo Inicio: registre +R$ 2.000 no Companion.',color) end
    if space.kind=='receber_banco' then printToColor('Receba R$ 2.000 do banco no Companion.',color) end
    if space.kind=='pagar_banco' then printToColor('Pague R$ 2.000 ao banco no Companion.',color) end
    if space.kind=='ir_prisao' then printToColor('Va para a casa 11 e marque prisao no Companion.',color) end
    if space.kind=='noticias' then printToColor('Consulte uma carta Noticias do seu jogo.',color) end
end
