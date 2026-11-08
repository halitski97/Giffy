# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase. This is a single-context repo: one glossary and one ADR folder at the root.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in.
- **`docs/architecture.md`** and the **Decision log** in `docs/PLAN.md`: Giffy's existing architecture and product decisions, recorded before `docs/adr/` existed. Treat them as ADRs.

If `GLOSSARY.md` or `docs/adr/` don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.

## File structure

```
/
├── GLOSSARY.md
├── docs/
│   ├── adr/                           ← example file names
│   │   ├── 0001-imageio-gif-encoder.md
│   │   └── 0002-serial-conversion-queue.md
│   ├── architecture.md
│   └── PLAN.md
└── Giffy/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, or a decision in `docs/architecture.md` or the `docs/PLAN.md` Decision log, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_

Decisions in `docs/architecture.md` don't change without the developer's approval (see `CLAUDE.md`): propose the change and wait.
