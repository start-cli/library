# Golang CLI Design Guide

## Purpose

This guide defines the recommended architecture, patterns, and conventions for building command-line tools in Go. It is derived from production CLIs and targets AI agents tasked with scaffolding or building new CLI projects.

Follow this guide when creating a new Go CLI. Deviate only when the domain demands it, and document why.

## Project Layout

Follow the standard Go project layout. The structure below shows the recommended internal packages for CLI tools.

```none
<project>/
├── cmd/<name>/
│   └── main.go
├── internal/
│   ├── cli/
│   ├── api/
│   ├── config/
│   ├── tui/
│   └── <domain>/
├── testdata/
├── scripts/
├── docs/
├── go.mod
├── go.sum
├── .golangci.yml
├── LICENSE
└── README.md
```

Package purposes:

- cmd/name/main.go — Minimal entry point. Delegates everything to internal/cli
- internal/cli/ — Cobra root command, subcommands, output helpers, exit codes
- internal/api/ — HTTP client, authentication, pagination, error types
- internal/config/ — Environment variable loading, validation, fallback chains
- internal/tui/ — Terminal colour constants, formatting helpers, progress indicators
- internal/width/ — Unicode display width calculation for table output (optional, add when table output is needed)
- internal/output/ — Table, detail, and JSON formatting (optional, can live in tui/ for simpler CLIs)
- internal/domain/ — Domain-specific packages as needed (e.g. converter, models, jira)

Not every CLI needs every package. A simple CLI might only need `cli/` and `config/`. Add packages as complexity demands.

Note: `testdata/` at the project root holds test fixtures (JSON responses, sample files). `scripts/` holds manual and integration test scripts.

## Entry Point

cmd/name/main.go is minimal. It calls cli.Execute(), formats any error, and exits with the appropriate code.

```go
package main

import (
"fmt"
"os"

"<module>/internal/cli"
"<module>/internal/tui"
)

func main() {
err := cli.Execute()
// Translate SIGINT/SIGTERM to POSIX 128+signum (130/143) before falling
// through to the error path. Without this, a cancelled context surfaces
// as context.Canceled and exits 1. See "Signal Handling".
if code := cli.SignalExitCode(); code != 0 {
os.Exit(code)
}
if err != nil {
// See "Preventing Double Output" for the IsPrintedError contract.
if !cli.IsPrintedError(err) {
fmt.Fprintln(os.Stderr, tui.ColorError.Sprint(err))
}
os.Exit(cli.ExitCodeFromError(err))
}
}
```

Rules:

- No application logic in main
- No flag parsing in main
- No configuration loading in main
- The only responsibilities are: run, format error, exit

## CLI Architecture

### Root Command

The root command lives in `internal/cli/root.go`. It defines global flags, command groups, and the `Execute()` function.

```go
package cli

import (
"context"
"os"
"os/signal"
"sync/atomic"
"syscall"

"github.com/spf13/cobra"
)

var Version = "dev"

var rootCmd = &cobra.Command{
Use:           "<name>",
Short:         "One-line description",
Version:       Version,
SilenceUsage:  true,
SilenceErrors: true,
Args:          cobra.NoArgs,
RunE: func(cmd *cobra.Command, args []string) error {
return cmd.Help()
},
}

var (
jsonOutput bool
verbose    bool
debug      bool
quiet      bool
noInput    bool
colorMode  string
)

func init() {
rootCmd.PersistentFlags().BoolVarP(&jsonOutput, "json", "j", false, "Emit a JSON envelope on stdout")
rootCmd.PersistentFlags().BoolVar(&verbose, "verbose", false, "Add detail to stdout output")
rootCmd.PersistentFlags().BoolVar(&debug, "debug", false, "Diagnostic logging to stderr")
rootCmd.PersistentFlags().BoolVarP(&quiet, "quiet", "q", false, "Suppress non-essential output")
rootCmd.PersistentFlags().BoolVar(&noInput, "no-input", false, "Never prompt; fail fast on missing required input")
rootCmd.PersistentFlags().StringVar(&colorMode, "color", "auto", "Colour output: auto, always, never")
}

// caughtSignal records which signal cancelled the context so main can map it
// to the POSIX 128+signum exit code via SignalExitCode below.
var caughtSignal atomic.Int32

func Execute() error {
ctx, cancel := context.WithCancel(context.Background())
defer cancel()

sigCh := make(chan os.Signal, 1)
signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
go func() {
if sig, ok := <-sigCh; ok {
caughtSignal.Store(int32(sig.(syscall.Signal)))
cancel()
}
}()

return rootCmd.ExecuteContext(ctx)
}

// SignalExitCode returns 128+signum if Execute was interrupted by SIGINT or
// SIGTERM, or 0 if no signal was caught. main consults this before falling
// through to ExitCodeFromError so cancellation exits 130/143 rather than 1.
// signal.NotifyContext alone would not produce 130/143 — a cancelled context
// surfaces as context.Canceled and falls through to ExitFailure (1).
func SignalExitCode() int {
if s := caughtSignal.Load(); s != 0 {
return 128 + int(s)
}
return 0
}
```

`SilenceUsage` and `SilenceErrors` stop Cobra from printing usage/errors itself; `main.go` handles both.

`RunE: cmd.Help()` makes root runnable so cobra renders the full help template (Usage + Flags), not just `Long`. `Args: cobra.NoArgs` rejects stray positionals; cobra's own resolver catches unknown subcommands first.

### Runtime Modes

Two independent runtime modes are detected once in `PersistentPreRunE` and exposed via accessor functions matching the `JSONOutput()` pattern.

- **Interactive mode** (whether prompts are allowed) is ON when stdin is a terminal AND none of `--no-input`, `--json`, `<CLI>_NO_INPUT=1` are set. Otherwise OFF.
- **Decoration mode** (whether ANSI escapes, spinners, progress bars are allowed in stdout) is ON when stdout is a terminal OR `FORCE_COLOR`/`CLICOLOR_FORCE` is set, AND none of `NO_COLOR`, `--color=never`, `TERM=dumb`, `--json`, `--quiet` are set. Otherwise OFF. Precedence on top of that base: `--color=always` overrides `--json` and `--quiet`; `NO_COLOR` overrides `--color=always` and `FORCE_COLOR`. Under `--json` the envelope path never emits ANSI on stdout regardless of decoration state, so the `--color=always` override only affects stderr diagnostics.

The two are orthogonal — a piped invocation (decoration off) may still be interactive, and a TTY invocation may have decoration disabled by env. Treat them as separate gates.

The `CI` environment variable is intentionally NOT consulted; TTY presence is the reliable signal. CI configurations that allocate a PTY MUST set `--no-input` or `<CLI>_NO_INPUT=1` explicitly to suppress prompts. To enable colour in CI log viewers (GitHub Actions, GitLab CI, etc.) where stdout is not a TTY, set `FORCE_COLOR=1` (or `CLICOLOR_FORCE=1`) in the pipeline environment — the de facto standard across the npm, Python, and Rust ecosystems. `NO_COLOR` always wins.

```go
import (
"os"
"strings"

"github.com/fatih/color"
"golang.org/x/term"
)

var (
interactive bool
decorated   bool
)

func detectModes() error {
stdinTTY := term.IsTerminal(int(os.Stdin.Fd()))
stdoutTTY := term.IsTerminal(int(os.Stdout.Fd()))

// Resolve decoration before any other outputErr so error messages do not
// leak ANSI when the user asked for --color=never. The --color validation
// itself runs against the package-default color.NoColor; fatih/color's
// init() already honours NO_COLOR, which covers the bad-value branch.
switch colorMode {
case "auto", "always", "never":
default:
return outputErr(&ErrorPayload{
Code:        "INVALID_COLOR",
Message:     "--color must be one of: auto, always, never",
Fix:         "<cli> --color=auto",
Transient:   false,
ValidValues: []string{"auto", "always", "never"},
})
}

forceColor := envTruthy("FORCE_COLOR") || envTruthy("CLICOLOR_FORCE")
noColor := os.Getenv("NO_COLOR") != ""
dumb := os.Getenv("TERM") == "dumb"

decorated = (stdoutTTY || forceColor) && !noColor && colorMode != "never" && !dumb && !jsonOutput && !quiet
if colorMode == "always" && !noColor {
decorated = true
}
color.NoColor = !decorated

noInputEnv, err := envBool("<CLI>_NO_INPUT")
if err != nil {
return err
}
interactive = stdinTTY && !noInput && !jsonOutput && !noInputEnv

// CLI-owned debug toggle. The flag wins; the env var lets agents and CI
// pipelines opt in once for the whole environment without amending every
// invocation. Same strict-bool semantics as <CLI>_NO_INPUT.
if !debug {
dbg, err := envBool("<CLI>_DEBUG")
if err != nil {
return err
}
debug = dbg
}

return nil
}

func Interactive() bool { return interactive }
func Decorated() bool   { return decorated }
```

