import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSS = (ROOT / "services/pwa/frontend/style.css").read_text()
HTML = (ROOT / "services/pwa/frontend/index.html").read_text()
SW = (ROOT / "services/pwa/frontend/service-worker.js").read_text()


def block(selector: str) -> str:
    marker = selector + " {"
    search_from = 0
    found = ""
    while True:
        idx = CSS.find(marker, search_from)
        if idx == -1:
            if found:
                return found
            raise ValueError(f"selector not found: {selector}")
        start = idx + len(marker)
        depth = 1
        i = start
        while i < len(CSS) and depth:
            if CSS[i] == "{":
                depth += 1
            elif CSS[i] == "}":
                depth -= 1
            i += 1
        found = CSS[start : i - 1]
        search_from = i


class PwaLayoutTests(unittest.TestCase):
    def test_chat_pane_is_scrollable_inside_mobile_flex_layout(self):
        self.assertIn("overflow: hidden", block("html, body"))
        self.assertIn("display: flex", block("body"))
        self.assertIn("min-height: 0", block("body"))
        messages = block("#messages")
        self.assertIn("flex: 1 1 auto", messages)
        self.assertIn("min-height: 0", messages)
        self.assertIn("overflow-y: auto", messages)
        self.assertIn("-webkit-overflow-scrolling: touch", messages)
        self.assertIn("touch-action: pan-y", messages)

    def test_feature_panel_cannot_consume_entire_phone_viewport(self):
        self.assertIn("max-height: 34dvh", CSS)
        self.assertIn("max-height: 22dvh", CSS)
        self.assertIn("overscroll-behavior: contain", CSS)

    def test_visible_pwa_controls_and_cache_bump_exist(self):
        for text in ["Background alerts", "Agent coordination", "Chat history", "Voice", "Update app"]:
            self.assertIn(text, HTML)
        self.assertIn("cto-shell-v21", SW)


if __name__ == "__main__":
    unittest.main()
