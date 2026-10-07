# Godot Web interface

Open `project.godot` in Godot 4.7.2. This presentation project renders the lobby,
balance animation, game actions, jail, property list, player list and history.
Icons and coin particles are drawn in Godot rather than using emoji glyphs.

The browser export runs in the same-origin `build/game/index.html` iframe.
JavaScriptBridge calls `companionView` and `companionAction` in the containing
page. The existing PeerJS host remains authoritative for gameplay. HTML modals
remain above the game canvas for native mobile input and accessible form fields.

Export using `tools/export-godot.ps1`, with Godot 4.7.2 Web export templates
installed. This uses the single-threaded template, suitable for GitHub Pages
without cross-origin isolation headers. The original HTML interface remains
available if the engine cannot initialize.

The root Godot project contains the earlier Firebase implementation and is
preserved. The web presentation is isolated here so it does not replace the
working PeerJS game logic with that earlier networking prototype.

Verification: `node tests/sync.test.cjs`, a headless Godot import/run/export,
and browser checks at mobile viewport sizes before publishing.

## Personal bank skins and mobile layout

Each player's normalized name has a local appearance preference. C4 Bank,
MuBank, Intel Bank, NeoBank and Nexus Bank are fictional parody names. Preferences never
modify or broadcast the room's financial state. The parent page supplies one
palette to both Godot and the HTML form overlays.

An explicit lobby theme choice overrides a returning player's previous choice
when they create or join a room and is then saved under their normalized name.
Input text and placeholders use the palette's text and muted colors. MuBank,
NeoBank and Nexus Bank use card-text contrast for the balance coin and accent
color for the Account navigation coin. C4 Bank and Intel Bank retain gold coins.

Only the compact header and six-tab navigation stay fixed. The Account page,
including balance, payments, the player overview and recent activity, scrolls
as a whole. Players, Properties, History and Prison have dedicated views.
The History tab displays every transaction, while Account previews the latest
three. Prison contains consecutive doubles and jail rounds. On desktop the same app is centered within
a 480 CSS-pixel frame. The visible balance coin always idles unless reduced
motion is enabled. Godot text excludes unsupported emoji from existing game
records; the records themselves are preserved.

The export helper fingerprints the PCK and frame URL so browsers do not reuse
the old interface after a deployment. It also copies the font assets and their
licenses for HTML forms. Fonts use the SIL Open Font License: Inter, Nunito
Sans, DM Sans, Manrope and Sora from https://github.com/google/fonts . These are
open fonts selected for the parody skins, not the banks' proprietary fonts.

Visual references consulted:

- C6 monochrome identity: https://www.c6bank.com.br/carbon-brand-space/cores/
- Nubank purple identity: https://nubank.com.br/nu/conta
- Inter orange identity: https://blog.inter.co/novo-logo-inter-muda-marca-e-se-consolida-como-super-app-financeiro/
- Neon blue/cyan identity: https://neon.com.br/conta-digital
- Neon gradients: https://anacouto.com.br/cases/neon/
- Next green identity: https://www.next.me/sobre-nos
- C6 Sans reference: https://www.c6bank.com.br/carbon-brand-space/tipografia/
- Nu Sans reference: https://blog.nubank.com.br/nu-sans/

Only NeoBank uses a gradient. Nexus Bank uses a flat green palette.
`layouts/conta.tscn`, `layouts/prisao.tscn` and `layouts/estrutura.tscn` are actual runtime scenes with
freely positioned controls and editable text. See `layouts/COMO-EDITAR.md`.
The native preview's Tema button changes the demo bank appearance. The web
router continues to handle actual room operations.

## Construction and banker undo

Properties store 0–4 houses and a manually entered rent. The construction form
asks for the unit price; the host computes `(new houses - existing houses) *
unit price` and debits the player to the bank atomically. Increasing the house
count without a positive price or sufficient balance is rejected. A property
revision prevents repeated submissions charging twice. Rent-only correction
without increasing the house count does not charge a construction cost.

New financial/property actions store inverse patches with balance deltas and
changed property snapshots. Only the host's local banker can issue undo; remote
commands, including a forged banker actor id, are rejected. In History the
banker taps a transaction to review an undo, or uses Select for a batch. The
confirmation previews each player's net balance change. Batches are simulated
newest-first on a clone and applied only when every selected action is valid.
Property dependencies and insufficient reversal balances require undoing the
later related action first. Successfully undone entries are removed from history
in the same atomic update that restores balances and properties. Legacy
property entries without inverse data remain visible but cannot be fully
reverted. Legacy monetary transfers with valid payer/recipient identifiers
are migrated to balance-only inverse patches when the banker restores a room.

Browser QA uses Playwright iPhone 11–17 viewport profiles, including heights
with browser controls visible, with all five skins. This is viewport and touch
emulation in Chromium, not certification on physical iPhones or mobile Safari.
Run `python tests/web_smoke.py` with Playwright and Edge installed. QA-only
canvas bounds and glyph diagnostics are enabled by `?qa=1`; the browser test
uses them to click the actual Godot controls across viewport sizes.

## Pix parody tab

Each player has a room-specific QR code. Scanning another active player's code
opens the existing payment form with the recipient locked. Their unmortgaged
properties can be selected to prefill rent; Pix payments retain property IDs
and payment method in history. Camera tracks stop on close, successful scan,
leaving the room or hiding the page. This is an in-game transfer, not a banking
Pix integration. QR generation and decoding libraries are vendored with licenses.