Boolean env parsing splits into a strict helper for CLI-owned vars and a lenient helper for ecosystem vars:

```go
// envBool is strict: 1/true/yes are truthy; 0/false/no/unset are falsy; any
// other value is a configuration error (exit 78). Use for <CLI>_<NAME>
// boolean env vars where the CLI owns the contract.
func envBool(name string) (bool, error) {
raw, ok := os.LookupEnv(name)
if !ok {
return false, nil
}
switch strings.ToLower(strings.TrimSpace(raw)) {
case "", "0", "false", "no":
return false, nil
case "1", "true", "yes":
return true, nil
default:
return false, outputErr(&ErrorPayload{
Code:        "CONFIG_INVALID",
Message:     name + " has invalid value (expected one of: 1, 0, true, false, yes, no)",
Fix:         "unset " + name + " or set to 1/true/yes/0/false/no",
Transient:   false,
ValidValues: []string{"1", "0", "true", "false", "yes", "no"},
})
}
}

// envTruthy is lenient: any non-empty, non-falsy value is truthy. Use for
// cross-ecosystem env vars (FORCE_COLOR, CLICOLOR_FORCE) where the convention
// is established outside the CLI and other tools must not see different
// behaviour for the same value.
func envTruthy(name string) bool {
v := strings.ToLower(strings.TrimSpace(os.Getenv(name)))
return v != "" && v != "0" && v != "false" && v != "no"
}
```

Wire `detectModes` into `rootCmd.PersistentPreRunE` so every subcommand sees consistent values:

```go
rootCmd.PersistentPreRunE = func(cmd *cobra.Command, args []string) error {
return detectModes()
}
```

Mode rules:

- Decoration off: no ANSI escape codes anywhere in stdout, no spinners, no progress bars, no animated output. Diagnostics and structured progress (if any) go to stderr only.
- Interactive off: no prompts. Missing required input fails fast with exit 2 listing the missing flags by name.
- Never prompt for secrets even when interactive mode is on. Secrets come from env, file, or stdin only.

`--quiet` suppresses decoration but does not gate prompts; an interactive command with `--quiet` still prompts for missing input.

### One File Per Command

Each command lives in its own file. Name files after the command hierarchy: `noun.go` for parent commands, `noun_verb.go` for subcommands.

```none
internal/cli/
├── root.go
├── exitcodes.go
├── help.go
├── completion.go
├── item.go              # Parent: defines "item" command
├── item_list.go         # Subcommand: item list
├── item_create.go       # Subcommand: item create
├── item_get.go          # Subcommand: item get  (alias: view)
├── page.go               # Parent: defines "page" command
├── page_list.go
├── page_create.go
└── page_get.go           # Subcommand: page get  (alias: view)
```

Each file contains:

1. Package-level flag variables for that command
2. A cobra.Command variable definition
3. An init function that registers flags and adds the command to its parent
4. A run function matching runCommandName(cmd, args) returning error

```go
package cli

import "github.com/spf13/cobra"

var (
itemListLimit  int
itemListStatus string
)

var itemListCmd = &cobra.Command{
Use:     "list <project>",
Aliases: []string{"ls"},
Short:   "List items",
Args:    cobra.ExactArgs(1),
RunE:    runItemList,
}

func init() {
itemListCmd.Flags().IntVarP(&itemListLimit, "limit", "l", 25, "Maximum results")
itemListCmd.Flags().StringVar(&itemListStatus, "status", "", "Filter by status")
itemCmd.AddCommand(itemListCmd)
}

func runItemList(cmd *cobra.Command, args []string) error {
// Implementation
return nil
}
```

Rules:

- Always use `RunE`, never `Run` — commands return errors, never call `os.Exit`
- Use `cobra.ExactArgs(N)` or `cobra.ArbitraryArgs` for argument validation
- Prefix flag variables with the command name to avoid collisions (e.g. `itemListLimit`, not `limit`)
- Register commands in `init()` — this keeps the command tree declarative

### Command Groups

Organise commands into logical groups using Cobra's `AddGroup` for better help output.

```go
func init() {
rootCmd.AddGroup(
&cobra.Group{ID: "commands", Title: "Commands:"},
&cobra.Group{ID: "utilities", Title: "Utilities:"},
)
}
```

Assign commands to groups via `GroupID` in the command definition.

## Command Design

### Hierarchy

Follow the pattern: `tool noun verb --flags`

```none
tool item list --status "Open"
tool item create -s "Summary" -t Bug
tool page get 12345 --json
```

For simple tools with a single domain, the noun can be omitted: `tool list`, `tool create`.

### Self-Describing Commands

Every command must have `Short` and `Long` descriptions. Include `Example` blocks for non-trivial commands.

```go
var itemCreateCmd = &cobra.Command{
Use:   "create",
Short: "Create a new item",
Long:  "Create a new item in the specified project with the given summary, type, and priority.",
Example: `  tool item create -s "Fix login bug"
  tool item create -s "Add feature" -t Story -d "Description"
  echo "Description" | tool item create -s "From stdin" -f -`,
RunE: runItemCreate,
}
```

Required, not decoration: agents drive off command help.

### Aliases

Use canonical verbs (`get`, `list`, `create`, `update`, `delete`, `run`, `status`) as the primary command names. Register the muscle-memory alternatives as Cobra aliases:

- `get` (canonical) with aliases `view`, `show`, `describe`, `info`
- `list` (canonical) with aliases `ls`, `all`, `find`
- `delete` (canonical) with aliases `rm`, `remove`, `destroy`
- `update` (canonical) with aliases `edit`, `modify`
- `create` (canonical) with aliases `add`, `new`, `make`

Aliases live in `--help` only and are not listed in the agent help reference. Always register `view` as a `get` alias for `gh`/`glab` muscle memory.

Alias plural and singular forms for noun commands (`item`/`items`, `page`/`pages`); lean singular as the canonical.

### Input Methods

Support multiple input methods where commands accept content:

- Positional arguments for short values
- -f flag for file input
- `-f -` for explicit stdin
- Piped stdin detection when no arguments provided

```go
func readInput(cmd *cobra.Command, args []string, flagFile string) ([]byte, error) {
if flagFile == "-" {
return io.ReadAll(os.Stdin)
}
if flagFile != "" {
return os.ReadFile(flagFile)
}
if len(args) > 0 {
return []byte(strings.Join(args, " ")), nil
}
if !term.IsTerminal(int(os.Stdin.Fd())) {
return io.ReadAll(os.Stdin)
}
return nil, fmt.Errorf("no input provided: use arguments, -f <file>, or pipe to stdin")
}
```

### Mutation Safety

Agents retry. Every mutation MUST be safe to invoke twice. The semantics differ by verb:

`create` follows a three-way decision based on what already exists:

| State                         | Behaviour                                 | Exit |
|-------------------------------|-------------------------------------------|------|
| No existing resource          | Create it                                 | 0    |
| Existing matches the request  | Return the resource with `existing: true` | 0    |
| Existing differs from request | Do not modify; return `Code: "CONFLICT"`  | 5    |

"Matching" means every field the caller supplied equals the corresponding field on the existing resource. Server-managed fields (IDs, timestamps, computed defaults) are not part of the comparison. The caller deliberately chooses `update` (or `delete` then `create`) when they want to change a differing resource.

`update` is idempotent on the same input — calling twice with the same fields produces the same result and exit 0 both times.

`delete` on an already-deleted resource returns exit 0 with a warning entry of `Code: "ALREADY_DELETED"` in `Envelope.Warnings`. The response describes the resource as it last existed, or omits it if the CLI keeps no tombstone.

Destructive operations require an explicit non-default flag. `--force` is the canonical bypass — `--yes`, `--no-confirm`, and `--skip-confirmations` are forbidden as canonicals (see "Aliases" under Global Flags for registering them as Cobra aliases).

```go
func runItemCreate(cmd *cobra.Command, args []string) error {
req := buildCreateRequest(/* flags */)

existing, err := client.GetItemByKey(cmd.Context(), req.Key)
switch {
case errors.Is(err, api.ErrNotFound):
// fall through to create
case err != nil:
return err
default:
if matchesRequest(existing, req) {
outputData(map[string]any{"item": existing, "existing": true})
return nil
}
return outputErr(&ErrorPayload{
Code:      "CONFLICT",
Message:   fmt.Sprintf("item %s exists with different fields", req.Key),
Fix:       fmt.Sprintf("<cli> item update %s ...", req.Key),
Transient: false,
})
}

created, err := client.CreateItem(cmd.Context(), req)
if err != nil {
return err
}
outputData(created)
return nil
}
```

`matchesRequest` compares only the fields the caller supplied. A nil or unset field on the request is not part of the comparison.

### Dry Run

Every consequential mutation supports `--dry-run`. With `--dry-run`, the response describes what would happen without applying the change. Trivial mutations (appending to a feedback log, recording telemetry) are exempt.

