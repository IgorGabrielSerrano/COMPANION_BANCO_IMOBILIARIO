-- Dados físicos e avanço opcional. Dinheiro e prisão continuam no Companion.
local pawnIds = {White='aa0001',Red='aa0002',Blue='aa0003',Green='aa0004',Yellow='aa0005',Orange='aa0006',Purple='aa0007',Pink='aa0008'}
local diceIds = {'dd0001','dd0002'}
local pending = nil
local rolling = false
local roller=nil
local rollSerial = 0
local colors={'White','Red','Blue','Green','Yellow','Orange','Purple','Pink'}
local colorNames={'Branco','Vermelho','Azul','Verde','Amarelo','Laranja','Roxo','Rosa'}
local config={count=2,names={},started=false}
local status='Configure os jogadores antes de iniciar.'
local newsText=''
local newsBusy=false
local setupOpen=true

local function esc(s)
    return tostring(s or ''):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;')
end
local function label(color) return config.names[color] or color end
function canReceiveTitle(args)
    if not config.started then return false end
    for i=1,config.count do if colors[i]==args.color then return true end end
    return false
end
local function playable(color)
    if not canReceiveTitle({color=color}) then printToColor('Configure a mesa e escolha uma cor ativa.',color) return false end
    return true
end

function renderUI()
    local setup=''
    if setupOpen then
        setup='<Panel width="590" height="670" color="#132c40" padding="20"><VerticalLayout spacing="6"><Text fontSize="26" color="white" preferredHeight="42">Jogadores e peões</Text><Text fontSize="18" color="#bed6e8" preferredHeight="35">O anfitrião configura de 2 a 8 jogadores.</Text><HorizontalLayout preferredHeight="38" spacing="8"><Button onClick="fewerPlayers">−</Button><Text color="white" fontSize="22">'..config.count..' jogadores</Text><Button onClick="morePlayers">+</Button></HorizontalLayout>'
        for i=1,config.count do
            local c=colors[i]
            setup=setup..'<HorizontalLayout preferredHeight="38" spacing="8"><Text preferredWidth="130" fontSize="20" color="white">'..colorNames[i]..'</Text><InputField id="name_'..c..'" onValueChanged="editName" characterLimit="32" textColor="#132c40" fontSize="20" readOnly="'..tostring(config.started)..'" text="'..esc(config.names[c])..'" placeholder="Nome do jogador" /></HorizontalLayout>'
        end
        setup=setup..'<Text preferredHeight="50" fontSize="16" color="#bed6e8">Cada pessoa deve escolher essa mesma cor no Tabletop. Os nomes ficam nos peões e no painel.</Text><Button preferredHeight="42" onClick="startGame">'..(config.started and 'Fechar' or 'Iniciar partida')..'</Button></VerticalLayout></Panel>'
    end
    local roster={}
    if config.started then for i=1,config.count do table.insert(roster,colorNames[i]..': '..label(colors[i])) end end
    UI.setXml('<Panel rectAlignment="UpperCenter" offsetXY="0 -12" width="780" height="155" color="#10273bf2"><VerticalLayout padding="10" spacing="6"><Text fontSize="23" color="white" preferredHeight="50">'..esc(status)..'</Text><Text fontSize="15" color="#bed6e8" preferredHeight="25">'..esc(table.concat(roster,' · '))..'</Text><HorizontalLayout preferredHeight="38" spacing="8"><Button onClick="uiRoll">Rolar dados</Button><Button onClick="uiAdvance">Avançar</Button><Button onClick="uiDiscard">Descartar</Button><Button onClick="uiNews">Notícias</Button><Button onClick="showSetup">Jogadores</Button><Button onClick="topView">Visão de cima</Button></HorizontalLayout></VerticalLayout></Panel>'..setup..(newsText~='' and '<Panel rectAlignment="LowerLeft" offsetXY="18 20" width="580" height="200" color="#10273bf2"><VerticalLayout padding="12"><Text fontSize="20" color="white" preferredHeight="145">'..esc(newsText)..'</Text><Button preferredHeight="30" onClick="closeNews">Fechar aviso</Button></VerticalLayout></Panel>' or ''))
end
function editName(player,value,id)
    if not player.host or config.started then return end
    local color=id:match('^name_(%a+)$')
    if pawnIds[color] then config.names[color]=value end
end
local function changeCount(player,delta)
    if not player.host or config.started then return end
    config.count=math.max(2,math.min(8,config.count+delta)) renderUI()
end
function fewerPlayers(p) changeCount(p,-1) end
function morePlayers(p) changeCount(p,1) end
function showSetup() setupOpen=true renderUI() end
function startGame(player)
    if config.started then setupOpen=false renderUI() return end
    if not player.host then return end
    local seen={}
    for i=1,config.count do
        local c=colors[i]
        local name=(config.names[c] or ''):match('^%s*(.-)%s*$')
        if name=='' or seen[name:lower()] then printToColor('Informe nomes diferentes para todos os jogadores.',player.color) return end
        seen[name:lower()]=true config.names[c]=name
    end
    config.started=true setupOpen=false
    for i,c in ipairs(colors) do
        local pawn=getObjectFromGUID(pawnIds[c])
        if pawn then
            if i<=config.count then pawn.setName(label(c)..' — '..colorNames[i]); pawn.setLock(false)
            else pawn.setName('Peão reserva — '..colorNames[i]); pawn.setPosition({25,2,14-i}); pawn.setLock(true) end
        end
    end
    for _,o in ipairs(getAllObjects()) do if o.getGMNotes()=='companion_news_deck' then o.shuffle() end end
    status='Partida iniciada · '..config.count..' jogadores. Role os dados.' renderUI()
