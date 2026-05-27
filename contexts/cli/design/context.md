# CLI Design for Agents

Agent instructions for designing or refactoring CLIs. Apply when generating a new CLI or auditing an existing one. Output a compliant CLI on first attempt.

In scope: command-based CLIs with subcommands, flags, and well-defined output.

Out of scope: TUI / full-screen apps, GUI apps, REST or GraphQL API design only, shell scripting helpers.

## Core stance

Agents are first-class consumers, not a tolerated secondary audience. The CLI you produce serves agents first; humans benefit from the same design.

Each command operates in three independent runtime modes: interactive mode (whether interactive prompts are allowed, gated on stdin), decoration mode (whether ANSI escapes, spinners, and progress are allowed in stdout, gated on stdout), and output mode (text mode by default; JSON mode via `--json` for parsing). The same command serves both audiences from one code path. See "TTY detection and environment signals" under Cross-cutting for the full list of triggers and rules.

Enforce these rules mechanically — schema-first generation for large CLIs, CI lints for smaller ones. See "Schema-first generation" under Cross-cutting. Manual review is unreliable.

## Priority tiers

Treat these rules as a guide, not a contract. Every CLI is different — drop, adapt, or extend as the command requires. The verb strength (MUST/SHOULD/MAY) and tier (P0/P1/P2) below signal how much room each rule leaves.

Rules are tiered P0, P1, P2.

- P0: without these the agent breaks. Treat violations as blockers.
- P1: without these the agent works inefficiently. Treat violations as friction.
- P2: without these the CLI works fine. Treat violations as optimization opportunities.

Severity scales with command type. Idempotency is a blocker for mutations and irrelevant for streaming. Apply rules where they make sense for the command at hand.

Verbs MUST, SHOULD, MAY follow RFC 2119 semantics.

## P0 — Critical

### 1. Non-interactive by default with wizard fallback in interactive mode

A command MUST never hang waiting for input. Whether the CLI may prompt depends on interactive mode; whether it may decorate output depends on decoration mode. The two are independent — see "TTY detection and environment signals" under Cross-cutting for the full rules.

- Interactive mode on, missing required input: prompt for it (wizard).
- Interactive mode off, missing required input: fail fast with stderr listing the missing flags by name. Exit code 2.
- `--no-input`, `--json`, `<CLI>_NO_INPUT=1`: never prompt regardless of stdin.

The same command serves both audiences. The agent passes complete flags and gets a deterministic response; the human at a terminal gets a guided wizard for the missing pieces.

Never prompt for secrets, even in interactive mode. Read secrets from env, file, or stdin only.

### 2. Token-efficient default output

Default output (without `--json`) is the priority output mode. Agents read it directly far more often than they parse JSON; humans read it always. Lean prose, scannable structure, minimal decoration.

- Lead with the answer. No preamble, no banners, no restating of the command the user just ran.
- Pick the format that fits the data — prose for narrative answers, aligned label-value pairs for a single resource, indented hierarchy for nested results, tables for genuinely tabular data.
- Convey structure through whitespace, indentation, and alignment. Avoid literal markdown syntax (`**bold**`, `# heading`, `---` rules), emoji, and box-drawing characters — they cost tokens and most terminals render them as noise. Use ANSI escapes for emphasis only when decoration mode is on, and only sparingly.
- No structural overhead. `Project: CW` rather than `{"project":"CW"}`. JSON wraps every value and key in quotes, separates with commas and braces; default output strips that out.
- For lists, skip per-row labels — a header row or no labels at all beats repeating `Project: X` on every line.
- Empty values render empty. No `null`, no `(none)`, no `-`. The whitespace is unambiguous.
- One blank line maximum between sections. Stacked blank lines are pure waste.
- Surface counts and bounds inline (`Showing 1-1 of 3,352 results`) so the reader knows where they are.
- End with the next concrete action when one exists (`(--next <token>)`).
- Same information, fraction of the tokens. That fraction is the win.

`--json` exists for parsing, not as the default. An agent reaches for it when iterating a list, extracting an ID, or branching on `status`. Everything else, default output wins on tokens and readability.

### 3. Structured output (JSON mode)

When the caller opts into JSON mode with `--json`, every data-returning command MUST emit a wrapped envelope with the same outer shape on success and failure so the agent parses once and branches on `status`.

Success:

```json
{"status":"ok","data":{"id":"post_8f2a","title":"Hello"}}
```

Failure:

```json
{"status":"error","error":{"code":"AUTH_EXPIRED","message":"API token has expired","fix":"<cli> auth refresh","transient":false}}
```

Warnings are optional and used for non-fatal conditions the agent can act on programmatically (deprecated flags, partial success on batch operations). Omit the `warnings` key entirely when empty. When present, each entry has the same shape as an error minus `transient` and `valid_values`:

