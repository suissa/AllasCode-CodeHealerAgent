# Zig Debugger Backlog

> Temporary backlog created because GitHub Issues are currently disabled for this repository. Each section below is intended to become one GitHub issue when Issues are enabled.

## Current repository assessment

The repository is still structurally close to Microsoft `debug-gym`: a Python 3.12 framework with `RepoEnv`, terminal backends, tool registration, LLM agents, benchmark integrations, and a Python-specific interactive debugger implemented as `PDBTool`.

The strongest reusable parts for Zig are:

- `RepoEnv` interaction loop;
- `Toolbox` dynamic tool registration;
- terminal/session abstraction;
- `bash`, `view`, `edit`, `grep`, `listdir`, `eval`, `submit` tools;
- Docker/Kubernetes isolation;
- edit hooks and persistent debugger-session lifecycle;
- multi-model LLM backend support.

The main blocker is that interactive debugging is coupled to Python/PDB. The Zig transformation should preserve the generic gym/agent infrastructure while replacing Python-specific debugger semantics with a normalized debugger protocol and Zig-aware environment.

---

## Issue 1 — Introduce language-agnostic debugger backend interface

### Goal
Extract debugger lifecycle and normalized operations from `PDBTool` so Zig backends can be added without duplicating session logic.

### Scope
- Add `DebuggerTool` / `DebuggerBackend` abstraction.
- Extract start/stop/restart, persistent breakpoints, entrypoint handling, timeout handling, edit hooks and current-frame tracking.
- Normalize operations: run/continue, step, next, break, clear, backtrace, frame, locals, print, watch, source.
- Keep PDB compatibility through the new interface.

### Acceptance criteria
- Existing PDB tests keep passing.
- New backends register through `Toolbox`.
- Backend-specific syntax is hidden behind normalized operations when possible.

---

## Issue 2 — Implement LLDB backend for Zig

### Goal
Add an LLDB-based interactive debugger as the primary Zig debugger backend.

### Scope
- New `LLDBTool` using persistent shell sessions.
- Support breakpoints by `file:line` and symbol.
- Support continue, step, next, finish, backtrace, frame selection, locals, expression evaluation and watchpoints.
- Parse LLDB prompt/output into normalized observations.
- Restart cleanly after edits while restoring breakpoints/watchpoints.
- Allow configurable executable and arguments.

### Acceptance criteria
- Debug a small Zig binary end-to-end.
- Stop on a Zig source breakpoint.
- Inspect locals and call stack.
- Continue after inspection.
- Persist breakpoints across edit/restart.

---

## Issue 3 — Implement GDB backend as Linux fallback

### Goal
Provide GDB support for Linux environments where LLDB is unavailable or behaves differently.

### Scope
- `GDBTool` implementing the same normalized debugger backend contract.
- Breakpoints, stepping, stack, locals, expression evaluation and watchpoints.
- Normalize differences between LLDB and GDB observations.

### Acceptance criteria
- Same Zig fixture can be debugged with either LLDB or GDB.
- Agent configuration can select debugger backend without changing prompts/workflow.

---

## Issue 4 — Add Zig-aware repository environment and entrypoint discovery

### Goal
Teach the environment how Zig projects build, test and execute.

### Scope
- Detect `build.zig` / `build.zig.zon`.
- Discover common entrypoints:
  - `zig build`;
  - `zig build test`;
  - `zig test <file>`;
  - `zig run <file>`;
  - built executables under `zig-out/bin`.
- Add configurable debug build mode and arguments.
- Preserve repository-local Zig version metadata when available.

### Acceptance criteria
- Resetting a Zig task produces usable build/test/debug entrypoints.
- The environment can distinguish compile failure from runtime/test failure.

---

## Issue 5 — Parse Zig compiler diagnostics into structured observations

### Goal
Make compiler errors first-class debugging evidence instead of raw terminal text.

### Scope
Parse Zig diagnostics into fields such as:
- file;
- line/column;
- error class/message;
- notes;
- referenced symbols/types;
- compile command;
- Zig version.

Emit a normalized `CompilerDiagnosticObservation` consumable by the agent.

### Acceptance criteria
- Multi-note Zig compiler errors are preserved structurally.
- File/line locations are machine-addressable.
- Agent can jump directly from diagnostic to `view`/debug context.

---

## Issue 6 — Normalize Zig runtime crashes, panics and stack traces

### Goal
Turn Zig runtime failures into structured evidence suitable for CodeHealer reasoning.

### Scope
- Detect panic, assertion failure, integer overflow, bounds violation, unreachable, allocator failure and signal-based crashes where possible.
- Parse source frames and stack traces.
- Preserve stderr/stdout separately.
- Link runtime failure to current build artifact and source revision.

### Acceptance criteria
- Runtime failure produces a structured failure signature.
- Same failure can be compared across repair attempts.
- Stack frames reference source files/lines when debug symbols exist.

