const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');

const html = readFileSync(require('node:path').join(__dirname, '../build/index.html'), 'utf8');
const source = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const peers = [];
const queue = [];
function page() {
    const elements = new Map();
    const storage = new Map();
    let now = 0, nextFrame = 0;
    const frames = new Map();
    const element = () => ({ value: '', innerHTML: '', style: {}, children: [], classList: {
        add() {}, remove() {}, toggle() {}, contains() { return true; }
    }, appendChild() {}, setAttribute() {} });
    const context = vm.createContext({
        crypto: { randomUUID }, structuredClone, console, URLSearchParams, location: { search: '' }, setTimeout: fn => fn(),
        performance: { now: () => now },
        requestAnimationFrame: callback => { frames.set(++nextFrame, callback); return nextFrame; },
        cancelAnimationFrame: id => frames.delete(id),
        window: { addEventListener() {} },
        localStorage: { getItem(key) { return storage.get(key) ?? null; }, setItem(key, value) { storage.set(key, value); }, removeItem(key) { storage.delete(key); } },
        alert: msg => { throw new Error(msg); }, confirm: () => true,
        document: { body: { dataset: {}, style: { setProperty() {} } }, getElementById(id) {
            if (!elements.has(id)) elements.set(id, element());
            return elements.get(id);
        }, createElement: element, querySelectorAll: () => [] },
        BroadcastChannel: class {
            constructor() { peers.push(this); }
            postMessage(data) {
                for (const other of peers) if (other !== this) queue.push(() => other.onmessage?.({ data: structuredClone(data) }));
            }
        }
    });
    vm.runInContext(source, context);
    return { run: code => vm.runInContext(code, context), elements,
        step(ms) {
            now += ms;
            const pending = [...frames.values()];
            frames.clear();
            pending.forEach(callback => callback(now));
        } };
}
function flush() { while (queue.length) queue.shift()(); }
const host = page(), alice = page(), bob = page();
host.run(`state = { pin: '1234', playerId: 'host', playerName: 'Host', isBanker: true,
    startingCash: 10000, players: { host: { name: 'Host', balance: 10000, isBanker: true, properties: [] } }, transactions: [] }; enterGame();`);
for (const [app, id] of [[alice, 'alice'], [bob, 'bob']]) {
    app.run(`state = { pin: '1234', playerId: '${id}', playerName: '${id}', isBanker: false,
        players: { '${id}': { name: '${id}', balance: 25000, properties: [] } }, transactions: [] }; enterGame();
        sendToHost({ type: 'JOIN', player: { id: '${id}', data: state.players['${id}'] } });`);
    flush();
}
assert.equal(alice.run('state.players.alice.balance'), 10000);
const beforeThemes = host.run('JSON.stringify(state)');
assert.equal(host.run("searchRules('PRISAO').some(r=>r.title==='Sair da prisão')"), true);
assert.equal(host.run("searchRules('cadeia').some(r=>r.title==='Ir à prisão')"), true);
assert.equal(host.run("searchRules('dados iguais').some(r=>r.title==='Dados iguais')"), true);
assert.equal(host.run("searchRules('hipoteca')[0].page"), 1);
assert.equal(host.run("searchRules('inexistente xyz').length"), 0);
assert.equal(host.run("highlightRule('Prisão & casas', 'prisao')"), '<mark>Prisão</mark> &amp; casas');
host.run('openRules(); closeRules();');
assert.equal(host.run('JSON.stringify(state)'), beforeThemes);
host.run("chooseBankTheme('mu')");
alice.run("chooseBankTheme('new')");
host.run('broadcastState()'); flush();
assert.equal(host.run('chosenBankTheme()'), 'mu');
assert.equal(alice.run('chosenBankTheme()'), 'new');
assert.equal(host.run('JSON.stringify(state)'), beforeThemes);
alice.run("state.playerName = 'Someone Else'; chooseBankTheme('intel'); state.playerName = 'alice'");
assert.equal(alice.run('chosenBankTheme()'), 'new');
alice.run("chooseBankTheme('invalid')");
assert.equal(alice.run('chosenBankTheme()'), 'new');
console.log('OK: temas independentes por jogador, persistência por nome e estado financeiro preservado.');
for (const theme of ['c4', 'mu', 'intel', 'new', 'nexus']) {
    for (const mode of ['create', 'join']) {
        const trial = page();
        trial.run(`initHostPeer = () => {}; initClientPeer = () => {};
            localStorage.setItem('companion_player_themes', JSON.stringify({igor:'intel'}));
            chooseBankTheme('${theme}');`);
        assert.equal(trial.run('chosenBankTheme()'), theme);
        if (mode === 'create') trial.run("document.getElementById('create-banker').value='Igor'; createRoom();");
        else trial.run("document.getElementById('join-name').value=' IGOR '; document.getElementById('join-pin').value='5678'; joinRoom();");
        assert.equal(trial.run('chosenBankTheme()'), theme);
        assert.equal(trial.run("JSON.parse(localStorage.getItem('companion_player_themes')).igor"), theme);
        assert.equal(trial.run("localStorage.getItem('companion_pending_bank_theme')"), null);
        trial.run("resetRoom(); state.playerName='igor'; state.pin='5678';");
        assert.equal(trial.run('chosenBankTheme()'), theme);
    }
}
console.log('OK: escolha no lobby substitui preferência antiga ao criar/entrar e persiste ao voltar nos cinco temas.');
alice.run(`document.getElementById('prop-name-input').value = 'Avenida';
    document.getElementById('prop-price-input').value = '3000';
    document.getElementById('prop-rent-input').value = '500';
    document.getElementById('prop-edit-index').value = '-1'; saveProperty();`);
