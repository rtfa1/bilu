---
name: technical-research
description: Deep technical research on similar solutions in the market (tech stacks, architectures, how features work, and how components integrate), using existing briefs/reports as seed input.
metadata:
  short-description: Reverse-engineer comparable products technically
---

# Technical Research

## Goal

Produce a technical “how it likely works” report for comparable products/solutions:
- What technologies/stacks they use (with evidence)
- How main features are implemented (workflows, components, protocols)
- How the pieces glue together (integrations, data flow, boundaries)
- What we should copy vs avoid (technical rationale)

This skill is intentionally technical-first (not business/market sizing).

## Inputs (seed-first)

Start from existing in-repo artifacts if available:
- A prior research report (e.g., from `researcher`)
- A brief file (e.g., `docs/briefs/<slug>.md`)
- Any earlier notes pasted by the user

If the user provides multiple sources, treat them as seed context and reconcile conflicts.

If no seed exists, ask for:
- 1–3 comparable products/tools (names/URLs)
- The top 5 features to analyze
- Hard constraints (platform, language, self-hosting, licensing)

## Operating Principles

- Evidence-driven: prefer official docs, engineering blog posts, conference talks, upstream repos.
- Separate **Verified** vs **Hypothesized** claims; never blur them.
- Focus on mechanisms: protocols, components, data models, queues/caches, deployment topology.
- Timebox by default (30–60 min) unless the user asks for exhaustive coverage.

## Network + Sandbox Reality

If network access is restricted, web fetching may require user approval. If you can’t fetch sources:
- Draft the structure and list exact URLs/queries to validate.
- Mark most claims as **Hypothesized** and note what would confirm/disconfirm them.

## Workflow

### 1) Define the comparison set

From seed inputs, extract:
- Target category (what kind of system)
- Comparable products/tools (3–8)
- Feature set to analyze (5–12)
- Constraints and evaluation criteria

If comparable products are missing, propose candidates and ask the user to confirm.

### 2) Gather technical signals per product

For each comparable, collect high-signal evidence:
- Public repos (dependency manifests, lockfiles, Dockerfiles, CI configs)
- Job postings/tech stack pages
- Public docs (API docs, SDKs, webhook formats)
- Browser/network clues (headers, frameworks, bundles) when applicable

Record each claim with a source URL and access date.

### 3) Reverse-engineer main features

For each feature:
- Likely components involved (client/server/jobs/storage)
- Data flow (happy path + failure modes)
- State/data model (entities, IDs, sync strategy)
- Constraints (latency, scaling, consistency)

### 4) “Glue” analysis

Describe how pieces integrate:
- Auth model (OIDC/OAuth/session, tokens, scopes)
- Integration patterns (webhooks, polling, event streams)
- Messaging/async (queues, retries, idempotency)
- Storage/caching choices
- Observability (logs/metrics/traces)

### 5) Synthesize into recommendations

Using the brief’s constraints, produce:
- A recommended reference architecture
- A shortlist of technologies/libraries worth prototyping
- A set of PoCs to validate the riskiest technical assumptions

### 6) Output

Write one Markdown report using `assets/template.md`.
Only create files if the user asks (suggest `docs/research/technical/<slug>.md`).

## Output Quality Checklist

- Includes a per-product tech stack table with sources.
- Includes per-feature “how it works” sections (even if partly hypothesized).
- Clearly distinguishes **Verified** vs **Hypothesized**.
- Ends with concrete PoCs and next actions aligned to constraints.

## Examples

- “Use `technical-research` with `docs/briefs/coffee-online-store-research-brief.md` and my previous report; map how competitors implement checkout, subscriptions, inventory, and payments.”
- “Use `technical-research` (timebox 45 min): for 3 alternatives, infer stack + architecture using public signals and cite sources.”
- “Use `technical-research`: reverse-engineer how feature X likely works (data flow + components) and propose a reference implementation approach.”

