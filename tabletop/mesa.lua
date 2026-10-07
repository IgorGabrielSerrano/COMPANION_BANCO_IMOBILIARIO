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
local turnIndex=1
local passing=false
local owners={}
local positions={}
local landing=nil
local purchaseBusy=false
local purchaseSerial=0
local layoutPrefs={}
local layoutOpen=false
local layoutIndex=1
local layoutDraft={}
local layoutMessage=''
local layoutItems={
 {id='hud',name='Vez e dados',x=.16,y=.91,w=340,h=86,font=17},
 {id='uiRoll',name='Rolar dados',x=.17,y=.04,w=96,h=30,font=14,button=true},
 {id='uiAdvance',name='Avançar',x=.28,y=.04,w=84,h=30,font=14,button=true},
 {id='uiDiscard',name='Descartar',x=.38,y=.04,w=90,h=30,font=14,button=true},
 {id='passTurn',name='Passar vez',x=.49,y=.04,w=96,h=30,font=14,button=true},
 {id='uiNews',name='Notícias',x=.60,y=.04,w=86,h=30,font=14,button=true},
 {id='showSetup',name='Jogadores',x=.71,y=.04,w=96,h=30,font=14,button=true},
 {id='topView',name='Visão de cima',x=.83,y=.04,w=112,h=30,font=14,button=true},
 {id='buyProperty',name='Comprar posse',x=.85,y=.09,w=150,h=34,font=15,button=true},
 {id='spaceInfo',name='Informações da casa',x=.85,y=.27,w=320,h=245,font=19},
 {id='newsInfo',name='Aviso de Notícias',x=.25,y=.23,w=500,h=200,font=18},
}

local function locateTitle(index)
    local guid=string.format('ff%04d',index)
    local loose=getObjectFromGUID(guid)
    if loose then
        local p=loose.getPosition()
        if (p.x-8)^2+(p.z-3)^2<=4 and not loose.held_by_color then return loose,false end
        return nil,false
    end
    for _,object in ipairs(getAllObjects()) do
        if object.tag=='Deck' then
            for _,card in ipairs(object.getObjects()) do if card.guid==guid then return object,true end end
        end
    end
    return nil,false
end

local function esc(s)
    return tostring(s or ''):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;')
end
local function preference(item) return layoutPrefs[item.id] or item end
local function frame(item,content)
    local p=preference(item)
    local anchor=p.x..' '..p.y
    return '<Panel id="'..item.id..'" anchorMin="'..anchor..'" anchorMax="'..anchor..'" pivot="0.5 0.5" width="'..p.w..'" height="'..p.h..'" color="#10273bdd">'..content..'</Panel>'
end
local function loadDraft()
    local p=preference(layoutItems[layoutIndex])
    layoutDraft={x=tostring(p.x*100),y=tostring(p.y*100),w=tostring(p.w),h=tostring(p.h),font=tostring(p.font)}
end
function openLayout(player)
    if not player.host then return end
    layoutOpen=not layoutOpen
    if layoutOpen then setupOpen=false loadDraft() end
    renderUI()
end
function previousLayout(player)
    if not player.host then return end
    layoutIndex=(layoutIndex-2)%#layoutItems+1 loadDraft() layoutMessage='' renderUI()
end
function nextLayout(player)
    if not player.host then return end
    layoutIndex=layoutIndex%#layoutItems+1 loadDraft() layoutMessage='' renderUI()
end
function editLayout(player,value,id)
    if player.host then layoutDraft[id:gsub('^layout_','')]=value end
end
function applyLayout(player)
    if not player.host then return end
    local p={}
    for _,field in ipairs({'x','y','w','h','font'}) do
        p[field]=tonumber((tostring(layoutDraft[field]):gsub(',','.')))
        if not p[field] or p[field]~=p[field] or math.abs(p[field])==math.huge then layoutMessage='Informe números válidos.' renderUI() return end
    end
    if p.x<3 or p.x>97 or p.y<3 or p.y>97 or p.w<60 or p.w>900 or p.h<24 or p.h>500 or p.font<10 or p.font>32 then
        layoutMessage='X/Y: 3–97%; largura: 60–900; altura: 24–500; fonte: 10–32.' renderUI() return
    end
    p.x=p.x/100 p.y=p.y/100
    layoutPrefs[layoutItems[layoutIndex].id]=p
    layoutMessage='Aplicado. Salve a partida para manter o layout.' renderUI()
end
function resetLayout(player)
    if not player.host then return end
    layoutPrefs={} loadDraft() layoutMessage='Layout padrão restaurado.' renderUI()
