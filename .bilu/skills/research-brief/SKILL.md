---
name: research-brief
description: Turn a rough technical idea into a structured handoff brief for a research agent (requirements, constraints, architecture sketch, unknowns, research questions, and evaluation plan).
metadata:
  short-description: Structure a technical idea into a research brief
---

# Research Brief

## Goal

Take a messy early technical idea and produce a crisp, actionable handoff brief that another agent can use to do deep research (prior art, existing tools, standards, feasible architectures, tradeoffs).

This skill is intentionally *not* business/market oriented. Avoid pricing, TAM, go-to-market, ROI, etc., unless the user explicitly asks.

## Operating Principles

- Keep it concrete: prefer requirements, interfaces, constraints, and measurable non-functional targets.
- Make uncertainty explicit: assumptions, unknowns, risks, and decision points.
- Preserve the user’s intent: don’t silently shift the problem.
- Ask questions sparingly: max 7 clarifying questions unless the user requests deeper discovery.
- Optimize for handoff: the output should be “research-agent ready” without extra back-and-forth.

## Workflow

### 1) Produce the Research Agent Brief

Produce only the “Research Agent Brief” section from the template

### 2) Clarify (optional)

Ask up to 7 questions only if answers materially change the plan. Prefer multiple-choice where possible.
If the user says “no questions”, proceed with explicit assumptions.

Focus questions on:
- Platform targets (web/mobile/CLI), runtime constraints, and deployment environment
- Integrations (APIs, auth, data sources), data sensitivity, and compliance constraints
- Performance/reliability targets and offline/latency expectations
- “Must-have” vs “nice-to-have” features

### 3) Produce the plan

Return one cohesive Markdown plan using `assets/template.md`.
Adapt sections to the domain; omit sections that don’t apply rather than filling with fluff.

## Output Quality Checklist

- Includes the “Research Agent Brief” that is copy/paste-able.

## Files

Only create files if the user asks. If asked, propose:
- `docs/briefs/<slug>.md`

## Examples

- “Use `research-brief`: I want a local-first note app with CRDT sync; make a research brief for libraries and architectures.”
- “Use `research-brief`: I want to build a web app that turns PDFs into structured JSON; create the research-agent brief.”
- “Use `research-brief`: Design options for a self-hosted SSO gateway; include threat model and evaluation plan.”