---

## Issue 7 — Add Zig debugging commands for memory, pointers and allocators

### Goal
Expose the failure classes that matter most in systems-level Zig debugging.

### Scope
Normalized capabilities for:
- pointer/address inspection;
- slices and lengths;
- optional/error unions;
- memory region inspection;
- watchpoints;
- allocator-related state where observable;
- thread listing and selection.

### Acceptance criteria
- Agent can inspect a slice/pointer bug without issuing raw LLDB/GDB syntax.
- Unsafe or unsupported evaluations fail explicitly rather than corrupting the session.

---

## Issue 8 — Create Zig-specific CodeHealer agent prompt and minimal tool harness

### Goal
Specialize the agent for Zig debugging rather than generic code generation.

### Scope
- Add a Zig-specific system prompt/config.
- Prefer inspect → reproduce → localize → hypothesize → patch → verify.
- Require execution evidence before declaring success.
- Minimize tool surface for small coder models.
- Keep implementation strategy supplied by CodeManager separate from patch generation.

### Proposed default tool set
- `view`
- `grep`
- `debugger`
- `edit`
- `eval`
- `submit`

### Acceptance criteria
- Agent does not propose success without executing validation.
- Debugger evidence is referenced in the repair trajectory.

---

## Issue 9 — Add Behavior-first validation boundary for CodeHealer

### Goal
Ensure CodeHealer implements a required behavior rather than overfitting to visible tests.

### Scope
- Accept a `BehaviorSpec` alongside the repair request.
- Distinguish public validation criteria from hidden tests.
- Do not expose hidden test source/input cases to the CodeHealer model.
- Allow an independent TestDesigner model to generate hidden regression/property tests before patch generation.

### Acceptance criteria
- Patch model cannot read hidden tests.
- Validation reports behavior-level failures, not only test names.
- A successful patch must satisfy BehaviorSpec + hidden validation.

---

## Issue 10 — Build a Zig bug fixture suite and debugger benchmark

### Goal
Create a reproducible benchmark for measuring whether the agent is becoming a good Zig debugger.

### Initial fixture categories
- compile-time type mismatch;
- comptime misuse;
- error-union handling bug;
- optional unwrap failure;
- bounds violation;
- integer overflow;
- allocator/leak misuse;
- use-after-lifetime pattern where detectable;
- concurrency/race-oriented scenario where tooling permits;
- incorrect build.zig configuration;
- C ABI/interoperability bug;
- logic regression that compiles but fails behavioral tests.

### Required metadata per fixture
- bug ID;
- Zig version;
- failing behavior;
- reproduction command;
- expected debugger evidence;
- gold causal location;
- gold patch kept hidden from the agent.

### Acceptance criteria
- Benchmark runs unattended in Docker.
- Reports first-attempt success and attempts-to-success.

---

## Issue 11 — Add multi-model coder fallback and per-model healing metrics

### Goal
Measure which coding model minimizes failed repair attempts for Zig.

### Scope
For each attempt record:
- model ID/version;
- tokens;
- latency;
- cost if available;
- compile result;
- public test result;
- hidden test result;
- invariant result;
- attempts-to-success;
- failure signature;
- patch hash.

On failure, route the next attempt to another coder model with the previous failed patch and validation evidence as NegativeKnowledge.

### Acceptance criteria
- Produce model ranking by Zig failure category.
- Track `first_attempt_success_rate`, `mean_attempts_to_success`, `compile_failure_rate`, `regression_rate`, and `cost_per_success`.

---

## Issue 12 — Add Zig debugger Docker image and CI end-to-end coverage

### Goal
Make Zig debugging reproducible in CI.

### Scope
- Pin Zig 0.16 toolchain.
- Install LLDB and GDB.
- Preserve debug symbols.
- Add CI jobs for compiler-diagnostic parsing, LLDB, GDB, edit/restart persistence and benchmark smoke tests.
- Verify Linux as the primary supported interactive-debug platform.

### Acceptance criteria
- CI proves a Zig fixture can be built, debugged, edited, rebuilt and validated.
- Failures upload useful debugger/agent trajectory artifacts.

---

## Suggested implementation order

1. Debugger abstraction
2. Zig environment/entrypoints
3. LLDB backend
4. Compiler/runtime diagnostic normalization
5. GDB fallback
6. Zig-specific prompt/harness
7. Fixture benchmark
8. CI image
9. Behavior-first hidden validation
10. Model-routing metrics
11. Advanced memory/thread tooling

## Architectural principle

The CodeHealerAgent should become a Zig debugging and patch-generation specialist, not the owner of repair strategy. The upstream CodeManagerAgent defines and validates the `RepairPlan`; CodeHealer receives the expected behavior, constraints and implementation standards, gathers debugger evidence, and materializes the approved strategy as a patch.