flush();
for (const app of [host, alice, bob]) {
    assert.equal(app.run('state.players.alice.balance'), 7000);
    assert.equal(app.run('state.players.alice.properties[0].name'), 'Avenida');
}
alice.run('passGO()'); flush();
for (const app of [host, alice, bob]) assert.equal(app.run('state.players.alice.balance'), 9000);
alice.run(`hostConn = { open: true, send(msg) { channel.postMessage({ type: 'COMMAND', pin: state.pin, sender: clientId, command: msg }); } }; passGO();`);
flush(); // Same command delivered by two transports must be applied once.
assert.equal(host.run('state.players.alice.balance'), 11000);
alice.run(`currentModalMode = 'PAY_PLAYER'; document.getElementById('modal-recipient').value = 'bob';
    document.getElementById('modal-amount').value = '1000'; confirmTransfer();`); flush();
assert.equal(host.run('state.players.alice.balance'), 10000);
assert.equal(bob.run('state.players.bob.balance'), 11000);
alice.run(`jailAction('ENTER')`); flush();
for (let round = 1; round <= 3; round++) {
    alice.run(`jailAction('ROUND')`); flush();
    for (const app of [host, alice, bob]) {
        assert.equal(app.run('state.players.alice.jailRounds'), round === 3 ? 0 : round);
        assert.equal(app.run('state.players.alice.jailed'), round < 3);
    }
}
alice.run(`jailAction('ENTER');`); flush();
alice.run(`jailAction('ROUND');`); flush();
alice.run(`jailAction('DOUBLES');`); flush();
assert.equal(bob.run('state.players.alice.jailed'), false);
assert.equal(bob.run('state.players.alice.jailRounds'), 0);
alice.run(`jailAction('MARK_DOUBLES')`); flush();
alice.run(`jailAction('MARK_DOUBLES')`); flush();
assert.equal(bob.run('state.players.alice.consecutiveDoubles'), 2);
alice.run(`jailAction('END_TURN')`); flush();
assert.equal(bob.run('state.players.alice.consecutiveDoubles'), 0);
for (let count = 1; count <= 3; count++) {
    alice.run(`jailAction('MARK_DOUBLES')`); flush();
    for (const app of [host, alice, bob]) {
        assert.equal(app.run('state.players.alice.consecutiveDoubles'), count === 3 ? 0 : count);
        assert.equal(app.run('state.players.alice.jailed'), count === 3);
        assert.equal(app.run('state.players.alice.jailRounds'), 0);
    }
}
alice.run(`jailAction('MARK_DOUBLES')`); flush();
assert.equal(bob.run('state.players.alice.consecutiveDoubles'), 0);
alice.run(`jailAction('DOUBLES')`); flush();
assert.equal(bob.run('state.players.alice.jailed'), false);
console.log('OK: sequência de duplas, encerramento de turno, prisão na terceira dupla e saída.');
alice.run(`sendToHost({ type: 'TRANSFER', tx: { fromId: 'alice', toId: 'missing', amount: 1000 } });`); flush();
assert.equal(host.run('state.players.alice.balance'), 10000);
alice.run(`openPropertyModal(0); document.getElementById('prop-color-input').value = '#ed7272'; saveProperty();`); flush();
assert.equal(bob.run('state.players.alice.properties[0].color'), '#ed7272');
alice.run(`openTransferModal(0); document.getElementById('transfer-prop-recipient').value = 'bob';
    document.getElementById('transfer-prop-price').value = '4500'; confirmTransferProp();`); flush();