end
local function layoutEditor()
    if not layoutOpen then return '' end
    local fields={{'x','X % (esquerda → direita)'},{'y','Y % (baixo → cima)'},{'w','Largura em pixels'},{'h','Altura em pixels'},{'font','Tamanho da fonte'}}
    local xml='<Panel visibility="Host" width="500" height="445" color="#132c40"><VerticalLayout padding="18" spacing="10"><HorizontalLayout preferredHeight="34"><Button onClick="previousLayout">←</Button><Text color="white" fontSize="21">'..esc(layoutItems[layoutIndex].name)..'</Text><Button onClick="nextLayout">→</Button></HorizontalLayout>'
    for _,field in ipairs(fields) do
        xml=xml..'<HorizontalLayout preferredHeight="35" spacing="12"><Text color="white" fontSize="17">'..field[2]..'</Text><InputField preferredWidth="100" textColor="#132c40" fontSize="18" id="layout_'..field[1]..'" onValueChanged="editLayout" text="'..esc(layoutDraft[field[1]])..'" /></HorizontalLayout>'
    end
    return xml..'<Text color="#bed6e8" fontSize="16" preferredHeight="55">'..esc(layoutMessage~='' and layoutMessage or 'Escolha cada botão ou painel nas setas. X/Y posicionam o centro; altere e aplique para visualizar.')..'</Text><HorizontalLayout preferredHeight="36" spacing="8"><Button onClick="applyLayout">Aplicar</Button><Button onClick="resetLayout">Restaurar tudo</Button><Button onClick="openLayout">Fechar</Button></HorizontalLayout></VerticalLayout></Panel>'
end
local function label(color) return config.names[color] or color end
local function controlledColor(color)
    -- O anfitrião opera o jogador atual sem trocar de assento.
    if config.started and Player[color].host then return colors[turnIndex] end
    return color
end
function canReceiveTitle(args)
    if not config.started then return false end
    for i=1,config.count do if colors[i]==args.color then return true end end
    return false
end
function titleRecipient(args)
    local color=controlledColor(args.color)
    if canReceiveTitle({color=color}) then return color end
    return nil
end
function registerTitleOwner(args)
    local recipient=titleRecipient(args)
    local index=tonumber(args.property)
    if not recipient or not index or not SPACES[index] then return nil end
    if SPACES[index].kind~='propriedade' and SPACES[index].kind~='acoes' then return nil end
    if purchaseBusy then return nil end
    if owners[tostring(index)] and owners[tostring(index)]~=recipient and not Player[args.color].host then
        printToColor('Esse título pertence a outro jogador.',args.color) return nil
    end
    owners[tostring(index)]=recipient
    renderUI()
    return recipient
end
function titleDescription(args)
    local index=tonumber(args.property)
    local space=SPACES[index]
    if not space then return '' end
    local owner=owners[tostring(index)]
    return (owner and ('Dono: '..label(owner)..'\n') or '')..'Compra: R$ '..space.price..'\nAluguéis, casas e hipoteca: a definir. Registre no Companion.'
end
local function playable(color)
    if not canReceiveTitle({color=color}) then printToColor('Configure a mesa e escolha uma cor ativa.',color) return false end
    if colors[turnIndex]~=color then printToColor('Agora é a vez de '..label(colors[turnIndex])..'.',color) return false end
    return true
end

