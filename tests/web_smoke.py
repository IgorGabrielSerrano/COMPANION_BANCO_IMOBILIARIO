"""Browser smoke test for the exported Godot interface.

Requires Python Playwright and Edge (default) or --channel chrome.
Runs on a local HTTP server, with PeerJS stubbed to avoid creating public rooms.
"""
import argparse
import functools
import http.server
import pathlib
import threading
from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parents[1]


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


def run(channel):
    server = http.server.ThreadingHTTPServer(
        ("127.0.0.1", 0), functools.partial(QuietHandler, directory=str(ROOT / "build"))
    )
    threading.Thread(target=server.serve_forever, daemon=True).start()
    screenshots = ROOT / "research" / "browser-qa"
    screenshots.mkdir(parents=True, exist_ok=True)
    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(
                channel=channel, headless=True,
                args=["--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
            )
            page = browser.new_page(viewport={"width": 390, "height": 844}, has_touch=True)
            errors = []
            page.on("pageerror", lambda error: errors.append(str(error)))
            page.on("console", lambda message: errors.append(message.text) if message.type == "error" else None)
            page.on("dialog", lambda dialog: dialog.accept())
            page.route("**/peerjs.min.js", lambda route: route.fulfill(
                content_type="application/javascript", body="class Peer { on() {} destroy() {} }"
            ))
            page.goto(f"http://127.0.0.1:{server.server_port}/?qa=1", wait_until="networkidle")
            page.wait_for_function("window.companionLayout && companionLayout.screen === 'lobby'")

            def layout():
                return page.evaluate("companionLayout")

            def click_canvas(key):
                page.wait_for_function("key => companionLayout.buttons[key] !== undefined", arg=key)
                page.wait_for_timeout(220)
                rect = layout()["buttons"][key]
                frame = page.locator("#godot-game").bounding_box()
                page.mouse.click(frame["x"] + rect["x"] + rect["width"] / 2,
                                 frame["y"] + rect["y"] + rect["height"] / 2)

            def select_tab(tab):
                if layout()["tab"] == tab:
                    return
                click_canvas("tab_" + tab)
                page.wait_for_function("tab => companionLayout.tab === tab", arg=tab)
                page.wait_for_timeout(220)

            page.screenshot(path=str(screenshots / "lobby.png"))
            click_canvas("name_input")
            page.keyboard.type("Igor")
            click_canvas("create")
            page.wait_for_function("state.isBanker && state.playerName === 'Igor' && companionLayout.screen === 'game'")
            page.wait_for_timeout(300)
            assert layout()["scroll"]["height"] / 844 > 0.72
            assert layout()["coinSpinning"]
            click_canvas("go")
            page.wait_for_function("Object.values(state.players)[0].balance === 27000")
            page.wait_for_function("Object.keys(moneyBuffers).length === 4 && moneyAudio.state === 'running'")
            page.wait_for_timeout(1900)
            assert layout()["coinSpinning"], "Coin should keep spinning after the count finishes"
            select_tab("posses")
            click_canvas("buy")
            page.wait_for_selector("#modal-property-editor:not(.hidden)")
            page.locator("#prop-name-input").fill("Av. Santo Amaro")
            page.locator("#prop-price-input").fill("2000")
            page.locator("#prop-rent-input").fill("140")
            page.locator("#btn-save-prop").click()
            page.wait_for_function("Object.values(state.players)[0].properties.length === 1")
            page.wait_for_timeout(300)
            click_canvas("prop_mortgage_0")
            page.wait_for_selector("#modal-mortgage-prop:not(.hidden)")
            assert page.locator("#mortgage-prop-value").inner_text() == "R$ 1.000"
            page.evaluate("closeMortgageModal()")
            select_tab("prisao")
            for count in range(1, 4):
                click_canvas("jail_double")
                if count < 3:
                    page.wait_for_function("count => state.players[state.playerId].consecutiveDoubles === count", arg=count)
                else:
                    page.wait_for_function("state.players[state.playerId].jailed && state.players[state.playerId].consecutiveDoubles === 0")
                page.wait_for_timeout(250)
            click_canvas("jail_round")
            page.wait_for_function("state.players[state.playerId].jailRounds === 1")
            page.wait_for_timeout(250)
            click_canvas("jail_double")
            page.wait_for_function("!state.players[state.playerId].jailed && state.players[state.playerId].jailRounds === 0")
            select_tab("conta")
            assert "jail_enter" not in layout()["buttons"]
            assert "view_players" in layout()["buttons"]
            # A larger table checks scrolling, names with accents and bank emoji sanitization.
            page.evaluate("""() => {
                for (let i = 0; i < 10; i++) state.players['other-' + i] = {
                    name: 'João da Silva ' + i, balance: 12345, properties: [], jailed: false
                };
                updateUI(); saveSession();
            }""")
            for bank in ["c4", "mu", "intel", "new", "nexus"]:
                click_canvas("settings")
                page.wait_for_selector("#modal-bank-settings:not(.hidden)")
                page.locator(f'.bank-theme-choice[data-theme="{bank}"]').click()
                page.wait_for_function("id => companionLayout.theme === id", arg=bank)
                page.locator("#modal-bank-settings .btn-blue").click()
                assert page.evaluate("chosenBankTheme()") == bank
                for tab in ["conta", "jogadores", "posses", "historico", "prisao"]:
                    select_tab(tab)
                    assert not layout()["missingGlyphs"], (bank, tab, layout()["missingGlyphs"])
                    page.screenshot(path=str(screenshots / f"{bank}-{tab}.png"))
                assert page.evaluate("state.players[state.playerId].balance") == 25000
            page.reload(wait_until="networkidle")
            page.wait_for_function("companionLayout && companionLayout.theme === 'nexus' && companionLayout.screen === 'game'")
            assert page.evaluate("chosenBankTheme()") == "nexus"
            # Playwright device viewport sizes include the browser chrome area.
            models = ["iPhone 11", "iPhone 11 Pro", "iPhone 12 Mini", "iPhone 12", "iPhone 13",
                      "iPhone 14", "iPhone 14 Pro", "iPhone 15", "iPhone 16", "iPhone 16 Pro",
                      "iPhone 17", "iPhone 17 Pro Max"]
            for bank in ["c4", "mu", "intel", "new", "nexus"]:
                page.evaluate("id => chooseBankTheme(id)", arg=bank)
                page.wait_for_function("id => companionLayout.theme === id", arg=bank)
                for model in models:
                    viewport = playwright.devices[model]["viewport"]
                    page.set_viewport_size(viewport)
                    page.wait_for_timeout(350)
                    select_tab("jogadores")
                    info = layout()
                    assert info["scroll"]["height"] / viewport["height"] > 0.72, (bank, model, info)
                    assert page.evaluate("document.documentElement.scrollWidth <= innerWidth")
                    assert not info["missingGlyphs"]
                    assert info["buttons"]["exit"]["y"] + info["buttons"]["exit"]["height"] < 80
                    if model in ["iPhone 11 Pro", "iPhone 17 Pro Max"]:
                        page.screenshot(path=str(screenshots / f"{bank}-{model.replace(' ', '-')}.png"))
            # Real finger drag moves the large player list; header/navigation remain in place.
            before = layout()
            cdp = page.context.new_cdp_session(page)
            area = before["scroll"]
            x, y = area["x"] + 120, area["y"] + area["height"] * 0.75
            cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": x, "y": y}]})
            for dy in range(0, 220, 20):
                cdp.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": [{"x": x, "y": y - dy}]})
                page.wait_for_timeout(25)
            cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
            page.wait_for_timeout(300)
            assert layout()["scroll"]["offset"] > before["scroll"]["offset"]
            assert layout()["buttons"]["exit"] == before["buttons"]["exit"]
            page.set_viewport_size({"width": 1280, "height": 720})
            page.wait_for_timeout(350)
            select_tab("historico")
            assert page.locator("#godot-game").bounding_box()["width"] <= 480
            page.screenshot(path=str(screenshots / "desktop.png"))
            click_canvas("exit")
            page.wait_for_function("state.pin === ''")
            assert page.evaluate("Object.keys(savedHostRooms()).length") == 1
            assert not errors, errors
            browser.close()
            print("OK: five player themes, 12 iPhone viewports, tabs, touch scrolling, font glyphs, persistent choice, idle coin, audio and unchanged gameplay.")
    finally:
        server.shutdown()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--channel", default="msedge")
    run(parser.parse_args().channel)
