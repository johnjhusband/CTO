# CTO v1 Project

## What
Autonomous AI CTO on OpenClaw, running on Hetzner VPS.

## Architecture
Five layers: Brain (OpenRouter multi-model), Hands (MCP tools), Memory (OpenClaw native tiers + wiki search), Spine (OpenClaw gateway + cron), Guardrails (advisory rules + circuit breakers as skills).

## Key Decisions
- OpenClaw over Hermes — macro evolution > micro evolution
- VPS-based testing, not Docker — system-level changes need real infrastructure
- Telegram over WhatsApp — zero friction
- Fully autonomous — John reviews after the fact
- Memory is the moat

## Current Status
Files cloned to VPS. OpenClaw not yet installed. Awaiting OpenRouter API key and Telegram bot token from John.
