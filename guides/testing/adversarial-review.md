# Adversarial Review: Auditing an AI-Built Codebase

> Referenced from `rules/testing.md` (Reviewing an AI-Built Codebase). Most useful at Business tier and above, before any launch you care about, and as the solo developer's substitute for pull-request review.

## Why Tests Aren't Enough

Tests verify the failure modes you thought of. The defects that take down real systems — an authorization check that passes for the wrong device, two locks taken in opposite orders, a migration that crash-loops on restart — are precisely the ones nobody thought to write a test for. AI-generated code makes this worse in a specific way: it produces *plausible* code, so the bugs that remain are the plausible-looking ones that survive a casual read.

Adversarial review is a structured hunt for those defects. It works with AI reviewers, human reviewers, or both. Done with AI, it's also the compensating control for solo developers: the "second pair of eyes" that pull-request review would normally provide.

## The Method

### 1. Review by failure class, not "find bugs"

One generic "review my code" pass produces shallow, scattered findings. Instead, run separate passes, each hunting a single failure class across the whole system:

| Lens | The question it asks |
|------|----------------------|
| **Authorization** | Can caller A act as B? Are client-supplied IDs (device, session, team) verified as belonging to the authenticated principal? Do guards fail closed? |
| **Input validation** | Does untrusted input reach a path, allocation, or decoder before validation? Is anything trusted because it attests to itself? |
| **Concurrency** | Lock ordering, races between check and use, non-idempotent retries, shared mutable state |
| **Data durability** | Can user data silently vanish? Migration re-run safety, backup coverage, delete scope |
| **Failure handling** | Timeouts, retry storms, partial-failure recovery, what happens when each dependency dies |
| **Privacy / metadata** | What could a curious or subpoenaed operator read or infer — from logs, push payloads, retained columns? |
| **Accessibility** | Screen-reader coverage, keyboard paths, contrast, font scaling (see `rules/accessibility.md`) |
| **Performance / scale** | Unbounded growth, missing indexes, N+1, hot-path allocations |

Give each pass the project's own rules (this framework, plus your `PROJECT_PROFILE.md`) as its brief. A reviewer hunting one class goes deep; a reviewer hunting everything skims.

### 2. Verify findings before believing them

AI reviewers produce confident, detailed findings that are simply wrong — the code path doesn't exist, the guard they missed is two lines up, the race can't occur because of a lock they didn't see. In practice, expect a **double-digit percentage of raw claims to dissolve** when traced end-to-end against the source.

So verification is its own stage: for every claimed defect, trace the actual code path and either (a) confirm it with the concrete failure scenario — inputs, state, wrong outcome — or (b) discard it with a note. Only verified findings go on the worklist. Skipping this stage buries real defects in noise and burns your trust in the process.

### 3. Close every finding, or close it in writing

A review is finished when **every** finding — LOW severity included — is either fixed or explicitly closed with a written rationale ("accepted risk because X", "not applicable because Y"). Findings that silently expire were never really found. Severity determines *order*, not whether an item gets handled.

### 4. Field-verify what the code can't prove

For mobile and anything hardware- or timing-dependent, "code-complete" is not "closed." Re-verify HIGH findings on real devices: the screen reader actually announces the error, the reconnect actually backs off, the killed app actually recovers. Simulators and reasoning both lie about background execution, push delivery, and lifecycle.

## Practical Cadence

- **Before first launch:** one pass per lens that applies to your tier.
- **After a major feature:** the two or three lenses the feature touches (a sync feature → concurrency + durability + authorization).
- **Periodically:** a full-tree pass, one reviewer per subsystem, each briefed with the project's rules. This is the pass that catches cross-cutting drift — e.g., a newer subsystem that never adopted a check the older ones have.

Record every pass in an assurance register (see `appendices/assurance-register-template.md`): what it targeted, what it found, what's closed. That register is the evidence a buyer, auditor, or future maintainer actually asks for.

## Running It with an AI Agent

A workable prompt shape for each pass:

> "You are an adversarial reviewer. Your only goal is to find **[failure class]** defects in this codebase. Read the project rules first; they define what correct looks like. For each finding, give the file and line, the concrete failure scenario (inputs/state → wrong outcome), and a severity. Do not report style issues."

Then, separately — ideally in a fresh session so the reviewer's reasoning doesn't leak into the verifier:

> "Here is a claimed defect. Trace the actual code end-to-end and either CONFIRM it with the concrete failing path or REFUTE it with the specific line that prevents it. Default to refuted if you cannot demonstrate the failure."

The separation matters. A reviewer rewarded for finding things overclaims; a verifier rewarded for skepticism prunes. You want both.
