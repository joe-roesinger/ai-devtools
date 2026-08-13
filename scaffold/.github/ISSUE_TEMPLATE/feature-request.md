---
name: Feature request
about: Request a new feature, structured to match the feature-spec skill's fields — tag @claude in a comment once filed to have it drafted into a spec and implemented.
title: "[Feature] "
labels: enhancement
---

<!--
  These fields match scaffold/.claude/skills/feature-spec/SKILL.md's spec shape 1:1. Filling
  them in here means a @claude mention on this issue arrives as a structured spec instead of a
  vague request — see docs/research/remote-agents-2026.md §5-6 for why that matters for
  repeated feature work specifically.
-->

## What

<!-- What the feature does, in concrete behavioral terms. -->

## Why

<!-- The problem or need this addresses. -->

## Out of scope

<!-- What this feature deliberately does not do. Be explicit — this is what keeps an agent
     (and a reviewer) from over-generalizing into adjacent territory. -->

## Interfaces / files involved

<!-- What's touched, what's new, what existing code it calls into, if known. Leave blank if
     you want feature-spec / codebase-recon to determine this. -->

## Acceptance criteria

<!-- A concrete, testable list. These become the basis for the failing tests tdd-implement
     writes first. -->

-

---

Once filed, comment `@claude implement this feature` to have Claude run `feature-spec` (which
will also check whether the touched area already has `codebase-recon`/local-`CLAUDE.md` coverage,
and flag it if not) followed by `tdd-implement`.
