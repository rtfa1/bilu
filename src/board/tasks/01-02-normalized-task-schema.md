# Phase 01 — Normalized task schema

## Goal

Define the canonical internal record the CLI uses for rendering and editing.

## Checklist

- [ ] Define required fields: `id`, `title`, `status`, `priority`, `path`.
- [ ] Define optional fields: `description`, `kind`, `tags[]`, `depends_on[]`, `link`.
- [ ] Define ID derivation rules (from filename, from index entry, etc).
- [ ] Define how links/paths are represented in installed vs repo layout.

## Acceptance

- A stable schema is documented and referenced by all renderers.

