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