end
function uiRoll(p) rollDice(nil,p.color) end
function uiAdvance(p) advancePawn(nil,p.color) end
function uiDiscard(p) discardRoll(nil,p.color) end
function uiNews(p) drawNews(nil,p.color) end
function topView(p) p.lookAt({position={0,1,0},pitch=80,yaw=0,distance=48}) end
function closeNews() newsText='' renderUI() end
function onSave() return JSON.encode({config=config,status=status,pending=pending,newsText=newsText}) end

function onLoad(saved)
    if saved and saved~='' then
        local ok,data=pcall(JSON.decode,saved)
        if ok and data.config then
            config=data.config status=data.status or status pending=data.pending newsText=data.newsText or ''
            setupOpen=not config.started
        end
    end
    local board = getObjectFromGUID('bb0001')
    if not board then return end
    renderUI()
    broadcastToAll('Companion: escolha a cor do seu peao. Pagamentos, duplas e prisao sao registrados no aplicativo.',{0.6,0.85,1})
end

local function watchDice(color)
    local a,b = getObjectFromGUID(diceIds[1]),getObjectFromGUID(diceIds[2])
    if not a or not b then printToColor('Um dado esta ausente. Recarregue a mesa ou restaure os dados.',color) return end
    rolling = true
    roller=color
    status=label(color)..' está rolando os dados…' renderUI()
    rollSerial = rollSerial + 1
    local serial = rollSerial
    -- Espera inicial evita ler os dados antes de o impulso começar.
    Wait.time(function()
        if serial~=rollSerial then return end
        Wait.condition(function()
            if serial ~= rollSerial then return end
            rolling = false
            roller=nil
            local x,y = tonumber(a.getValue()),tonumber(b.getValue())
            if not x or not y or x<1 or x>6 or y<1 or y>6 then
                status='Resultado inválido. Role novamente.' renderUI()
                printToColor('Resultado invalido. Role novamente.',color) return
            end
            pending = {color=color,total=x+y}
            status=label(color)..': '..x..' + '..y..' = '..(x+y)..(x==y and '\nDADOS IGUAIS — marque no Companion!' or '\nDados diferentes.')
            renderUI()
            broadcastToAll(status,{1,1,1})
        end,function() return a.resting and b.resting end,15,function()
            if serial ~= rollSerial then return end
            rolling=false
            roller=nil
            status='Os dados não pararam. Tente novamente.' renderUI()
            printToColor('Os dados nao pararam. Tente novamente.',color)
        end)
    end,1)
end

function rollDice(_,color)
    if not playable(color) then return end
    if rolling or pending then printToColor('Avance ou descarte o resultado anterior antes de rolar novamente.',color) return end
    local a,b=getObjectFromGUID(diceIds[1]),getObjectFromGUID(diceIds[2])
    if not a or not b then printToColor('Um dado está ausente.',color) return end
    a.setPosition({-2,4,5}) b.setPosition({2,4,5}) a.randomize() b.randomize()
    watchDice(color)
end

function onObjectRandomized(object,color)
    if object.getGUID()~=diceIds[1] and object.getGUID()~=diceIds[2] then return end
    if not playable(color) then return end
    if (pending and pending.color~=color) or (rolling and roller~=color) then
        printToColor('Outra pessoa tem um resultado pendente. A rolagem manual não será usada.',color) return
    end
    pending=nil
    watchDice(color) -- os eventos dos dois dados são unidos pela última sequência
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
    broadcastToAll(label(color)..' chegou a '..target..': '..space.name,{0.7,0.9,1})
    if nearest-1+steps>=40 then printToColor('Passou pelo Inicio: registre +R$ 2.000 no Companion.',color) end
    if space.kind=='receber_banco' then printToColor('Receba R$ 2.000 do banco no Companion.',color) end
    if space.kind=='pagar_banco' then printToColor('Pague R$ 2.000 ao banco no Companion.',color) end
    if space.kind=='ir_prisao' then printToColor('Va para a casa 11 e marque prisao no Companion.',color) end
    if space.kind=='noticias' then printToColor('Clique em Notícias para comprar uma carta.',color) end
end

function drawNews(_,color)
    if not playable(color) or newsBusy then return end
    local deck=nil
    for _,o in ipairs(getAllObjects()) do
        local isNews=o.getGMNotes()=='companion_news_deck'
        if not isNews and o.tag=='Deck' then
            local cards=o.getObjects()
            if cards[1] then for _,n in ipairs(NEWS) do if cards[1].guid==n.guid then isNews=true break end end end
        end
        if isNews then deck=o break end
    end
    local function reveal(card)
        newsBusy=false
        local id=tonumber(card.getGMNotes():match('^companion_news:(%d+)$'))
        local n=NEWS[id]
        if not n then return end
        newsText=label(color)..' · NOTÍCIAS #'..id..'\n'..n.title..'\n'..n.text..'\n'..(n.amount>0 and 'Receba R$ ' or 'Pague R$ ')..math.abs(n.amount)..(n.amount>0 and ' do banco.' or ' ao banco.')..' Registre no Companion.'
        renderUI() broadcastToAll(newsText,{0.9,0.9,0.6})
    end
    if deck then
        newsBusy=true
        deck.takeObject({position={-8,2,7},rotation={0,180,0},smooth=false,callback_function=reveal})
    else
        -- Quando resta uma carta o Tabletop destrói o objeto Deck.
        for _,n in ipairs(NEWS) do
            local card=getObjectFromGUID(n.guid)
            if card then
                local p=card.getPosition()
                if (p.x+8)^2+(p.z-3)^2<2 then card.setPosition({-8,2,7}); card.setRotation({0,180,0}); reveal(card); return end
            end
        end
        printToColor('Baralho esgotado. Junte os descartes, vire e embaralhe para reutilizar.',color)
    end
end
