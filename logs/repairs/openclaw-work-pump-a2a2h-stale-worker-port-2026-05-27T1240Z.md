# A2A2H stale worker watchdog port — 2026-05-27T12:40Z

- Per-tick upstream-port check initially found no committed drift since 97a48575c029778b483433ef7f2ea594fad2bd31.
- While advancing BACKLOG-019, CTO commit ff51e4440f2150c4596f50d71d802dbee4fce7e6 touched upstream-eligible PWA code, so the generic server change was ported to A2A2H.
- Ported CTO ff51e4440f2150c4596f50d71d802dbee4fce7e6 to A2A2H as fce477dfcebb81581c4236bcf9413b847802809c.
- Verification in /opt/a2a2h: backend/Hermes/job_runner py_compile passed; CTO-string grep over services/scripts/frontend returned no hits.