for (const app of [host, alice, bob]) {
    assert.equal(app.run('state.players.alice.balance'), 14500);
    assert.equal(app.run('state.players.bob.balance'), 6500);
    assert.equal(app.run('state.players.alice.properties.length'), 0);
    assert.equal(app.run('state.players.bob.properties[0].price'), 3000);
    assert.equal(app.run('state.players.bob.properties[0].color'), '#ed7272');
}
// A stale resale command cannot charge for a property no longer owned.
alice.run(`sendToHost({ type: 'SELL_PROPERTY', propertyId: state.players.bob.properties[0].id, buyerId: 'bob', amount: 1000 });`); flush();
assert.equal(bob.run('state.players.bob.balance'), 6500);
// The mortgage uses the original bank purchase price, not the negotiated resale price.
bob.run(`deleteProperty(0); confirmMortgage(); confirmMortgage();`); flush();
for (const app of [host, alice, bob]) {
    assert.equal(app.run('state.players.bob.balance'), 8000);
    assert.equal(app.run('state.players.bob.properties.length'), 1);
    assert.equal(app.run('state.players.bob.properties[0].mortgaged'), true);
}
// Failed sales leave both balances and ownership intact.
host.run(`sendToHost({ type: 'BUY_PROPERTY', property: { name: 'Praça', rent: 100, color: '#67c587' },
    tx: { fromId: 'host', toId: 'BANK', amount: 1000 } });`); flush();
host.run(`sendToHost({ type: 'SELL_PROPERTY', propertyId: state.players.host.properties[0].id, buyerId: 'bob', amount: 9000 });`); flush();
assert.equal(host.run('state.players.host.properties.length'), 1);
assert.equal(host.run('state.players.host.balance'), 9000);
assert.equal(bob.run('state.players.bob.balance'), 8000);
console.log('OK: cores compartilhadas, venda negociada, hipoteca a 50%, comandos repetidos e saldo insuficiente.');
alice.run('leaveRoom()'); flush();
assert.equal(host.run("'alice' in state.players"), false);
assert.equal(bob.run("'alice' in state.players"), false);
// Rejoin by normalized name restores the same identity and game data.
host.run(`state.departedPlayers.alice.properties = [{ id: 'restored-property', name: 'Avenida', price: 3000, rent: 500 }];
    state.departedPlayers.alice.jailed = true; state.departedPlayers.alice.jailRounds = 2;`);
alice.run(`state = { pin: '1234', playerId: 'new-alice', playerName: '  ALICE  ', isBanker: false,
    players: { 'new-alice': { name: '  ALICE  ', balance: 25000, properties: [] } }, transactions: [] };
    enterGame(); sendToHost({ type: 'JOIN', player: { id: state.playerId, data: state.players[state.playerId] } });`); flush();