function passTurn(player)
    if not config.started or passing then return end
    if player.color~=colors[turnIndex] and not player.host then
        printToColor('Só o jogador da vez ou o anfitrião pode passar a vez.',player.color) return
    end
    if rolling or purchaseBusy then printToColor('Espere os dados ou a retirada do título antes de passar a vez.',player.color) return end
    passing=true
    pending=nil
    landing=nil
    newsText=''
    turnIndex=turnIndex%config.count+1
    status='Vez encerrada. '..label(colors[turnIndex])..', pode rolar os dados.'
    renderUI()
    broadcastToAll('Agora é a vez de '..label(colors[turnIndex])..'.',{0.5,1,0.7})
    Wait.time(function() passing=false end,0.4)
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
    local info=''
    local details=''
    local canBuy=false
    if config.started then
        local color=colors[turnIndex]
        local index=positions[color] or 1
        local space=SPACES[index]
        local owner=owners[tostring(index)]
        local purchasable=space.kind=='propriedade' or space.kind=='acoes'
        local inBank=purchasable and locateTitle(index) or nil
        details='Casa '..index..' · '..space.name
        if purchasable then
            details=details..'\nCompra: R$ '..space.price..'\n'..(owner and ('Dono: '..label(owner)..' · indisponível') or (inBank and 'Disponível para compra' or 'Título fora do banco · confirme o dono'))..'\nAluguel, casas e hipoteca: a definir.'
        elseif space.kind=='receber_banco' then details=details..'\nReceba R$ 2.000 do banco.'
        elseif space.kind=='pagar_banco' then details=details..'\nPague R$ 2.000 ao banco.'
        elseif space.kind=='noticias' then details=details..'\nCompre uma carta no botão Notícias.'
        elseif space.kind=='ir_prisao' then details=details..'\nVá para a prisão e marque no Companion.'
        elseif space.kind=='inicio' then details=details..'\nInício: bônus de R$ 2.000 ao completar a volta.'
        else details=details..'\nEsta casa não está à venda.' end
        local enabled=purchasable and not owner and inBank and landing and landing.color==color and landing.index==index and not purchaseBusy and not rolling
        canBuy=not not enabled
    end
    if details~='' then
        local item=layoutItems[10]
        local p=preference(item)
        -- Reutiliza o conteúdo de informações com dimensões escolhidas pelo host.
        info=frame(item,'<VerticalLayout padding="10" spacing="6"><Text fontSize="'..p.font..'" color="white" horizontalOverflow="Wrap" preferredHeight="'..math.max(50,p.h-52)..'">'..esc(details)..'</Text><Text fontSize="13" color="#bed6e8" preferredHeight="32">Compra e pagamento: registre no Companion.</Text></VerticalLayout>')
    end
    local hud=layoutItems[1]
    local hp=preference(hud)
    local xml=frame(hud,'<VerticalLayout padding="8" spacing="4"><Text id="currentTurn" fontSize="'..hp.font..'" color="#7ae5b0" preferredHeight="24">'..esc(config.started and ('VEZ DE '..label(colors[turnIndex])) or 'Aguardando início')..'</Text><Text fontSize="'..hp.font..'" color="white" horizontalOverflow="Wrap" preferredHeight="'..math.max(28,hp.h-44)..'">'..esc(status)..'</Text></VerticalLayout>')
    for _,item in ipairs(layoutItems) do
        if item.button then
            local p=preference(item)
            local enabled=item.id~='buyProperty' or canBuy
            local button='<Button onClick="'..item.id..'" fontSize="'..p.font..'" colors="#204963|#326784|#163449|#34424a" textColor="white" interactable="'..tostring(enabled)..'">'..esc(item.name)..'</Button>'
            xml=xml..frame(item,button)
        end
    end
    if newsText~='' then
        local p=preference(layoutItems[11])
        xml=xml..frame(layoutItems[11],'<VerticalLayout padding="10"><Text fontSize="'..p.font..'" color="white" horizontalOverflow="Wrap" preferredHeight="'..math.max(40,p.h-45)..'">'..esc(newsText)..'</Text><Button preferredHeight="28" onClick="closeNews">Fechar aviso</Button></VerticalLayout>')
    end
    xml=xml..info..setup..'<Button visibility="Host" rectAlignment="UpperRight" offsetXY="-12 -12" width="78" height="28" onClick="openLayout" colors="#204963|#326784|#163449|#34424a" textColor="white">Layout</Button>'..layoutEditor()
    UI.setXml(xml)
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
    config.started=true setupOpen=false turnIndex=1
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
function onSave() return JSON.encode({config=config,status=status,pending=pending,newsText=newsText,turnIndex=turnIndex,owners=owners,positions=positions,landing=landing,layoutPrefs=layoutPrefs}) end

function onLoad(saved)
    if saved and saved~='' then
        local ok,data=pcall(JSON.decode,saved)
        if ok and data.config then
            config=data.config status=data.status or status pending=data.pending newsText=data.newsText or ''
            turnIndex=math.max(1,math.min(config.count,tonumber(data.turnIndex) or 1))
            owners=data.owners or {} positions=data.positions or {} landing=data.landing
            layoutPrefs=data.layoutPrefs or {}
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
    landing=nil
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
    color=controlledColor(color)
    if not playable(color) then return end
    if purchaseBusy then printToColor('Espere o título sair do baralho.',color) return end
    if rolling or pending then printToColor('Avance ou descarte o resultado anterior antes de rolar novamente.',color) return end
    local a,b=getObjectFromGUID(diceIds[1]),getObjectFromGUID(diceIds[2])
    if not a or not b then printToColor('Um dado está ausente.',color) return end
    a.setPosition({-2,4,5}) b.setPosition({2,4,5}) a.randomize() b.randomize()
    watchDice(color)
end

