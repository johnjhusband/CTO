#!/usr/bin/env python3
"""Index the CTO wiki for search via memweave (FTS-only, no API key needed)."""
import asyncio
from pathlib import Path
from memweave import MemWeave, MemoryConfig, QueryConfig, EmbeddingConfig

async def main():
    workspace = Path("/home/john/repos/CTO")
    config = MemoryConfig(
        workspace_dir=str(workspace),
        query=QueryConfig(strategy="fts"),
        embedding=EmbeddingConfig(model="none"),
    )
    async with MemWeave(config) as mem:
        wiki_dir = workspace / "wiki"
        count = 0
        for md_file in sorted(wiki_dir.glob("*.md")):
            await mem.add(md_file)
            count += 1
            print(f"Indexed: {md_file.name}")

        for name in ["SOUL.md", "AGENTS.md", "HANDOFF.md", "MEMORY.md", "GUARDRAILS.md", "FAILURE.md"]:
            f = workspace / name
            if f.exists():
                await mem.add(f)
                count += 1
                print(f"Indexed: {name}")

        print(f"\nTotal: {count} files indexed")

        print("\n--- Test search: 'memory architecture' ---")
        results = await mem.search("memory architecture")
        for r in results[:3]:
            print(f"  [{r.score:.2f}] {r.snippet[:100]}...")

asyncio.run(main())
