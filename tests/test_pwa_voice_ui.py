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
        self.assertIn('id="voice-status"', index)
        self.assertIn('id="voice-help"', index)
        self.assertIn('id="report-voice-status"', index)
        self.assertIn("SpeechSynthesisUtterance", app)
        self.assertIn("SpeechRecognition", app)
        self.assertIn("pwa-voice-enabled", app)
        self.assertIn("voiceSupportSnapshot", app)
        self.assertIn("reportVoiceDeviceStatus", app)
        self.assertIn("autoReportDailyDeviceReadiness", app)
        self.assertIn("pwa-device-readiness-auto-report-day", app)
        self.assertIn('/api/voice/device_status', app)
        self.assertIn("appendMessage(m, { speak: true })", app)
        self.assertIn("#voice-input.listening", style)
        self.assertIn('SHELL_CACHE = "cto-shell-v20"', worker)
        self.assertIn("let reported = false", app)
        self.assertIn("if (reported) localStorage.setItem(key, day);", app)


if __name__ == "__main__":
    unittest.main()