```go
var itemCreateDryRun bool

func init() {
itemCreateCmd.Flags().BoolVar(&itemCreateDryRun, "dry-run", false,
"Validate and describe the change without applying it")
// ... other flags
itemCmd.AddCommand(itemCreateCmd)
}

func runItemCreate(cmd *cobra.Command, args []string) error {
req := buildCreateRequest(/* flags */)

if itemCreateDryRun {
outputData(map[string]any{"would_create": req, "dry_run": true})
return nil
}

// ... actual create
}
```

For async submitters, `--dry-run` MUST NOT submit a job or write a ledger entry.

`--dry-run` is the universal name (`git`, `kubectl`, `helm`, `aws`, `rsync`); do not invent `--plan`, `--simulate`, or `--preview`.

## Global Flags

### Standard Set

Persistent root flags:

| Flag         | Short | Purpose                                                      |
|--------------|-------|--------------------------------------------------------------|
| `--json`     | `-j`  | Emit a wrapped JSON envelope on stdout                       |
| `--verbose`  |       | Add detail to stdout (extra fields on `data` under `--json`) |
| `--debug`    |       | Diagnostic logging to stderr; never affects stdout           |
| `--quiet`    | `-q`  | Suppress non-essential output (errors still emit)            |
| `--no-input` |       | Never prompt; fail fast on missing required input            |
| `--color`    |       | Colour output: `auto` (default), `always`, `never`           |

Per-command flags (registered on the commands that need them):

| Flag        | Purpose                                                       |
|-------------|---------------------------------------------------------------|
| `--dry-run` | Validate and describe the change without applying it          |
| `--force`   | Bypass interactive confirmation; required for destructive ops |
| `--limit`   | Bounded result set on list-style commands                     |
| `--next`    | Opaque pagination cursor                                      |
| `--fields`  | Restrict the columns returned                                 |
| `--output`  | Destination: `stdout`, `file:<path>`, `webhook:<url>`, …      |
| `--wait`    | Block until an async job completes                            |
| `--timeout` | Duration value (`30s`, `1h30m`); pairs with `--wait`          |

Not every CLI needs every flag. `--json`, `--no-input`, `--color`, and `--quiet` are always recommended; the rest follow the canonical vocabulary when the corresponding capability exists.

### Aliases

Non-canonical names (`--yes`, `--no-color`, `--non-interactive`, `--plan`, `--simulate`, `--max-results`, `--page`, `--out`, `--block`) MAY be registered as Cobra aliases of their canonical for muscle memory or backward compatibility. Use `cobra.Command.Flags().SetNormalizeFunc` or per-flag `Aliases` fields to wire them. Aliases live in `--help` only — the agent help reference (`<cli> help agents`) lists canonicals only.

### Colour Output

