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
    const element = () => ({ value: '', innerHTML: '', style: {}, children: [], classList: {
        add() {}, remove() {}, toggle() {}, contains() { return true; }
    }, appendChild() {} });
    const context = vm.createContext({
        crypto: { randomUUID }, console, setTimeout: fn => fn(),
        window: { addEventListener() {} },
        localStorage: { setItem() {}, removeItem() {} },
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
    return { run: code => vm.runInContext(code, context), elements };
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