assert.equal(alice.run('state.playerId'), 'alice');
assert.equal(alice.run('state.players.alice.balance'), 14500);
assert.equal(alice.run('state.players.alice.properties[0].id'), 'restored-property');
assert.equal(alice.run('state.players.alice.jailRounds'), 2);
assert.equal(host.run("'alice' in state.departedPlayers"), false);
// A repeat JOIN after reconnecting must not reset the restored balance.
alice.run(`sendToHost({ type: 'JOIN', player: { id: state.playerId, data: state.players[state.playerId] } });`); flush();
assert.equal(alice.run('state.players.alice.balance'), 14500);
host.run('leaveRoom()'); flush();
assert.equal(host.run('state.pin'), '');
assert.equal(bob.run('state.pin'), '1234');
host.run(`Peer = class { on() {} destroy() {} }; document.getElementById('join-pin').value = '1234';
    document.getElementById('join-name').value = 'host'; joinRoom();`); flush();
assert.equal(host.run('state.isBanker'), true);
assert.equal(host.run('state.playerId'), 'host');
assert.equal(host.run('state.players.alice.balance'), 14500);
host.run('endGame()'); flush();
assert.equal(bob.run('state.pin'), '');
assert.equal(alice.run('state.pin'), '');
assert.equal(host.run('state.departedPlayers'), undefined);
assert.equal(host.run("savedHostRooms()['1234']"), undefined);
console.log('OK: saída remove jogador, retorno pelo nome restaura identidade/saldo/posses/prisão e encerramento apaga recuperação.');
console.log('OK: compra, bônus, pagamento, deduplicação, cadeia, saída e encerramento em três sessões.');

const animated = page();
animated.run('animateBalance(10000, true); animateBalance(12000);');
assert.equal(animated.elements.get('balance-amount').innerText, 'R$ 10.000');
animated.step(250);
const intermediate = animated.run('displayedBalance');
assert.ok(intermediate > 10000 && intermediate < 12000);
// Duplicate synchronization must not jump to the target or restart the counter.
animated.run('state.players.test = { balance: 12000, properties: [] }; state.playerId = "test"; previousVisualState = { balance: 12000, properties: "[]", jail: "false:0", transactions: 0 }; updateUI();');
assert.equal(animated.run('displayedBalance'), intermediate);
animated.step(100);
assert.ok(animated.run('displayedBalance') > intermediate);
// A second payment retargets from the currently visible amount.
animated.run('animateBalance(14000);');
animated.step(2000);
assert.equal(animated.elements.get('balance-amount').innerText, 'R$ 14.000');
animated.run('animateBalance(9000);');
animated.step(200);
assert.ok(animated.run('displayedBalance') < 14000 && animated.run('displayedBalance') > 9000);
animated.step(2000);
assert.equal(animated.run('displayedBalance'), 9000);
animated.run('window.matchMedia = () => ({ matches: true }); animateBalance(11000);');
assert.equal(animated.run('displayedBalance'), 11000);
animated.run('window.matchMedia = () => ({ matches: false }); animateBalance(13000); resetRoom();');
animated.step(2000);
assert.equal(animated.run('displayedBalance'), null);
console.log('OK: contagem progressiva, novo pagamento durante animação, redução, movimento reduzido e cancelamento ao sair.');

animated.run(`
    let contextsCreated = 0, samplesStarted = 0;
    window.AudioContext = class {
        constructor() { contextsCreated++; this.state = 'running'; this.currentTime = 0; }
        createBufferSource() { return { playbackRate: { value: 1 },
            connect() {}, disconnect() {}, start() { samplesStarted++; }, stop() { this.onended?.(); } }; }
        createGain() { return { gain: { value: 1 },
            connect() {}, disconnect() {} }; }
    };
    Object.keys(MONEY_SOUND_FILES).forEach(name => moneyBuffers[name] = { name });
    unlockMoneyAudio(); unlockMoneyAudio(); animateBalance(10000, true); animateBalance(12000);
`);
animated.step(100);
assert.equal(animated.run('contextsCreated'), 1);
assert.equal(animated.run('samplesStarted'), 1);
animated.step(2000);
assert.equal(animated.run('samplesStarted'), 2); // Recorded coin tick + recorded jingle.
animated.run('toggleMoneySound(); animateBalance(14000);');
animated.step(100);
animated.step(2000);
assert.equal(animated.run('samplesStarted'), 2);
assert.equal(animated.run('activeMoneySounds.size'), 0);
assert.equal(animated.run('displayedBalance'), 14000);
console.log('OK: áudio compartilhado, moedas, toque final e botão para silenciar.');