Colour and decoration are governed by the Runtime Modes logic above — `detectModes` is the single source of truth. It honours `NO_COLOR` (per the spec at [https://no-color.org](https://no-color.org)), `--color`, `FORCE_COLOR`/`CLICOLOR_FORCE`, `TERM=dumb`, `--json`, and `--quiet`, and sets `color.NoColor = true` when decoration is off. See "Runtime Modes" for the precedence rules. Do not add a second `PersistentPreRun` for colour — Cobra holds one per command, so a duplicate silently overwrites the mode-detection hook.

`--color` values not in the set `{auto, always, never}` are a usage error (exit 2) with `Code: "INVALID_COLOR"` and `ValidValues: ["auto", "always", "never"]`.

### Accessor Functions

Export flag state through functions, not variables.

```go
func JSONOutput() bool { return jsonOutput }
```

## Output Design

### Modes

Text by default; JSON envelope with `--json`. Text is the priority mode — agents read it directly more often than they parse JSON. Use `--json` only when parsing (iterating a list, extracting an ID, branching on `status`).

### Output Helpers

Define typed envelope structs in `internal/cli/envelope.go`. Every `--json` response uses the same outer shape so callers parse once and branch on `Status`.

```go
type Envelope struct {
Status   string           `json:"status"` // "ok" or "error"
Data     any              `json:"data,omitempty"`
Error    *ErrorPayload    `json:"error,omitempty"`
Warnings []WarningPayload `json:"warnings,omitempty"`
Next     string           `json:"next,omitempty"`
}

type ErrorPayload struct {
Code        string   `json:"code"`
Message     string   `json:"message"`
Fix         string   `json:"fix,omitempty"`
Transient   bool     `json:"transient"`
ValidValues []string `json:"valid_values,omitempty"`
RetryAfter  string   `json:"retry_after,omitempty"`
ExitCode    int      `json:"-"` // optional override for the process exit code
}

type WarningPayload struct {
Code       string `json:"code"`
Message    string `json:"message"`
Fix        string `json:"fix,omitempty"`
RetryAfter string `json:"retry_after,omitempty"`
}
```

Define these helpers in `root.go` or a shared file within `internal/cli/`:

```go
// outputData accepts an optional warnings tail. Under --json they ride in
// Envelope.Warnings; in text mode they print to stderr after the rendered
// output.
func outputData(v any, warnings ...WarningPayload) {
if JSONOutput() {
outputJSON(Envelope{Status: "ok", Data: v, Warnings: warnings})
return
}
renderText(v)
for _, w := range warnings {
fmt.Fprintln(os.Stderr, tui.ColorWarning.Sprintf("Warning: %s", w.Message))
}
}

func outputErr(p *ErrorPayload) error {
if JSONOutput() {
outputJSON(Envelope{Status: "error", Error: p})
} else {
fmt.Fprintln(os.Stderr, tui.ColorError.Sprintf("Error: %s", p.Message))
if p.Fix != "" {
fmt.Fprintln(os.Stderr, tui.ColorDim.Sprintf("  Fix: %s", p.Fix))
}
}
return &ExitError{
Code: exitCodeForPayload(p),
Err:  &printedError{msg: p.Message},
}
}

// exitCodeForPayload maps an ErrorPayload to the canonical process exit code.
// Prefer setting ExitCode on the payload at the call site for new codes
// rather than growing this switch — the table only carries the codes
// documented under <cli> help schemas.
func exitCodeForPayload(p *ErrorPayload) int {
if p.ExitCode != 0 {
return p.ExitCode
}
if p.Transient {
return ExitTransient
}
switch p.Code {
case "INVALID_COLOR", "INVALID_FIELDS", "INVALID_HELP_TOPIC",
"BAD_REQUEST", "OUTPUT_REQUIRED", "SPACE_REQUIRED":
return ExitUsage
case "AUTH_EXPIRED", "UNAUTHENTICATED", "PERMISSION_DENIED":
return ExitPermission
case "NOT_FOUND":
return ExitNotFound
case "CONFLICT", "ALREADY_DELETED", "CURSOR_INVALID":
return ExitConflict
case "CONFIG_INVALID":
return ExitConfig
default:
return ExitFailure
}
}

func outputNotice(msg string) {
if JSONOutput() {
return
}
fmt.Fprintln(os.Stderr, tui.ColorWarning.Sprint(msg))
}

func outputHint(msg string) {
if JSONOutput() {
return
}
fmt.Fprintln(os.Stderr, tui.ColorDim.Sprint("Hint: "+msg))
}

func outputJSON(v any) {
data, err := json.MarshalIndent(v, "", "  ")
if err != nil {
fmt.Fprintln(os.Stderr, tui.ColorError.Sprintf("internal: json marshal: %v", err))
return
}
fmt.Println(string(data))
}
```

`outputNotice` and `outputHint` are stderr-only diagnostics for the human at a terminal; under `--json` they are suppressed because they have no place in the envelope. Programmatic warnings (deprecated flags, partial-success conditions an agent can act on) belong in `Envelope.Warnings` and travel with the success response — accumulate them on a per-command warnings slice and pass them when calling `outputData`.

### JSON Output

When `--json` is set, stdout carries one envelope and nothing else.

Success:

```json
{"status":"ok","data":{"id":"post_8f2a","title":"Hello"}}
```

Failure:

```json
{"status":"error","error":{"code":"AUTH_EXPIRED","message":"API token has expired","fix":"<cli> auth refresh","transient":false}}
```

Rules:

- The discriminator is the string `status` ("ok" or "error"), not a boolean.
- Success responses always carry `data`. Failure responses always carry `error` as a structured object.
- Warnings are optional and omitted when empty. When present, each entry has the same shape as `ErrorPayload` minus `transient` and `valid_values`.
- Paginated responses include `next` at the envelope root as an opaque cursor token; omit when no more pages exist.
- Streaming responses (`--follow`, `--watch`) emit NDJSON: one envelope per line.
- Parsers must ignore unknown fields anywhere in the response so additive changes (new envelope fields, `--verbose` extras on `data`) do not break callers.
- Subtractive or renaming changes (removing a field, changing its type, renaming a key) MUST announce at least one release ahead via a `Warnings` entry with `Code: "DEPRECATED_FIELD"`. The `Message` names the field and its successor or removal release; the `Fix` shows the new shape. This gives agents that pin against an older envelope a programmatic deprecation signal — they branch on the warning code rather than diffing the response shape.
- stdout carries only the envelope. Diagnostics, prompts, progress, and log lines go to stderr.
- ANSI escape codes never appear in stdout when decoration mode is off.
- Hints and notices intended for humans are suppressed under `--json`; structured warnings ride in `Envelope.Warnings`.

### Text Output

For list commands, use table formatting with Unicode-aware column widths. For detail commands, use key-value pairs with tabwriter alignment. See `internal/output/` or `internal/tui/` for implementations.

### Field Selection

Every data-bearing command supports `--fields` so the caller requests only the columns it needs. Highest-leverage flag for per-call token cost.

`--fields` accepts a comma-separated list of field names: `--fields=id,status`. Do not use `--columns` or `--select`.

Behaviour by mode:

- Text mode: only the named columns appear in the rendered output. Column order matches the order specified.
- JSON mode: only the named keys appear in each `data` entry. The envelope structure is unchanged.
- `--verbose` adds extra fields by default; `--fields` overrides — explicit selection wins.

Each command exposes a known field set. Unknown field names return exit 2 with `Code: "INVALID_FIELDS"` and `ValidValues` listing accepted names so the agent can correct without guessing.

```go
var itemListFields []string

func init() {
itemListCmd.Flags().StringSliceVar(&itemListFields, "fields", nil,
"Comma-separated list of fields to return")
}

var itemListKnownFields = []string{"key", "summary", "status", "assignee", "priority", "created", "updated"}

func runItemList(cmd *cobra.Command, args []string) error {
selected, err := selectFields(itemListFields, itemListKnownFields)
if err != nil {
return err
}
rows, err := client.ListItems(cmd.Context(), /* ... */)
if err != nil {
return err
}
return renderRows(rows, selected)
}

func selectFields(requested, known []string) ([]string, error) {
if len(requested) == 0 {
return known, nil
}
knownSet := make(map[string]struct{}, len(known))
for _, f := range known {
knownSet[f] = struct{}{}
}
for _, f := range requested {
if _, ok := knownSet[f]; !ok {
return nil, outputErr(&ErrorPayload{
Code:        "INVALID_FIELDS",
Message:     fmt.Sprintf("unknown field: %q", f),
Fix:         "use one of the accepted field names",
Transient:   false,
ValidValues: known,
})
}
}
return requested, nil
}
```

`selectFields` is generic across commands; the per-command piece is the `<cmd>KnownFields` slice. List the known fields under `<cli> help schemas` so agents discover the per-command field set without trial and error.

### Pagination Indicators

Every list-style response surfaces where the reader is in the result space and the concrete command to advance.

```none
Showing 1-25 of 3,352 results  (--next eyJvZmZzZXQiOjI1fQ)
Showing 1-12 of 12 results
```

Rules:

- Surface the range (`<start>-<end>`) and total when cheap to compute. When the total is expensive, drop the `of N` portion: `Showing 1-25 results (--next ...)`.
- Always include the `(--next <token>)` hint when more pages exist; omit when the response is the last page.
- Under `--json`, the same cursor goes at the envelope root as `next` (see "JSON Output"); do not embed the text hint in the JSON.

## Agent Help System

### Purpose

Two tiers:

- `<cli> help agents` — entry point. Prose, token-efficient, read once on first contact.
- `<cli> help <topic>` — sibling reference docs fetched on demand: `schemas` (machine shapes), `workflows` (composed multi-command operations), `query` (filter/query language), or any domain-specific topic.

### Implementation

Embed help content as markdown files and register one Cobra subcommand per topic under a `help` parent.

```none
internal/cli/
├── help.go
└── agent-help/
    ├── agents.md
    └── schemas.md
```

```go
//go:embed agent-help/agents.md
var helpAgents string

//go:embed agent-help/schemas.md
var helpSchemas string

// helpTopics is the single source of truth for the topic set. Long is
// rendered from it so adding a topic only requires updating the slice (and
// the matching `var helpXxx string` + cobra.Command + AddCommand triple).
var helpTopics = []string{"agents", "schemas"}

func helpLong() string {
var b strings.Builder
b.WriteString("Show extended help topics. Available topics:\n\n")
for _, t := range helpTopics {
fmt.Fprintf(&b, "  %s\n", t)
}
b.WriteString("\nRun \"<cli> help\" with no arguments for the standard command tree, or\n")
b.WriteString("\"<cli> <command> --help\" for per-command help.")
return b.String()
}

var helpCmd = &cobra.Command{
Use:   "help [topic]",
Short: "Show extended help topics for agents and humans",
Long:  helpLong(),
RunE: func(cmd *cobra.Command, args []string) error {
if len(args) == 0 {
root := cmd.Root()
// Cobra's execute() calls InitDefaultHelpFlag/VersionFlag on the
// command being executed. When `<cli> help` runs, that is helpCmd,
// not root, so root's -h/--help and -v/--version are not yet
// registered. Mirror what cobra's own auto-help does before
// delegating (cobra command.go ~line 1304 in v1.10.x).
root.InitDefaultHelpFlag()
root.InitDefaultVersionFlag()
return root.Help()
}
return outputErr(&ErrorPayload{
Code:        "INVALID_HELP_TOPIC",
Message:     fmt.Sprintf("unknown help topic %q", args[0]),
Fix:         "<cli> help " + helpTopics[0],
Transient:   false,
ValidValues: helpTopics,
})
},
}

var helpAgentsCmd = &cobra.Command{
Use:   "agents",
Short: "Token-efficient reference for AI agents",
RunE: func(cmd *cobra.Command, args []string) error {
fmt.Print(helpAgents)
return nil
},
}

var helpSchemasCmd = &cobra.Command{
Use:   "schemas",
Short: "JSON envelope, exit codes, and error code reference",
RunE: func(cmd *cobra.Command, args []string) error {
fmt.Print(helpSchemas)
return nil
},
}

func init() {
helpCmd.AddCommand(helpAgentsCmd)
helpCmd.AddCommand(helpSchemasCmd)
// Both calls are needed on a bare root: SetHelpCommand stops cobra
// installing its own help command; AddCommand puts helpCmd in the
// resolvable tree (InitDefaultHelpCmd skips that until root has another
// subcommand). Once other subcommands land, AddCommand stays safe —
// InitDefaultHelpCmd does Remove+Add on the registered helpCommand.
rootCmd.SetHelpCommand(helpCmd)
rootCmd.AddCommand(helpCmd)
}
```

Canonical sibling topics worth registering when the corresponding capability exists:

- `schemas` — envelope shape, exit codes, error code namespace, per-command field sets, streaming event shapes. Always present. Content per `cli-design-for-agents.md` Rule 10.
- `workflows` — composed multi-command sequences the agent should know about (auth flow, paginated traversal, async submit-and-wait). Present when the CLI's value comes from chaining commands.
- `query` — query/filter language reference if the CLI accepts one (JQL, CEL, KQL, etc.).
- `<domain>` — anything else the agent may need to fetch on demand (formatting conventions, vendor-specific quirks).

Topic content is contract-shaped, not Go-specific. The Go work is the embed-and-register pattern above; the content rules live in the parent design doc.

### Content Guidelines

Agent help is a condensed cheat sheet, not a flag reference. Token-efficient; readable in one pass.

Structure:

1. One-line tool description
2. Environment and configuration notes (what must be set, what is optional)
3. Global flags summary (one line)
4. A single code block listing real, runnable example commands covering all operations
5. Brief notes after the code block for non-obvious behaviours
6. Other/less common commands listed by name with a pointer to --help
7. Chaining examples showing JSON output piped to jq

Rules for agent help content:

- No bold, italic, or decorative formatting
- No emojis
- No verbose explanations — state facts
- Show commands by example, not by flag description
- Show flag variations inline within examples (e.g. multiple list commands with different filters)
- Group examples logically by operation (list, create, edit, delete)
- Include the most common workflows as runnable one-liners

Example format:

````markdown
# tool

Short oneline description.

- SERVICE_API_TOKEN env required
- SERVICE_BASE_URL env optional (defaults to https://example.com)

Global flags: -j/--json, --verbose, --no-input, --color=auto|always|never. Only use --json when piping to jq.

## Core Commands

\```
tool item list
tool item list -l 10 --status "Active" -t Widget
tool item list --order-by created --reverse
tool item get ITEM-123
tool item create -s "New item" -t Widget
tool item create -s "From file" -f description.md
echo "Content" | tool item create -s "From stdin" -f -
tool item edit ITEM-123 -s "Updated summary"
tool item delete ITEM-123 --force
tool item assign ITEM-123 me
tool item move ITEM-123 "Done" -m "Completed"
\```

Note: get shows 5 comments by default. IDs shown as [date] [id] Author.

## Other Commands

See --help: info, user search, config list
````

### Design Implication

Agent help should influence command design:

- Commands should be guessable from name alone
- Flag names should be self-explanatory
- Consistent flag naming across commands (`-l` always means limit, `-j` always means JSON)
- Avoid flags that require reading documentation to understand

## Exit Codes

### Standard Codes

Use this taxonomy for every CLI. The codes are anchored on `sysexits.h` (`75` for transient/retry, `78` for configuration errors) and Bash convention (`2` for usage errors), so agents and shells generalise correctly across tools.

```go
const (
ExitSuccess    = 0  // Continue
ExitFailure    = 1  // General failure; do not retry blindly
ExitUsage      = 2  // Bad arguments; fix and retry
ExitNotFound   = 3  // Resource not found
ExitPermission = 4  // Permission denied; authenticate or escalate
ExitConflict   = 5  // Resource state prevents the operation
ExitTransient  = 75 // Retry with backoff (sysexits EX_TEMPFAIL)
ExitConfig     = 78 // Configuration error (sysexits EX_CONFIG)
)
```

`ExitTransient` (75) is the explicit retry signal — agents use it to decide whether automatic retry is worthwhile. Document the codes a CLI uses under `<cli> help schemas`.

Signal-terminated runs follow POSIX `128+signal`: SIGINT exits `130`, SIGTERM exits `143`. The shim under "Signal Handling" is what produces those codes; without it, a cancelled context falls through to `ExitFailure (1)`. These MUST NOT be conflated with `ExitTransient` — a user interrupt is intent, not a transient failure the agent may retry on its own.

### ExitError Type

```go
type ExitError struct {
Code int
Err  error
}

func (e *ExitError) Error() string { return e.Err.Error() }
func (e *ExitError) Unwrap() error { return e.Err }
```

### Exit Code Mapping

```go
func ExitCodeFromError(err error) int {
var exitErr *ExitError
if errors.As(err, &exitErr) {
return exitErr.Code
}

var apiErr *api.APIError
if errors.As(err, &apiErr) {
switch {
case apiErr.StatusCode == 401, apiErr.StatusCode == 403:
return ExitPermission
case apiErr.StatusCode == 404:
return ExitNotFound
case apiErr.StatusCode == 409:
return ExitConflict
case apiErr.StatusCode == 408, apiErr.StatusCode == 425, apiErr.StatusCode == 429,
apiErr.StatusCode >= 500 && apiErr.StatusCode <= 599:
return ExitTransient
default:
return ExitFailure
}
}

var netErr net.Error
if errors.As(err, &netErr) {
return ExitTransient
}

return ExitFailure
}
```

Cobra's "unknown command" error is untyped, so it falls through to `ExitFailure (1)` rather than `ExitUsage (2)`. Left as-is — matches `git`/`gh`/`glab`. If a contract demands exit 2, wrap `Execute()` and string-match the cobra message; brittle across cobra versions.

## Error Handling

### Error Code Conventions

Every error that reaches the user carries a machine-readable `Code` on its `ErrorPayload`. Codes follow these rules:

- UPPER_SNAKE_CASE, modelled on gRPC canonical codes and Google Cloud's API error model.
- Domain-bare, not CLI-prefixed. Use `AUTH_EXPIRED`, not `MYCLI_AUTH_EXPIRED`. The agent learns the namespace from `<cli> help schemas`.
- Enumerated under `<cli> help schemas` so agents can branch on `Code` reliably.
- Reuse codes from the canonical taxonomy under `<cli> help schemas` (`RATE_LIMITED`, `CONFLICT`, `CURSOR_INVALID`, `OUTPUT_REQUIRED`, `ALREADY_DELETED`, …) rather than coining bespoke synonyms per command. The taxonomy mixes gRPC-derived codes (`PERMISSION_DENIED`, `NOT_FOUND`) with CLI-specific shapes (`ALREADY_DELETED` for idempotent delete, `CURSOR_INVALID` for stale pagination) — both classes carry the same exit-code-and-transient contract documented in the schemas table.

### Wrapping

Always wrap errors with context using `%w` for internal Go error chains:

```go
if err := client.GetPage(ctx, pageID); err != nil {
return fmt.Errorf("getting page %s: %w", pageID, err)
}
```

`%w` is for composition between Go layers. At the boundary where an error reaches the user, convert it to an `ErrorPayload` and emit via `outputErr` — that is where `Code`, `Fix`, `Transient`, and `ValidValues` are populated.

### Preventing Double Output

The `printedError` type wraps errors that have already been output to stderr. `main.go` checks for this before printing.

```go
type printedError struct {
msg string
err error
}

func (e *printedError) Error() string { return e.msg }
func (e *printedError) Unwrap() error { return e.err }

func IsPrintedError(err error) bool {
var pe *printedError
return errors.As(err, &pe)
}
```

`main.go` (see "Entry Point") already consults `IsPrintedError` before printing — that is what closes the double-output loop. Any new error path that is emitted via `outputErr` MUST be wrapped in `printedError` so `main` skips the second print.

### Actionable Messages

Errors that reach the user are emitted as structured `ErrorPayload` values. Every payload carries a `Code`, `Message`, `Fix`, and `Transient`. When the rejection is against a closed set of accepted values, include `ValidValues` so the agent can pick from the enumeration without parsing prose.

```go
// Good — structured, populates code/fix/valid_values
return outputErr(&ErrorPayload{
Code:        "SPACE_REQUIRED",
Message:     "space key required",
Fix:         "<cli> page list --space <KEY>  (or set CONFLUENCE_SPACE_KEY)",
Transient:   false,
})

return outputErr(&ErrorPayload{
Code:        "INVALID_VISIBILITY",
Message:     "--visibility must be one of: public, private, unlisted",
Fix:         "<cli> post create --visibility=public --content=...",
Transient:   false,
ValidValues: []string{"public", "private", "unlisted"},
})

// Bad — no code, no fix, no machine-readable shape
return fmt.Errorf("missing space key")
```

### Rate Limiting

Rate-limit failures use the canonical code `RATE_LIMITED` with `Transient: true` and exit code 75. When the upstream `Retry-After` header is present, surface it as `RetryAfter` using the duration grammar (`30s`, `1h30m`):

```go
return outputErr(&ErrorPayload{
Code:       "RATE_LIMITED",
Message:    "API rate limit exceeded",
Fix:        "wait and retry",
Transient:  true,
RetryAfter: "30s",
})
```

JSON envelope:

```json
{"status":"error","error":{"code":"RATE_LIMITED","message":"API rate limit exceeded","fix":"wait and retry","transient":true,"retry_after":"30s"}}
```

Agents use `RetryAfter` when present and fall back to exponential backoff when absent.

### Validation Order

Validate flags, args, and preconditions before the first API call — errors after a side effect are harder to recover from.

## Configuration

Configuration is layered. Environment variables, profiles, and a user config file each occupy a tier in a precedence chain. Resolve every setting through the same chain at startup.

### Precedence

Highest priority first:

1. Explicit flag on the command line.
2. Environment variable specific to the CLI (e.g. `TOOL_API_TOKEN`).
3. Profile selected via `--profile <name>`.
4. Active profile from `<cli> profile use <name>`.
5. User config file at `$XDG_CONFIG_HOME/<cli>/config.cue`.
6. Built-in default.

Env vars outrank `--profile` so a per-shell override beats the loaded profile — same behaviour as `gh`, AWS CLI, and kubectl. Use `--profile` to swap identities; use env to override one setting.

No project-level tier — express per-project overrides via env or `--profile`. If a CLI genuinely needs project-scoped config, accept an explicit `--config <path>` and let `cue/load` handle it; do not walk the filesystem for `.<cli>.*` files.

### XDG Paths

| Env var            | Default              | Use for                                          |
|--------------------|----------------------|--------------------------------------------------|
| `$XDG_CONFIG_HOME` | `$HOME/.config`      | User-owned settings, profiles, preferences       |
| `$XDG_STATE_HOME`  | `$HOME/.local/state` | Runtime-derived data (jobs ledger, feedback log) |
| `$XDG_CACHE_HOME`  | `$HOME/.cache`       | Transient regenerable data                       |

Never write user-owned settings to `$XDG_STATE_HOME` or transient data to `$XDG_CONFIG_HOME` — the split is what lets users back up config independently of cache.

Resolve via the published env vars, NOT `os.UserConfigDir()` / `os.UserCacheDir()` — those return platform-specific paths (`$HOME/Library/Application Support` on macOS, `%AppData%` on Windows) regardless of `$XDG_*`, contradicting the table above:

```go
func xdgPath(envVar, defaultRel string) (string, error) {
if dir := os.Getenv(envVar); dir != "" {
return dir, nil
}
home, err := os.UserHomeDir()
if err != nil {
return "", err
}
return filepath.Join(home, defaultRel), nil
}

// configDir() = xdgPath("XDG_CONFIG_HOME", ".config")
// stateDir()  = xdgPath("XDG_STATE_HOME",  ".local/state")
// cacheDir()  = xdgPath("XDG_CACHE_HOME",  ".cache")
```

### Environment Variables

Env vars carry secrets and per-invocation overrides. They sit at tier 2 in the precedence chain.

```go
type Config struct {
BaseURL  string
Email    string
APIToken string
}

func Load() (Config, error) {
var errs []error
cfg := Config{}

cfg.BaseURL = firstNonEmpty(os.Getenv("TOOL_BASE_URL"), os.Getenv("ATLASSIAN_BASE_URL"))
if cfg.BaseURL == "" {
errs = append(errs, fmt.Errorf("TOOL_BASE_URL or ATLASSIAN_BASE_URL must be set"))
}

cfg.APIToken = firstNonEmpty(os.Getenv("TOOL_API_TOKEN"), os.Getenv("ATLASSIAN_API_TOKEN"))
if cfg.APIToken == "" {
errs = append(errs, fmt.Errorf("TOOL_API_TOKEN or ATLASSIAN_API_TOKEN must be set"))
}

if len(errs) > 0 {
return Config{}, errors.Join(errs...)
}
return cfg, nil
}
```

### Naming and Vendor Fallbacks

The canonical name for every CLI-specific env var is `<CLI>_<NAME>` where `<CLI>` is the uppercase command name and `<NAME>` is SCREAMING_SNAKE_CASE: `AJIRA_API_TOKEN`, `ACON_BASE_URL`, `<CLI>_NO_INPUT`, `<CLI>_DEBUG`. This is the name that appears in error messages, help reference, and the documented contract.

Standard cross-CLI env vars (`NO_COLOR`, `TERM`, `XDG_*`, `HOME`, `PATH`) keep their published names. Never define `<CLI>_NO_COLOR`, `<CLI>_HOME`, or any other CLI-prefixed parallel that shadows a standard — agents and shells already know the unprefixed names and will set them once for the whole environment.

When a CLI belongs to a tool family that has its own vendor namespace (AWS: `aws`, `aws-vault`; GitHub: `gh`, `glab`-from-GitLab side), accept the vendor-prefixed name as a fallback. Tool-specific wins; vendor-prefixed fills in.

```none
1. AJIRA_API_TOKEN    (canonical for this CLI; wins if set)
2. ATLASSIAN_API_TOKEN (vendor fallback for the Atlassian family)
3. error if neither is set
```

Rules for vendor fallbacks:

- The fallback is opt-in per env var, not blanket. Decide deliberately for tokens, base URLs, default project IDs; do not auto-fallback every setting.
- Fallback names MUST be documented in `<cli> help agents` so agents discover them rather than guessing. Lines like `Token: AJIRA_API_TOKEN (or ATLASSIAN_API_TOKEN)` make this concrete.
- CLI-owned boolean env vars (`<CLI>_NO_INPUT`, `<CLI>_DEBUG`, etc.) accept `1`, `true`, `yes` (case-insensitive) as truthy and `0`, `false`, `no` (case-insensitive) or unset as falsy. Any other value is a configuration error (exit 78, `Code: "CONFIG_INVALID"`). Use the strict `envBool` helper from "Runtime Modes". Cross-ecosystem boolean env vars (`FORCE_COLOR`, `CLICOLOR_FORCE`) keep their published lenient semantics — any non-empty, non-falsy value is truthy — so the same value behaves identically across tools. Use the lenient `envTruthy` helper for those.

### User Config

User config lives at `$XDG_CONFIG_HOME/<cli>/config.cue` and holds non-secret defaults the user wants to apply across all invocations.

CUE is the standard config format — type validation and constraints at load time catch errors before runtime. Use the `cuelang.org/go` package to load and validate.

```cue
// $XDG_CONFIG_HOME/<cli>/config.cue
default_project: "GCP" | string
default_board:   1342 | int
output: {
color:  "auto" | "always" | "never"
limit:  int & >0 & <=100 | *25
}
```

The `cuelang.org/go/cue/load` package produces a single `cue.Value` you can decode into your `Config` struct via `value.Decode(&cfg)`.

### Profiles

Profiles persist named bundles of flag values so an agent (or human) does not re-specify the same flags on every invocation. Profiles sit at tiers 3 and 4 in the precedence chain.

Required surface:

```none
<cli> profile save <name> [flags...]   # save current/specified flag values under <name>
<cli> profile use <name>               # set the active profile for subsequent invocations
<cli> profile list                     # list saved profile names
<cli> profile get <name>               # show the contents of one profile
<cli> profile delete <name>            # remove a profile
```

Plus a persistent root flag `--profile <name>` that overrides the active profile for one invocation.

Storage: `$XDG_CONFIG_HOME/<cli>/profiles.cue`, same CUE format and validation as `config.cue`. Use `os.UserConfigDir()` to resolve the path; create the directory with `0700` permissions.

```cue
// $XDG_CONFIG_HOME/<cli>/profiles.cue
active?: string
profiles: [Name=string]: {
name:  Name
flags: [string]: string
}
```

```go
type Profile struct {
Name  string            `json:"name"`
Flags map[string]string `json:"flags"`
}

type ProfileStore struct {
Active   string             `json:"active,omitempty"`
Profiles map[string]Profile `json:"profiles"`
}

func profilesPath(cli string) (string, error) {
dir, err := configDir()
if err != nil {
return "", err
}
return filepath.Join(dir, cli, "profiles.cue"), nil
}
```

Read with `cuelang.org/go/cue/load` and decode into `ProfileStore` exactly as `config.cue` is loaded. Write by encoding the struct with `cuelang.org/go/encoding/gocode/gocodec`, then serialising with `cuelang.org/go/cue/format`. The struct tags above are reused — gocodec honours `json` tags. The CLI is the only writer; re-parse the existing file before re-emitting if you want to preserve user comments.

Rules:

- `profile save` MUST refuse to persist any flag the CLI documents as carrying secrets, and SHOULD exclude every credential-source flag in the `secretFlags` registry (`--token-file`, `--client-secret-file`, `--private-key-file`, etc.) by default. Profile storage uses normal file permissions and is not a secrets store.
- Active profile from `profile use` is recorded in the same file via the `Active` field; reading it requires no separate lookup.
- `profile delete` on a non-existent name returns exit 0 with `Code: "ALREADY_DELETED"` for idempotency.
- Available profile names appear in `<cli> help agents` so the agent discovers identities without reading config files. Up to 10 names appear inline; surplus profiles are reachable via `<cli> profile list`.

### Secrets

Secrets MUST NEVER be accepted via flags. Flag values leak everywhere a command line goes:

- Process listings (`ps`, `top`, `htop` show full argv to other users on the system).
- Shell history (`bash_history`, `zsh_history`).
- CI logs (most CI systems log every command they run).
- Terminal scrollback and `tmux` capture buffers.
- Cobra usage messages on error (which echo the failing invocation).

A token leaked via `--token <value>` once is permanently compromised — unsetting it later does not undo the exposure.

Three accepted input paths, in order of preference:

1. **Environment variable**: the canonical channel. `<CLI>_API_TOKEN`, with the vendor-fallback rules from "Naming and Vendor Fallbacks".
2. **File reference flag**: a `*-file` flag whose value is a path, not the secret itself — `--token-file`, `--client-secret-file`, `--private-key-file`, whichever variants the CLI accepts. Register every variant under the `secretFlags` map below. Permissions on the file are the user's responsibility but the CLI SHOULD warn (stderr only, never stdout) if the file is world-readable.
3. **Stdin pipe**: when the secret is being generated or piped from another tool. Real-world precedent: `docker login --password-stdin`, `gh auth login --with-token < token.txt`. Modern tutorials universally use this pattern.

No fourth path exists. Not `--token`, not `--password`, not `--api-key`. If a third-party SDK requires a string at a function call, read it from one of the three accepted paths first and pass the value through.

Mark secret-bearing flags with a small registry so the profile-save and debug-redact code can both consult it:

```go
// secretFlags lists every flag NAME that carries a path to a secret. Add
// each variant the CLI accepts; profile-save and the HTTP debug logger both
// consult this set. Keep entries lower-case to match Cobra's normalisation.
var secretFlags = map[string]struct{}{
"token-file":         {},
"client-secret-file": {},
"private-key-file":   {},
}

func IsSecretFlag(name string) bool {
_, ok := secretFlags[name]
return ok
}
```

`profile save` reads `IsSecretFlag` and skips matching flags (see "Profiles"). The HTTP client logger reads it indirectly via header redaction.

Redaction in `--debug` and `--verbose`:

```go
var redactedHeaders = map[string]struct{}{
"authorization": {},
"x-api-key":     {},
"x-auth-token":  {},
"cookie":        {},
"set-cookie":    {},
}

func logRequest(w io.Writer, req *http.Request) {
fmt.Fprintf(w, "> %s %s\n", req.Method, req.URL.Path)
for k, vs := range req.Header {
if _, redact := redactedHeaders[strings.ToLower(k)]; redact {
fmt.Fprintf(w, "> %s: [REDACTED]\n", k)
continue
}
for _, v := range vs {
fmt.Fprintf(w, "> %s: %s\n", k, v)
}
}
}
```

The redaction set covers HTTP standards plus any custom header the CLI documents as carrying credentials. When in doubt, redact.

Never log request or response bodies in `--debug` or `--verbose` if those bodies could contain secrets (token-issuance endpoints, session refresh, configuration reads). Body logging stays opt-in via a separate flag (e.g. `--debug-bodies`) that the user toggles deliberately.

### Validation

Validate configuration at load time. CUE handles schema validation natively; aggregate any remaining application-level errors before returning so the user can fix everything in one pass.

```go
var errs []error
if cfg.BaseURL == "" {
errs = append(errs, fmt.Errorf("BASE_URL must be set"))
}
if cfg.APIToken == "" {
errs = append(errs, fmt.Errorf("API_TOKEN must be set"))
}
return errors.Join(errs...)
```

Configuration errors (malformed CUE, unknown schema, unreadable file at a tier the CLI was instructed to read) exit with code 78 (`ExitConfig`) and `ErrorPayload.Code: "CONFIG_INVALID"`. Missing-required-value errors exit with code 2 (`ExitUsage`) — the user just needs to set the value.

## Async Jobs

Some operations submit work to an upstream queue and return before completion (long renders, exports, batch operations). The CLI treats them uniformly: submit returns immediately by default, `--wait` blocks until completion, and a persistent ledger lets a killed `--wait` resume without resubmitting.

### Submission and Waiting

Every async-submitting command supports `--wait` paired with `--timeout <duration>` (default `10m`). With `--wait`, the CLI polls upstream with backoff and returns the final result in the same envelope shape as a synchronous command. Without `--wait`, the response carries the job ID and current status so the caller can poll later.

Timeout returns exit 75 (`ExitTransient`) with `Code: "WAIT_TIMEOUT"`. The job ID stays in the response so the agent resumes by re-invoking `--wait` against the same ID.

```go
var (
renderWait    bool
renderTimeout time.Duration
)

func init() {
renderCmd.Flags().BoolVar(&renderWait, "wait", false,
"Block until the job completes")
renderCmd.Flags().DurationVar(&renderTimeout, "timeout", 10*time.Minute,
"Maximum wait duration; exit 75 on expiry")
}
```

### Jobs Ledger

Async state lives at `$XDG_STATE_HOME/<cli>/jobs.jsonl`. One JSON record per line, append-only:

```jsonl
{"job_id":"job_8f2a","kind":"render","status":"complete","submitted_at":"2026-04-30T18:22:11Z","completed_at":"2026-04-30T18:22:48Z","duration_s":35,"result":{"url":"https://.../out.mp4"}}
```

```go
type JobRecord struct {
JobID       string         `json:"job_id"`
Kind        string         `json:"kind"`
Status      string         `json:"status"` // submitted | running | complete | failed | cancelled
SubmittedAt time.Time      `json:"submitted_at"`
StartedAt   *time.Time     `json:"started_at,omitempty"`
CompletedAt *time.Time     `json:"completed_at,omitempty"`
DurationS   int            `json:"duration_s,omitempty"`
Result      map[string]any `json:"result,omitempty"`
Error       *ErrorPayload  `json:"error,omitempty"`
}
```

JSONL at `$XDG_STATE_HOME` matches the runtime-state tier; CUE at `$XDG_CONFIG_HOME` is for user-edited config.

### Concurrent Append

Concurrent invocations on the same host MUST NOT corrupt the ledger. Take an exclusive file lock around the append:

```go
func appendJob(path string, rec JobRecord) error {
f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0600)
if err != nil {
return err
}
defer f.Close()

if err := syscall.Flock(int(f.Fd()), syscall.LOCK_EX); err != nil {
return err
}
defer syscall.Flock(int(f.Fd()), syscall.LOCK_UN)

return json.NewEncoder(f).Encode(rec)
}
```

`syscall.Flock` is POSIX only — use `github.com/gofrs/flock` for cross-platform support if the CLI ships to Windows.

The ledger is per-host. Do not assume it is shareable across hosts even when `$XDG_STATE_HOME` resolves to a network filesystem.

### Required Subcommands

```none
<cli> jobs list                  # list ledger entries
<cli> jobs get <id>              # show one entry
<cli> jobs cancel <id>           # cancel an in-flight job upstream
<cli> jobs prune                 # remove completed/failed entries by age or status
<cli> jobs repair --force        # rewrite ledger keeping only valid lines (destructive)
```

`jobs prune` accepts `--older-than <duration>` and `--status <status>` to narrow scope; defaults to completed and failed records older than 30 days.

`jobs repair` is the recovery path for a corrupted ledger; kept distinct from `prune` so corruption recovery never overlaps with age- or status-based removal. It rewrites the ledger in place and drops lines that fail to parse, so it requires `--force` per the destructive-op rule under "Mutation Safety".

### Reader Tolerance

`jobs list`, `jobs get`, and `jobs prune` MUST skip malformed lines, emit a stderr warning naming the line number, and continue. A corrupted ledger is degraded but usable.

```go
func readLedger(path string) ([]JobRecord, error) {
f, err := os.Open(path)
if err != nil {
return nil, err
}
defer f.Close()

var records []JobRecord
scanner := bufio.NewScanner(f)
scanner.Buffer(make([]byte, 64<<10), 16<<20) // up to 16 MB per record
for line := 1; scanner.Scan(); line++ {
var rec JobRecord
if err := json.Unmarshal(scanner.Bytes(), &rec); err != nil {
fmt.Fprintf(os.Stderr, "warning: skipping malformed ledger line %d\n", line)
continue
}
records = append(records, rec)
}
return records, scanner.Err()
}
```

### Signal Handling During --wait

SIGINT exits 130 (128+SIGINT); SIGTERM exits 143 (128+SIGTERM) via the `SignalExitCode` shim under "Signal Handling". The job ID is written to stderr in both cases. The upstream job continues running; the ledger entry remains marked in-progress. Resuming is an explicit action — the agent re-invokes `--wait` against the same job ID, or `<cli> jobs cancel <id>` to stop the work.

Exit 75 is reserved for transient failures the caller MAY auto-retry; signal interrupts are user intent and MUST NOT be conflated. See "Signal Handling" below for the context plumbing.

## API Client

### Structure

```go
type Client struct {
baseURL    string
httpClient *http.Client
auth       string
verbose    io.Writer
}

func NewClient(cfg *config.Config) *Client {
return &Client{
baseURL: cfg.BaseURL,
httpClient: &http.Client{
Timeout: 30 * time.Second,
},
auth: cfg.APIToken,
}
}
```

### Standard Methods

Implement `Get`, `Post`, `Put`, `Delete` methods that handle:

- Authentication headers (Basic or Bearer)
- Content-Type setting
- Response body reading and closing (`defer resp.Body.Close()`)
- Status code validation (2xx range)
- Error parsing into `APIError` type

### APIError Type

```go
type APIError struct {
StatusCode int
Status     string
Code       string // upstream error identifier when exposed
Messages   []string
Method     string
Path       string
RetryAfter string // parsed from Retry-After header, duration grammar
}

func (e *APIError) Error() string {
if len(e.Messages) > 0 {
return fmt.Sprintf("%s %s: %s (%d)", e.Method, e.Path, strings.Join(e.Messages, "; "), e.StatusCode)
}
return fmt.Sprintf("%s %s: %s", e.Method, e.Path, e.Status)
}
```

### APIError to ErrorPayload

Map HTTP status to a structured `ErrorPayload` at the boundary where the error reaches the user. Prefer the upstream `Code` when present, fall back to the canonical name for the status:

| Status      | Code                         | Transient | Notes                                    |
|-------------|------------------------------|-----------|------------------------------------------|
| 400         | upstream or `BAD_REQUEST`    | false     | usage-shaped failure from the API        |
| 401         | `AUTH_EXPIRED` or upstream   | false     | suggest `<cli> auth refresh` in `Fix`    |
| 403         | `PERMISSION_DENIED`          | false     |                                          |
| 404         | `NOT_FOUND`                  | false     |                                          |
| 409         | `CONFLICT`                   | false     | re-fetch state and retry deliberately    |
| 408/425/429 | `RATE_LIMITED`               | true      | populate `RetryAfter` from `Retry-After` |
| 5xx         | upstream or `UPSTREAM_ERROR` | true      | exit 75; agent may retry with backoff    |

### Pagination

Cursor-based pagination is the rule. Every list-style command exposes `--limit` (bounded result set) and `--next <token>` (opaque cursor) to the caller. Offset-based pagination drifts when rows are added or deleted during traversal — agents that paginate mutating data with offsets silently skip or duplicate records.

Rules:

- The cursor in `--next` and at `Envelope.Next` is opaque to the caller. Never document its internal structure; agents MUST treat it as a string.
- Cursors are short-lived. Valid for at least a normal traversal session (minutes), not guaranteed beyond an hour, never across sessions.
- Cursors are bound to the query that produced them. Reusing a cursor against a different filter, sort, or `--fields` selection returns `Code: "CURSOR_INVALID"` with exit 5 (`ExitConflict`).
- When the upstream API only offers offset pagination AND the data is provably static (an archive of closed records, an immutable log), the CLI MAY use offset internally — but MUST still expose `--next` to the caller and translate the opaque token to an offset. The caller never sees offsets.
- Set a maximum page count to prevent runaway pagination.
- Trim results to the exact `--limit` requested.

Cursor encoding (base64-JSON) lets the CLI control the format regardless of what the upstream API uses:

```go
type cursor struct {
Offset int    `json:"o,omitempty"`
Token  string `json:"t,omitempty"`
Query  string `json:"q,omitempty"` // hash of filter+sort+fields
}

func encodeCursor(c cursor) string {
b, _ := json.Marshal(c)
return base64.RawURLEncoding.EncodeToString(b)
}

func decodeCursor(s string) (cursor, error) {
b, err := base64.RawURLEncoding.DecodeString(s)
if err != nil {
return cursor{}, err
}
var c cursor
if err := json.Unmarshal(b, &c); err != nil {
return cursor{}, err
}
return c, nil
}
```

When decoding fails, or the embedded query hash does not match the current invocation's filter/sort/fields, return:

```go
return outputErr(&ErrorPayload{
Code:      "CURSOR_INVALID",
Message:   "pagination cursor is invalid or stale",
Fix:       "restart the traversal without --next",
Transient: false,
})
```

Exit code is 5 (`ExitConflict`) — the underlying state moved out from under the cursor, not a usage mistake.

### Verbose Logging

Support verbose HTTP logging via an `io.Writer` that can be set to `os.Stderr`:

```go
func (c *Client) SetVerboseOutput(w io.Writer) {
c.verbose = w
}
```

Log request method, path, status code, and duration when verbose is enabled.

## Signal Handling

`Execute` (see "CLI Architecture / Root Command") wires a goroutine that captures SIGINT and SIGTERM into a package-level `caughtSignal` value, then cancels the root context. `main` (see "Entry Point") calls `SignalExitCode()` before consulting the error path so a cancelled run exits with the POSIX `128+signum` code: 130 for SIGINT, 143 for SIGTERM.

The capture is required because `signal.NotifyContext` alone would not produce 130/143 — a cancelled context surfaces as `context.Canceled` and falls through to `ExitFailure (1)`. The `caughtSignal` value is what holds the documented contract.

Exit 75 (`ExitTransient`) is reserved for transient failures the caller MAY auto-retry; signal interrupts are user intent and MUST NOT be conflated. Agents that see 130 or 143 must treat the run as cancelled, not retryable.

Pass context through to API calls and long-running operations. Check `ctx.Done()` in loops and pagination.

## TUI Package

`internal/tui/` holds terminal formatting utilities.

### Colour Constants

```go
package tui

import "github.com/fatih/color"

var (
ColorError   = color.New(color.FgRed)
ColorWarning = color.New(color.FgYellow)
ColorSuccess = color.New(color.FgGreen)
ColorHeader  = color.New(color.FgGreen)
ColorDim     = color.New(color.Faint)
)
```

### Formatting Helpers

```go
func Annotate(format string, a ...any) string {
text := fmt.Sprintf(format, a...)
return ColorDim.Sprintf("(%s)", text)
}

func Bracket(format string, a ...any) string {
text := fmt.Sprintf(format, a...)
return ColorDim.Sprintf("[%s]", text)
}
```

### Progress Indicator

A simple carriage-return progress indicator that only outputs to terminals:

```go
type Progress struct {
writer    io.Writer
isTerminal bool
}

func NewProgress(w io.Writer) *Progress {
fd, ok := w.(interface{ Fd() uintptr })
isTerm := ok && term.IsTerminal(int(fd.Fd()))
return &Progress{writer: w, isTerminal: isTerm}
}

func (p *Progress) Update(msg string) {
if !p.isTerminal {
return
}
fmt.Fprintf(p.writer, "\r%s", msg)
}

func (p *Progress) Done() {
if !p.isTerminal {
return
}
fmt.Fprint(p.writer, "\r\033[K")
}
```

## Testing

### Design for Testability

Declare interfaces at the consumer so tests can substitute without mocking the full API surface:

```go
// In the package that consumes the API client
type PageGetter interface {
GetPage(ctx context.Context, pageID string) (*api.Page, error)
}
```

### HTTP Testing

Use `httptest.NewServer` to exercise real HTTP behaviour without mocks:

```go
func TestGetPage(t *testing.T) {
server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
w.Header().Set("Content-Type", "application/json")
fmt.Fprint(w, `{"id": "123", "title": "Test"}`)
}))
defer server.Close()