```json
{"status":"ok","data":[{"id":"post_a"},{"id":"post_b"}],"warnings":[{"code":"FLAG_DEPRECATED","message":"--max-results is deprecated, use --limit","fix":"<cli> posts list --limit=10"}]}
```

Rules around the envelope:

- stdout carries only the JSON envelope. Nothing else.
- stderr carries diagnostics, prompts, progress, log lines, debug output.
- Parsers MUST ignore unknown fields anywhere in the response — at the envelope root and inside `data`, `error`, and `warnings` entries. This is the contract that makes additive changes (Rule 12) and `--verbose` field additions (Rule 9) safe; an agent that fails on unrecognised keys converts every minor version bump or verbose invocation into a break.
- ANSI escape codes never appear in stdout when decoration mode is off.
- Paginated responses include `next` at the envelope root (sibling to `data`) as an opaque cursor token. Omit `next` when no more pages exist:

```json
{"status":"ok","data":[{"id":"post_a"},{"id":"post_b"}],"next":"eyJvZmZzZXQiOjJ9"}
```
- Streaming responses (`--follow`, `--watch`, or continuous data) emit NDJSON: one envelope per line. `--follow` is append-only; each line is the next data record. `--watch` is a resource-change stream; CLIs supporting it MUST document the event shape (initial-state replay behaviour, per-event fields, reconnect/resume semantics) in `<cli> help schemas`.
- A `-` value means stdin or stdout depending on context.
- Document the envelope shape under `<cli> help schemas`. Do not repeat it everywhere.
- Commands with binary payloads route bytes via `--output` rather than stdout when `--json` is set. See Rule 14.

Pagination cursors:

- Cursors are short-lived. Valid for at least a normal traversal session (minutes), not guaranteed beyond an hour, never across sessions. Agents MUST NOT persist cursors across long pauses or store them in profiles or config.
- An expired or invalid cursor returns error code `CURSOR_INVALID` with exit code 5 and `transient: false`. The `fix` field instructs the agent to restart the traversal from the beginning. Exit 5 (Conflict) signals the underlying state moved out from under the cursor; exit 2 is reserved for argument mistakes the caller authored, and exit 75 is wrong because retrying with the same cursor fails the same way.
- Cursors are bound to the query that produced them. Reusing a cursor from one query against a different filter, sort, or fields selection is undefined behaviour and SHOULD return `CURSOR_INVALID`.

### 4. Semantic exit codes

Use this taxonomy:

| Code | Meaning | Action implied |
| --- | --- | --- |
| 0 | Success | Continue |
| 1 | General failure | Do not retry blindly |
| 2 | Usage error | Fix arguments and retry |
| 3 | Resource not found | Surface to user |
| 4 | Permission denied | Authenticate or escalate |
| 5 | Conflict | Current resource state prevents the operation. Examples: version mismatch on `update`, a `create` where an existing resource differs from the request (see Rule 8), or a `CURSOR_INVALID` response when the underlying state moved out from under a pagination cursor (see Rule 3). Re-fetch state and retry |
| 75 | Transient failure | Retry with backoff |
| 78 | Configuration error | User must fix config |

Code 75 is the explicit retry signal. The agent uses it to decide whether automatic retry is worthwhile. Document the exit codes used by the CLI under `<cli> help schemas`.

### 5. Errors that teach and enumerate

Every error MUST carry four elements:

- `code`: UPPER_SNAKE_CASE machine-readable identifier. Codes are domain-bare (`AUTH_EXPIRED`), not CLI-prefixed. The agent learns the namespace from `<cli> help schemas`.
- `message`: human-readable one-line summary.
- `fix`: concrete next command or action.
- `transient`: retry hint matching exit code 75.

