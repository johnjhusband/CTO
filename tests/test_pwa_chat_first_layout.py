"""
Real PWA layout regression test.

Loads the live PWA in a headless browser at a phone-sized viewport, signs in
via the bootstrap token flow, and asserts the chat is the dominant UI:

1. The chat composer (input box) is visible above the fold.
2. At least one of the message area or composer is in the top 60% of the
   viewport on first render — chat is the primary content, not chrome.
3. Any feature/status disclosure is collapsed by default.

Why this matters: the previous "PWA scroll layout regression test" only
string-searches CSS for keywords like "overflow: hidden", which lets the
agents pile feature cards on top of the chat without any test failing.
This test renders the page and reads bounding rectangles — the only kind
of test that catches "the chat is buried under 4 status cards."

Run:
    PWA_BASE_URL=https://cto.husband.llc \\
    PWA_AUTH_TOKEN=<token> \\
    pytest tests/test_pwa_chat_first_layout.py -v

If PWA_BASE_URL or PWA_AUTH_TOKEN are not set, the test skips so CI without
secrets does not fail. CTO's autonomous work-pump MUST set both and treat
a skip as a failure.
"""
from __future__ import annotations

import os
import unittest

try:
    from playwright.sync_api import sync_playwright  # type: ignore
    PLAYWRIGHT_AVAILABLE = True
except Exception:
    PLAYWRIGHT_AVAILABLE = False


PHONE_VIEWPORT = {"width": 390, "height": 844}
CHAT_FIRST_TOP_FRACTION = 0.60


@unittest.skipUnless(PLAYWRIGHT_AVAILABLE, "playwright not installed")
class PwaChatFirstLayoutTests(unittest.TestCase):
    def setUp(self) -> None:
        self.base_url = os.environ.get("PWA_BASE_URL", "").rstrip("/")
        self.token = os.environ.get("PWA_AUTH_TOKEN", "")
        if not self.base_url or not self.token:
            self.skipTest(
                "PWA_BASE_URL or PWA_AUTH_TOKEN not set; cannot exercise the live PWA."
            )

    def test_chat_composer_is_visible_above_the_fold(self) -> None:
        bootstrap = f"{self.base_url}/?token={self.token}"
        with sync_playwright() as p:
            browser = p.chromium.launch()
            try:
                context = browser.new_context(viewport=PHONE_VIEWPORT)
                page = context.new_page()
                page.goto(bootstrap, wait_until="domcontentloaded")
                page.wait_for_selector("#composer", state="visible", timeout=15000)
                composer = page.locator("#composer")
                box = composer.bounding_box()
                self.assertIsNotNone(box, "composer has no bounding box")
                # Composer must be on screen
                self.assertLess(
                    box["y"], PHONE_VIEWPORT["height"],
                    f"composer is below the fold at y={box['y']} on a 844px viewport"
                )
                self.assertGreaterEqual(box["y"], 0)

                # Chat (messages area) must be the dominant content region.
                messages = page.locator("#messages")
                m_box = messages.bounding_box()
                self.assertIsNotNone(m_box)
                threshold = CHAT_FIRST_TOP_FRACTION * PHONE_VIEWPORT["height"]
                self.assertLess(
                    m_box["y"], threshold,
                    f"chat messages region starts at y={m_box['y']}; "
                    f"more than {int(CHAT_FIRST_TOP_FRACTION*100)}% of the viewport is "
                    f"consumed by chrome before chat begins. Chat-first violated."
                )

                # Any feature disclosure must be collapsed at first render.
                # If a <details> exists in the topbar, assert it is closed.
                topbar_details = page.locator("header .settings, header details")
                if topbar_details.count():
                    self.assertEqual(
                        topbar_details.first.evaluate("el => el.open"),
                        False,
                        "topbar details element should be collapsed by default"
                    )

                # Any orphan .feature-panel or .feature-summary in DOM must be
                # display:none — they should not consume vertical space.
                for legacy in (".feature-panel", ".feature-summary"):
                    if page.locator(legacy).count():
                        visible = page.locator(legacy).first.evaluate(
                            "el => window.getComputedStyle(el).display !== 'none'"
                        )
                        self.assertFalse(
                            visible,
                            f"legacy {legacy} is visible; revert chrome bloat"
                        )
            finally:
                browser.close()


if __name__ == "__main__":
    unittest.main()
