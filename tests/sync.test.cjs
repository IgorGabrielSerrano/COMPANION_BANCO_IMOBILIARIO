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
    let now = 0, nextFrame = 0;
    const frames = new Map();
    const element = () => ({ value: '', innerHTML: '', style: {}, children: [], classList: {
        add() {}, remove() {}, toggle() {}, contains() { return true; }
    }, appendChild() {}, setAttribute() {} });
    const context = vm.createContext({
        crypto: { randomUUID }, console, setTimeout: fn => fn(),
        performance: { now: () => now },
        requestAnimationFrame: callback => { frames.set(++nextFrame, callback); return nextFrame; },
        cancelAnimationFrame: id => frames.delete(id),
        window: { addEventListener() {} },
        localStorage: { getItem() { return null; }, setItem() {}, removeItem() {} },
        alert: msg => { throw new Error(msg); }, confirm: () => true,
        document: { getElementById(id) {
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
alice.run(`sendToHost({ type: 'TRANSFER', tx: { fromId: 'alice', toId: 'missing', amount: 1000 } });`); flush();
assert.equal(host.run('state.players.alice.balance'), 10000);
alice.run('leaveRoom()'); flush();
assert.equal(host.run("'alice' in state.players"), false);
assert.equal(bob.run("'alice' in state.players"), false);
host.run('endGame()'); flush();
assert.equal(bob.run('state.pin'), '');
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
    let contextsCreated = 0, tonesStarted = 0;
    window.AudioContext = class {
        constructor() { contextsCreated++; this.state = 'running'; this.currentTime = 0; }
        createOscillator() { return { frequency: { setValueAtTime() {}, exponentialRampToValueAtTime() {} },
            connect() {}, disconnect() {}, start() { tonesStarted++; }, stop() {} }; }
        createGain() { return { gain: { setValueAtTime() {}, linearRampToValueAtTime() {}, exponentialRampToValueAtTime() {} },
            connect() {}, disconnect() {} }; }
    };
    unlockMoneyAudio(); unlockMoneyAudio(); animateBalance(10000, true); animateBalance(12000);
`);
animated.step(100);
assert.equal(animated.run('contextsCreated'), 1);
assert.equal(animated.run('tonesStarted'), 1);
animated.step(2000);
assert.equal(animated.run('tonesStarted'), 5); // Coin tick + four-note finale.
animated.run('toggleMoneySound(); animateBalance(14000);');
animated.step(100);
animated.step(2000);
assert.equal(animated.run('tonesStarted'), 5);
assert.equal(animated.run('displayedBalance'), 14000);
console.log('OK: áudio compartilhado, moedas, toque final e botão para silenciar.');
