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
            page.goto(f"http://127.0.0.1:{server.server_port}/", wait_until="networkidle")
            page.wait_for_function("document.body.classList.contains('godot-ready')")
            page.wait_for_timeout(500)
            page.screenshot(path=str(screenshots / "lobby.png"))
            page.mouse.click(150, 355)
            page.keyboard.type("Igor")
            page.mouse.click(195, 635)
            page.wait_for_function("state.isBanker && state.playerName === 'Igor'")
            page.wait_for_timeout(500)
            # Actual clicks on the game canvas validate the Godot -> JS bridge.
            page.mouse.click(190, 300)
            page.wait_for_function("Object.values(state.players)[0].balance === 27000")
            page.wait_for_function("Object.keys(moneyBuffers).length === 4")
            page.wait_for_function("moneyAudio.state === 'running'")
            page.wait_for_timeout(1900)
            page.mouse.click(190, 720)
            page.wait_for_timeout(300)
            page.mouse.click(190, 450)
            page.wait_for_selector("#modal-property-editor:not(.hidden)")
            page.locator("#prop-name-input").fill("Av. Santo Amaro")
            page.locator("#prop-price-input").fill("2000")
            page.locator("#prop-rent-input").fill("140")
            page.locator("#btn-save-prop").click()
            page.wait_for_function("Object.values(state.players)[0].properties.length === 1")
            page.wait_for_timeout(500)
            # Simulate a real finger drag over a card containing clickable buttons.
            cdp = page.context.new_cdp_session(page)
            cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": 180, "y": 600}]})
            for y in range(600, 440, -20):
                cdp.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": [{"x": 180, "y": y}]})
                page.wait_for_timeout(30)
            cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
            page.wait_for_timeout(300)
            page.screenshot(path=str(screenshots / "touch-scroll.png"))
            assert page.locator("#modal-property-editor").evaluate("node => node.classList.contains('hidden')")
            page.mouse.click(190, 632)
            page.wait_for_selector("#modal-mortgage-prop:not(.hidden)")
            assert page.locator("#mortgage-prop-value").inner_text() == "R$ 1.000"
            page.evaluate("closeMortgageModal()")
            for width, height in [(320, 568), (390, 667), (768, 1024), (1280, 720)]:
                page.set_viewport_size({"width": width, "height": height})
                page.wait_for_timeout(250)
                assert page.evaluate("document.documentElement.scrollWidth <= innerWidth")
                page.screenshot(path=str(screenshots / f"{width}x{height}.png"))
            page.set_viewport_size({"width": 390, "height": 844})
            page.wait_for_timeout(250)
            page.mouse.click(280, 795)
            page.wait_for_function("state.pin === ''")
            assert page.evaluate("Object.keys(savedHostRooms()).length") == 1
            assert not errors, errors
            browser.close()
            print("OK: Godot/WebGL, canvas buttons, forms, touch scroll, mobile sizes, WAV decode and fixed exit.")
    finally:
        server.shutdown()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--channel", default="msedge")
    run(parser.parse_args().channel)