const undoHost = page();
undoHost.run(`state = { pin:'8888', playerId:'banker', playerName:'Banker', isBanker:true,
    players: { banker:{name:'Banker',balance:5000,isBanker:true,properties:[]},
        buyer:{name:'Buyer',balance:5000,properties:[]}, other:{name:'Other',balance:5000,properties:[]} }, transactions:[] }; enterGame();
    handleIncomingData({type:'BUY_PROPERTY',actorId:'buyer',tx:{fromId:'buyer',toId:'BANK',amount:1000},property:{name:'Rua',rent:100}});`);
const purchaseId = undoHost.run('state.transactions.at(-1).id');
const propertyId = undoHost.run('state.players.buyer.properties[0].id');
undoHost.run(`handleIncomingData({type:'BUILD_HOUSES',actorId:'buyer',propertyId:'${propertyId}',houses:1,rent:600,unitCost:0,revision:0});`);
assert.equal(undoHost.run('state.players.buyer.properties[0].houses'), 0);
assert.equal(undoHost.run('state.players.buyer.balance'), 4000);
undoHost.run(`handleIncomingData({type:'BUILD_HOUSES',actorId:'buyer',propertyId:'${propertyId}',houses:1,rent:600,unitCost:200,revision:0});`);
const constructionId = undoHost.run('state.transactions.at(-1).id');
assert.equal(undoHost.run('state.players.buyer.balance'), 3800);
assert.equal(undoHost.run('state.players.buyer.properties[0].houses'), 1);
assert.equal(undoHost.run('state.players.buyer.properties[0].rent'), 600);
// A repeated/stale construction cannot debit again.
undoHost.run(`handleIncomingData({type:'BUILD_HOUSES',actorId:'buyer',propertyId:'${propertyId}',houses:1,rent:600,unitCost:200,revision:0});`);
assert.equal(undoHost.run('state.players.buyer.balance'), 3800);
assert.match(undoHost.run(`undoProblem(state.transactions.find(tx=>tx.id==='${purchaseId}'))`), /alterada/);
undoHost.run(`handleIncomingData({type:'UNDO',actorId:'banker',transactionId:'${constructionId}'}, true);`);
assert.equal(undoHost.run('state.players.buyer.balance'), 3800); // Even a forged host identity is blocked remotely.
undoHost.run(`handleIncomingData({type:'UNDO',actorId:'buyer',transactionId:'${constructionId}'});`);
assert.equal(undoHost.run('state.players.buyer.balance'), 3800);
undoHost.run(`handleIncomingData({type:'SELL_PROPERTY',actorId:'buyer',propertyId:'${propertyId}',buyerId:'other',amount:900});`);
assert.equal(undoHost.run('state.players.other.properties.length'), 0);
undoHost.run(`handleIncomingData({type:'SELL_HOUSES',actorId:'buyer',propertyId:'${propertyId}',count:1,rent:100,revision:1});`);
const houseSaleId = undoHost.run('state.transactions.at(-1).id');
assert.equal(undoHost.run('state.players.buyer.balance'), 3900);
undoHost.run(`handleIncomingData({type:'SELL_PROPERTY',actorId:'buyer',propertyId:'${propertyId}',buyerId:'other',amount:900});`);
const saleId = undoHost.run('state.transactions.at(-1).id');
assert.equal(undoHost.run('state.players.other.properties[0].houses'), 0);
undoHost.run(`undoTransaction('${saleId}'); undoTransaction('${houseSaleId}'); undoTransaction('${constructionId}'); undoTransaction('${purchaseId}');`);
assert.equal(undoHost.run('state.players.buyer.balance'), 5000);
assert.equal(undoHost.run('state.players.other.balance'), 5000);
assert.equal(undoHost.run('state.players.buyer.properties.length'), 0);
assert.equal(undoHost.run('state.players.other.properties.length'), 0);
assert.equal(undoHost.run(`state.transactions.some(tx=>${JSON.stringify([saleId, houseSaleId, constructionId, purchaseId])}.includes(tx.id))`), false);
assert.notEqual(undoHost.run(`undoProblem(state.transactions.find(tx=>tx.id==='${purchaseId}'))`), '');
undoHost.run(`handleIncomingData({type:'TRANSFER',actorId:'buyer',tx:{fromId:'buyer',toId:'other',amount:100}});`);
const transferId = undoHost.run('state.transactions.at(-1).id');
undoHost.run(`handleIncomingData({type:'TRANSFER',actorId:'buyer',tx:{fromId:'buyer',toId:'BANK',amount:50}}); undoTransaction('${transferId}');`);
assert.equal(undoHost.run('state.players.buyer.balance'), 4950);
assert.equal(undoHost.run('state.players.other.balance'), 5000);
undoHost.run(`handleIncomingData({type:'BUY_PROPERTY',actorId:'buyer',tx:{fromId:'buyer',toId:'BANK',amount:1000},property:{name:'Praça',rent:100}});`);
const secondBuy = undoHost.run('state.transactions.at(-1).id');
const secondProp = undoHost.run('state.players.buyer.properties[0].id');
undoHost.run(`handleIncomingData({type:'BUILD_HOUSES',actorId:'buyer',propertyId:'${secondProp}',houses:4,rent:900,unitCost:99999,revision:0});`);
assert.equal(undoHost.run('state.players.buyer.properties[0].houses'), 0);
assert.equal(undoHost.run('state.players.buyer.balance'), 3950);
undoHost.run(`handleIncomingData({type:'MORTGAGE_PROPERTY',actorId:'buyer',propertyId:'${secondProp}'});`);
const mortgageId = undoHost.run('state.transactions.at(-1).id');
assert.equal(undoHost.run('state.players.buyer.properties[0].mortgaged'), true);
assert.equal(undoHost.run('state.players.buyer.balance'), 4450);
undoHost.run(`handleIncomingData({type:'TRANSFER',actorId:'other',tx:{fromId:'other',toId:'buyer',amount:100,propertyId:'${secondProp}'}});`);
assert.equal(undoHost.run('state.players.buyer.balance'), 4450);
undoHost.run(`handleIncomingData({type:'REDEEM_PROPERTY',actorId:'buyer',propertyId:'${secondProp}'});`);
const redemptionId = undoHost.run('state.transactions.at(-1).id');
assert.equal(undoHost.run('state.players.buyer.balance'), 3850);
assert.equal(undoHost.run('state.players.buyer.properties[0].mortgaged'), false);
undoHost.run(`undoTransaction('${redemptionId}');`);
undoHost.run(`undoTransaction('${mortgageId}'); undoTransaction('${secondBuy}');`);
assert.equal(undoHost.run('state.players.buyer.balance'), 4950);
assert.equal(undoHost.run('state.players.buyer.properties.length'), 0);
undoHost.run(`handleIncomingData({type:'TRANSFER',actorId:'buyer',tx:{fromId:'buyer',toId:'other',amount:100}});`);
const fundedTransfer = undoHost.run('state.transactions.at(-1).id');
undoHost.run(`handleIncomingData({type:'TRANSFER',actorId:'other',tx:{fromId:'other',toId:'BANK',amount:5100}});`);
const spendingId = undoHost.run('state.transactions.at(-1).id');
assert.match(undoHost.run(`undoProblem(state.transactions.find(t=>t.id==='${fundedTransfer}'))`), /Saldo insuficiente/);
undoHost.run(`undoTransaction('${spendingId}'); undoTransaction('${fundedTransfer}');`);
assert.equal(undoHost.run('state.players.other.balance'), 5000);
console.log('OK: construção paga ao banco, casas/aluguel, venda preserva casas, reversão completa e permissão exclusiva do banqueiro.');
undoHost.run(`handleIncomingData({type:'TRANSFER',actorId:'buyer',tx:{fromId:'buyer',toId:'BANK',amount:200}});
    handleIncomingData({type:'TRANSFER',actorId:'buyer',tx:{fromId:'buyer',toId:'BANK',amount:300}});`);
