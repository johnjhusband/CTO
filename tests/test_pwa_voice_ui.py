#!/usr/bin/env python3
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
FRONTEND = ROOT / "services" / "pwa" / "frontend"


class PwaVoiceUiTests(unittest.TestCase):
    def test_voice_controls_are_visible_and_cache_bumped(self):
        index = (FRONTEND / "index.html").read_text()
        app = (FRONTEND / "app.js").read_text()
        style = (FRONTEND / "style.css").read_text()
        worker = (FRONTEND / "service-worker.js").read_text()

        self.assertIn('id="voice-toggle"', index)
        self.assertIn('aria-pressed="false"', index)
        self.assertIn('id="voice-input"', index)
        self.assertIn("SpeechSynthesisUtterance", app)
        self.assertIn("SpeechRecognition", app)
        self.assertIn("pwa-voice-enabled", app)
        self.assertIn("appendMessage(m, { speak: true })", app)
        self.assertIn("#voice-input.listening", style)
        self.assertIn('SHELL_CACHE = "cto-shell-v11"', worker)


if __name__ == "__main__":
    unittest.main()