function onObjectRandomized(object,color)
    if object.getGUID()~=diceIds[1] and object.getGUID()~=diceIds[2] then return end
    color=controlledColor(color)
    if purchaseBusy then return end
    if not playable(color) then return end
    if (pending and pending.color~=color) or (rolling and roller~=color) then
        printToColor('Outra pessoa tem um resultado pendente. A rolagem manual não será usada.',color) return
    end
    pending=nil
    watchDice(color) -- os eventos dos dois dados são unidos pela última sequência
end

function discardRoll(_,color)
    color=controlledColor(color)
    if pending and (pending.color==color or Player[color].host) then pending=nil end
end

function advancePawn(_,color)
    color=controlledColor(color)
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
    positions[color]=target
    landing={color=color,index=target}
    pawn.setPositionSmooth({space.x+offsets.x,2,space.z+offsets.z},false,false)
    renderUI()
    broadcastToAll(label(color)..' chegou a '..target..': '..space.name,{0.7,0.9,1})
    if nearest-1+steps>=40 then printToColor('Passou pelo Inicio: registre +R$ 2.000 no Companion.',color) end
    if space.kind=='receber_banco' then printToColor('Receba R$ 2.000 do banco no Companion.',color) end
    if space.kind=='pagar_banco' then printToColor('Pague R$ 2.000 ao banco no Companion.',color) end
    if space.kind=='ir_prisao' then printToColor('Va para a casa 11 e marque prisao no Companion.',color) end
    if space.kind=='noticias' then printToColor('Clique em Notícias para comprar uma carta.',color) end
end

function buyProperty(player)
    local color=controlledColor(player.color)
    if not playable(color) or rolling or purchaseBusy then return end
    if not landing or landing.color~=color then printToColor('Avance até uma posse antes de comprar.',player.color) return end
    local index=landing.index
    local space=SPACES[index]
    if space.kind~='propriedade' and space.kind~='acoes' then printToColor('Esta casa não está à venda.',player.color) return end
    if owners[tostring(index)] then printToColor('A posse já pertence a '..label(owners[tostring(index)])..'.',player.color) return end
    local source,isDeck=locateTitle(index)
    if not source then printToColor('Título fora do banco. Confirme o dono antes de comprar.',player.color) return end
    purchaseBusy=true
    purchaseSerial=purchaseSerial+1
    local serial=purchaseSerial
    renderUI()
    local count=0
    for _,owner in pairs(owners) do if owner==color then count=count+1 end end
    local seat=1
    for i,c in ipairs(colors) do if c==color then seat=i end end
    local target={x=(seat-4.5)*3,y=2+math.floor(count/4)*.1,z=-7-(count%4)*2.5}
    local function receive(card)
        if serial~=purchaseSerial then return end
        owners[tostring(index)]=color
        purchaseBusy=false
        card.setDescription('Dono: '..label(color)..'\nCompra: R$ '..space.price..'\nRegistre posse e pagamento no Companion. Aluguéis: a definir.')
        broadcastToAll(label(color)..' comprou '..space.name..' por R$ '..space.price..'. Registre no Companion.',{0.5,1,0.7})
        renderUI()
    end
    if isDeck then
        local ok=pcall(function() source.takeObject({guid=string.format('ff%04d',index),position=target,rotation={0,180,0},smooth=false,callback_function=receive}) end)
        if not ok then purchaseBusy=false renderUI() printToColor('Não foi possível retirar o título. Tente novamente.',player.color) end
    else
        source.setPosition({target.x,target.y,target.z}) source.setRotation({0,180,0}) receive(source)
    end
    Wait.time(function()
        if purchaseBusy and serial==purchaseSerial then
            purchaseBusy=false purchaseSerial=purchaseSerial+1 renderUI()
            printToColor('A retirada do título não terminou. Confira a carta e use o menu de atribuir posse se necessário.',player.color)
        end
    end,10)
end

function onObjectDrop(actor,object)
    for color,guid in pairs(pawnIds) do
        if object.getGUID()==guid then
            local p=object.getPosition()
            local nearest,distance=1,math.huge
            for i,s in ipairs(SPACES) do
                local d=(p.x-s.x)^2+(p.z-s.z)^2
                if d<distance then nearest,distance=i,d end
            end
            if distance<=12 then
                positions[color]=nearest
                if config.started and color==colors[turnIndex] and not rolling then landing={color=color,index=nearest} end
                renderUI()
            end
            return
        end
    end
    if object.getGUID():match('^ff') then renderUI() end
end

function onObjectLeaveContainer(container,object)
    if object.getGUID():match('^ff') then Wait.time(renderUI,.1) end
end
function onObjectEnterContainer(container,object)
    if object.getGUID():match('^ff') then Wait.time(renderUI,.1) end
end

function drawNews(_,color)
    color=controlledColor(color)
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