const batchIds = JSON.parse(undoHost.run('JSON.stringify(state.transactions.slice(-2).map(t=>t.id))'));
const batchBefore = undoHost.run('state.players.buyer.balance');
undoHost.run(`openUndoModal(${JSON.stringify(batchIds)}); confirmUndo();`);
assert.equal(undoHost.run('state.players.buyer.balance'), batchBefore + 500);
assert.equal(undoHost.run(`state.transactions.some(tx=>${JSON.stringify(batchIds)}.includes(tx.id))`), false);
undoHost.run(`handleIncomingData({type:'TRANSFER',actorId:'buyer',tx:{fromId:'buyer',toId:'BANK',amount:25}});`);
const validId = undoHost.run('state.transactions.at(-1).id');
const stateBeforeBadBatch = undoHost.run('JSON.stringify(state)');
assert.notEqual(undoHost.run(`prepareUndo(['${validId}', '${batchIds[0]}']).problem`), '');
assert.equal(undoHost.run('JSON.stringify(state)'), stateBeforeBadBatch);
console.log('OK: desfazer múltiplas ações contabiliza todas e lote inválido não altera nada.');
undoHost.run(`state.players.other.properties=[{id:'qr-property',name:'Rua QR',rent:400,price:1500,houses:0,mortgaged:false}];`);
assert.equal(undoHost.run(`pixRecipient(JSON.stringify({kind:'companion-player',version:1,pin:'8888',playerId:'other'})).id`), 'other');
assert.ok(undoHost.run(`pixRecipient(JSON.stringify({kind:'companion-player',version:1,pin:'9999',playerId:'other'})).error`));
assert.ok(undoHost.run(`pixRecipient(pixPayload()).error`));
assert.ok(undoHost.run(`pixRecipient('https://example.com').error`));
undoHost.run(`openPixPayment(pixPayload('other')); document.getElementById('modal-amount').value='400';
    document.getElementById('modal-property').value='qr-property'; onPropertySelected();confirmTransfer();`);