client := api.NewClient(&config.Config{BaseURL: server.URL})
page, err := client.GetPage(context.Background(), "123")
if err != nil {
t.Fatalf("unexpected error: %v", err)
}
if page.Title != "Test" {
t.Errorf("got title %q, want %q", page.Title, "Test")
}
}
```

### Table-Driven Tests

Use table-driven tests for functions with multiple input/output scenarios:

```go
func TestValidateSpaceKey(t *testing.T) {
tests := []struct {
name    string
input   string
wantErr bool
}{
{"valid", "MYSPACE", false},
{"with numbers", "SPACE123", false},
{"empty", "", true},
{"special chars", "MY SPACE!", true},
}
for _, tt := range tests {
t.Run(tt.name, func(t *testing.T) {
err := validateSpaceKey(tt.input)
if (err != nil) != tt.wantErr {
t.Errorf("validateSpaceKey(%q) error = %v, wantErr %v", tt.input, err, tt.wantErr)
}
})
}
}
```

### Test Utilities

- `t.TempDir()` for temporary file and directory tests
- `t.Setenv()` for environment variable tests (auto-cleanup)
- `testdata/` directory for JSON fixtures and sample files
- Flag reset helpers when testing cobra commands (flags are package-level mutable state)

## Recommended Dependencies

These packages have been evaluated against alternatives and are recommended for Go CLI projects.

### Core

| Package                  | Purpose                                          |
|--------------------------|--------------------------------------------------|
| `github.com/spf13/cobra` | CLI framework: commands, flags, help, completion |
| `github.com/fatih/color` | Terminal colour output with NO_COLOR support    |
| `golang.org/x/term`      | Terminal detection, TTY checks                   |

### Markdown and Content

| Package                                           | Purpose                                     |
|---------------------------------------------------|---------------------------------------------|
| `github.com/yuin/goldmark`                        | Markdown parsing and rendering, GFM support |
| `github.com/charmbracelet/glamour`                | Terminal markdown rendering with themes     |
| `github.com/JohannesKaufmann/html-to-markdown/v2` | HTML to Markdown conversion                 |

### Configuration

| Package          | Purpose                                             |
|------------------|-----------------------------------------------------|
| `cuelang.org/go` | CUE language for typed configuration and validation |

### Authentication

| Package               | Purpose                                            |
|-----------------------|----------------------------------------------------|
| `golang.org/x/oauth2` | OAuth2 with Google Application Default Credentials |

### Utilities

| Package                      | Purpose                         |
|------------------------------|---------------------------------|
| `github.com/google/uuid`     | UUID generation                 |
| `github.com/chzyer/readline` | REPL and interactive line input |
| `github.com/coder/websocket` | WebSocket client                |
| `golang.org/x/mod`           | Module and version handling     |

### Testing

| Package              | Purpose                           |
|----------------------|-----------------------------------|
| `go.uber.org/goleak` | Goroutine leak detection in tests |

### Dependency Philosophy

Keep dependencies minimal and purposeful. Every dependency is a maintenance burden. Before adding a package:

- Check if the standard library can do it
- Evaluate alternatives for size, maintenance, and API quality
- Prefer packages with no or few transitive dependencies

## Build and Distribution

### Building

```bash
go build -o <name> ./cmd/<name>/
```

### Version Injection

Set the version at build time:

```bash
go build -ldflags "-X <module>/internal/cli.Version=v1.0.0" -o <name> ./cmd/<name>/
```

### Linting

Include a `.golangci.yml` at the project root. A minimal starting configuration:

```yaml
linters-settings:
  errcheck:
    exclude-functions:
      - fmt.Fprint
      - fmt.Fprintf
      - fmt.Fprintln
```

Run before commits: `golangci-lint run`

### Distribution

Publish via Homebrew tap for easy installation:

```bash
brew tap <user>/tap
brew install <name>
```

Also support `go install`:

```bash
go install <module>@latest
```