When validation rejects a value against a known set, include `valid_values` listing what would have been accepted. Use cases include enum literals (public, private, unlisted), scheme prefixes (stdout, file:, webhook:, http://), accepted formats (RFC 3339, Unix timestamp), or any closed set the agent can pick from. Omit when the accepted set is open or not enumerable:

```
Error: --visibility must be one of: public, private, unlisted
  Code:     INVALID_VISIBILITY
  Accepted: public, private, unlisted
  Fix:      <cli> post create --visibility=public --content=...
```

Validate inputs before side effects fire. An error after a resource is created is harder to recover from than an error before.

Rate limiting:

Rate-limit failures use the canonical code `RATE_LIMITED` with exit code 75. When the upstream exposes a retry-after value, include it as an optional `retry_after` field using the duration grammar defined under Cross-cutting (single segment like `30s` or compound like `1h30m`). Agents use `retry_after` when present and fall back to exponential backoff when absent.

```
Error: API rate limit exceeded
  Code:        RATE_LIMITED
  Retry after: 30s
  Fix:         wait 30s and retry
```

### 6. Bounded output

List-style commands MUST default to a bounded result set. Default `--limit` is in the low tens (10 to 25 is typical). Unbounded output is a blocker for routine commands.

When truncating, the response includes:

- Total count if cheap to compute, surfaced inline in the response.
- A `next` cursor token — shown inline as `(--next <token>)` in text, at the envelope root in JSON (see Rule 3).

Cursor-based pagination via `--next` is the rule. Offset-based pagination drifts when underlying data changes during traversal and is forbidden for mutating data sets.

Support `--fields` on data-bearing commands so the agent requests only the columns it needs.

When wrapping the CLI as an MCP tool, treat tool descriptions as a token budget. A bloated description costs every agent on every call. Target ~50 tokens (roughly 200 characters of plain English) per tool description; agents see the description on every tool listing.

### 7. Output guides the next action

Every success or failure response MUST suggest what to do next.

- On success: include identifiers and the next-step commands the agent or human is likely to run.
- On failure: include the `fix` element defined in Rule 5.
- On partial result: include the `next` token defined in Rule 6.

The agent reads the output, sees the suggested invocation, and continues without guessing or hallucinating commands.

### 8. Safe retries and explicit mutation boundaries

Mutating commands MUST be safe to retry.

- `create` operations are idempotent. The outcome depends on whether a matching resource already exists:
  - No existing resource: create it. Exit 0.
  - Existing resource matching the request: return the resource with an `existing: true` indicator. Exit 0.
  - Existing resource differing from the request: do not modify it. Exit 5 with error code `CONFLICT`. The caller must `update` (or `delete` and re-`create`) deliberately.

  "Matching" means every field the caller supplied equals the corresponding field on the existing resource. Server-managed fields (IDs, timestamps, computed defaults) are not part of the comparison.
- `update` operations are idempotent on the same input.
- `delete` operations on already-deleted resources return exit 0 with a warning of code `ALREADY_DELETED`. The response describes the resource as it last existed, or omits it if the CLI keeps no tombstone.
- Destructive operations require an explicit non-default flag. `--force` is the canonical bypass.
- Every consequential mutation MUST support `--dry-run`. With `--dry-run`, the response describes what would happen without applying the change. Trivial mutations (e.g., appending to a feedback log) are exempt. For async submitters (Rule 11), `--dry-run` MUST validate input locally and return the would-be request; it MUST NOT submit a job to the upstream system or write a ledger entry.

For long-running async operations, retry safety extends across the submit-poll-collect arc. See Rule 11.

## P1 — High

### 9. Cross-CLI vocabulary consistency

The agent generalises from every CLI it has seen. A non-conforming CLI succeeds slowly with extra retries and burned tokens.

Canonical verbs:

| Use | Never as canonical |
| --- | --- |
| get | info, show, describe |
| list | ls, all, find |
| create | add, new, make |
| update | edit, modify |
| delete | rm, remove, destroy |
| run | exec, do |
| status | health, state |

Core flags:

| Use | Never as canonical |
| --- | --- |
| --json | --format=json, --output=json |
| --force | --skip-confirmations, --no-confirm, --yes-to-all, --yes |
| --no-input | --non-interactive |
| --dry-run | --plan, --preview, --simulate |
| --quiet | --silent |
| --verbose | — |
| --help | — |
| --version | — |

Data-shape flags:

| Use | Never as canonical |
| --- | --- |
| --limit | --max-results, --count, --max |
| --next | --page, --offset, --cursor |
| --fields | --columns, --select |
| --filter | --where, --query |
| --since | --from, --start-time, --after |
| --until | --to, --end-time, --before |

Operational flags:

| Use | Never as canonical |
| --- | --- |
| --config | --config-file, --conf |
| --debug | --trace, --diagnostics |
| --color | --colour, --ansi |
| --recursive | --recurse, --tree |
| --follow | --tail |
| --watch | --observe, --subscribe |
| --output | --out, --destination, --write-to, --save-to, --target |
| --profile | --config-name, --env-name |
| --wait | --block, --sync |
| --timeout | --time-limit, --max-duration, --deadline |

Subcommand groups when the rule applies:

| Group | Subcommands |
| --- | --- |
| auth | login, logout, status, refresh |
| jobs | list, get, cancel, prune, repair |
| profile | save, use, list, get, delete |
| feedback | (root verb takes a string), list |

Auth semantics:

- `auth login` initiates authentication. May open a browser in interactive mode; otherwise requires credentials via env, file, or stdin (see Secrets handling).
- `auth logout` clears local credentials. Idempotent — logout when already logged out returns 0.
- `auth status` reports the current authentication state. Exit 0 with the authentication state surfaced as `authenticated: true|false`. The authenticated form includes identity and expiry; the unauthenticated form includes a `reason` explaining why (no token, expired, revoked). Exit 4 if `auth status` itself cannot run because the credentials store is unreadable (filesystem permissions, OS keychain access denied); exit 78 only when the store is structurally invalid (malformed config, unknown schema).
- `auth refresh` renews an expiring token without re-authenticating. Exit 0 on success, exit 4 if refresh fails.

Notes that travel with the table:

- `--debug` enables diagnostic logging on stderr only. Never affects stdout regardless of mode.
- `--verbose` adds detail to stdout. In text mode, more fields or lines appear on the rendered output. In JSON mode, the additional detail appears as extra fields on `data`; the envelope shape is unchanged, so existing parsers that ignore unknown fields (Rule 3) keep working.
- `--debug` and `--verbose` are different flags and may be set together.
- `--color` values are auto (default, follows stdout per decoration mode), always, never. `NO_COLOR` overrides everything including `--color=always`.
- Prefer enum values (`--color=never`) over negation flag pairs (`--no-color`).
- `--quiet` suppresses non-error output. Stdout emits requested data only; stderr emits errors only; warnings, progress, and informational output are dropped.
- When `--quiet` and `--json` are both set, `--json` governs stdout — the full envelope is emitted including any warnings. `--quiet` only suppresses stderr informationals.
- Absolute times on `--since` and `--until` use RFC 3339 (`2026-04-30T18:22:11Z`); relative times use the duration grammar (see Cross-cutting).
- `--timeout` takes a duration value (see Cross-cutting) and is paired with `--wait` (Rule 11).

Aliases:

The CLI MAY expose any name from the Never column as an alias of the canonical for muscle memory or backward compatibility, with one constraint: an alias must point to a canonical that performs the same conceptual operation. `ls` aliasing `list` is fine. `ls` aliasing `delete` is not. Aliases live in `--help` only — they do not appear in the agent help reference.

Short forms:

Short single-letter flags exist as 1:1 aliases of long flags, never independent. The CLI maintainer binds short letters per CLI domain — the same letter may mean `--limit` in one CLI and `--list` in another, so no cross-CLI bindings are prescribed here. Agents emit long forms by default and only use short forms when documented in the CLI's `--help`. Capital-letter short forms (e.g., `-r` and `-R`) are acceptable only for semantically related or inverse pairs, never as a generic disambiguation tactic.

Singular vs plural noun forms:

Pick one form (singular or plural) for the CLI's resource namespaces and use it consistently across every command. Always alias the other form so both invocations resolve to the same handler. Lean singular as the default — it composes more naturally with single-resource verbs (`post get <id>`).

Domain-specific verbs (publish, deploy, render) stay domain-specific. Name them consistently within the CLI and document them once in the agent help reference.

### 10. Three-layer introspection

The CLI MUST expose three audience-specific introspection layers.

Layer 1: `<cli> --help` and `<cli> <subcommand> --help`. Human prose. Lists the surface, shows usage, includes 2–3 examples per subcommand. Aliases appear here, not elsewhere.

Layer 2: `<cli> help agents`. Token-efficient markdown reference for agents. Compact, example-heavy. Includes:

- Schema version present in the first line of the document, either as a title suffix (e.g., `# <cli> agent reference (Schema: v1.0)`) or a standalone leading line. Format is `<major>.<minor>` matching `<cli> --schema-version` (Rule 12). Minor version bumps on additive changes; major version bumps on breaking changes.
- Defaults and the env vars that set them.
- Stdin sentinel reminder when relevant.
- One-liner on when to use `--json` (only when parsing structured output).
- Common invocations grouped by resource — code blocks with realistic flags.
- Output conventions worth knowing (e.g., "comment IDs shown as `[date] [id] Author:`").
- Available profiles on one line, if any. Up to 10 names; when more exist, the first 10 followed by `... +<n> more (see <cli> profile list)`.
- Whether the upstream feedback endpoint is configured, on one line.
- Skill path on one line, if SKILL.md is shipped.
- Cross-references to `<cli> help schemas` and any `<cli> help <topic>` pages.
- Less-common commands listed by name only with a `<cmd> --help` pointer to keep the reference compact.

On first encounter with an unfamiliar CLI, the agent SHOULD read `<cli> help agents` before invoking commands. The reference is the entry point; everything else is fetched on demand.

Sample shape for `<cli> help agents`:

````
# <cli> agent reference (Schema: v1.0)

- Defaults: <CLI>_PROJECT, <CLI>_BOARD
- `-f -` reads body from stdin
- See `<cli> help schemas`, `<cli> help <topic>`
- Profiles: my-podcast, client-demo
- Feedback: configured
- Skill: /usr/share/<cli>/skills/SKILL.md
- Use --json only when parsing

## Core commands

```
<cli> issue list
<cli> issue list --limit 10 --status "In Progress"
<cli> issue create --subject "Title" --file description.md
echo "..." | <cli> issue create --subject "Title" --file -
```

## Other commands

Run `<cmd> --help` for usage.

- Auth: status, refresh, login, logout
- Project: list
- Issue meta: clone, delete, watch
````

Layer 3: `<cli> help schemas`. JSON output shapes for the cases the agent needs to parse. The wrapped envelope, exit codes, error codes, and pagination response shape are documented here once. Text-mode output conventions live in Layer 2 (`help agents`) — they're prose, not schema.

Domain topics: `<cli> help <topic>` for reference material the agent fetches on demand (formatting conventions, query languages, etc.).

Long-form skill manifest: `SKILL.md` shipped alongside the CLI source, exposed via `<cli> help skill` or `<cli> skill-path`. Long-form prose teaching the agent how to compose operations into useful workflows. No prescribed structure.

### 11. Async-aware execution

A command that submits an asynchronous job MUST support `--wait`, which blocks until the job completes and returns the final result in the same shape as the synchronous case. `--wait` MUST pair with `--timeout <duration>` defaulting to 10 minutes. On timeout, exit code 75 is returned with the job ID in the response so the agent can resume polling later.

Without `--wait`, the response includes the job ID and status. The agent can poll, but the recommended path is to let the CLI handle polling with backoff and jitter behind `--wait`.

Async state lives in a persistent ledger at `$XDG_STATE_HOME/<cli>/jobs.jsonl` (default `$HOME/.local/state/<cli>/jobs.jsonl` when the env var is unset). One JSON record per line:

```json
{"job_id":"job_8f2a","kind":"video.render","status":"complete","submitted_at":"2026-04-30T18:22:11Z","started_at":"2026-04-30T18:22:13Z","completed_at":"2026-04-30T18:22:48Z","duration_s":35,"result":{"url":"https://.../out.mp4"}}
```

The CLI MUST expose `<cli> jobs list`, `<cli> jobs get <id>`, `<cli> jobs cancel <id>`, `<cli> jobs prune`, and `<cli> jobs repair`. `jobs prune` removes completed and failed records older than 30 days by default; `--older-than <duration>` and `--status <status>` narrow the scope. `jobs repair` is the recovery path for a corrupted ledger (see below) and is kept distinct from `prune` so its semantics never overlap with age- or status-based removal. The ledger lets a `--wait` invocation killed mid-poll find its existing job on retry rather than submitting a duplicate.

On SIGINT during `--wait`, the CLI exits 130 (128+SIGINT); on SIGTERM, exit 143 (128+SIGTERM). The job ID is written to stderr in both cases. The upstream job continues running; the ledger entry remains marked in-progress. Resuming is an explicit action — the agent re-invokes `--wait` against the same job ID to continue polling, or `<cli> jobs cancel <id>` to stop the work. Exit 75 is reserved for transient failures the caller MAY retry automatically; signal interrupts are the user's intent and MUST NOT be conflated with that signal.

Ledger durability:

- Concurrent invocations on the same host MUST NOT corrupt the ledger. Implementations append in a way that is safe against other invocations writing at the same time.
- The ledger is a per-host artifact. It MUST NOT be assumed shareable across hosts, even when `$XDG_STATE_HOME` resolves to a networked filesystem.
- Reader tolerance. `jobs list`, `jobs get`, and `jobs prune` MUST skip malformed lines, emit a stderr warning naming the line number, and continue. A corrupted ledger is degraded but usable.
- Recovery. `<cli> jobs repair` rewrites the ledger keeping only valid lines, replacing the original atomically.

### 12. Contract stability

The CLI's existing surface is a contract. Once shipped, every flag name, subcommand name, exit code meaning, default text output structure, and JSON envelope field is part of that contract.

Additive changes are always safe:

- Adding a new flag with a default that preserves existing behaviour.
- Adding a new field to default text output (preserving existing fields).
- Adding a new optional field to the JSON envelope.
- Adding a new subcommand.
- Adding a new exit code for a case that previously returned 1.
- Adding `--json`, `--fields`, `--quiet`, `--dry-run` where they did not exist.

Breaking changes require a major version bump:

- Removing or renaming a flag, subcommand, or env var.
- Changing the meaning of an existing exit code.
- Removing or renaming a field in default text output.
- Removing or renaming a JSON envelope field.
- Changing default behaviour of an existing command.
- Changing positional argument order.

The `Schema:` version on the first line of `<cli> help agents` records the consequence: any additive change MUST bump the minor version; any breaking change MUST bump the major version. The bump records the surface change; it is not itself the change.

Agents that need to gate behaviour on schema version MUST be able to query it programmatically. The CLI MUST expose `<cli> --schema-version` returning the value as `<major>.<minor>` in text mode and at `data.schema` in JSON mode, matching the value that appears in `<cli> help agents`. Regex-extracting from the prose document is fragile and forbidden as the agent's primary path.

When deprecating, emit a stderr warning on the old form and keep it working through one major version.

When in doubt, add. Do not modify.

## P2 — Compounding

### 13. Persistent identity through profiles

Agents come back across sessions with the same intent and different specific input. Stateless commands that re-specify the same flags every invocation waste tokens.

The CLI MUST expose:

- `<cli> profile save <name> [flags...]` — saves a named bundle of flag values.
- `<cli> profile use <name>` — sets the active profile for subsequent invocations.
- `<cli> profile list` — lists saved profiles.
- `<cli> profile get <name>` — shows the contents of a profile.
- `<cli> profile delete <name>` — removes a profile.
- `--profile <name>` as a persistent root flag that overrides the active profile for one invocation.

Profile storage: `$XDG_CONFIG_HOME/<cli>/profiles.json` (default `$HOME/.config/<cli>/profiles.json`).

`profile save` MUST refuse to persist any flag the CLI documents as carrying secrets, and SHOULD exclude `--token-file` and similar credential-source flags by default. Profile storage uses normal file permissions and is not a secrets store.

Available profile names appear in `<cli> help agents` so the agent discovers identities without reading config files. Up to 10 names appear inline; surplus profiles are reachable via `<cli> profile list`.

### 14. Two-way I/O

Output destinations. The `--output` flag accepts scheme-prefixed values that route the artifact to where it is needed:

| Value | Behaviour |
| --- | --- |
| `stdout` or `-` | emit to stdout |
| `file:<path>` or bare path | write atomically to the file (write to temp, then rename) |
| `webhook:<url>` or `http(s)://<url>` | POST the payload to the URL; surface HTTP status in the response |
| (CLI-defined) | e.g., `s3:<bucket>/<key>`, `gs://<bucket>/<key>` |

Unknown schemes return a structured error listing the supported set.

Binary output. Commands producing binary payloads (downloads, renders, exports) MUST require `--output` to specify a destination when `--json` is set. Under `--json`, the response describes the artifact but does not embed the bytes. Common fields (`id`, `bytes`, `sha256`, `content_type`) appear regardless of destination. A `destination` object carries scheme-specific fields:

```
ID:           blob_8f2a
Bytes:        4815162342
SHA256:       a1b2...
Content type: application/octet-stream
Destination:  file ./out.bin
```

Destination shapes:

| Scheme | Required `destination` fields |
| --- | --- |
| `file` | `scheme`, `path` |
| `webhook` / `http(s)` | `scheme`, `url`, `http_status` |
| `stdout` | `scheme` only |
| CLI-defined | `scheme` plus the fields documented in `<cli> help schemas` |

Without `--json`, default behaviour is preserved (binary to stdout if no `--output` given, or to the destination if specified). When `--json` is set and `--output` is omitted on a binary-producing command, fail fast with exit 2 and error code `OUTPUT_REQUIRED`, listing supported schemes in `valid_values`.

Feedback channel. The CLI SHOULD expose:

- `<cli> feedback "<text>"` — records the entry as one JSONL row at `$XDG_STATE_HOME/<cli>/feedback.jsonl`. Record shape: `{"timestamp":"<RFC 3339>","text":"<message>","cli_version":"<semver>","command_context":"<last invocation, optional>"}`.
- `<cli> feedback list` — lists local feedback entries.

When the env var `<CLI>_FEEDBACK_ENDPOINT` is set to a URL, the CLI also POSTs the entry upstream and surfaces the HTTP status in the response. Whether the upstream channel is configured appears in `<cli> help agents`.

Friction observed by agents — flags rejected for the wrong reason, ambiguous error messages, race conditions in async paths — flows back to the maintainer through this channel.

## Cross-cutting

### TTY detection and environment signals

Two independent runtime modes are detected from the environment.

Interactive mode (whether prompts are allowed) is on when stdin is a terminal AND none of `--no-input`, `--json`, `<CLI>_NO_INPUT=1` are set. Otherwise off.

Decoration mode (whether ANSI escapes, spinners, progress bars are allowed in stdout) is on when stdout is a terminal AND none of `NO_COLOR`, `--color=never`, `TERM=dumb`, `--json`, `--quiet` are set. Otherwise off. `NO_COLOR` overrides `--color=always` per the published spec.

The `CI` environment variable is intentionally not consulted. CI environments suppress prompts and decoration via the absence of a TTY on stdin/stdout, which is reliable; reading `CI=true` is not (developers commonly export it for unrelated reasons). CI configurations that allocate a PTY MUST set `--no-input` or `<CLI>_NO_INPUT=1` explicitly.

`--quiet` controls output volume; it suppresses decoration but does not affect interactive mode. A human running an interactive command with `--quiet` still gets prompted for missing input.

Decoration-off rules:

- No ANSI escape codes anywhere in stdout.
- No spinners, no progress bars, no animated output.
- Diagnostics and structured progress (if any) go to stderr only.

Interactive-off rules:

- No prompts. Missing required input fails fast per Rule 1.

### Configuration precedence

Highest priority first:

1. Explicit flag on the command line.
2. Environment variable specific to the CLI.
3. Profile selected via `--profile`.
4. Active profile from `profile use`.
5. Project config file (e.g., `.<cli>.yaml`). Walk from CWD upward until a `.<cli>.yaml` (or `.<cli>.yml`) is found, or until reaching `$HOME` or a filesystem root, whichever comes first. The first file found wins; ancestor files are not merged.
6. User config file at `$XDG_CONFIG_HOME/<cli>/config.yaml`.
7. Built-in default.

XDG path defaults when the env vars are unset:

- `$XDG_CONFIG_HOME` is `$HOME/.config`
- `$XDG_STATE_HOME` is `$HOME/.local/state`
- `$XDG_CACHE_HOME` is `$HOME/.cache`

Use config for user-owned settings (profiles, preferences), state for runtime-derived data (jobs ledger, feedback log), cache for transient regenerable data.

### Environment variables

CLI-specific env vars use the form `<CLI>_<NAME>` where `<CLI>` is the uppercase command name and `<NAME>` is SCREAMING_SNAKE_CASE. Examples: `MYCLI_API_TOKEN`, `MYCLI_PROJECT`, `MYCLI_NO_INPUT`, `MYCLI_FEEDBACK_ENDPOINT`.

Standard cross-CLI env vars (`NO_COLOR`, `TERM`, `XDG_*`, `HOME`) keep their published names without the `<CLI>_` prefix. Do not shadow them with CLI-prefixed parallels.

Boolean env vars accept `1`, `true`, `yes` (case-insensitive) as truthy and `0`, `false`, `no` (case-insensitive) or unset as falsy. Any other value is a configuration error (exit 78).

### Duration values

Every flag or field that accepts a duration uses one grammar: one or more `<n><unit>` segments where `<n>` is a positive integer and `<unit>` is `s`, `m`, `h`, or `d`. Segments MUST appear in descending unit order (`d`, `h`, `m`, `s`) and each unit MUST appear at most once. Examples: `30s`, `5m`, `2h`, `7d`, `1h30m`, `2d12h`.

- Mixed orderings (`30m1h`) and repeated units (`1h2h`) are usage errors (exit 2).
- `0` is reserved to mean "no limit" or "instant" depending on context. The CLI documents the semantics per flag.
- Applies to `--timeout`, `--since`/`--until` (relative form), `retry_after`, `--older-than`, and any future duration-bearing flag or field.

### Secrets handling

Never accept secrets via flags. Flags leak to `ps` output, shell history, and CI logs.

Accept secrets via:

- Environment variable (e.g., `<CLI>_API_TOKEN`).
- File reference flag (e.g., `--token-file <path>`).
- Stdin pipe.

Never log secrets in `--debug` or `--verbose` output.

### Shell completion

The CLI SHOULD ship completion scripts for at least bash and zsh, exposed via `<cli> completion <shell>` writing to stdout. Completion is a human-experience feature; agents do not consume it. Generation MUST NOT depend on running an upstream call — completion scripts are static artifacts and shells invoke them on every keystroke.

### Schema-first generation

For CLIs of meaningful size or shipping parallel surfaces (SDK, MCP server, Terraform provider, OpenAPI docs), generate the surface from a single schema rather than writing each command by hand. The schema enforces vocabulary, three-layer introspection, and shape consistency mechanically.

For smaller hand-written CLIs the rules apply equally, enforced by CI lints. Three lints carry most of the weight:

- Banned-verb / banned-flag check. Walk the parser definition, fail the build on any verb or flag in the "Never as canonical" columns of Rule 9 unless explicitly registered as an alias of its canonical.
- Envelope-shape validation. For every command supporting `--json`, run it under `--dry-run` (or against a fixture) and assert the response parses, contains `status`, and matches the success or error shape from Rule 3.
- Help-reference drift check. Diff the surface enumerated by the parser against `<cli> help agents`; fail when subcommands or flags appear in one but not the other.

Manual enforcement through code review is unreliable and lets edge cases through.

## Anti-patterns

Each anti-pattern is followed by a one-line detection cue.

- Decoration when decoration mode is off. ANSI escape codes, spinners, or animated progress in stdout while decoration mode is off. Detection: pipe through `cat -v`; if `^[[` sequences appear, the rule is violated.
- Interactive prompt with no flag bypass. Command hangs when stdin is `/dev/null`. Detection: run with `< /dev/null` and a 10s timeout; if it does not exit, the prompt has no bypass.
- Silent success or silent failure. Command exits without output even though state changed, or fails without explanation. Detection: an exit-0 with empty stdout and no `--quiet` flag.
- Mixing data and diagnostics on stdout. Anything that isn't part of the requested response (raw text warnings, log lines, debug output) on stdout corrupts downstream consumers in either mode. In text mode, warnings belong on stderr; in JSON mode, structured warnings inside `warnings[]` are fine. Detection: `<cli> ... --json | jq .` fails.
- Verbose default output without `--fields` or `--quiet`. A single command emits hundreds of lines into agent context. Detection: a routine list command exceeding a screenful of output by default.
- Renaming or removing existing flags, exit codes, or JSON envelope fields without a major version bump. Detection: a diff that touches the flag table or envelope keys without a changelog entry.
- Designing humans-first then bolting agent support on later. Symptom: `--json` was added recently and only covers half the commands; or default output is verbose, decorated, and unbounded with no thought to token cost. Detection: `--json` not supported uniformly, or default output bloated by JSON-style overhead and decoration.
- Inconsistent verbs and flag names within the same CLI. `posts list` uses `--limit` but `comments list` uses `--max-results`. Detection: scan the flag table; flag names must match across resources for the same operation.
- Returning prose error under --json. `--json` is set but stdout carries unstructured text instead of an envelope. Detection: `<cli> bogus-subcommand --json 2>/dev/null | jq .` returns a parse error or empty result. The argument parser must be `--json`-aware before any error fires; the same applies to panic handlers and any sub-process the CLI shells out to (capture and re-wrap their stderr rather than letting it leak to the user's stdout).
- JSON output by default. The CLI emits a JSON envelope when `--json` was not set, forcing humans and agents to parse braces and quotes for routine commands. Detection: `<cli> some-cmd` without `--json` returns text containing `{` and `"`.

## Audit checklist

Walk this list against the CLI under review. Items are grouped by tier; failures earlier in the list are more severe.

```
P0
[ ] Default (non --json) output follows token-efficient style: text-first, no JSON overhead, counts and next-action inline (Rule 2)
[ ] Every data-returning command supports --json with the wrapped envelope
[ ] stdout carries only data; stderr carries diagnostics, prompts, progress
[ ] Exit codes are semantic with 75 reserved for transient/retry
[ ] Every prompt has a flag bypass (--force or specific flag)
[ ] Non-terminal stdin is detected and never prompts (interactive mode off)
[ ] Errors include code, message, fix, transient, and valid_values when the accepted set is enumerable
[ ] Mutating commands are idempotent (create matches → existing: true; create differs → CONFLICT; delete already-deleted → ALREADY_DELETED)
[ ] Destructive commands require an explicit non-default flag
[ ] --dry-run available for every consequential mutation
[ ] List commands paginate with bounded defaults
[ ] --fields available on data-bearing commands
[ ] No ANSI escape codes in stdout when decoration mode is off
[ ] NO_COLOR, TERM=dumb honoured
[ ] Success and failure output suggest the next concrete command
P1
[ ] Verbs and flags follow the canonical vocabulary tables
[ ] Three layers of introspection present: --help, help agents, help schemas
[ ] Async submitters expose --wait paired with --timeout, and write to a persistent job ledger
[ ] jobs subcommand surfaces list, get, cancel, prune, repair
[ ] Job ledger is durable against concurrent same-host writers and readers tolerate malformed lines
[ ] Existing flags, exit codes, and envelope fields are additive-only since last major version
P2
[ ] Profiles: save, use, list, get, delete with documented precedence
[ ] --output routes artifacts to stdout, file:, webhook:, http(s):
[ ] feedback subcommand records locally and POSTs upstream when configured
General
[ ] Configuration precedence: flag > env > profile > project > user > default
[ ] Env vars use <CLI>_<NAME> SCREAMING_SNAKE_CASE; booleans accept 1/true/yes vs 0/false/no
[ ] Secrets never accepted via flags
[ ] XDG paths used for config, state, cache
```