assert.equal(undoHost.run('state.transactions.at(-1).paymentMethod'), 'PIX');
assert.equal(undoHost.run('state.transactions.at(-1).propertyId'), 'qr-property');
console.log('OK: hipoteca mantém posse, aluguel bloqueado, resgate +20%, QR de mesa/jogador e Pix com aluguel.');

(async () => {
    const loading = page();
    loading.run(`
        let downloads = 0, decodes = 0;
        window.AudioContext = class {
            constructor() { this.state = 'running'; }
            async decodeAudioData(bytes) { decodes++; return { decoded: true }; }
        };
        fetch = async () => { downloads++; return { ok: true, arrayBuffer: async () => new ArrayBuffer(8) }; };
        unlockMoneyAudio(); unlockMoneyAudio();
    `);
    await loading.run('moneySoundsLoading');
    assert.equal(loading.run('downloads'), 4);
    assert.equal(loading.run('decodes'), 4);
    assert.equal(loading.run('Object.keys(moneyBuffers).length'), 4);
    for (const name of loading.run('Object.values(MONEY_SOUND_FILES)')) {
        const bytes = readFileSync(require('node:path').join(__dirname, '../build', name));
        assert.equal(bytes.toString('ascii', 0, 4), 'RIFF');
        assert.equal(bytes.toString('ascii', 8, 12), 'WAVE');
        assert.ok(bytes.length > 1000);
    }
    loading.run(`moneySoundsLoading = null; delete moneyBuffers.tickA; fetch = async () => ({ ok: false }); loadMoneySounds();`);
    await loading.run('moneySoundsLoading');
    assert.equal(loading.run('moneySoundsLoading'), null);
    console.log('OK: arquivos WAV locais, carregamento único, decodificação e falha de download sem travar o jogo.');
})().catch(error => { console.error(error); process.exitCode = 1; });
