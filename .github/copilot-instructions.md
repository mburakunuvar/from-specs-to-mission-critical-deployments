# Project Guidelines

## Scope
- This is a static, single-page demo.
- Keep changes lightweight and portable. Do not add frameworks, build tooling, or architecture migrations.

## Architecture
- Main implementation is in [index.html](../index.html).
- Preserve the current script organization:
  - config constants and app state near the top
  - small rendering functions for SVG nodes and paths
  - animation logic separate from routing and state transitions
- Preserve SVG layer order so packets and labels stay above base elements.

## Build and Test
- No build step is required.
- No test runner is configured in this repository.
- Validate manually in a browser using [index.html](../index.html):
  - start or pause behavior works
  - failure simulation reroutes correctly
  - reset clears animations and visual state

## Conventions
- Use plain HTML, CSS, and vanilla JavaScript only.
- Prefer focused edits to existing functions over large rewrites.
- Keep routing deterministic and failure-aware: round-robin across healthy backends only.
- Keep flow explicit and accurate: Client -> Gateway -> Load Balancing -> Backend.
- Reuse existing SVG IDs, naming patterns, and helper utilities.

## Documentation
- Product and behavior requirements live in [prompting.md](../prompting.md).
- Keep this file short and actionable; link to source docs instead of duplicating specs.