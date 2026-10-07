#!/usr/bin/env bash
# ============================================================================
# Markov - a general-purpose LLM harness and coding agent
# Copyright (c) 2026 Damiano Monaco
# SPDX-License-Identifier: MIT
# ============================================================================

MA_VERSION="0.1.0"

set -o pipefail
[[ -v MA_DEVELOP ]] && set -u

usage() {
	local name="$(basename "$0")"
	_markov_cli_help=\
"markov - a general purpose LLM harness and coding agent [v${MA_VERSION}]

Usage:  $name [options]

Examples:
    $name -u http://127.0.0.1:8012/v1/
    $name -m moonshotai/kimi-k3

Options:
  -u, --url <url>          Set endpoint API URL manually (for local models)
                           Environment variable: MA_API_URL_CLI
  -m, --model <prv/model>  Requested model from a provider
                           Must be prefixed with provider:
                             -m <provider/model_id>
                           model_id can be a partial match:
                             -m openrouter/glm
                           Providers are resolved using the open-source
                           database at 'https://models.dev/api.json'
                           To add or override a provider manually, add
                             MARKOV_PROVIDERS[name]='ENV_KEY_NAME|URL'
                           in your config.sh
  -k, --key <k>            Override API key
                           Not needed if a provider-specific key is found
  --list-providers         List all providers from models.dev api.json
  --update-providers       Force-update the providers database file
  --list-models            List available models for a provider and exit
  --working-dir <dir>      Specify working directory instead of \$PWD
  --config-dir <dir>       Add global configuration directory
  --modules-dir <dir>      Add custom directory for modules
                           Environment variable: MA_MODULES_DIR
  --skills-dir <dir>       Add custom directory for skills
                           Environment variable: MA_SKILLS_DIR
  --prompts-dir <dir>      Add custom directory for prompt templates
                           Environment variable: MA_PROMPTS_DIR
  --personas-dir <dir>     Add custom directory for personas
                           Environment variable: MA_PERSONAS_DIR
  -s, --session <name>     Name of the file-based session to load or create
                           If <name> is an existing session file, it will be
                           imported and used as the session file
                           Environment variable: MA_SESSIONS_DIR
  --new <name>             Same as --session, but discard the existing one
  --resume                 Resume the most recent session on disk
  -n, --no-session         Ephemeral session: memory only, no disk
  --sessions-dir <dir>     Override session storage directory
  --list-sessions          List all sessions and exit
  --system <arg>           Override default system prompt
                           Environment variable: MA_SYSTEM_PROMPT_CLI
  --append-system <arg>    Append to system prompt
                           Environment variable: MA_APPEND_SYSTEM_PROMPT_CLI
  --thinking <level>       Set thinking effort: off|low|medium|high|xhigh|max
                           Environment variable: MA_THINKING_CLI
  --no-thinking            Disable reasoning (same as --thinking off)
  --hide-thinking          Disable printing of thinking blocks
  --no-preserve-think      Do not store or send back thinking blocks
  -t, --tools <list>       Comma-separated list of tools that will replace
                           the default built-in tools
                           The tools list can still change at runtime if tools
                           are found on reload
                           - Core built-in tools, enabled by default:
                             read,write,edit,bash,skills,execute,websearch,
                             delegate
                           - Other built-in tools, marked as lazy by default:
                             docs,reload
                             These tools can be enabled as core tools only if
                             --no-lazy-docs and --no-lazy-reload are enabled
                           - Optional built-in tools:
                             symbols,ask,find,grep,ls
                           Tools from modules are automatically added
  --allowed-tools <list>   Comma-separated list of tools to allow
                           Actively excludes any core tools not specified
                           Lazy tools found at runtime are still allowed
  -l, --lazy <list>        Comma-separated list of lazy tools
                           Lazy tools are called by the 'execute' tool
                           They stay hidden until searched for by the LLM,
                           or until the name/schema is provided by the user
  --no-lazy-reload         Don't automatically mark 'reload' as a lazy tool
                           Makes it directly callable without 'execute' tool
                           Alternatively, from config:
                             MA_USE_LAZY_RELOAD=false
  --no-lazy-docs           Don't automatically mark 'docs' as a lazy tool
                           Makes it directly callable without 'execute' tool
                           Alternatively, from config:
                             MA_USE_LAZY_DOCS=false
                           or from module:
                             unset 'MA_LAZY_TOOLS[docs]'
  --no-tools               Disable all tools (plain chat mode)
  --no-context-files       Disable all external files used for instrunctions
                           like custom SYSTEM.md and AGENTS.md files
  --modules <list>         Comma-separated list of modules to use
  --no-modules             Disable all modules
  --no-prompts             Disable searching for prompt template files
  --persona <name>         Load persona by name from local or global config
  --llm-opts <list>        Specify LLM parameters.
                           Format: 'key1=val,key2=val,...'
                           Keys:
                             temperature, max_tokens, top_p, top_k, min_p,
                             seed, presence_penalty, repetition_penalty,
                             frequency_penalty 
  -p, --print <arg>        One-shot mode: print response and exit
  --file <filepath>        Attach a file as first message
  --print-all              Show all output normally hidden in one-shot mode
  --no-stream              Disable streaming response
  --no-check-endpoint      Skip initial request for local model info
  --ctx <tokens>           Set context size to use when not auto-detected
  --no-spinner             Suppress the spinner
  --max-turns <N>          Max number of iterations in the agent loop
  --ipc                    Enable inter-process communication service
                           IPC client don't need this enabled
  --ipc-token <ipc-PID>    IPC token used to send requests to another instance
  --send <cmd> [payload]   Send an IPC request to another instance
                           Requires --ipc-token or MA_IPC_TOKEN
                           IPC commands:
                             status: return IDLE or RUNNING
                             queue: queue prompt for the next IDLE time
                             steer: send prompt for the next turn
                             abort: interrupt the running operation
                             shutdown: shut down the instance
                           queue and steer require a 'payload'
  --ipc-secure             Enable full token validation for IPC requests
                           By default, the server does not validate the token
                           (only the PID is needed to connect, not the secret)
  --ipc-only               Run in IPC-only mode with an interactive prompt
                           Requires --ipc-token or MA_IPC_TOKEN
  -q, --quiet              Suppress common startup messages on first load
  --                       The rest of the arguments are not evaluated
                           Pass custom options to modules and config files
  -a, --trust-dir          Allow loading of local context files/modules/skills
  --callcheck-always       Ask for confirmation before every tool call
  --callcheck-analyzer     Let the LLM analyze tool calls
                           Fall back to user confirmation for suspicious calls
                           It is better to configure the 'call_analyzer' role
                           with a trusted endpoint/model
  --callcheck-pattern      Catch risky commands via pattern match
                           Warning: This mechanism is intended to catch
                           accidental misuse, not malicious input
                           It should not be relied upon as a security control
  --confine                Confine built-in tools (block path traversal)
                           Replaces Bash tool with a neutralized version
  -h, --help               Show this help text
  --docs                   Print the docs
  --readme                 Print the entire README.md
  -v, --version            Show version number"
	printf '%s\n' "$_markov_cli_help"
	return 1
}

ma_init_readme() {
	local _readme_incipit
	[[ -v MA_README ]] || {
		IFS= read -r -d '' _readme_incipit <<'EOF'

# Markov

A general-purpose LLM harness and coding agent implemented as a single,
hackable Bash script.

![Markov](demo.gif)

`Markov` works with just `curl`, [jq], and very common Unix utilities as its
dependencies, so you can download the script file and run it right away,
provided you have Bash 5+.

For `markov`, everything else is `OSP` (*On-Site Procurement*).
`Markov` infiltrates your system without any other baggage, working only with
whatever tools you already use or are comfortable installing yourself.

`Markov` supports **delegation of sub-tasks** to **sub-agents** running
(synchronously) in dedicated `threads` to avoid polluting the parent thread.
Each sub-agent has its own customizable `role` and `endpoint`.

`Markov` can be easily extended via `modules`, which are simply scripts in a
directory that provide new `slash commands`, `tools`, and `hook functions`.

Modules can add or replace built-in functionality, even while running, using
the `/reload` command [pi]-style: It sources the modules and config scripts,
reloads context files, and applies the changes without restarting the harness.

The documentation is self-contained within the harness script itself, and
by having access to `docs` and a `reload` tool, the model can self-modify its
own modules and then source them live.

Because the **REPL and the Bash interpreter are basically one and the same**,
you have complete control over the entire internal state of the harness.
It is easy to inspect, modify, and hack stuff on the fly.

For example, enter this at the prompt to acquire a new `/ciao` command:

```bash
!command_ciao() { echo "Ciao, ${1:-Mondo}"; }
```

A more interesting example: make your LLM able to call a new tool mid-session
*without invalidating the model's `cached prompt prefix`* by dropping this:

```bash
!
execute_ciao() {
  local name=$(jq -r '.name // "Mondo"' <<< "$1")
  echo "Ciao, $name!"
}
MA_TOOL[ciao]='{
  "type": "function",
  "name": "ciao",
  "description": "Say ciao to someone",
  "parameters": {
    "type": "object",
    "properties": {
      "name": { "type": "string" }
    }
  }
}'
MA_LAZY_TOOLS[ciao]=1
```

`Markov` supports its own version of dynamic tool discovery (**lazy tools**)
that doesn't rely on any provider-specific functionality.

As you may have noticed, using `!` lets you execute Bash commands directly
in the running process, and the internal state of `markov` is inspectable
and modifiable. Using `!!` instead executes the command in a *separate* PTY,
and its output is captured and sent to the LLM.

`Markov` assumes your favorite editor is set in `EDITOR` or `VISUAL`.

Optional utilities you may want in your `PATH` (recommended):

* `fzf` or `skim`: A fuzzy finder and picker for better completion.
* `perl` or `python`: This will speed up the `edit` tool considerably.
* `lynx` or `w3m`: Terminal web browser for rendering web pages.
* `pdftotext`, `mutool` or `gs`: Basic PDF text extraction support.

`Markov` was tested with `bash` version 5+ on Linux and Windows with both
[MSYS2] Bash and [Git Bash]. It has been used extensively with local models
using the excellent [llama.cpp] as the inference backend.

`Markov` is **still under development** and has many limitations, so things may
not work as intended. 

[jq]: https://github.com/jqlang/jq
[pi]: https://github.com/earendil-works/pi
[MSYS2]: https://www.msys2.org/
[Git Bash]: https://git-scm.com/install/windows
[llama.cpp]: https://github.com/ggml-org/llama.cpp

## Features

* **Streaming API** compatibility (*text-output only*):
  `OpenAI Chat Completions`, `OpenAI Responses`, `Anthropic`
* Multiple `threads` within the same session
* **Sub-task delegation**: custom, configurable sub-agents run (synchronously)
  in their dedicated `threads` 
* **Lazy tools**: dynamically discover and use new tools at runtime without
  invalidating the model's `cached prompt prefix`
* **Self-modifying capability**: the model can write and autonomously reload
  its own `modules` at runtime using the `reload` tool
* Built-in tools enabled by default: `read`, `write`, `edit`, `bash`, 
  `skills`, `execute`, `websearch`, `delegate`
* Additional tools: `symbols`, `reload`, `docs`, `ask`, `grep`, `find`, `ls`
* **Built-in tool call analyzer**: use a trusted LLM to analyze tool calls
* **Inter-process communication** for sending and queueing messages from
  external scripts/processes
* Ephemeral and persistent file-based sessions
* Configurable model parameters (`temperature`, `seed`, `top_k`, etc.)
* Bash scripts (`modules`) as a natural extension mechanism
* Configurable context and project-specific files
* File attachment via `/file` command
* Custom prompt templates with argument expansion
* One-shot mode: `markov.sh --file cat.jpg -p "what is it? and why is a cat?"`

## Security note

`Markov` provides no validation or restrictions on Bash commands or tool
execution by default. Tools and modules can execute arbitrary commands with
the permissions of the user running the script, so **it is a good idea to use
a limited user**.

By default, only *global* modules and context files are loaded. To allow
modules and context files from the *current working directory*, use the
`--trust-dir` or `-a` CLI option.

The `--callcheck-pattern` CLI option enables confirmation prompts for tool
calls flagged by pattern matching. It is intended to catch accidental misuse.

The `--callcheck-analyzer` option enables an LLM-based security filter that
checks tool calls for suspicious or dangerous actions. It should be configured
to use a fast and trusted endpoint (see docs section on `call_analyzer`).

Use `--callcheck-always` to require confirmation for every tool call, or
`--confine` to restrict built-in tools to the current working directory (and
its subdirectories) plus temporary directories, blocking access outside of
them. This also disables `bash`, since it cannot be easily restricted.

## Limitations

This is Bash.

`Markov` is heavily **llama.cpp-oriented**. Support for SOTA model providers
and their proprietary quirks may be limited and bare-bones.

There is **no pretty-printing** for LLM responses.

The interactive interface is just `readline`, so you should rely on an external
editor to write long multiline messages efficiently.

The loop responds to a pause command between turns (with `P`, or `spacebar`),
but the only way to steer the model or queue up prompts without interrupting
an ongoing streaming response is through the `IPC` mechanism.

On Windows there can be a noticeable lag when spawning processes compared to
Linux, where it is almost instantaneous. But most of the time, an LLM loop is
either streaming inference or waiting for a tool to complete, so the overhead
of spawning processes is likely irrelevant.

Documentation is still WIP. 

If you hate all of this, `markov` is probably not for you.

## Wait, but why?

I always wanted to tinker with *local* LLMs, and building my own hackable
harness script seemed like the perfect way to do that. I chose Bash because
it's the most **low-effort, Turing-complete language available on practically
any Linux system**, and I cannot confirm or deny that this was actually born
out of a joke.

I find the myriad of existing harnesses either bloated, overcomplicated, or
simply annoying. The only half-decent exception, in my opinion, is [pi].
It's easy to see that `pi` was a major inspiration for `markov`, but unlike
`pi`, there are fortunately no `Node.js` dependencies to worry about.

## License

Licensed under the MIT License.

It means you can do whatever you want with it, but don't @ me if your clanker
completes its self-destruct sequence on your system.


EOF
	}
	ma_init_docs
	MA_README="${_readme_incipit}${MA_DOCS}"
}

ma_init_docs() {
	[[ -v MA_DOCS ]] || {
		IFS= read -r -d '' MA_DOCS <<'EOF'
## Docs

`markov` is a general-purpose LLM harness and coding agent implemented as a
single, hackable Bash script.

### CLI arguments

Use `--help` to get a list of all available command-line options.

Quick examples:

```bash
$ markov.sh -u http://127.0.0.1:8000/v1
$ markov.sh -m openrouter/glm -k your-key --session mytask
$ markov.sh --no-tools -- --custom-option
```

Arguments after `--` are not evaluated by `markov`. Use it to pass custom
options to the config file and modules.


### REPL

```
[General]
 /config       Edit or set up config file
 /model        Switch the model. All threads will be updated
               Optionally specify for what role (default 'main')
               Usage:
                 /model '<provider/model-name>' [role]
 /reload       Reload context files and re-source configuration and modules
               System prompts and tools of all threads will be updated, so
               this may invalidate the 'cached prompt prefix' of the model if
               context files, module tools, or skill descriptions have changed
 /persona      Rebuild the system prompt and inject a Persona file into it,
               replacing the current Persona if one is already set
               Only threads using the 'main' role are affected
               May invalidate the 'cached prompt prefix' of the model
 /continue     Let model continue (with no new user message, if not required)
 /help         Display the documentation
 /quit         Exit

[Session]
 /import       Replace the current session with one loaded from a file
 /export       Export the current session to another file
 /new          Start anew, wiping the current session and all threads
               Pass a new name to create a fresh session file
 /fork         Fork the current or specified session into a new session
 /session      Session utility.
               Accept argument for sub-commands:
                 info (default): display session info
                 make-ephemeral: make session ephemeral (no saved on disk)
 /save         Manually save the session to disk
               Also converts ephemeral sessions into files
               NOTE: Sessions are saved automatically during agent runs
               Manual changes (e.g. /compact, /rewind) are not saved
               automatically and must be saved manually with /save
 /usage        Print estimated session costs
 /roles        List all the roles

[Threads]
 /switch       Create or switch to a user thread by name, optionally under a
               given role:
                 /switch <thread_name> [role]
               If the thread has a delegated sub-task, automatically switch
               to the deepest sub-thread to continue the task
               (Note: a thread cannot continue until its child has returned)
 /thread       Accept argument for sub-commands:
                 inspect: shows actual session messages (JSON) in memory
                 context: display system-prompt and json tools used
                 edit: open editor on thread messages (JSON) in memory
                 tools: print the tool list for current thread
 /compact      Manually compact the messages of the thread
               Compaction is also triggered automatically when context usage
               exceeds MA_COMPACT_THRES (enabled by default)
               Active skills are reinjected after compaction
               Customization:
                 MA_COMPACT_AUTO: true
                 MA_COMPACT_THRES: 85
                 MA_COMPACT_BUDGET_HEAD: 0
                 MA_COMPACT_BUDGET_TAIL: 10000
                 MA_COMPACT_PROMPT: replace default compaction prompt
               Head/tail budgets are approximate character counts specifying
               how much of the beginning and end of the thread to preserve
               Optional head and tail budgets can be passed to /compact:
               Example:
                 /compact 0 5000
 /return       (From a delegated sub-thread)
               Smoothly return to the parent thread, instructing the model to
               submit the task result, even if incomplete
 /abort        (From a delegated sub-thread)
               Immediately terminate this sub-task and switch to the parent
               thread (most likely without submit or preserve task results)

[Messages]
 /file         Send message with file attachment. Non-text files require a
               model that supports non-text inputs (such as images/PDF/audio)
               Usage:
                 /file <filepath> [<message>]
               If no message is provided, it will just insert the file
 /message      Manually insert 'user' or 'assistant' text message
 /reprint      Reprint messages of the thread. Optionally accept an index
               Negative indices are supported (e.g. -1 for the last message)
 /copy         Copy a message to the clipboard. Optionally accept an index
               Negative indices are supported (e.g. -1 for the last message)
 /edit         Edit a message or tool result. Optionally accept an index
               Negative indices are supported (e.g. -1 for the last message)
 /discard      Delete a message. Optionally accept an index
               Negative indices are supported (e.g. -1 for the last message)
 /rewind       Rewind to a previous message and discard everything after it

[LLM]
 /thinking     Change thinking effort for the thread, or globally toggle hide
               of reasoning blocks
 /llm-opts     Set LLM parameters for current thread
               Parameters:
                 temperature, max_tokens, top_p, top_k, min_p, seed,
                 presence_penalty, repetition_penalty, frequency_penalty
               Usage:
                 /llm-opts <parameter> <value>
                 /llm-opts reset

[IPC]
 /ipc-token    Set the IPC token used to connect to another instance
 /ipc-queue    Queue a prompt for the next IDLE time
 /ipc-steer    Queue a prompt for the next turn
 /ipc-status   Show the current status: IDLE or RUNNING
 /ipc-abort    Abort the running operation
 /ipc-shutdown Shut down the instance
 /ipc-session  Show session information in JSON format
 /ipc-pause    Gracefully return IDLE after the current turn
 /ipc-continue Trigger RUNNING state without adding a new message
```

#### Bash

Use `!` to evaluate Bash commands directly. The command runs in the internal
`markov` shell process, whose state can be inspected and modified.

Use `!!` when you want Bash output to be captured and sent to the LLM.
The command runs in a *separate* PTY.

#### Fuzzy file search

This requires a fuzzy finder in your `PATH`, like `fzf` or `skim`.
Use `@` + `Tab`.

#### Inline expansion of prompt templates and files

A prompt template command `/prompt-name` or a text-file path written in
`readline` can expand to the actual file content directly into the `readline`
buffer by pressing `Alt+T`.


### Built-in Tools

```
Tools enabled by default:
  read        Read local paths or fetch URLs; render PDF/HTML to cached text
              External tools for basic PDF/HTML text extraction:
                HTML: lynx, w3m or elinks
                PDF: pdftotext (xpdf-tools), mutool, gs or pypdf
                PDF OCR: ocrmypdf, or tesseract + pdftoppm (xpdf-tools)
              Default cache dir: ${MA_CACHE_DIR:-/var/tmp/markov/cache}
              Text extraction from PDF is best-effort, quality may be low
              Expect web fetch to break easily and fail completely on sites
              behind anti-bot protection or requiring JavaScript
              Defaults: MA_READ_MAX_LINES: 2000
  write       Create or overwrite files
  edit        Edit files via string replacement
              Whitespace normalization fallback support
              Warning: perl or python recommended for performance!
  bash        Execute shell commands
              The MA_BASH_ENV_PREFIX array can be used to limit env access
              Example:
                MA_BASH_ENV_PREFIX=(env -i HOME=$HOME PATH=/usr/bin:/bin)
              MA_BASH_PRELOAD_CONTENT can contain arbitrary Bash code
              that is evaluated before executing the command
              Useful for declaring custom Bash functions for LLM commands
              Defaults:
                MA_BASH_TIMEOUT_SEC: 120
                MA_BASH_MAX_OUTPUT_LINES: 400
                MA_BASH_TERM_MAX_OUTPUT_LINES: 0 (unlimited to user)
  execute     Search and call lazy tools, including built-in 'docs' and
              the 'reload' tool added automatically
              Lazy tools are excluded from the normal tool list and don't
              consume context or invalidate the cached prompt prefix
              Mark tools lazy with: MA_LAZY_TOOLS[tool_name]=1 in modules
              Or from CLI options: --lazy <comma-separated-list>
              Search limits output to 20 matches (MA_SEARCH_MAX_RESULTS:20)
  skills      Load skills
  websearch   Basic web search via web, wikipedia, arxiv, openalex, pubmed,
              archive, unpaywall or hackernews
              Uses ddgr/websearch binaries when available, otherwise fallback
              to awk HTML parsing
              'unpaywall' may require an email set in MA_WEB_SEARCH_EMAIL
  delegate    Enable synchronous 'sub-task' delegation in sub-threads
              The parent thread is blocked until the sub-task returns a result
              Useful for keeping delegated work out of the main context
              Delegation can be used recursively by sub-threads
              Defaults:
                MA_DELEGATE_MAX_PARENTS: 2

Tools automatically marked as lazy:
  reload      Reload context files and module scripts
              --no-lazy-reload makes it directly callable
              Or unset MA_LAZY_TOOLS[reload] from a module
  docs        Print self-contained Markov documentation for the LLM
              --no-lazy-docs makes it directly callable

Extra tools:
  symbols     Navigate source symbols; available with ctags or tree-sitter
              MA_TS_PARSER_DIR and MA_TS_QUERY_DIR override tree-sitter dirs
              (colon-separated dirs like in PATH)
  ask         Ask the user questions via dialogs
  grep        Search file contents
  find        Find files
  ls          List directory contents

Special reserved tools (should never be used manually):
  submit     Added automatically to every sub-thread to submit results
  feedback   Added automatically to evaluator threads to send verdict/steering
```

#### Tool Output

By default, `stdout` is captured and displayed after a tool finishes.
`stderr` is user-facing only.

To configure tool display:

```bash
MA_TOOL_DISPLAY_OUTPUT[toolname]=false     # hide captured output
MA_TOOL_DISPLAY_REPRINT[toolname]=true     # show hidden output on reprints
MA_TOOL_DISPLAY_NAME[toolname]=false       # hide tool name in header
MA_TOOL_DISPLAY_SEPARATORS[toolname]=false # hide separators
```


### Session Files

Session files are JSON files that can contain multiple conversation histories
(referred to as `threads`).

Default directory for session files:

```Bash
MA_SESSIONS_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/markov/sessions
```

Use `--session-dir` or set `MARKOV_SESSIONS_DIR` in the config to change it.

The entire session is kept in memory as `MA_DOC_JSON` and is updated
during the agent loop when the session is not ephemeral.

### Threads and sub-tasks

Threads organize separate conversations within a session.
The `/switch` command creates or resumes a thread.

There is always just one active thread: its name is in `MA_THREAD_NAME`, while
`MA_THREAD_JSON` contains the entire JSON string of the thread messages.

`MA_THREAD_OBJ` is an associative array holding the configuration for the
current thread. Its fields are:

* `role`: role name, which governs context and tool usage
* `endpoint`: endpoint used
* `use_tools`: set to `false` when tools are disabled
* `tools`: comma-separated list of tool names
* `tools_json`: JSON string containing the tools sent with API requests
* `persona`: name of the persona file
* `thinking`: reasoning effort
* `llm_opts`: model parameters as space-separated `key=value` pairs
* `max_tokens`: maximum completion tokens
* `stream`: set to `false` when streaming is disabled
* `system_prompt`: final system prompt assembled from context files

Fields are automatically set from the `roles` configuration on every reload.
Do not modify them manually.

You can get the associative array of any thread by name:

```bash
local -n thread_obj="MA_THREAD_OBJ_<thread_name>"
```

`delegate` can create a **sub-thread** with fresh context for a sub-task.
Sub-threads are fully synchronous: the parent is blocked until the sub-task
returns a result, gracefully or forcefully.

*The purpose of sub-threads is to avoid polluting the parent context window,
not to run background jobs.*

Custom `roles` can be used by user threads or sub-threads. `main` is reserved
for the default endpoint, role, and thread.


### Configuration

If neither `MA_CONFIG_DIR` nor `--config-dir` is set, the global configuration
directory is:

```bash
MA_CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/markov
```

Global configuration layout:

```text
$MA_CONFIG_DIR/
├── config.sh
├── SYSTEM.md
├── APPEND_SYSTEM.md
├── AGENTS.md
├── modules/
├── skills/
├── prompts/
└── personas/
```

#### `config.sh`

`$MA_CONFIG_DIR/config.sh` is sourced at initialization and on every `reload`.

It receives all CLI arguments passed to `markov` and can define default
options, such as the model or additional providers.

Custom `slash commands` and `tools` can also be defined here, but cannot
override built-ins because `config.sh` is sourced before many built-in
functions are defined. Use `modules` to override built-ins.

Use `/config` to create a config template or edit the existing file.

Config variables use the `MARKOV_` prefix rather than `MA_` to distinguish
configuration from internal state and CLI variables.

```
Configuration file options (overridden by CLI options):
 MARKOV_PROVIDERS            Associative array used to add or override
                             providers
                             Providers are resolved using the open-source
                             database from:
                               https://models.dev/api.json
                             To add or override one manually:
                               MARKOV_PROVIDERS[name]='ENV_KEY_NAME|URL'
 MARKOV_MODEL                Default provider/model_id
                             The provider is extracted from the
                             'provider/model_id' prefix
                             The model ID can be a partial match, or omitted
                             to pick first available model automatically
 MARKOV_API_KEY              Override provider API key for authentication
 MARKOV_API_URL              Specify API endpoint URL manually
                             Not recommended: just add a custom provider
 MARKOV_CTX                  Context size to use when not auto-detected
 MARKOV_SYSTEM_PROMPT        System prompt prepended to every session
 MARKOV_APPEND_SYSTEM_PROMPT Additional text appended to the system prompt
 MARKOV_DEFAULT_TOOLS        Comma-separated list of core tools that will
                             replace the default built-in tools
                             The tools list can still change at runtime if
                             new tools are found on reload
                             Core built-in tools, enabled by default:
                               read,write,edit,bash,skills,execute,websearch,
                               delegate
 MARKOV_LAZY_LIST            Comma-separated list of tools to mark as 'lazy'
 MARKOV_ALLOWED_TOOLS        Comma-separated list of core tools to allow
                             Actively excludes any core tools not specified
                             Lazy tools found at runtime are still allowed 
 MARKOV_PROMPT_PREFIX        Change default prompt prefix (default '❯ ')
 MARKOV_MAX_TURNS            Limit the number of LLM loop iterations
 MARKOV_ALLOWED_MODULES      Comma-separated list of allowed modules
 MARKOV_MODULES_DIR          Directory containing modules
 MARKOV_SKILLS_DIR           Directory containing skills
 MARKOV_PROMPTS_DIR          Directory containing prompt template files
 MARKOV_PERSONAS_DIR         Directory containing persona definition files
 MARKOV_SESSIONS_DIR         Directory used to store session files
 MARKOV_THINKING             Default reasoning effort level:
                             [off, low, medium, high, xhigh, max]
 MARKOV_THINKING_BUDGET      Associative array used to specify token budget
                             for reasoning levels. Default:
                               MARKOV_THINKING_BUDGET[low]=2048
                               MARKOV_THINKING_BUDGET[medium]=8192
                               MARKOV_THINKING_BUDGET[high]=16384
                               MARKOV_THINKING_BUDGET[xhigh]=32768
                               MARKOV_THINKING_BUDGET[max]=65536
 MARKOV_LLM_OPTS             Additional LLM comma-separated options:
                             key=value pairs
                               temperature, max_tokens, top_p, top_k, min_p,
                               seed, presence_penalty, repetition_penalty,
                               frequency_penalty
 MARKOV_PRICING              Associative array defining model pricing.
                             Auto-populated for providers, including context
                             tiers. Users can override existing values or add
                             new entries
                             Keys:
                               "provider/model_id"
                               "provider/model_id@N"     (context tier)
                             Values: 4 space-separated prices per 1M tokens:
                               input, output, cache-read, cache-write
                             Example:
                               MARKOV_PRICING+=(
                                 [provider/model_id]="10 50 0.5 0"
                                 [provider/model_id@200000]="20 80 2.0 0"
                               )
                             Tiers: "@N" specifies a token threshold. If the
                             total prompt (cached + uncached) exceeds N, that
                             tier is used instead of the base price. The
                             highest matching N wins. Tier entries must specify
                             all 4 prices; values are not inherited
 MARKOV_HIDE_THINKING        Hide the model's reasoning output
 MARKOV_TRUST_DIR            Trust the current directory
 MARKOV_USE_TOOLS            Set to false to disable tool usage
 MARKOV_USE_MODULES          Set to false to disable modules
 MARKOV_USE_PROMPTS          Set to false to disable prompt templates
 MARKOV_USE_SKILLS           Set to false to disable skills
 MARKOV_USE_CONTEXT_FILES    Set to false to disable context files
 MARKOV_USE_SPINNER          Set to false to disable animated spinner
 MARKOV_USE_IPC              Set to true to enable IPC service
 MARKOV_SKIP_MODEL_CHECK     (local models) Skip request for ctx size / alias
 MARKOV_SESSION_EPHEMERAL    Set to true to disable session file creation
                             unless a session name specified with --session
 MARKOV_PERSONA_NAME         Use a persona in all sessions
 MARKOV_CALLCHECK_ANALYZER   Let the LLM check tool calls
                             (see 'call_analyzer' role for more information)
 MARKOV_CALLCHECK_ALWAYS     Always ask before executing tool calls
 MARKOV_CALLCHECK_PATTERN    Use pattern match to catch undesired tool calls
                             WARNING: This mechanism is intended to
                             catch accidental misuse, not malicious input
                             You may add/modify patterns in:
                               MA_PATTERNS_BASH, MA_PATTERNS_PROTECTED_PATHS
                               MA_PATTERNS_SECRETS
 MARKOV_CONFINE              Enable 'confinement' mode on the built-in tools
 MARKOV_STREAM               Set to false to disable streaming responses
 MARKOV_API_PROXY            Curl proxy server arguments for API requests
 MARKOV_WEB_PROXY            Curl proxy server arguments for web requests
 MARKOV_WEB_USER_AGENT       Custom User-Agent string for web requests
 MARKOV_WEB_SEARCH_EMAIL     Some web search services require one
 MARKOV_NO_PRESERVE_THINKING Do not preserve reasoning between turns
 MARKOV_QUIET                Silence common output
```

#### Endpoints

Endpoints are specified by the user in associative arrays using the 
`custom_endpoint_<name>` naming convention, with `model` or `api_url` as keys.

Example:

```bash
declare -gA custom_endpoint_local=([api_url]="http://127.0.0.1:8012/v1")
declare -gA custom_endpoint_online=([model]="zai/glm-5.2")
```

After loading, their runtime information is in different associative arrays.
To get a specific endpoint's data by name, or to print it:

```bash
local -n endpoint_obj="MA_ENDPOINT_OBJ_<endpoint_name>"
declare -p "MA_ENDPOINT_OBJ_<endpoint_name>"
```

For convenience, `MA_ENDPOINT_OBJ` holds the current thread endpoint data.

#### Roles

A `role` customizes a thread's context and endpoint.

Roles are defined as associative arrays in the config file using the
`delegate_role_<name>` or `custom_role_<name>` naming convention.
The suffix is the role name.

All `delegate_role_*` roles are available to the `delegate` tool, allowing
the model to select one automatically during sub-task delegation.
If no `delegate_role_*` roles are defined, a sub-thread inherits the default.

`custom_role_*` roles are user-only.

All roles can be selected explicitly, e.g. with `/switch <new_thread> <role>`.

`main` is a reserved name for the default role, thread, and endpoint.
Other reserved custom roles: `call_analyzer` and `task_evaluator`.

Role fields (optional):

* `description`: short description, visible to the model via `delegate` tool
* `endpoint`: endpoint name; defaults to `main`
* `use_context_files`: set to `false` to disable context files
* `system_prompt`: system prompt (same as `--system`)
  if specified, replaces the system prompt, even if set to *empty* string
* `append_system_prompt`: additional system prompt (same as `--append-system`)
* `persona`: persona name (same as `--persona`)
* `use_tools`: set to `false` to disable tools
* `allowed_tools`: comma-separated **strict tool whitelist**
  (same as `--allowed-tools`)
* `tools`: comma-separated list of default tools; modules may add tools
  automatically if reloaded (same as `--tools`)
* `lazy_tools`: comma-separated lazy tools (same as `--lazy`)
* `llm_opts`: model parameters (same as `--llm-opts`)
* `stream`: set to `false` to disable streaming
* `thinking`: reasoning effort level (same as `--thinking`)
* `evaluator`: role used to **evaluate the submitted sub-task results from
  a delegated sub-agent**

  If set, enables task auto-evaluation and assigns this role to the
  sub-agent that reviews the task result.
  `Markov` has a special `task_evaluator` role you can use for this job.
  `Markov` automatically adds the `feedback` tool to the evaluator thread,
  which is used to finish the evaluation and eventually accept or revise
  the result and steer the sub-agent toward a correct solution.
* `max_evaluations`: maximum number of steering attempts before accepting
  the result anyway (default 8)

Example:

```bash
declare -gA delegate_role_researcher=(
  [description]="Research and summarize information"
  [endpoint]=online
  [allowed_tools]="read,websearch"
  [use_context_files]=false
  [append_system_prompt]='Find and summarize relevant information.'
)

declare -gA delegate_role_coder=( # inherits endpoint, use default evaluator
  [description]="Implement and review code"
  [tools]="read,edit,write,bash"
  [thinking]=high
  [evaluator]=task_evaluator
  [append_system_prompt]='Implementing correct, minimal changes.'
)

declare -gA custom_role_reviewer=( # available to user only
  [description]="Review changes without modifying files"
  [endpoint]=local
  [allowed_tools]="read,bash"
  [use_context_files]=true
  [persona]=reviewer
)
```

##### Special role: `call_analyzer`

`custom_role_call_analyzer` is the role used to check tool calls for security.
It acts as a gate: flagged calls will require user confirmation.
This role is configured automatically by `markov`.

By default, it is disabled because it requires an extra API call for every
change to tool call arguments. Enable it using the `--callcheck-analyzer` CLI
option, or setting `MARKOV_CALLCHECK_ANALYZER=true` from the config.

Remember to configure the `call_analyzer` role with a fast/trusted endpoint:

```bash
declare -gA custom_endpoint_trusted=([api_url]="http://127.0.0.1:8080/v1")
custom_role_call_analyzer[endpoint]=trusted
```

By default, only the `path` argument of `write` and `edit` calls is remembered
after a successful call. Set `MA_CALL_ANALYZER_SCAN_EDITS=true` to scan all
edits to the same file.

##### Special role: `task_evaluator`

`custom_role_task_evaluator` is a role automatically configured by `Markov`
and ready to use for reviewing results submitted by a sub-agent.

Set the `evaluator` field of a delegate role to `task_evaluator` to use it.

This role is configured automatically by `Markov`, but you may replace its
system prompt to better adapt it to your sub-tasks.

#### System prompt

The system prompt is assembled from the system message, context files, and
optional persona content.

All components are optional. If `SYSTEM.md` or `--system` is not specified,
`markov` uses its built-in default system prompt.
Use `--trust-dir` to enable loading of local context files.

The resulting system prompt is assembled in this order:

```text
1. System message
   SYSTEM.md, --system, or markov's default
2. Append system message
   APPEND_SYSTEM.md or --append-system
3. Global AGENTS.md
   $MA_CONFIG_DIR/AGENTS.md
4. Local AGENTS.md files
   Project root → current directory
5. Persona (--persona <name>)
```

##### `AGENTS.md`

The global `$MA_CONFIG_DIR/AGENTS.md` is loaded in every session before all
other context. Use it for instructions common to all projects.

Use `--trust-dir` to enable loading local `AGENTS.md` files. They are
concatenated from the project root to the current directory, with at most one
file loaded from each directory. The project root is the nearest ancestor
containing `.git`, or `$PWD` if none is found.

`CLANKERS.md` is `markov`-specific and takes precedence over `AGENTS.md` when
both exist in the same directory.

##### Personas

Persona files are text or Markdown files appended to the system prompt last.

```text
${MA_CONFIG_DIR}/personas/
├── grumpy.txt
├── pirate.md
└── socrates.txt
```

Set `$MA_PERSONAS_DIR` to use a custom personas directory.

Use `--persona <name>` or `/persona` to load a persona by name.

#### Skills

Skills are loaded on demand by the LLM via the `skills` tool or by the user
through the slash command automatically created from the skill name. All skill
descriptions are included in the tool description.

Set `disable-model-invocation:true` in `SKILL.md` front matter to exclude its
description from the tool description. The skill remains available as a slash
command and can still be invoked by the LLM when the user provides its name.

Each skill has its own directory:

```text
${MA_CONFIG_DIR}/skills/
├── pdf/
│   ├── SKILL.md
│   ├── scripts/
│   │   └── extract.sh
│   └── examples/
└── caveman/
    └── SKILL.md
```

Custom skills directory: `$MA_SKILLS_DIR`

`SKILL.md` contains the skill instructions; additional files may be included
in the same directory.

#### Prompt Templates

Prompt templates are plain-text or Markdown files in `prompts/` that create
slash commands for reusable prompts.

Default directory: `${MA_CONFIG_DIR}/prompts/`
Custom directory: `$MA_PROMPTS_DIR`

Bash positional parameters are expanded when invoked. `Alt+T` expands the
prompt inline on the `readline` buffer.

For example, `prompts/explain.md`:

```text
Explain the purpose of "$1" in the following code:

$2
```

```text
/explain main.cpp 'int main() {}'
```

Parameters are expanded before the prompt is submitted.


### Modules

Modules are Bash scripts sourced into the `markov` shell process, with full
access to its global state. They are sourced on every `reload` and receive all
CLI arguments passed to `markov`.

Use modules to add:

* Custom REPL `slash commands`
* Custom `tools`, or override built-in tools
* `Hook functions`

Default directory: `${MA_CONFIG_DIR}/modules/`

Custom directory: `$MA_MODULES_DIR`

Use `/reload` after creating or modifying a module to apply changes without
restarting `markov`.

#### Signal Hygiene

`Markov` installs custom traps for signals including `INT`, `EXIT`, `TERM` and
`WINCH`. User code must preserve and restore them when modifying these traps.

Be careful when using `RETURN`: always unset your `RETURN` trap from within
the trap itself:

```bash
trap 'user_code; trap - RETURN' RETURN
```

This is the *bash-witchcraft* that enables push/pop semantics for recursive
`RETURN` traps in sub-functions.

#### Custom REPL Commands

Slash commands are Bash functions running in the same shell as `markov`.
Define `command_<cmd_name>` to create `/<cmd_name>`.

The function receives the full argument string as `$1`; split and parse it
manually if needed.

Set `MA_TRIGGER_LOOP=true` to trigger the agent loop when the function
returns. A non-empty `MA_USER_PROMPT` is automatically added as a user
message.

Use `MA_COMMAND_DESCR` for command descriptions and `completion_<cmd_name>`
for `readline` completion.

Example `/ciao` command:

```bash
MA_COMMAND_DESCR["/ciao"]="Greet someone"

command_ciao() {
  echo "Ciao ${1:-Mondo}!"
}

# Quick completions:
completion_ciao() {
  ma_completion_arg '' '' mario luigi bowser
}

# Picker completions with descriptions (fzf or skim):
completion_ciao() {
  local prefix="" # prefix to strip, useful when no picker installed
  local -a characters=( mario luigi bowser )
  local -A descr=(
    [mario]="A brave plumber"
    [luigi]="Mario's timid brother"
  )
  ma_completion_arg "$prefix" descr "${characters[@]}"
}
```

See the built-in commands for more examples.

#### Custom Tools

A tool requires a `schema` and an `execution function`. An optional `header
function` runs whenever the tool header is printed.

Schemas use the **OpenAI Responses API function schema** format.

* `MA_TOOL` is a global associative array containing all tool schemas;
  add schemas by tool name: `MA_TOOL[browser]` defines `browser`.
* `execute_<name>` runs the tool in a **subshell**.
* `header_<name>` runs in the **same shell** and may run multiple times,
  including during message reprints. `MA_TOOL_IS_REPRINTING=true` during
  reprints.
* Both functions receive tool arguments as JSON in `$1`.

The `MA_TOOL` key, schema `name`, and function `<name>` must match exactly.

> [!IMPORTANT]
> `execute_*` output for the LLM must go to `stdout`. `stderr` is user-facing
> only and is intended for live progress or diagnostics.

> [!IMPORTANT]
> Check that `MA_TOOL_IS_REPRINTING` is unset before performing state-changing
> operations in a `header_*` function that should only run during tool calls.

> [!NOTE]
> Reloading may automatically update the tools sent to the LLM.
> Adding a tool to a module may invalidate the model's `cached prompt prefix`.
> To prevent this, explicitly mark new module tools as `lazy` to hide them.

##### Custom Tool Example:

```bash
MA_TOOL[git_log]='
{
  "type": "function",
  "name": "git_log",
  "description": "Show recent git commits",
  "parameters": {
    "type": "object",
    "properties": {
      "limit": {
        "type": "integer",
        "description": "Number of commits to show"
      },
      "author": {
        "type": "string",
        "description": "Filter commits by author"
      },
      "oneline": {
        "type": "boolean",
        "description": "Show each commit on a single line"
      }
    }
  }
}'

header_git_log() {
  local limit author oneline
  { IFS= read -r -d '' limit
    IFS= read -r -d '' author
    IFS= read -r -d '' oneline
  } < <(jq -jb '(.limit // 10), "\u0000",
                (.author // ""), "\u0000",
                (.oneline // true), "\u0000"' <<< "$1")
  printf "show git log (limit: %s, author: %s)\n" "$limit" "${author:-any}"
}

execute_git_log() {
  local limit author oneline
  { IFS= read -r -d '' limit
    IFS= read -r -d '' author
    IFS= read -r -d '' oneline
  } < <(jq -jb '(.limit // 10), "\u0000",
                (.author // ""), "\u0000",
                (.oneline // true), "\u0000"' <<< "$1") \
    || { echo "ERROR: Failed to parse arguments"; return 1; }
  local opts=(-n "$limit")
  [[ -n "$author" ]] && opts+=(--author="$author")
  [[ "$oneline" == "true" ]] && opts+=(--oneline)
  git log "${opts[@]}" 2>&1
}
```

##### Lazy tools

Lazy tools are hidden from the LLM until needed. They are discovered and
invoked through the `execute` tool without changing the session's tool list,
preserving the `cached prompt prefix`.

Mark a tool as lazy with:

```bash
MA_LAZY_TOOLS[tool_name]=1
```

The actual value is unimportant: only key existence is checked.

The user has full control over when and how a lazy tool is made known to the
model, such as by mentioning its name, providing its definition, or including
it in a system prompt.

When the LLM searches for lazy tools, matching tools are returned as:

```text
[<name>]
Description: <tool description>
Parameters: {<compacted JSON>}
```

#### Hooks

Hooks are functions called by `markov` at specific points, directly in the
same shell process.

Modules define hooks as Bash functions named `hook_<event>`.

```
  Hook                  Arguments / description
  -------------------   -----------------------------------------------
  hook_reload           On startup or `reload`

  hook_cleanup          Before another `reload` or at exit

  hook_session_load     After loading a session from disk

  hook_session_store    Before storing a session on disk

  hook_loop_start       Before the LLM loop starts
                        $1: nameref to user input string

  hook_loop_end         After the LLM loop ends
                        $1: total number of turns in the loop
                        $2: total number of tool calls in the loop
                        $3: return code
                        $4: elapsed microseconds

  hook_turn_start       At the start of each turn
                        $1: current turn number

  hook_turn_end         At the end of each turn
                        $1: turn number
                        $2: num of tool calls in this turn

  hook_request          Before sending the request
                        $1: nameref to the entire curl json body

  hook_response_stream  During streaming
                        $1: partial reasoning
                        $2: partial content

  hook_response         After receiving the complete response
                        $1: nameref to response array
                        Indices: idx_reasoning,
                                 idx_content,
                                 idx_tool_calls,
                                 idx_rstate,
                                 idx_http_code,
                                 idx_err_body

  hook_tool_start       Before a tool executes
                        $1: tool name
                        $2: nameref to tool arguments JSON
                        return 1 to block the tool call

  hook_tool_end         After tool completes
                        $1: tool name
                        $2: nameref to tool result
                        $3: exit code

  hook_confirm_start    Before confirmation dialog
                        $1: tool name
                        $2: tool arguments
                        $3: reason

  hook_confirm_end      After confirmation dialog
                        $1: dialog response
```


### Inter-process communication (IPC)

IPC is enabled with `--ipc` or by setting `MARKOV_USE_IPC=true` in config
file. Clients that need to send ipc requests don't need to have ipc enabled.

Each server instance has an IPC token, printed at startup and available via
`/session`. The token contains the instance `PID` and may include a secret.

Clients can use the `IPC token` of a running instance to send requests.

Only the same system `user` running `markov` can send IPC requests.
`--ipc-secure` enables authorization using a secret embedded in the token.

The token can be provided with `--ipc-token`, `/ipc-token`, or the
`MA_IPC_TOKEN` environment variable.

Clients can send requests with `--send` or from the REPL.
Use `--ipc-only` to start an interactive IPC-only prompt.

Supported IPC requests and corresponding REPL commands:

* `status`, `/ipc-status`: Return `IDLE` or `RUNNING`.
* `steer`, `/ipc-steer`: Send a prompt for the next turn.
* `queue`, `/ipc-queue`: Queue a prompt to be used when the instance becomes
  IDLE again.
* `session`, `/ipc-session`: Get session information in JSON format.
* `thread`, `/ipc-thread`: Return the current thread (message history)
  in JSON format (or re-printed on the terminal if in interactive-mode).
* `pause`, `/ipc-pause` : Gracefully return `IDLE` after current turn.
* `continue`, `/ipc-continue` : Trigger `RUNNING` state without new messages.
* `abort`, `/ipc-abort`: Interrupt the running operation. Put in `IDLE` state.
* `shutdown`, `/ipc-shutdown`: Shut down the instance.

Queued prompts and `steer` requests are coalesced into a single user message.

CLI examples:

```bash
$ markov.sh --ipc-token "ipc-<PID>-<xxx>" --ipc-only # interactive prompt
$ markov.sh --ipc-token "ipc-<PID>-<xxx>" --send status
$ markov.sh --ipc-token "ipc-<PID>-<xxx>" --send queue "<message>"
```

EOF
	}
}

ma_ansi_defs() {
	if [[ ${MA_ANSI:-} != false && -t 1 ]]; then
		A_R=$'\033[0m'; A_K=$'\033[K'; A_CURSOR_ON=$'\033[?25h'; A_CURSOR_OFF=$'\033[?25l';
		A_B=$'\033[1m'; A_B0=$'\033[22m'; A_D=$'\033[2m'; A_D0=$'\033[22m'; A_I=$'\033[3m'; A_I0=$'\033[23m'
		A_U=$'\033[4m'; A_U0=$'\033[24m'; A_V=$'\033[7m'; A_V0=$'\033[27m'; A_S=$'\033[9m'; A_S0=$'\033[29m'
		if [[ "${MA_LIGHT:-}" == true ]]; then
			A_SPECIAL=${A_R}$'\033[1;35m';
			A_COMP=${A_R}$'\033[38;5;18m';
			if [[ "${MA_256_COLORS:-}" != false ]]; then
				A_ERR=${A_R}$'\033[38;5;124m'"$A_B"; A_WARN=${A_R}$'\033[38;5;94m'; A_INFO=${A_R}$'\033[38;5;241m'
				A_INPUT=${A_R}$'\033[48;5;253m\033[38;5;16m';
				A_THINK=${A_R}$'\033[38;5;243m'"$A_I";
				A_RESP=${A_R}$'\033[38;5;16m';
				A_SEP=${A_R}$'\033[38;5;249m';
				A_MARKOV=${A_R}$'\033[38;5;130m'
				A_RESP_SEP=${A_R}$'\033[38;5;25m';
				A_TOOL_SEP=${A_R}$'\033[38;5;60m';
				A_TOOL_OK=${A_R}$'\033[38;5;28m';
				A_TOOL_FAIL=${A_R}$'\033[1;38;5;124m';
				A_TOOL_NAME=${A_R}$'\033[1;38;5;94m';
				A_TOOL_HEAD=${A_R}${A_B};
				A_TOOL_BODY=${A_R};
			else
				A_ERR=${A_R}$'\033[0;31m'; A_WARN=${A_R}$'\033[0;33m'; A_INFO=${A_R}$'\033[0;30m'
				A_INPUT=${A_R}$'\033[47m\033[30m';
				A_THINK=${A_R}$'\033[2m\033[3m'"$A_I";
				A_RESP=${A_R}$'\033[0;30m';
				A_SEP=${A_R}$'\033[2m';
				A_MARKOV=$'\033[0;33m'
				A_RESP_SEP=${A_R}$'\033[2m';
				A_TOOL_SEP=${A_R}$'\033[2m';
				A_TOOL_OK=${A_R}$'\033[0;32m';
				A_TOOL_FAIL=${A_R}$'\033[1;31m';
				A_TOOL_NAME=${A_R}$'\033[1;33m';
				A_TOOL_HEAD="${A_R}${A_B}";
				A_TOOL_BODY=${A_R};
			fi
		else
			A_SPECIAL=${A_R}$'\033[1;35m';
			A_COMP=${A_R}$'\033[34m';
			if [[ "${MA_256_COLORS:-}" != false ]]; then
				A_ERR=${A_R}$'\033[38;5;1m'"$A_B"; A_WARN=${A_R}$'\033[38;5;3m'; A_INFO=${A_R}${A_D}
				A_INPUT=${A_R}$'\033[48;5;237m\033[38;5;255m';
				A_THINK=${A_R}$'\033[2;27m'"$A_I";
				A_RESP=${A_R}$'\033[38;5;230m';
				A_SEP=${A_R}$'\033[38;5;58m';
				A_MARKOV=${A_R}$'\033[38;5;214m'
				A_RESP_SEP=${A_R}$'\033[2;34m';
				A_TOOL_SEP=${A_R}$'\033[2;25m';
				A_TOOL_OK=${A_R}$'\033[38;5;10m';
				A_TOOL_FAIL=${A_R}$'\033[1;31m';
				A_TOOL_NAME=${A_R}$'\033[1;33m';
				A_TOOL_HEAD=${A_R}${A_B};
				A_TOOL_BODY=${A_R};
			else
				A_ERR=${A_R}$'\033[0;31m'; A_WARN=${A_R}$'\033[0;33m'; A_INFO=${A_R}$'\033[0;34m'
				A_INPUT=${A_R}$'\033[47m\033[30m';
				A_THINK=${A_R}$'\033[2m\033[3m'"$A_I";
				A_RESP=${A_R}$'\033[0;97m';
				A_SEP=${A_R}$'\033[2m';
				A_MARKOV=$'\033[33m'
				A_RESP_SEP=${A_R}$'\033[2m';
				A_TOOL_SEP=${A_R}$'\033[2;25m';
				A_TOOL_OK=${A_R}$'\033[0;32m';
				A_TOOL_FAIL=${A_R}$'\033[1;31m';
				A_TOOL_NAME=${A_R}$'\033[1;33m';
				A_TOOL_HEAD="${A_R}${A_B}";
				A_TOOL_BODY=${A_R};
			fi
		fi
		A_PROMPT_PREFIX=$'\001'$A_MARKOV$'\002'; A_PROMPT_PREFIX0=$'\001'"${A_R}"$'\002'
	else
		MA_REPL_STYLE=separator
		A_R=''; A_K=''; A_CURSOR_ON=""; A_CURSOR_OFF="";
		A_ERR=""; A_WARN=""; A_INFO=""
		A_B=''; A_B0=''; A_D=''; A_D0=''; A_I=''; A_I0=''
		A_U=''; A_U0=''; A_V=''; A_V0=''; A_S=''; A_S0=''
		A_SPECIAL=
		A_COMP=
		A_INPUT=
		A_THINK=
		A_RESP=
		A_SEP=
		A_MARKOV=
		A_RESP_SEP=
		A_TOOL_SEP=
		A_TOOL_OK=
		A_TOOL_FAIL=
		A_TOOL_NAME=
		A_TOOL_HEAD=
		A_TOOL_BODY=
		A_PROMPT_PREFIX=; A_PROMPT_PREFIX0=
	fi
}
ma_ansi_defs

A_ASCREEN_ON=$'\033[?1049h'; A_ASCREEN_OFF=$'\033[?1049l'

err() { printf "${A_ERR}${1:-}${A_R}" >&2; }
warn()  { printf "${A_WARN}${1:-}${A_R}" >&2; }
info() { printf "${A_INFO}${1:-}${A_R}" >&2; }
die() { err "\n${1:-}"; exit 1; }

declare -a MA_CLI_ARGS=("$@")
export MA_MARKOV_PATH="$0"
declare -a _PASSTHROUGH_ARGS_PROMPT=()
while [[ $# -gt 0 ]]; do
	case "$1" in
		-u|--url)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --url\n"; }
			MA_API_URL_CLI="$2"; shift 2 ;;
		-k|--key|--api-key)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --key\n"; }
			MA_API_KEY_CLI="$2"
			shift 2 ;;
		-m|--model)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --model\n"; }
			MA_MODEL_CLI="$2";
			shift 2 ;;
		--system)
			[[ ! -v "2" ]] && { usage; die "Missing value for --system\n"; }
			MA_SYSTEM_PROMPT_CLI="$2"; shift 2 ;;
		--append-system)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --append-system\n"; }
			MA_APPEND_SYSTEM_PROMPT_CLI="$2"; shift 2 ;;
		--allowed-tools)
			[[ -z "${2:-}" ]] && { usage; die "Missing list for --allowed-tools. Built-in: read,write,edit,bash,skills,execute,delegate,websearch,symbols,ls,grep,find,ls,ask\n"; }
			MA_ALLOWED_TOOLS_CLI="$2"; shift 2 ;;
		-t|--tools)
			[[ -z "${2:-}" ]] && { usage; die "Missing list for --tools. Built-in: read,write,edit,bash,skills,execute,delegate,websearch,symbols,ls,grep,find,ls,ask\n"; }
			MA_DEFAULT_TOOLS_CLI="$2"; shift 2 ;;
		--lazy-tools|-l)
			[[ -z "${2:-}" ]] && { usage; die "Missing list for --lazy-tools.\n"; }
			MA_LAZY_LIST_CLI="$2"; shift 2 ;;
		--ipc) MA_USE_IPC_CLI=true; shift ;;

		--ipc-token)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --ipc-token\n"; }
			MA_IPC_TOKEN="$2"; shift 2 ;;
		--send)
			[[ -z "${2:-}" ]] && { usage; die "Missing values for --send\n"; }
			MA_IPC_SEND_CMD="$2"
			shift 2
			case "$MA_IPC_SEND_CMD" in
				queue|steer)
					[[ -z "${1:-}" ]] && { usage; die "Missing payload for --send $MA_IPC_SEND_CMD\n"; }
					MA_IPC_SEND_PAYLOAD="$1"
					shift
					;;
				session|status|thread|interrupt|abort|shutdown)
					;;
				*) usage; die "Unknown IPC command: $MA_IPC_SEND_CMD\n"; ;;
			esac
			;;
		--ipc-secure) MA_IPC_SECURE=true; shift;;
		--ipc-only) MA_IPC_ONLY_MODE=true; shift;;
		--max-turns)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --max-turns\n"; }
			MA_MAX_TURNS="$2"; shift 2 ;;
		--modules)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --modules\n"; }
			MA_ALLOWED_MODULES_CLI="$2"; shift 2 ;;
		--working-dir)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --working-dir\n"; }
			if [ -d "$2" ] && cd "$2"; then MA_WORKING_DIR="$PWD"; else die "Cannot access directory $2\n"; fi
			shift 2 ;;
		--config-dir)
			[[ -z "${2:-}" ]] && { usage; die "Missing path for --config-dir\n"; }
			MA_CONFIG_DIR="$2"; shift 2 ;;
		--modules-dir)
			[[ -z "${2:-}" ]] && { usage; die "Missing path for --modules-dir\n"; }
			MA_MODULES_DIR="$2"; shift 2 ;;
		--skills-dir)
			[[ -z "${2:-}" ]] && { usage; die "Missing path for --skills-dir\n"; }
			MA_SKILLS_DIR="$2"; shift 2 ;;
		--prompts-dir)
			[[ -z "${2:-}" ]] && { usage; die "Missing path for --prompts-dir\n"; }
			MA_PROMPTS_DIR="$2"; shift 2 ;;
		--personas-dir)
			[[ -z "${2:-}" ]] && { usage; die "Missing path for --personas-dir\n"; }
			MA_PERSONAS_DIR="$2"; shift 2 ;;
		--print-all) MA_PRINT_ALL=true; shift ;;
		--file)
			[[ -z "${2:-}" || ! -s "${2:-}" ]] && { usage; die "Invalid file path for --file\n"; }
			_MA_INPUT_FILE_CLI="$2"; shift 2 ;;
		-s|--session)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --session\n"; }
			MA_DOC_NAME="$2"; shift 2 ;;
		--fork)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --fork\n"; }
			MA_DOC_NAME="$2";
			MA_FORK_SESSION=true; shift 2 ;;
		--resume) _MA_RESUME_LAST_SESSION=true; shift ;;
		-n|--no-session) MA_DOC_EPHEMERAL=true; shift ;;
		--new)
			[[ -z "${2:-}" ]] && { usage; erma_die "Missing session name for --new\n"; }
			MA_DOC_NAME="$2"; MA_NEW_SESSION=true; shift 2 ;;
		--list-sessions) _LIST_SESSIONS=true; shift ;;
		--sessions-dir)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --sessions-dir\n"; }
			[[ ! -d "${2:-}" ]] && { die "$2 is not a directory\n"; }
			MA_SESSIONS_DIR="$2"; shift 2 ;;
		--confine)
			MA_CONFINE=true;
			_UNBASH=true;
			shift ;;
		--callcheck-always) MA_CALLCHECK_ALWAYS=true; shift ;;
		--callcheck-analyzer) MA_CALLCHECK_ANALYZER=true; shift ;;
		--callcheck-pattern)       MA_CALLCHECK_PATTERN=true;   shift ;;
		--no-stream)   MA_STREAM=false; shift ;;
		--no-thinking) MA_THINKING_CLI='off'; shift ;;
		--thinking)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --thinking\n"; }
			[[ "${2:-}" =~ ^(off|low|medium|high|xhigh|max|([0-9]|[1-9][0-9]|100))$ ]] || { die "Invalid thinking effort: $2. Use: off|low|medium|high|xhigh|max or value in range 0-100\n"; }
			MA_THINKING_CLI="$2"; shift 2 ;;
		--llm-opts)
			[[ -z "${2:-}" ]] && { usage; die "Missing value for --llm-opts\n"; }
			MA_LLM_OPTS_CLI="$2"
			shift 2
			;;
		--hide-thinking) MA_HIDE_THINKING=true; shift ;;
		--no-preserve-think) MA_NO_PRESERVE_THINKING=true; shift ;;
		-a|--trust-dir)  MA_TRUST_DIR=true;      shift ;;
		--no-config)	 MA_USE_CONFIG=false; shift ;;
		--no-modules)    MA_USE_MODULES=false;     shift ;;
		--no-tools)      MA_USE_TOOLS=false;   shift ;;
		--no-prompts)    MA_USE_PROMPTS=false;     shift ;;
		--no-context-files)	 MA_USE_CONTEXT_FILES=false; shift ;;
		--no-skills)	 MA_USE_SKILLS=false; shift ;;
		-c|--clean)
			MA_USE_CONFIG=false
			MA_USE_MODULES=false
			MA_USE_CONTEXT_FILES=false
			MA_USE_TOOLS=false
			MA_USE_SKILLS=false
			MA_USE_PROMPTS=false
			shift;;
		--list-models) _LIST_MODELS=true; shift ;;
		--list-providers) _LIST_PROVIDERS=true; shift ;;
		--persona)
			[[ -z "${2:-}" ]] && { usage; die "Missing name for --persona\n"; }
			MA_PERSONA_NAME="$2"
			shift 2;;
		--no-check-endpoint) MA_SKIP_ENDPOINT_CHECK=true; shift;;
		-q|--quiet) MA_QUIET=true; shift;;
		--ctx)
			[[ -z "${2:-}" ]] || [[ ! "$2" =~ ^[0-9]+$ ]] || [ ! "$2" -gt 0 ] && { usage; die "Invalid context size for --ctx\n"; }
			MA_CTX_CLI=$2;
			shift 2;;
		--no-spinner)  MA_USE_SPINNER=false; shift ;;
		--update-providers) MA_MODELDEV_FORCE_UPDATE=true; shift;;
		--no-lazy-reload) MA_USE_LAZY_RELOAD=false; shift ;;
		--no-lazy-docs) MA_USE_LAZY_DOCS=false; shift ;;
		-p|--print) [[ -z "${2:-}" ]] && { usage; die "Missing prompt for --print\n"; }
			MA_ONE_SHOT_MODE=true
			MA_USER_PROMPT="$2"; shift 2;;
		-h|--help)  usage; exit 0 ;;
		--docs) ma_init_docs; printf '%s' "$MA_DOCS"; exit ;;
		--readme) ma_init_readme; printf '%s' "$MA_README"; exit ;;
		-v|--version)  echo "markov v$MA_VERSION"; exit 0 ;;
		--) shift "$#"; ;;
		-*) usage; die "Unknown option: $1\n" ;;
		*) _PASSTHROUGH_ARGS_PROMPT+=("$1"); shift ;;
	esac
done

export MA_CONFIG_DIR="${MA_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/markov}"

ma_source_config() {
	declare -gA MARKOV_PROVIDERS
	declare -gA MARKOV_PRICING=()
	declare -gA MARKOV_THINKING_BUDGET

	MARKOV_PROVIDERS+=( # urls for these not found in models.dev api.json
		[cerebras]="CEREBRAS_API_KEY|https://api.cerebras.ai/v1"
		[groq]="GROQ_API_KEY|https://api.groq.com/openai/v1"
		[mistral]="MISTRAL_API_KEY|https://api.mistral.ai/v1"
		[google]="GEMINI_API_KEY|https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
		[openai]="OPENAI_API_KEY|https://api.openai.com/v1"
		[xai]="XAI_API_KEY|https://api.x.ai/v1"
		[openrouter]="OPENROUTER_API_KEY|https://openrouter.ai/api/v1"
		[anthropic]="ANTHROPIC_API_KEY|https://api.anthropic.com/v1/messages"
	)

	declare -gA custom_role_call_analyzer=(
		[description]="Used internally to analyze tool calls"
		[use_tools]=false [use_context_files]=false [thinking]=off [stream]=false
		[system_prompt]="${MA_CALL_ANALYZER_SYSTEM_PROMPT:-}"
	)

	declare -gA custom_role_task_evaluator=(
		[description]="May be used as default evaluator for delegated sub-tasks"
		[use_context_files]=false
		[system_prompt]="${MA_TASK_EVALUATOR_SYSTEM_PROMPT:-}"
	)



	local config_file="$MA_CONFIG_DIR/config.sh"
	[[ ${MA_USE_CONFIG:-} != false && -f "$config_file" ]] && {
		if ! . "$config_file" "${MA_CLI_ARGS[@]}"; then err "Failed to source config: $config_file\n"; fi
	}

	unset MA_SYSTEM_PROMPT
	if [[ -v MA_SYSTEM_PROMPT_CLI ]]; then
		MA_SYSTEM_PROMPT=$MA_SYSTEM_PROMPT_CLI
	elif  [[ -v MARKOV_SYSTEM_PROMPT ]]; then
		MA_SYSTEM_PROMPT=$MARKOV_SYSTEM_PROMPT
	fi

	MA_APPEND_SYSTEM_PROMPT="${MA_APPEND_SYSTEM_PROMPT_CLI:-${MARKOV_APPEND_SYSTEM_PROMPT:-}}"
	MA_MAX_TURNS="${MA_MAX_TURNS:-${MARKOV_MAX_TURNS:-}}"

	export MA_MODULES_DIR="${MA_MODULES_DIR:-${MARKOV_MODULES_DIR:-}}"
	export MA_SKILLS_DIR="${MA_SKILLS_DIR:-${MARKOV_SKILLS_DIR:-}}"
	export MA_PROMPTS_DIR="${MA_PROMPTS_DIR:-${MARKOV_PROMPTS_DIR:-}}"
	export MA_PERSONAS_DIR="${MA_PERSONAS_DIR:-${MARKOV_PERSONAS_DIR:-}}"
	MA_SESSIONS_DIR="${MA_SESSIONS_DIR:-${MARKOV_SESSIONS_DIR:-}}"
	export MA_SESSIONS_DIR="${MA_SESSIONS_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/markov/sessions}"

	MA_DOC_EPHEMERAL="${MA_DOC_EPHEMERAL:-${MARKOV_SESSION_EPHEMERAL:-}}"

	MA_CALLCHECK_ANALYZER="${MA_CALLCHECK_ANALYZER:-${MARKOV_CALLCHECK_ANALYZER:-}}"
	MA_CALLCHECK_ALWAYS="${MA_CALLCHECK_ALWAYS:-${MARKOV_CALLCHECK_ALWAYS:-}}"
	MA_CALLCHECK_PATTERN="${MA_CALLCHECK_PATTERN:-${MARKOV_CALLCHECK_PATTERN:-}}"

	MA_CONFINE="${MA_CONFINE:-${MARKOV_CONFINE:-}}"
	unset _UNBASH; [[ ${MA_CONFINE:-} == true ]] && { _UNBASH=true; }

	MA_USE_IPC="${MA_USE_IPC_CLI:-${MARKOV_USE_IPC:-}}"

	MA_DEFAULT_TOOLS="${MA_DEFAULT_TOOLS_CLI:-${MARKOV_DEFAULT_TOOLS:-}}"
	MA_LAZY_LIST="${MA_LAZY_LIST_CLI:-${MARKOV_LAZY_LIST:-}}"
	MA_ALLOWED_TOOLS="${MA_ALLOWED_TOOLS_CLI:-${MARKOV_ALLOWED_TOOLS:-}}"
	MA_ALLOWED_MODULES="${MA_ALLOWED_MODULES_CLI:-${MARKOV_ALLOWED_MODULES:-}}"

	MA_STREAM="${MA_STREAM:-${MARKOV_STREAM:-}}"

	MA_PERSONA_NAME="${MA_PERSONA_NAME:-${MARKOV_PERSONA_NAME:-}}"

	[[ -n "${MARKOV_THINKING:-}" ]] && {
		[[ "${MARKOV_THINKING:-}" =~ ^(off|low|medium|high|xhigh|max|([0-9]|[1-9][0-9]|100))$ ]] || {
			err "Invalid thinking effort: $MARKOV_THINKING. Use: off|low|medium|high|xhigh|max or value in range 0-100\n";
			MARKOV_THINKING=
		}
	}
	MA_THINKING="${MA_THINKING_CLI:-${MARKOV_THINKING:-}}"

	[[ -n "${MARKOV_LLM_OPTS:-}" ]] && {
		IFS=',' read -ra _opts <<< "$MARKOV_LLM_OPTS"
		MARKOV_LLM_OPTS=''
		for _opt in "${_opts[@]}"; do
			if [[ "$_opt" =~ ^[a-z_]+=-?[0-9]+\.?[0-9]*$ ]]; then
				MARKOV_LLM_OPTS+=" $_opt"
			else
				err "Invalid llm-opts format: $_opt. Use key=value\n";
			fi
		done
	}

	MA_LLM_OPTS=${MA_LLM_OPTS_CLI:-${MARKOV_LLM_OPTS:-}}

	MA_MAX_TOKENS=${MA_MAX_TOKENS:-${MARKOV_MAX_TOKENS:-8192}}

	MA_TRUST_DIR="${MA_TRUST_DIR:-${MARKOV_TRUST_DIR:-}}"
	MA_USE_CONTEXT_FILES="${MA_USE_CONTEXT_FILES:-${MARKOV_USE_CONTEXT_FILES:-}}"
	MA_USE_MODULES="${MA_USE_MODULES:-${MARKOV_USE_MODULES:-}}"
	MA_USE_TOOLS="${MA_USE_TOOLS:-${MARKOV_USE_TOOLS:-}}"
	MA_USE_PROMPTS="${MA_USE_PROMPTS:-${MARKOV_USE_PROMPTS:-}}"
	MA_USE_SKILLS="${MA_USE_SKILLS:-${MARKOV_USE_SKILLS:-}}"
	MA_SKIP_ENDPOINT_CHECK="${MA_SKIP_ENDPOINT_CHECK:-${MARKOV_SKIP_MODEL_CHECK:-}}"

	MA_API_PROXY="${MA_API_PROXY:-${MARKOV_API_PROXY:-}}"
	MA_WEB_PROXY="${MA_WEB_PROXY:-${MARKOV_WEB_PROXY:-}}"
	MA_WEB_USER_AGENT="${MA_WEB_USER_AGENT:-${MARKOV_WEB_USER_AGENT:-}}"
	MA_WEB_SEARCH_EMAIL="${MA_WEB_SEARCH_EMAIL:-${MARKOV_WEB_SEARCH_EMAIL:-}}"

	MA_HIDE_THINKING="${MA_HIDE_THINKING:-${MARKOV_HIDE_THINKING:-false}}"
	MA_NO_PRESERVE_THINKING="${MA_NO_PRESERVE_THINKING:-${MARKOV_NO_PRESERVE_THINKING:-}}"
	MA_USE_SPINNER="${MA_USE_SPINNER:-${MARKOV_USE_SPINNER:-}}"
	MA_QUIET="${MA_QUIET:-${MARKOV_QUIET:-}}"

	MA_API_URL="${MA_API_URL_CLI:-${MARKOV_API_URL:-}}"
	[[ -n $MA_API_URL ]] && {
		MA_API_URL="${MA_API_URL%/}"
		case "$MA_API_URL" in
			*/chat/completions|*/responses|*/messages) ;;
			*) MA_API_URL+="/${MA_CUSTOM_API_URL_END:-"chat/completions"}" ;;
		esac
	}

	MA_API_KEY="${MA_API_KEY_CLI:-${MARKOV_API_KEY:-}}"
	MA_CTX="${MA_CTX_CLI:-${MARKOV_CTX:-}}"

	[[ -n "${MA_API_URL_CLI:-}" && -n "${MARKOV_MODEL:-}" ]] && MARKOV_MODEL=
	MA_MODEL="${MA_MODEL_CLI:-${MARKOV_MODEL:-}}"
	[[ ${MA_MODEL:-} != */* ]] && MA_MODEL="${MA_MODEL:-}/";

	declare -gA custom_endpoint_main=( [model]="${MA_MODEL:-"/"}" [api_url]="$MA_API_URL" )

	declare -ga MA_USER_AGENT_ARRAY=()
	[[ -n ${MA_USER_AGENT:-} ]] && MA_USER_AGENT_ARRAY=(-A "$MA_USER_AGENT")
}


[[ "${_LIST_SESSIONS:-}" == "true" ]] && {
	ma_source_config
	[[ -d "$MA_SESSIONS_DIR" ]] && {
		printf 'From: %s\n' "$MA_SESSIONS_DIR"
		find "$MA_SESSIONS_DIR" -maxdepth 1 -name '*.mrk' -printf '%T@ %TY-%Tm-%Td %TH:%TM | %f\n' | sort -rn | cut -d' ' -f2- | sed 's/\.mrk$//'
	}
	exit 0
}

(( BASH_VERSINFO[0] < 5 )) && die '%s\n' 'Bash version 5.0 or newer is required.\n'
MA_BASH_53=0;
(( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 3) )) && MA_BASH_53=1

_check_deps=()
for tool in jq curl sed awk tail; do if ! command -v "$tool" &> /dev/null; then _check_deps+=("$tool"); fi done
(( ${#_check_deps[@]} )) && { die "Dependencies not found: ${_check_deps[*]}\n"; }

if command -v perl &> /dev/null; then
	_HAS_PERL=1;
else
	_HAS_PERL=0;
	if command -v python3 &>/dev/null; then
		_PYTHON=python3
	elif command -v python &>/dev/null && python -c 'import sys; sys.exit(0 if sys.version_info.major==3 else 1)' 2>/dev/null; then
		_PYTHON=python
	fi
	_HAS_CYGPATH=0 # mingw python needs windows paths
	[[ -n ${_PYTHON:-} && -n "${MSYSTEM:-}" ]] && command -v cygpath &>/dev/null && { _HAS_CYGPATH=1; }
fi

ma_tty_echo_off() { [[ -t 1 && -t 2 ]] && { stty -echo </dev/tty 2>/dev/null; printf "${A_CURSOR_OFF}" >/dev/tty; } }
ma_tty_echo_on() { [[ -t 1 && -t 2 ]] && { stty echo </dev/tty 2>/dev/null; printf "${A_CURSOR_ON}" >/dev/tty; } }
ma_reserve_screen() { printf "${A_CURSOR_OFF}\n\n\n\n\n\n\n\n\n\n\n\n\033[12A" >&2; }
ma_now() { local -n _r=$1; _r=${EPOCHREALTIME/[,.]/}; [[ -z $_r ]] && _r="$(date +%s%6N)"; }

[[ -v _ma_sleepfifo ]] || {
	_ma_sleepfifo="/tmp/ma_sleepfifo_${$}_${EPOCHREALTIME/[.,]/}"
	mkfifo "$_ma_sleepfifo"				|| { die "Failed creating sleep fifo"; }
	exec {fd_sleep}<>"$_ma_sleepfifo"	|| { die "Failed opening sleep fifo"; }
	rm -f "$_ma_sleepfifo"
}
ma_sleep() {
	local end_us elapsed_us remaining_us timeout_us start_us=${EPOCHREALTIME/[,.]/}
	if [[ -n "$start_us" ]]; then
		if [[ $1 == *.* ]]; then
			local sec=${1%%.*}
			local frac=${1#*.}
			frac=${frac:0:6}
			while ((${#frac} < 6)); do frac+="0"; done
			timeout_us=$((sec * 1000000 + 10#$frac))
		else
			timeout_us=$((10#$1 * 1000000))
		fi
		read -s -r -t "$1" -u "$fd_sleep"
		end_us=${EPOCHREALTIME/[,.]/}
		elapsed_us=$((end_us - start_us))
		remaining_us=$((timeout_us - elapsed_us))
		((remaining_us > 1000)) && {
			printf -v rem '%d.%06d' $((remaining_us/1000000)) $((remaining_us%1000000))
			sleep "$rem"
		}
	else
		sleep "${1:-}"
	fi
}
ma_spinner_start() {
    [[ "${MA_USE_SPINNER:-}" == false || ! -t 1 ]] && return
    [[ ! -t 2 ]] && return
	ma_reserve_screen
	local msg="${1:-"working…"}"
	local style=${2:-}
	if [[ ${MA_SPINNER_NO_SUBSHELL:-} != true ]]; then
		local colors=() frames=('π' 'λ' 'μ' 'σ' 'Σ' 'Δ' 'θ' 'φ')
		local base=240; local ext=$((255-$base)) im=2 jm=1
		for (( i = 0; i < ext; ++i )); do colors+=( $((base+i)) ); done
		for (( i = 0; i < ext; ++i )); do colors+=( $((base+ext-i)) ); done
		local ncolors=${#colors[@]}
		(
			local i=0
			while true; do
				if [[ ${MA_ANSI:-} != false ]]; then
					local frame="${frames[$((i % ${#frames[@]}))]}"
					local text="$frame $msg"; local len=${#text}; local out=" "
					local j=0
					while (( j < len )); do
						local ch="${text:j:1}"
						local c=${colors[$(( (i*im - j*jm) % ncolors ))]}
						out+=$'\033'"[2;38;5;${c}m${ch}"
						(( j++ ))
					done
					printf "${A_CURSOR_OFF}\r%s${A_R} " "$out" >&2
				else
					printf "${A_CURSOR_OFF}\r%s%s${A_R} " "${frames[$((i % ${#frames[@]}))]}" "$msg" >&2
				fi
				i=$(( i + 1 ));
				ma_sleep 0.1
			done
		) &
		_SPINNER_PID=$!
	else
		_SPINNER_PID=0
		printf "${A_D}\r %s${A_R} " "$msg" >&2
	fi
}
ma_spinner_stop() {
    [[ "${MA_USE_SPINNER:-}" == false || ! -t 1 ]] && return
	[[ -n "${_SPINNER_PID:-}" ]] && {
		[[ ${MA_SPINNER_NO_SUBSHELL:-} != true && $_SPINNER_PID != 0 ]] && {
			kill "${_SPINNER_PID}" 2>/dev/null
			wait "${_SPINNER_PID}" 2>/dev/null
		}
		printf "${A_R}\033[2K\r" >&2
		_SPINNER_PID=
	}
}
ma_toggle_var() { # $1:var(ref) $2:msg $3:value
	local -n var="$1"
	local log_msg="$2" val="${3:-}"
	case "$val" in
		on|1)  var=true;  info "${log_msg}: ON\n\n" ;;
		off|0) var=false; info "${log_msg}: OFF\n\n" ;;
		*) if [[ "$var" == true ]]; then var=false; info "${log_msg}: OFF\n\n";
		   else var=true; info "${log_msg}: ON\n\n"; fi ;;
	esac
}
ma_is_json() { printf '%s' "$1" | jq -e . >/dev/null 2>&1; }
ma_get_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }
ma_get_size() { stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null; }
ma_human_num() {
	local n="$1" d
	local -n out=$2
	if (( n < 1000 )); then
		printf -v out '%d' "$n"
	elif (( n < 1000000 )); then
		d=$(((n%1000)/100))
		(( d )) && printf -v out '%d.%dk' $((n/1000)) "$d" || printf -v out '%dk' $((n/1000))
	elif (( n < 1000000000 )); then
		d=$(((n%1000000)/100000))
		(( d )) && printf -v out '%d.%dM' $((n/1000000)) "$d" || printf -v out '%dM' $((n/1000000))
	else
		d=$(((n%1000000000)/100000000))
		(( d )) && printf -v out '%d.%dG' $((n/1000000000)) "$d" || printf -v out '%dG' $((n/1000000000))
	fi
}
ma_clipboard_copy() {
	if command -v win32yank.exe >/dev/null 2>&1; then
		win32yank.exe -i
	elif command -v wl-copy >/dev/null 2>&1; then
		wl-copy
	elif command -v xclip >/dev/null 2>&1; then
		xclip -selection clipboard
	elif command -v xsel >/dev/null 2>&1; then
		xsel --clipboard --input
	else
		return 1
	fi
}
ma_normalize_path() {
    local path="$1" seg
    local -a segs out
    IFS=/ read -ra segs <<< "$path"
    for seg in "${segs[@]}"; do
        case "$seg" in
            ''|.) continue ;;
            ..) [[ ${#out[@]} -gt 0 ]] && unset 'out[-1]' ;;
            *) out+=("$seg") ;;
        esac
    done
    local joined
    printf -v joined '/%s' "${out[@]}"
    _NORM_PATH="${joined/\/\//\/}"
    [[ -z "$_NORM_PATH" ]] && _NORM_PATH="/"
}
ma_press_enter_to_continue() { 
	[[ ${MA_ONE_SHOT_MODE:-} != true ]] && {
		ma_tty_echo_off;
		warn "\nPress ${A_B}Enter${A_WARN} to continue...";
		read -r;
	   	printf '\033[2K\r' >&2; 
	}
}
ma_hash() { # $1:out(ref) $2:string
	local -n _sh_out=$1
	local s="$2" h=
	if   command -v md5sum &>/dev/null; then	h="$(printf '%s' "$s" | md5sum)"; h="${h%% *}"
	elif command -v cksum &>/dev/null; then		h="$(printf '%s' "$s" | cksum)"; h="${h//[$' \t']/_}"
	elif command -v sha256sum &>/dev/null; then	h="$(printf '%s' "$s" | sha256sum)"; h="${h%% *}"
	elif command -v openssl &>/dev/null; then	h="$(printf '%s' "$s" | openssl dgst -sha256 -r)"; h="${h%% *}"
	fi
	_sh_out="$h"
}
ma_uid() { # 1:out_var(ref) -> 6 chars time (epoch ms) + 2 chars pid, base36
	local -n _r=$1
	local n=${EPOCHREALTIME/[,.]/} p=${BASHPID:-$$} chars=0123456789abcdefghijklmnopqrstuvwxyz s= i
	[[ -z $n ]] && n=$(date +%s%6N)
	n=$(( n / 1000 ))
	for (( i = 0; i < 6; i++ )); do s=${chars:n%36:1}$s; n=$(( n / 36 )); done
	s+=${chars:p%36:1}${chars:(p/36)%36:1}
	_r=$s
}

_hook_call() {
	local hook arrname="_hooks_$1"
	local -n _hook_list="$arrname" 2>/dev/null || return 0
	local ret=0 status
	shift
	for hook in "${_hook_list[@]}"; do "$hook" "$@" >&2; status=$?; (( status != 0 )) && ret=$status; done
	return "$ret"
}

_err_ep_unknown_provider() {
	err "Unknown provider: ${1:-}\n";
	info " You can add new providers in your configuration file:\n   $MA_CONFIG_DIR/config.sh\n"
	info "\n ${A_B}MARKOV_PROVIDERS${A_INFO}[name]=\"ENV_API_KEY|https://[URL]/v1\"\n"
	info '\n'
	info " Use ${A_B}/config${A_INFO} to edit your config file.\n"
	info " Use ${A_B}/model${A_INFO} to select another provider/model.\n\n"
}
_err_ep_no_url() {
	err "No model selected or API URL specified.\n"
	info " To select a model from providers, use the ${A_B}--model${A_INFO} CLI option, or use\n"
	info " the ${A_B}/model${A_INFO} command.\n\n"
	info " Provider models examples:\n"
	info "   \"${A_I}zai/glm${A_INFO}\"        (partial match)\n"
	info "   \"${A_I}openrouter/${A_INFO}\"    (picked automatically)\n"
	info " To make it the default, set ${A_B}MARKOV_MODEL${A_INFO} in the config file.\n\n"
	info " To connect directly to a custom URL use ${A_B}--url${A_INFO} or edit the config file.\n"
	info " Alternatively, set the URL from the prompt:\n   ${A_B}!MA_API_URL_CLI=<base_addr>${A_INFO}, then ${A_B}/reload${A_INFO} to apply changes.\n\n"
	info " Use ${A_B}/config${A_INFO} to set up the config file.\n\n"
	info " To add or override a provider:\n"
	info "   ${A_B}MARKOV_PROVIDERS${A_INFO}[name]=\"ENV_KEY_NAME|URL\"\n\n"
}

_endpoint_check_api_type() {
	MA_API_TYPE='openai_chat'
	[[ "${MA_API_URL:-}" == *"/v1/responses"* ]] && MA_API_TYPE='openai_resp'
	[[ "${MA_API_URL:-}" == *"/v1/messages"* ]] && MA_API_TYPE='anthropic'
}

_modelsdev_to_cache(){
	_modelsdev_cachedfile="${_ma_cache_dir}/models.dev.json"
	local modelsdev_file_present=false
	[[ -s "$_modelsdev_cachedfile" ]] && {
		local age=$(( $(date +%s) - $(ma_get_mtime "$_modelsdev_cachedfile" || echo 0) ))
		if (( age < ${MA_MODELSDEV_MAX_AGE_SECS:-604800} )); then modelsdev_file_present=true; fi
	}

	[[ ${MA_MODELDEV_FORCE_UPDATE:-} == true ]] && modelsdev_file_present=false

	[[ "$modelsdev_file_present" == false ]] && {
		unset MA_MODELDEV_FORCE_UPDATE
		local _modelsdev_api_url="${MA_MODELSDEV_API_URL:-https://models.dev/api.json}"
		ma_spinner_start "updating providers database…"
		local _tmp_models_file="${_modelsdev_cachedfile}.tmp.$$"
		local content_type
		if content_type=$(curl ${MA_WEB_PROXY:-} -fsSL -H 'Accept: application/json' -w '%{content_type}' \
				-o "$_tmp_models_file" "$_modelsdev_api_url" 2>/dev/null) &&
				[[ -s "$_tmp_models_file" && ${content_type%%;*} == application/json ]]; then
			mv -f "$_tmp_models_file" "$_modelsdev_cachedfile"
			ma_spinner_stop
			return 0
		else
			ma_spinner_stop
			warn "Warning: Failed to update providers database ($_modelsdev_api_url).\n"
			warn "Information about providers and models will be absent or stale.\n"
			warn "You can download api.json file manually from models.dev. Put it in ${_ma_cache_dir}.\n"
			rm -f "$_tmp_models_file"
			return 1
		fi
	}
	return 0
}

_modelsdev_list_all_models_arr() {
	if _modelsdev_to_cache; then
		local -n _out=$1
		mapfile -t _out < <(
			jq -br '
				to_entries[]
				| .key as $provider
				| (.value.models // {})
				| to_entries[]
				| "\($provider)/\(.key)"
			' "$_modelsdev_cachedfile"
		)
	fi
}
_modelsdev_list_models_arr() {
	local ep_provider=$2
	if [[ -n "$ep_provider" ]] && _modelsdev_to_cache; then
		local -n _out=$1
		mapfile -t _out < <(
			jq -br --arg p "$ep_provider" '
				(.[$p].models // {})
				| to_entries[]
				| .key
			' "$_modelsdev_cachedfile"
		)
	fi
}

# extract providers and models info from JSON database (https://models.dev/api.json)
_modelsdev_get() { # 1:provider 2:model_match
	local ep_provider=$1 ep_model_id=$2
	MDV_PROVIDER_FOUND=false
	MDV_ID=null
	if [[ -n "$ep_provider" ]] && _modelsdev_to_cache; then
		eval "$(jq -br --arg p "$ep_provider" --arg m "$ep_model_id" '
				.[$p] as $provider | ($provider.models // {}) as $models
				| ($provider.env // []) as $provider_env
				| ($provider.npm // "") as $provider_npm
				| ($provider.api // "") as $provider_api
				| ($m | ascii_downcase) as $m_lc |
				def is_text_model:
					((.value.modalities.input // []) | index("text"))
					and
					((.value.modalities.output // []) | index("text"));
				($models | to_entries) as $entries |
				(
					($entries | map(select((.key | ascii_downcase) == $m_lc)) | .[0]) as $exact
					| ($entries | map(select((.key | ascii_downcase) == ("~" + $m_lc))) | .[0]) as $tilde
					| ($entries | map(select($m_lc != "" and ( (.key | ascii_downcase | contains($m_lc))
							or (.key | ascii_downcase | contains("~" + $m_lc))
						)))
						| .[0]) as $partial
					| (($entries | map(select(is_text_model)) | .[0]) // $entries[0]) as $first_any
					| ($models | to_entries | .[0]) as $any
					|
					if $exact then {match: $exact, type: "exact"}
					elif $tilde then {match: $tilde, type: "exact"}
					elif $partial then {match: $partial, type: "partial"}
					elif $first_any then {match: $first_any, type: "fallback"}
					else {match: $any, type: "none"}
					end
				) as $result
				| $result.match.key as $model_id
				| $result.match.value as $x
				| $result.type as $match_type |
				"MDV_ID=" + ($model_id | @sh),
				"MDV_RAW_JSON=" + ($x | tojson | @sh),
				"MDV_MATCH_TYPE=" + ($match_type | @sh),
				"MDV_REASONING=\($x.reasoning // false)",
				"MDV_TOOL_CALL=\($x.tool_call // false)",
				"MDV_STRUCTURED_OUTPUT=\($x.structured_output // false)",
				"MDV_TEMPERATURE=\($x.temperature // false)",
				"MDV_OPEN_WEIGHTS=\($x.open_weights // false)",
				"MDV_LIMIT_CONTEXT=\($x.limit.context // 0)",
				"MDV_LIMIT_INPUT=\($x.limit.input // 0)",
				"MDV_LIMIT_OUTPUT=\($x.limit.output // 0)",
				"MDV_COST_INPUT=\($x.cost.input // 0)",
				"MDV_COST_OUTPUT=\($x.cost.output // 0)",
				"MDV_COST_CACHE_READ=\($x.cost.cache_read // 0)",
				"MDV_COST_CACHE_WRITE=\($x.cost.cache_write // 0)",
				"MDV_TIERS=(" + ([ ($x.cost // {}) | to_entries[]
					| select(.key | startswith("context_over_"))
					| (.key | ltrimstr("context_over_")) as $s
					| (($s | sub("[kKmM]$";"") | tonumber)
						* (if ($s|test("[kK]$")) then 1000 elif ($s|test("[mM]$")) then 1000000 else 1 end) | floor) as $t
					| "\($t) \(.value.input // 0) \(.value.output // 0) \(.value.cache_read // 0) \(.value.cache_write // 0)"
				  ] | map(@sh) | join(" ")) + ")",
				"MDV_MODALITIES_INPUT=(" + (($x.modalities.input // []) | map(@sh) | join(" ")) + ")",
				"MDV_MODALITIES_OUTPUT=(" + (($x.modalities.output // []) | map(@sh) | join(" ")) + ")",
				"MDV_REASONING_OPTIONS=(" + ([ $x.reasoning_options[]?.values[]? ] | map(@sh) | join(" ")) + ")",
				"MDV_ENVS=(" + ($provider_env | map(@sh) | join(" ")) + ")",
				"MDV_NPM=" + ($provider_npm | @sh),
				"MDV_API_URL=" + ($provider_api | @sh)
			' "$_modelsdev_cachedfile"
		)"
		[[ $MDV_ID != "null" ]] && { MDV_PROVIDER_FOUND=true; return 0; }
	fi
	return 1
}

endpoint_obj_set() { # 1:name 2:model_id
	local ep_name=$1 ep_model_id=$2 ep_provider= 
	[[ ${ep_model_id:-} == */* ]] && { ep_provider=${ep_model_id%%/*}; ep_model_id=${ep_model_id#*/}; }
	_EP_MODEL="${ep_model_id:-"no-model"}"
	_EP_ALIAS=

	local custom_provider= ep_ret_code=0
	[[ -n $ep_provider ]] && {
		custom_provider="${MARKOV_PROVIDERS[$ep_provider]:-}"
		_modelsdev_get "$ep_provider" "$ep_model_id"
	}

	if [[ -n $ep_provider && ${MDV_PROVIDER_FOUND:-} != true && -z $custom_provider ]]; then
		[[ $ep_name != main ]] && err "Error for custom endpoint '$ep_name'\n"
		_err_ep_unknown_provider "$ep_provider"; 
		_EP_MODEL="no-model"
		ep_provider=
		ep_ret_code=1
	elif [[ -n $ep_provider && -z $custom_provider && -z $MDV_API_URL ]]; then
		[[ $ep_name != main ]] && err "Error for custom endpoint '$ep_name'\n"
		err "\nNo API URL found for provider '$ep_provider'.\n"
		info " Override ${A_B}$ep_provider${A_INFO} provider API URL in the config file.\n\n";
		ep_ret_code=2
	fi

	local -a _EP_ENVS_UNSET

	local input=0 output=0 rcache=0 wcache=0 max_tokens=8192 reasoning=true reasoning_opts= tool_call=true input_mode= temperature= raw_json=

	[[ -n $custom_provider ]] && {
		local key_env= url=
		if [[ $custom_provider == *'|'* ]]; then
			IFS='|' read -r key_env url <<< "$custom_provider"
		else
			url="$custom_provider"
		fi
		[[ -n $key_env ]] && {
			eval 'MA_API_KEY="${MA_API_KEY:-${'$key_env':-}}"'
			[[ -z "$MA_API_KEY" && -z ${!key_env:-} && $MDV_PROVIDER_FOUND != true ]] && { _EP_ENVS_UNSET+=("$key"); }
		}
		MA_API_URL="${MA_API_URL:-$url}"
	}

	if [[ ${MDV_PROVIDER_FOUND:-} == true ]]; then
		local found=true
		if [[ "$MDV_MATCH_TYPE" != "exact" && "$MDV_MATCH_TYPE" != "partial" ]]; then
			if [[ -n "$_EP_MODEL" && "$_EP_MODEL" != "no-model" ]]; then
				warn "Model specified not found in catalog: $_EP_MODEL.\n"
				info " Try updating fle with ${A_B}--update-providers${A_INFO}, or add information manually.\n\n" >&2
				MDV_ID=$_EP_MODEL
				found=false
			else
				info "No model specified. Using: ${A_B}$MDV_ID${A_INFO}.\n\n"
			fi
		fi
		[[ $found == true ]] && {
			reasoning=${MDV_REASONING:-false}
			tool_call=${MDV_TOOL_CALL:-false}
			local IFS=','
			input_mode=${MDV_MODALITIES_INPUT[*]}
			(( MDV_LIMIT_OUTPUT > 0 )) && max_tokens=${MDV_LIMIT_OUTPUT:-}
			input=${MDV_COST_INPUT:-0}
			output=${MDV_COST_OUTPUT:-0}
			rcache=${MDV_COST_CACHE_READ:-0}
			wcache=${MDV_COST_CACHE_WRITE:-0}
			reasoning_opts=${MDV_REASONING_OPTIONS[*]:-}
			temperature=$MDV_TEMPERATURE
			raw_json=$MDV_RAW_JSON
			(( MDV_LIMIT_CONTEXT <= 0)) && MDV_LIMIT_CONTEXT=128000
			_EP_CTX=${MDV_LIMIT_CONTEXT:-128000}
		}

		_EP_MODEL="$MDV_ID"
		local key
		[[ -z ${MA_API_KEY:-} ]] && {
			for key in "${MDV_ENVS[@]}"; do
				[[ -n "${!key-}" && $MDV_API_URL != *${key}* ]] && { MA_API_KEY="${MA_API_KEY:-${!key}}"; break; }
			done
			[[ -z "$MA_API_KEY" ]] && {
				for key in "${MDV_ENVS[@]}"; do
					[[ -z "${!key-}" && $MDV_API_URL != *${key}* ]] && { _EP_ENVS_UNSET+=("$key"); eval $key=""; }
				done
			}
		}
		for key in "${MDV_ENVS[@]}"; do
			[[ -z "${!key-}" && $MDV_API_URL == *${key}* ]] && { err "$key env required for the API URL\n"; exit 1; }
		done
		[[ -n $MDV_API_URL && -z "$MA_API_URL" ]] && {
			eval "MDV_API_URL=\"$MDV_API_URL\""
			MDV_API_URL="${MDV_API_URL%/}"
			if [[ $MDV_NPM == *anthropic* ]]; then
				MDV_API_URL="$MDV_API_URL/messages"
			else
				MDV_API_URL="$MDV_API_URL/${MA_CUSTOM_API_URL_END:-"chat/completions"}"
			fi
			MA_API_URL="${MDV_API_URL}"
		}

	else

		if [[ -z $MA_API_URL ]]; then
			[[ $ep_name != main ]] && err "Error for custom endpoint '$ep_name'\n"
			_err_ep_no_url
			ep_ret_code=3
		else
			[[ ${MA_SKIP_ENDPOINT_CHECK:-} != true ]] && {
				ma_spinner_start "connecting…"
				local raw= models_url
				_endpoint_request_models
				ma_spinner_stop
				if [[ -z "$raw" ]]; then
					[[ $ep_name != main ]] && err "Error for custom endpoint '$ep_name'\n"
					err "Failed to connect to endpoint: $MA_API_URL\n"
					ep_ret_code=4
				elif [[ "$raw" == *'"error"'* || "$raw" == *"<!DOCTYPE"* ]]; then
					[[ $ep_name != main ]] && err "Error for custom endpoint '$ep_name'\n"
					err "Server error\n"
					printf '%s' "$raw" | jq -br '.error.message // ""' 2>/dev/null
					ep_ret_code=5
				else
					if ! _endopint_parse_models "${raw:-{\}}" "$ep_model_id"; then
						ep_ret_code=6
					fi
				fi
			}
		fi
	fi

	[[ -n $MA_API_URL ]] && {
		MA_API_URL="${MA_API_URL%/}"
		case "$MA_API_URL" in
			*/chat/completions|*/responses|*/messages) ;;
			*) MA_API_URL+="/${MA_CUSTOM_API_URL_END:-"chat/completions"}" ;;
		esac
	}
	_endpoint_check_api_type

	local original_name="${_EP_ALIAS:-$_EP_MODEL}"
	local model_name="${original_name##*/}"
	model_name="${model_name%.gguf}"
	local _len=${#model_name}
    local model_id="${ep_provider}/${model_name}"
	local display_name=$model_name
	(( _len > 48 )) && display_name="${display_name:_len-48}"
	declare -gA "MA_ENDPOINT_OBJ_$ep_name"
	local -n endpoint="MA_ENDPOINT_OBJ_$ep_name"
	endpoint=(
		[provider]=$ep_provider
		[model.name]=$original_name
		[model.id]=$model_id
		[model.display_name]=$display_name
		[model.ctx]=${MA_CTX:-${_EP_CTX:-128000}}
		[api_type]=$MA_API_TYPE
		[api_url]=$MA_API_URL
		[api_key]=$MA_API_KEY
		[api_proxy]=${MA_API_PROXY:-}
		[input_mode]=$input_mode
		[max_tokens]=$max_tokens
		[reasoning]=$reasoning
		[reasoning_opts]=$reasoning_opts
		[tool_call]=$tool_call
		[temperature]=$temperature
		[raw]=$raw_json
	)

	[[ -v 'MARKOV_PRICING[$model_id]' ]] || { MARKOV_PRICING["$model_id"]="${input:-0} ${output:-0} ${rcache:-0} ${wcache:-0}"; }
	[[ ${MDV_PROVIDER_FOUND:-} == true ]] && for t in "${MDV_TIERS[@]}"; do
		[[ -v 'MARKOV_PRICING[$model_id@${t%% *}]' ]] || MARKOV_PRICING["$model_id@${t%% *}"]="${t#* }"
	done

	[[ ${_EP_ENVS_UNSET[*]+x} ]] && (( ${#_EP_ENVS_UNSET[@]} > 0 )) && [[ -z $MA_API_KEY ]] && {
		[[ $ep_name != main ]] && warn "Warning for endpoint '$ep_name'\n"
		local IFS=' '
		warn "API keys not set: ${_EP_ENVS_UNSET[*]}\n"
		info " You can set provider specific keys directly: ${A_B}!${_EP_ENVS_UNSET[0]}=<secret>\n"
		info " Or override any key with: ${A_B}!MA_API_KEY_CLI=<secret>\n"
		info " Then use command ${A_B}/reload${A_INFO} or ${A_B}/model${A_INFO} to apply changes.\n\n"
		_EP_ENVS_UNSET=()
		ep_ret_code=100
	}

	MA_API_URL=
	MA_API_KEY=
	MA_API_MODEL=

	return $ep_ret_code
}

_get_llm_opts(){
	local -n _out_llmopts=$1
	local llm_comma_separated=$2
	local -a _opts=()
	IFS=',' read -ra _opts <<< "${llm_comma_separated:-}"
	_out_llmopts=
	for _opt in "${_opts[@]}"; do
		[[ "$_opt" =~ ^[a-z_]+=-?[0-9]+\.?[0-9]*$ ]] || { err "Invalid llm-opts format: $_opt. Use key=value,..,key=value\n"; break; }
		_out_llmopts+="$_opt "
	done
}

thread_obj_set() { # 1:thread_name 2:role 3:parents_count 4:is_task_evaluator
	local th_name=$1 role=${2:-main} parents_count=${3:-0} is_task_evaluator=${4:-} _th_obj_ret_code=0
	if [[ -v MA_ROLES[$role] ]]; then
		local -n _role=${MA_ROLES[$role]}
	else
		ma_spinner_stop
		_th_obj_ret_code=1
		err "No $role role found for thread $th_name\n"
		local -n _role=${MA_ROLES[main]}
	fi

	local -n _original_thread_tools="MA_ROLE_TOOLS_$role"
	local -A _thread_tools=()
	eval "_thread_tools=(${_original_thread_tools[@]@K})"
	local max=${_role[max_parents]:-}

	local n_max_parents="${_role[max_parents]:-"${MA_DELEGATE_MAX_PARENTS:-2}"}"
	(( parents_count > 0 )) && _thread_tools[submit]=1;
	(( parents_count > n_max_parents )) && unset '_thread_tools[delegate]';

	[[ -v 'MA_EVALUATED["$th_name@evaluated"]' ]] && is_task_evaluator=true
	[[ "$role" == task_evaluator || $is_task_evaluator == true ]] && { 
		is_task_evaluator=true
		_thread_tools[feedback]=1; unset '_thread_tools[submit]'; 
	}

	declare -gA "MA_THREAD_OBJ_$th_name"
	local -n thread_obj="MA_THREAD_OBJ_$th_name"
	thread_obj=()

	local ep_name=main
	[[ -v _role[endpoint] && -n "${_role[endpoint]}" ]] && ep_name="${_role[endpoint]}"
	ep_name="${thread_obj["endpoint"]:-$ep_name}"

	local -n ep="MA_ENDPOINT_OBJ_$ep_name"
    declare -gA "MA_ACTIVE_SKILLS_$th_name"
	local _tool_json= tools_str=

	[[ ${_role[use_tools]:-} != false ]] && {
		local IFS=','
		tools_str="${!_thread_tools[*]}"
		for t in "${!_thread_tools[@]}"; do _tool_json+="${MA_TOOL[$t]},"; done
		_tool_json="[${_tool_json%,}]"
		[[ -n "${MA_NO_DEFERRED:-}" ]] && { _tool_json="$(jq -bc '[.[] | del(.defer_loading)]' <<< "$_tool_json" 2>/dev/null)"; }
		case "${ep[api_type]}" in
			anthropic)
				local _conv_json TOOL_SEARCH_ANTHROPIC='{"type":"tool_search_tool_regex_20251119","name":"tool_search_tool_regex"}'
				_conv_json="$(jq -bc --argjson search "$TOOL_SEARCH_ANTHROPIC" '
					. as $orig
					| [$orig[] | select(.type == "function") | (
						{name}
						+ (if .description != null then {description} else {} end)
						+ (if .parameters != null then {input_schema: .parameters} else {} end)
						+ (if .defer_loading != null then {defer_loading} else {} end)
					)]
					| if any($orig[]; .defer_loading == true) then [$search] + . else . end
				' <<< "$_tool_json" 2>/dev/null)"
				_tool_json="$_conv_json"
				;;
			openai_resp)
				local _conv_json TOOL_SEARCH_OPENAI_RESP='{"type":"tool_search"}'
				_conv_json="$(jq -bc --argjson search "$TOOL_SEARCH_OPENAI_RESP" '
					if any(.[]; .defer_loading == true) then [$search] + . else . end
				' <<< "$_tool_json" 2>/dev/null)"
				_tool_json="$_conv_json"
				;;
			openai_chat)
				local _conv_json
				_conv_json="$(jq -bc '
					[.[] | select(.type == "function") | {
						type: "function",
						function: (
							{name}
							+ (if .description != null then {description} else {} end)
							+ (if .parameters != null then {parameters} else {} end)
							+ (if .strict != null then {strict} else {} end)
						)
					}]
				' <<< "$_tool_json" 2>/dev/null)"
				_tool_json="$_conv_json"
				;;
		esac
	}

	thread_obj["role"]="$role"
	thread_obj["task_evaluator"]="$is_task_evaluator"
	thread_obj["endpoint"]="${thread_obj["endpoint"]:-$ep_name}"
	thread_obj["tools_json"]="$_tool_json"
	thread_obj["tools"]=$tools_str
	thread_obj["parents_count"]=$parents_count
	thread_obj["persona"]="${_role[persona]:-}"
	_get_llm_opts thread_obj["llm_opts"] "${_role[llm_opts]:-}"
	thread_obj["max_tokens"]="${_role[max_tokens]:-8192}"
	thread_obj["thinking"]="${_role["thinking"]:-medium}"
	thread_obj["use_tools"]="${_role["use_tools"]:-${MA_USE_TOOLS:-true}}"
	thread_obj["stream"]=${_role["stream"]:-${MA_STREAM:-true}}

	local sprompt=
	_system_prompt_for_role "$role" _thread_tools sprompt

	local prompt_tail=
	[[ -v '_thread_tools[submit]' ]] && { prompt_tail=$MA_SUBMIT_MSG; }
	[[ -v '_thread_tools[feedback]' ]] && { prompt_tail=$MA_FEEDBACK_MSG; }

	local notes_msg=
	[[ ${MA_DELEGATE_USE_NOTES:-} != false && -v '_thread_tools[submit]' ]] && {
		[[ -v '_thread_tools[edit]' ]] && {
			local thread_id=
			[[ "$MA_THREAD_NAME" =~ _sub_([a-zA-Z0-9_-]+)$ ]] && thread_id="${BASH_REMATCH[1]}"
			[[ -n "$thread_id" ]] && {
				local notes_file="${_ma_notes_dir}/task-${thread_id}.md"
				notes_msg=${MA_DELEGATE_PROMPT_NOTES:-"
NOTE: For long tasks, you may maintain compact persistent notes on task
progress in '${notes_file}'. Create the file if it does not exist.
Treat the notes as a compact handoff document for another agent that may need
to resume the task. Write them as if briefing someone with zero prior context.
Use concise bullets. No reasoning, history, or redundant information.
Update the notes whenever important state changes occur.
"}
			}
		}
	}

	thread_obj["system_prompt"]="${sprompt}${notes_msg}${prompt_tail}"

	return $_th_obj_ret_code
}

ma_source_modules(){
	declare -gA MA_MODULES_LOADED=()
	local t
	[[ -v _MA_INITIALIZED ]] || {
		declare -gA _builtin_tools_map=();
		for t in "${!MA_TOOL[@]}"; do _builtin_tools_map["$t"]=1; done
	}

	[[ "${MA_USE_MODULES:-true}" != false ]] && {

		_hook_register() {
			local hname="$1" event="$2"
			local arrname="_hooks_$event"
			if ! declare -p "$arrname" >/dev/null 2>&1; then declare -ga "$arrname=()"; fi
			local -n _hook_arr="$arrname"
			local _h found=0
			for _h in "${_hook_arr[@]}"; do [[ "$_h" == "$hname" ]] && { found=1; break; }; done
			(( found )) || _hook_arr+=("$hname")
		}

		local _mod_dirs=("$MA_CONFIG_DIR/modules")
		[[ -d "${MA_MODULES_DIR:-}" ]] && _mod_dirs+=("$MA_MODULES_DIR")
		[[ "${MA_TRUST_DIR:-}" == "true" ]] && _mod_dirs+=("./.markov/modules")

		local allowed_modules_list=()
		[[ -n ${MA_ALLOWED_MODULES:-} ]] && IFS=',' read -ra allowed_modules_list <<< "${MA_ALLOWED_MODULES// /}"

		local _supported_hooks=(
			reload cleanup
			session_load session_store
			loop_start loop_end
			turn_start turn_end
			request response response_stream
			tool_start tool_end
			confirm_start confirm_end
		)

		local dir _script _allowed _hk var
		for dir in "${_mod_dirs[@]}"; do
			[[ -d "$dir" ]] || continue
			for _script in "$dir"/*.sh; do
				[[ -f "$_script" ]] || continue

				local _mod_id="${_script##*/}"
				_mod_id="${_mod_id%.sh}"

				if [[ ${#allowed_modules_list[@]} -gt 0 ]]; then
					for _allowed in "${allowed_modules_list[@]}"; do
						[[ $_allowed == "$_mod_id" ]] && break
					done
					[[ $_allowed == "$_mod_id" ]] || continue
				fi

				[[ -v 'MA_MODULES_LOADED[$_mod_id]' ]] && continue;
				. "$_script" "${MA_CLI_ARGS[@]}" || { err "Failed to source module: $_script\n"; continue; }
				MA_MODULES_LOADED["$_mod_id"]="$_script"

				# hook_<event> to hook_<module>_<event>
				for _hk in "${_supported_hooks[@]}"; do
					if declare -F "hook_$_hk" >/dev/null 2>&1; then
						local _hdef; _hdef="$(declare -f "hook_$_hk")"
						_hdef="${_hdef/hook_$_hk/hook_${_mod_id}_${_hk}}"
						eval "$_hdef"
						_hook_register "hook_${_mod_id}_${_hk}" "$_hk"
						unset -f "hook_$_hk"
					fi
				done
			done
		done

		declare -ga _modules_tool_names=()
		[[ "${MA_USE_TOOLS:-}" != false ]] && { # module tool validation
			local -a names=() jsons=() valid=()
			for t in "${!MA_TOOL[@]}"; do
				[[ -v '_builtin_tools_map["$t"]' ]] && continue
				names+=("$t")
				jsons+=("${MA_TOOL[$t]}")
			done
			(( ${#jsons[@]} > 0 )) && {
				mapfile -t valid < <(printf '%s\0' "${jsons[@]}" | jq -bR -s -c '
					split("\u0000") | .[:-1] | map(try (fromjson | true) catch false) | .[]
				')
				local i
				for i in "${!names[@]}"; do
					[[ "${valid[$i]:-false}" != "true" ]] && { warn "Invalid JSON: ${names[$i]}\n"; continue; }
					_modules_tool_names+=("${names[$i]}")
				done
			}
		}

	}
}

_persona_load() {
	local -n _out=$1
	local _name=$2
	_out=
	[[ -n $_name ]] || return 0
	if [[ -v 'MA_PERSONAS[$_name]' && -f ${MA_PERSONAS[$_name]} ]]; then
		_out=$'\n'"$(<"${MA_PERSONAS[$_name]}")"
	else
		return 1
	fi
}

_role_set() { # 1:role
	local role=$1
	local -n _role=${MA_ROLES[$role]}

	declare -gA "MA_ROLE_TOOLS_$role"
	declare -gA "MA_ROLE_LAZY_TOOLS_$role"

	local -n _out_tools="MA_ROLE_TOOLS_$role"
	local -n _lazy_tools="MA_ROLE_LAZY_TOOLS_$role"
	local allowed_tools_list="${_role[allowed_tools]:-}"
	local default_tools_list="${_role[tools]:-}"
	local lazy_tools_list="${_role[lazy_tools]:-}"

	_out_tools=()
	local -a _list=()
	local _t ret_code=0

	[[ -n ${_role[endpoint]:-} ]] && {
		_ep=MA_ENDPOINT_OBJ_${_role[endpoint]:-}
		if ! declare -p "$_ep" &>/dev/null; then
			warn "Warning: endpoint '${_role[endpoint]}' for role '$role' not found. Using 'main' endpoint.\n"
			ret_code=2
			unset _role[endpoint]
		fi
	}

	[[ "${_role[use_tools]:-}" != false ]] && {
		[[ -n ${lazy_tools_list:-} ]] && {
			local -a list
			IFS=',' read -ra list <<< "${lazy_tools_list// /}"
			for _t in "${list[@]/execute/}"; do
				[[ -n "${MA_TOOL[$_t]-}" ]] && declare -F "execute_$_t" >/dev/null && _lazy_tools["$_t"]=1
			done
		}

		if [[ -n "${allowed_tools_list:-}" ]]; then
			IFS=',' read -ra _list <<< "${allowed_tools_list// /}"
		else
			local -a default_core_tools=(read write edit bash execute delegate websearch)
			[[ ${MA_USE_SKILLS:-} != false ]] && default_core_tools+=(skills)

			[[ -n ${default_tools_list:-} ]] && {
				default_core_tools=()
				IFS=',' read -ra _list <<< "${default_tools_list// /}"
				for _t in ${_list[@]+"${_list[@]}"}; do
					[[ -n "${MA_TOOL[$_t]-}" ]] && declare -F "execute_$_t" >/dev/null && default_core_tools+=("$_t")
				done
			}
			_list=("${default_core_tools[@]}" "${_modules_tool_names[@]}")
		fi
		for _t in ${_list[@]+"${_list[@]}"}; do
			if declare -F "execute_$_t" >/dev/null; then
				[[ -v _lazy_tools["$_t"] ]] || _out_tools["$_t"]=1
			else
				warn "Warning: Schema or execute function for tool '$_t' could not be found.\n";
				ret_code=1
			fi
		done
		[[ ${MA_USE_SKILLS:-} == false ]] && { unset '_out_tools[skills]'; unset '_lazy_tools[skills]'; }
		[[ ${_SYMBOLS_REQUIREMENT_FOUND:-} == false ]] && { unset '_out_tools[symbols]'; unset '_lazy_tools[symbols]'; }
	}

	local role_persona_content=
	if ! _persona_load role_persona_content "${_role[persona]:-}"; then 
		warn "[Warning] In role '$role': No persona matching '${_role[persona]:-}' found.\n" >&2
		ret_code=2;
	fi
	_role[persona_content]=$role_persona_content

	return $ret_code
}

MA_DEFAULT_SYSTEM_PROMPT=${MA_DEFAULT_SYSTEM_PROMPT:-"You are a general-purpose assistant running inside markov, a terminal harness."}

MA_SUBMIT_MSG=${MA_SUBMIT_STEER_MESSAGE:-"
[CRITICAL: Call 'submit' to finish the task and report results. Do NOT write task result in the final response. Use 'submit' only.]"}

MA_CALL_ANALYZER_SYSTEM_PROMPT="You are a security gate reviewing a single tool call. Output only PASS when the call is clearly safe and appropriate;
otherwise output FAIL. Any suspicious, destructive, irreversible, privileged, malicious, or uncertain call must be FAIL."

MA_TASK_EVALUATOR_SYSTEM_PROMPT="
You are a reviewer in markov, a terminal harness. Review the worker submission against the task requirements and determine whether it should be accepted.

Call 'feedback' once after gathering sufficient evidence:
- 'pass' to accept if complete, correct, and requirements are satisfied.
- 'revise' otherwise, to steer the worker toward a correct solution.

For 'revise', give self-contained imperative instructions: state what is wrong, cite file/line/command/test evidence, and specify exactly what to change.

Do not praise, recap the task, restate working parts, make changes, or request unnecessary improvements.
Accept valid solutions regardless of implementation preference unless they conflict with the user's requirements or applicable project/system instructions.
"

MA_FEEDBACK_MSG=${MA_FEEDBACK_STEER_MESSAGE:-"
[CRITICAL: You must call 'feedback' to finish the review. Do not output the review directly, use 'feedback' only]
"}

_build_tools_message() { # 1:msg_out(ref) tools(ref)
	local -n _out=$1 _tools=$2
	local -a _names
	local _list
	if ((${#_tools[@]})); then
		mapfile -d '' -t _names < <(printf '%s\0' "${!_tools[@]}" | LC_ALL=C sort -z)
		printf -v _list '%s, ' "${_names[@]}"
		printf -v _out '\n\nTools available: %s.\n' "${_list%, }"
		[[ -v '_tools[execute]' ]] && _out+="Additional tools can be searched with 'execute'."
	else
		printf -v _out '\n\nNo tools are available in this session.\n'
	fi
}

_load_local_or_global() {
	local -n _out=$1
	local d dirs=("$MA_CONFIG_DIR")
	[[ ${MA_TRUST_DIR:-} == true ]] && dirs=(. .markov .agents "${dirs[@]}")
	for d in "${dirs[@]}"; do
		[[ -f $d/$2 ]] && { _out=$(<"$d/$2"); return; }
	done
}

_system_prompt_for_role() { # 1:role 2:tools 3:_out_sys_prompt(ref)
	if [[ -v MA_ROLES[$1] ]]; then
		local -n _role=${MA_ROLES[$1]}
	else
		local -n _role=${MA_ROLES[main]}
	fi
	local _tools_ref=$2
	local -n _out=$3

	local -n role_persona_content='_role[persona_content]'
	local system_prompt=
	if [[ -v '_role[system_prompt]' ]]; then
		system_prompt="${_role[system_prompt]}"
	else
		local role_msg_tools=
		_build_tools_message role_msg_tools "$_tools_ref"
		system_prompt="${MA_DEFAULT_SYSTEM_PROMPT}${role_msg_tools}"$'\n\n'"CWD: $MA_WORKING_DIR"
	fi

	[[ -n "${_role[append_system_prompt]:-}" ]] && system_prompt+="${_role[append_system_prompt]}"

	local agents_files_content=
	[[ ${_role[use_context_files]:-} != false ]] && agents_files_content=$MA_AGENTS_FILES_CONTENT
	local v val
	for v in agents_files_content role_persona_content; do val="${!v:-}"; [[ -n "$val" ]] && system_prompt+=$'\n'"$val"$'\n'; done
	_out=$system_prompt
}

ma_reload() {
	local reload_ret_value=0
	[[ -v _MA_INITIALIZED ]] && _hook_call cleanup

	declare -gA MA_ROLES=() MA_ENDPOINTS=()
	declare -ga MA_DELEGATE_ROLES=() MA_CUSTOM_ROLES=() MA_CUSTOM_ENDPOINTS=()

	ma_source_config

	declare -gA MA_ROLE_LAZY_TOOLS_main
	declare -gn MA_LAZY_TOOLS=MA_ROLE_LAZY_TOOLS_main
	ma_builtin_tools
	ma_builtin_commands
	ma_source_modules

	[[ ${MA_USE_SKILLS:-} != false ]] && {
		local _pc
		for _pc in "${!MA_SKILLS_DESCR[@]}"; do
			MA_COMMAND_DESCR["/$_pc"]="Skill:\n${MA_SKILLS_DESCR["$_pc"]}"
		done
	}

	declare -gA MA_CUSTOM_PROMPTS=()
	[[ ${MA_USE_PROMPTS:-} != false ]] && {
		local _pc dir _dirs
		_dirs=("$MA_CONFIG_DIR/prompts")
		[[ -d ${MA_PROMPTS_DIR:-} ]] && _dirs+=("$MA_PROMPTS_DIR")
		[[ "${MA_TRUST_DIR:-}" == "true" ]] && _dirs=("./.markov/prompts" "${_dirs[@]}" )
		for dir in "${_dirs[@]}"; do
			[[ -d "$dir" ]] || continue
			for f in "$dir"/*; do
				[[ -f "$f" ]] || continue
				local e_name="${f##*/}"
				e_name="${e_name%%.*}"  # strip extension
				[[ -n "${MA_CUSTOM_PROMPTS[$e_name]:-}" ]] && continue
				MA_CUSTOM_PROMPTS["$e_name"]="$f"
				MA_COMMAND_DESCR["/$e_name"]="Prompt file.\nTo expand inline, write ${A_B}/$e_name${A_R} and press ${A_B}alt+t${A_R}."
			done
		done
	}

	declare -gA MA_PERSONAS=()
	[[ ${MA_USE_PERSONAS:-} != false ]] && {
		local _pc dir _dirs
		_dirs=("$MA_CONFIG_DIR/personas")
		[[ -d ${MA_PERSONAS_DIR:-} ]] && _dirs+=("$MA_PERSONAS_DIR")
		[[ "${MA_TRUST_DIR:-}" == "true" ]] && _dirs=("./.markov/personas" "${_dirs[@]}" )
		for dir in "${_dirs[@]}"; do
			[[ -d "$dir" ]] || continue
			for f in "$dir"/*; do
				[[ -f "$f" ]] || continue
				local e_name="${f##*/}"
				e_name="${e_name%%.*}"
				[[ -n "${MA_PERSONAS[$e_name]:-}" ]] && continue
				MA_PERSONAS["$e_name"]="$f"
			done
		done
	}

	MA_AGENTS_FILES_CONTENT=
	declare -ga _ma_ctx_files=()

	[[ ${MA_USE_CONTEXT_FILES:-} != false ]] && {

		[[ ! -v MA_SYSTEM_PROMPT ]] && _load_local_or_global MA_SYSTEM_PROMPT "SYSTEM.md"
		[[ -z $MA_APPEND_SYSTEM_PROMPT ]] && _load_local_or_global MA_APPEND_SYSTEM_PROMPT	"APPEND_SYSTEM.md"

		for f in "$MA_CONFIG_DIR/CLANKERS.md" "$MA_CONFIG_DIR/AGENTS.md" ; do
			local dd="${f/#"$MA_CONFIG_DIR"/'<global>'}"
			[[ -f "$f" ]] && { _ma_ctx_files+=( "$dd" ); MA_AGENTS_FILES_CONTENT+=$'\n'"$(<"$f")"; break; };
		done
		[[ "${MA_TRUST_DIR:-}" == "true" ]] && { # take as project root any dir with .git inside
			local _cur="$PWD" _root=""
			while :; do
				[[ -e "$_cur/.git" ]] && { _root="$_cur"; break; }
				[[ "$_cur" == "/" ]] && break
				_cur="${_cur%/*}"
				[[ -z "$_cur" ]] && _cur="/"
			done
			[[ -z "$_root" ]] && _root="$PWD" # no repo found
			local _dirs=("$_root") _accum="$_root" _rel="" _seg
			[[ "$PWD" != "$_root" ]] && {
				_rel="${PWD#"$_root"/}"
				while [[ "$_rel" == */* ]]; do
					_seg="${_rel%%/*}"
					_rel="${_rel#*/}"
					_accum+="/$_seg"
					_dirs+=("$_accum")
				done
				[[ -n "$_rel" ]] && _dirs+=("$_accum/$_rel")
			}
			local d dd
			for d in "${_dirs[@]}"; do
				for f in "$d/CLANKERS.md" "$d/AGENTS.md"; do
					[[ -f "$f" ]] && {
						#_ma_ctx_files+=(".${f/"$_root"}")
						dd="${f/#"$_root"/'<proj>'}"
						_ma_ctx_files+=("$dd")
						MA_AGENTS_FILES_CONTENT+=$'\n'"$(<"$f")"
						break
					}
				done
			done
		}
	}



	[[ ${MA_QUIET:-} != true || -v _MA_INITIALIZED ]] && {
		(( _MA_SHOULD_PRINT )) && {
			printf "\033[0J${A_MARKOV}${A_B}markov ${A_R}${A_D}v${MA_VERSION}${A_R}\n\n" >&2
			[[ ! -v _MA_INITIALIZED ]] && {
				local _MA_HELP_KEYS=
				_MA_HELP_KEYS+="${A_INFO}new-line: ${A_B}ctrl+j${A_INFO} | submit: ${A_B}enter${A_INFO} | editor: ${A_B}ctrl+e${A_INFO} | discard: ${A_B}ctrl+c${A_INFO}"
				_MA_HELP_KEYS+="\ninline expansion: ${A_B}/<prompt>${A_INFO} or ${A_B}<filepath>${A_INFO} + ${A_B}alt+t${A_INFO}"
				_MA_HELP_KEYS+="\nbash: ${A_B}!${A_INFO} or ${A_B}!!${A_INFO} (to send output to LLM) | exit: ${A_B}/quit${A_INFO} or 3x(${A_B}ctrl+c${A_INFO})"
				printf "$_MA_HELP_KEYS\n\n" >&2
			}
			_context_info_print
			printf "\n" >&2
		}
	}

	local ep_name role

	_collect_from_suffixes MA_CUSTOM_ENDPOINTS	custom_endpoint_
	for ep_name in "${MA_CUSTOM_ENDPOINTS[@]}"; do 
		MA_ENDPOINTS[$ep_name]=1
		local -n ep="custom_endpoint_$ep_name"
		[[ -n "${ep[api_url]:-}" ]] && { MA_API_URL="${ep[api_url]}"; }
		[[ ${MA_ENDPOINT_MODEL_OVERRIDE[*]+x} && -v 'MA_ENDPOINT_MODEL_OVERRIDE[$ep_name]' ]] && {
			ep=([model]="${MA_ENDPOINT_MODEL_OVERRIDE[$ep_name]}")
			MA_API_URL=
		}
		if ! endpoint_obj_set "$ep_name" "${ep[model]:-"/"}"; then reload_ret_value=1; fi
	done

	declare -gA custom_role_main=(
		[tools]="$MA_DEFAULT_TOOLS" 
		[allowed_tools]="$MA_ALLOWED_TOOLS" 
		[lazy_tools]="$MA_LAZY_LIST" 
		[append_system_prompt]="${MA_APPEND_SYSTEM_PROMPT:-}"
		[persona]="$MA_PERSONA_NAME"
		[use_context_files]="$MA_USE_CONTEXT_FILES"
		[thinking]="${MA_THINKING:-medium}"
		[llm_opts]="${MA_LLM_OPTS:-}"
		[use_tools]="$MA_USE_TOOLS"
		[max_tokens]="${MA_MAX_TOKENS:-8192}"
	)
	[[ -v MA_SYSTEM_PROMPT ]] && custom_role_main[system_prompt]=$MA_SYSTEM_PROMPT


	_collect_from_suffixes MA_CUSTOM_ROLES		custom_role_
	for role in "${MA_CUSTOM_ROLES[@]}"; do MA_ROLES[$role]=custom_role_$role;   done

	for role in "${!MA_ROLES[@]}"; do
		if ! _role_set "$role"; then reload_ret_value=2; fi
	done

	[[ -n ${MA_THREAD_JSON:-} && -n ${MA_DOC_JSON:-} ]] && { 
		_doc_threads_update_on_reload; 
	}

	[[ ${_SYMBOLS_REQUIREMENT_FOUND:-} != false && -z "${_markov_symcache_dir:-}" ]] && {
		declare -F bootstrap_symbols >/dev/null && bootstrap_symbols
	}

	_hook_call reload

	declare -gi _MA_INITIALIZED=1

	return $reload_ret_value
}

_context_info_print(){
	local IFS=' '
	[[ ${#_ma_ctx_files[@]} -gt 0 ]] && { printf "${A_D}${A_B}Context:\n ${A_R}${A_D}%s\n${A_R}" "${_ma_ctx_files[*]}" >&2;  }
	[[ ${#MA_MODULES_LOADED[@]} -gt 0 ]] && { printf "${A_D}${A_B}Modules:\n ${A_R}${A_D}%s\n${A_R}" "${!MA_MODULES_LOADED[*]}" >&2; }

	_print_keys() {
		local -n map=$1
		local key
		[[ ${#map[@]} -eq 0 ]] && return
		printf '%b' "$2" >&2
		for key in "${!map[@]}"; do printf ' /%s' "$key" >&2; done
		printf '\n' >&2
	}
	_print_keys MA_SKILLS_DESCR "${A_D}${A_B}Skills:\n$A_R$A_D"
	_print_keys MA_CUSTOM_PROMPTS "${A_D}${A_B}Prompts:\n$A_R$A_D"
}

ma_prompt_lines_update() {
	MA_PROMPT_HEADER_LINES=()
	MA_PROMPT_FOOTER_LINES=()
	local role=; [[ $MA_ROLE_NAME != main ]] && role=${MA_ROLE_NAME}
	local head=; _draw_separator_var head left ─ "$A_SEP" "$role" "$A_INFO$A_B$A_D" $_MA_COLUMNS
	MA_PROMPT_HEADER_LINES+=("${head}${A_R}")
	local th=; [[ $MA_THREAD_NAME != main ]] && th=${MA_THREAD_NAME}
	local foot=; _draw_separator_var foot center ─ "$A_SEP" "$th" "$A_MARKOV${A_D}" $_MA_COLUMNS
	MA_PROMPT_FOOTER_LINES+=("$foot${A_R}")

	[[ ${MA_IPC_ONLY_MODE:-} != true ]] && {
		_footerline_project
		MA_PROMPT_FOOTER_LINES+=("$_MA_STATUSLINE_PROJECT")
		_footerline_stats
		MA_PROMPT_FOOTER_LINES+=("$_MA_STATUSLINE_STATS")
	}
	[[ -n "${MA_IPC_TOKEN:-}" ]] && {
		local token="Peer: $MA_IPC_TOKEN"
		MA_PROMPT_FOOTER_LINES+=("${token:0:_MA_COLUMNS}")
	}

	local th=$MA_THREAD_NAME
	local is_evaluator=0
	[[ -v 'MA_EVALUATED["$MA_THREAD_NAME@evaluated"]' ]] && {
		th=${MA_EVALUATED["$MA_THREAD_NAME@evaluated"]}
		is_evaluator=1
	}
	[[ -v 'MA_DELEGATED["$th@snip"]' ]] && {
		local subtask_name
		if (( is_evaluator )); then
			local s="Evaluating Task: ${A_I}${MA_DELEGATED["$th@snip"]:-'no-summary'}"
		else
			local s="Sub-task: ${A_I}${MA_DELEGATED["$th@snip"]:-'no-summary'}"
		fi
		MA_PROMPT_FOOTER_LINES+=("${s:0:_MA_COLUMNS}")
	}

}

ma_term_update() {
	_MA_COLUMNS="${COLUMNS:-}"; [[ -z "$_MA_COLUMNS" ]] && _MA_COLUMNS=$(tput cols 2>/dev/null);
	_MA_LINES="${LINES:-}"; [[ -z "$_MA_LINES" ]] && _MA_LINES=$(tput lines 2>/dev/null);
	[[ -z "$_MA_COLUMNS" || "$_MA_COLUMNS" -le 0 ]] && _MA_COLUMNS=80
	[[ -z "$_MA_LINES" || "$_MA_LINES" -le 0 ]] && _MA_LINES=20
	_MA_SHORTER_COLUMNS=$(( _MA_COLUMNS * 618033 / 1000000 ))
	local ch="─"
	printf -v _MA_SEPARATOR '%*s' "$((_MA_COLUMNS))" ''
	_MA_SEPARATOR=${_MA_SEPARATOR// /$ch}
	printf -v _MA_SEPARATOR_SHORT '%*s' "$((_MA_SHORTER_COLUMNS))" ''
	_MA_SEPARATOR_SHORT=${_MA_SEPARATOR_SHORT// /$ch}
	ma_prompt_lines_update
}

_draw_user_message() {
	local -n _user_msg=$1
	printf "${A_INPUT}\r\033[0J\033[K\n\033[K" >&2
	local _res_for_print=$'\n'"$_user_msg"$'\n'
	_res_for_print="${_res_for_print//$'\n'/$'\033[K'$'\n'}"
	printf "\033[1A${A_K}%s${A_K}${A_R}\n\033[0J\n" "$_res_for_print" >&2
}

thread_add_msg() { # $1:_session_json, $2:role, $3:content
	local -n _session_json=$1
	local _role_json _content_json
	_role_json="\"$2\""
	_content_json="$(printf '%s' "$3" | jq -bcRs .)"
	_session_json="${_session_json%"]"},{\"role\":${_role_json},\"content\":${_content_json}}]"
}

thread_add_msg_with_file() { # $1:_session_json $2:text $3:path_or_url $4:mime(optional)
	local -n _session_json=$1
	local role=user text=$2 src=$3 mime=${4:-} kind=image fmt="" is_url="false"

	if [[ $src == http://* || $src == https://* ]]; then
		is_url="true"
		case "$src" in
			*.pdf) kind=pdf ;;
			*.wav|*.mp3) kind=audio ;;
			*.txt|*.md|*.csv|*.json|*.yaml|*.yml|*.log) kind=text ;;
		esac
	else
		[[ -r $src ]] || { err "Cannot read file: $src\n"; return 1; }
		[[ -n $mime ]] || mime="$(file --mime-type -b "$src" 2>/dev/null)"
		case "${mime:-$src}" in
			application/pdf|*.pdf) kind=pdf; mime=application/pdf ;;
			audio/*|*.wav|*.mp3)   kind=audio; mime=${mime:-audio/mpeg} ;;
			text/*|*.txt|*.md|*.csv|*.json|*.yaml|*.yml|*.log) kind=text; mime=text/plain ;;
			*)                     mime=${mime:-image/jpeg} ;;
		esac
	fi

	[[ $kind == audio ]] && {
		[[ $is_url == true ]] && { err "Audio input must be provided as a local file, not URL.\n"; return 1; }
		fmt=wav; [[ $src == *.mp3 ]] && fmt=mp3
	}

	local -a feed
	case "$kind:$is_url" in
		text:true)  feed=(curl -fsSL "$src") ;;
		text:false) feed=(cat "$src") ;;
		*:true)     feed=(printf '%s' "$src") ;;
		*:false)    feed=(base64 -w0 "$src") ;;
	esac

	[[ $kind == text && $is_url != true ]] && {
	   	local _sz; _sz=$(ma_get_size "$src")
		(( ${_sz:-0} > 200000 )) && warn "Warning: Big text files will pollute the context.\n"
	}

	local jq_script='
		(if $kind == "text" then . else gsub("\n"; "") end) as $raw_in |
		(if $kind == "text" then null
		 elif $is_url == "true" then $raw_in
		 else "data:\($mime);base64,\($raw_in)" end) as $data_url |
		(
			if $kind == "pdf" then {type: "file", file: {filename: $name, file_data: $data_url}}
			elif $kind == "audio" then {type: "input_audio", input_audio: {data: $raw_in, format: $fmt}}
			elif $kind == "text" then {type: "text", text: $raw_in}
			else {type: "image_url", image_url: {url: $data_url}}
			end
		) as $part |
		{role: $role, content: (
			(if $text == "" then [] else [{type: "text", text: $text}] end) + [$part]
		)}
	'

	local raw
	raw="$("${feed[@]}" 2>/dev/null | jq -bcRs --arg role "$role" --arg text "$text" --arg kind "$kind" \
			--arg name "${src##*/}" --arg fmt "$fmt" --arg mime "$mime" --arg is_url "$is_url" "$jq_script")" || return 1
	[[ -z $raw ]] && { err "Failed to build message for: $src\n"; return 1; }

	_session_json="${_session_json%"]"},$raw]"
}

thread_add_msg_after_system() { # $1:_session_json, $2:role, $3:content
	local -n _session_json=$1
	_session_json="$(
		jq -bc --arg role "$2" --arg content "$3" '.[0:1] + [{role: $role, content: $content}] + .[1:]' <<< "$_session_json")"
}

_thread_rs_frag() { # $1:out(ref) $2:items_json
	local -n _rsf_out=$1
	local items=${2:-} _a=${MA_ENDPOINT_OBJ["api_type"]} _m=${MA_ENDPOINT_OBJ["model.name"]}
	_rsf_out=''
	[[ -z $items || $items == '[]' ]] && return 0
	_m=${_m//\\/\\\\}; _m=${_m//\"/\\\"}   # JSON-escape the model name
	printf -v _rsf_out ',"x_rs":{"api":"%s","model":"%s","items":%s}' "$_a" "$_m" "$items"
}

thread_add_tool_calls() { # $1:_session_json $2:content $3:tool_calls $4:rstate_items(optional)
	local -n _session_json=$1
	local raw frag
	raw="$(jq -bcn --arg content "$2" --argjson tc "$3" \
		'{role:"assistant", content:(if $content=="" then null else $content end), tool_calls:$tc}')" || return 1
	_thread_rs_frag frag "${4:-}"
	_session_json="${_session_json%"]"},${raw%\}}${frag}}]"
}

thread_add_tool_result() { # $1:_session_json $2:call_id $3:func_name $4:tool_result
	local -n _session_json=$1
	local _provider="${MA_ENDPOINT_OBJ[provider]}" _msg_json
	_msg_json="$(printf '%s' "$4" | jq -bcRs --arg cid "$2" --arg tn "$3" --arg provider "$_provider" '
		if $provider == "google"
		then {role:"tool", tool_call_id:$cid, content:.}
		else {role:"tool", tool_call_id:$cid, name:$tn, content:.}
		end')" || { warn "Cannot add tool result in session messages\n"; return 1; }
	_session_json="${_session_json%]},${_msg_json}]"
}

thread_init() { # $1:_session_json(ref) $2:_system_prompt
	local -n _session_json=$1
	local system_prompt=$2 _sp_escaped
	_sp_escaped="$(printf '%s' "$system_prompt" | jq -bRs .)"
	if [[ -n "$_sp_escaped" ]]; then
		_session_json="[{\"role\":\"system\",\"content\":${_sp_escaped}}]"
	else
		_session_json="[{\"role\":\"system\",\"content\":""}]"
	fi
}

_thinking_effort_resolve() { # $1:out_label(ref) $2:out_pct(ref) $3:thinking_effort(label or 0-100)
	local -n _er_label=$1 _er_pct=$2
	local raw=${3:-medium}
	if [[ $raw =~ ^[0-9]+$ ]]; then
		raw=$((10#$raw)); (( raw > 100 )) && raw=100
		_er_pct=$raw
		if   (( raw == 0 ));  then _er_label=off
		elif (( raw <= 37 )); then _er_label=low
		elif (( raw <= 62 )); then _er_label=medium
		elif (( raw <= 82 )); then _er_label=high
		elif (( raw <= 95 )); then _er_label=xhigh
		else                       _er_label=max
		fi
		return 0
	fi
	case $raw in
		off|none)  _er_label=off;     _er_pct=0 ;;
		minimal)   _er_label=minimal; _er_pct=5 ;;
		low)       _er_label=low;     _er_pct=25 ;;
		high)      _er_label=high;    _er_pct=75 ;;
		xhigh)     _er_label=xhigh;   _er_pct=90 ;;
		max)       _er_label=max;     _er_pct=100 ;;
		*)         _er_label=medium;  _er_pct=50 ;;
	esac
}

_get_budget_from_pct() { # $1:out(ref) $2:pct
	local -n _bp_out=$1
	local p=$2 i
	local -a xs=(0 25 50 75 90 100)
	local -a ys=(
		1024 
		"${MARKOV_THINKING_BUDGET[low]:-2048}"
	   	"${MARKOV_THINKING_BUDGET[medium]:-8192}"
	    "${MARKOV_THINKING_BUDGET[high]:-16384}"
	   	"${MARKOV_THINKING_BUDGET[xhigh]:-32768}"
	   	"${MARKOV_THINKING_BUDGET[max]:-65536}"
	)
	for (( i=1; i<${#xs[@]}; i++ )); do
		if (( p <= xs[i] )); then
			_bp_out=$(( ys[i-1] + (p - xs[i-1]) * (ys[i] - ys[i-1]) / (xs[i] - xs[i-1]) ))
			return 0
		fi
	done
	_bp_out=${ys[-1]}
}

_api_request_body() {
	local -n _session_json=$1
	local -n _api_body_out=$2

	local -n api_type="MA_ENDPOINT_OBJ['api_type']"
	local -n provider="MA_ENDPOINT_OBJ['provider']"
	local -n model_name="MA_ENDPOINT_OBJ['model.name']"

	local -n tools_json="MA_THREAD_OBJ['tools_json']"
	local -n thinking_effort="MA_THREAD_OBJ['thinking']"

	local -n llm_opts="MA_THREAD_OBJ['llm_opts']"
	local max_tokens="${MA_THREAD_OBJ[max_tokens]}"
	local streaming="${MA_THREAD_OBJ[stream]}"
	local use_tools="${MA_THREAD_OBJ[use_tools]}"

	local thinking_enabled=true
	[[ $thinking_effort == off ]] && thinking_enabled=false

	local thinking_mode=''
	local tools_field=''
	local system_msg=''

	#[[ ${_MA_COMPACTING:-} == true ]] && streaming=false

	local _llm_opts_inline=''
	local _llm_effort_opt=''
	if [[ -n "${llm_opts:-}" ]]; then
		local _kv _key _val
		for _kv in $llm_opts; do
			_key=${_kv%%=*}
			_val=${_kv#*=}
			[[ -z "$_key" ]] && continue
			case "$_key" in
				max_tokens)
					[[ -n "$_val" ]] && max_tokens="$_val" ;;
				effort|reasoning_effort)
					_llm_effort_opt="$_val" ;;
				temperature|top_p|top_k)
					[[ "$api_type" = "anthropic" ]] && {
						case "$model_name" in
							claude-opus-4-7*|claude-opus-4-8*|claude-fable-5*) continue ;;
						esac
					}
					[[ -n "$_llm_opts_inline" ]] && _llm_opts_inline+=,
					_llm_opts_inline+="\"$_key\":$_val"
					;;
				*)
					[[ -n "$_llm_opts_inline" ]] && _llm_opts_inline+=,
					_llm_opts_inline+="\"$_key\":$_val"
					;;
			esac
		done
	fi

	local _eff_label _eff_pct
	_thinking_effort_resolve _eff_label _eff_pct "${_llm_effort_opt:-${thinking_effort:-medium}}"
	[[ $_eff_label == off ]] && thinking_enabled=false

	case "$api_type" in
		openai_chat)
			if [[ "$thinking_enabled" = false ]]; then
				thinking_mode='"reasoning_effort":"none"'
			else
				local _effort=$_eff_label
				case $_effort in
					off)       _effort=none ;;
					xhigh|max) _effort=high ;;
				esac
				printf -v thinking_mode '"reasoning_effort":"%s"' "$_effort"
			fi

			[[ -z "$provider" && ${MA_DISABLE_KWARGS:-} != "true" ]] && {
				if [[ "$thinking_enabled" = false ]]; then
					thinking_mode+=',"chat_template_kwargs":{"enable_thinking":false}'
				elif [[ "$thinking_enabled" = true ]]; then
					thinking_mode+=',"chat_template_kwargs":{"preserve_thinking":true}'
				fi
			}

			[[ "${use_tools:-}" != false ]] && tools_field="\"tools\":${tools_json}"

			# some backends may reject unknown fields
			local _msgs=$_session_json
			[[ $_msgs == *'"x_rs"'* ]] && _msgs="$(jq -c 'map(del(.x_rs))' <<< "$_msgs")"

			local -a fields=(
				"\"model\":\"${model_name}\""
				"\"messages\":${_msgs}"
				"\"max_completion_tokens\":${max_tokens}"
				"\"stream\":${streaming}"
				"\"stream_options\":{\"include_usage\":true}"
			)

			[[ -n "$tools_field" ]] && fields+=("${tools_field}")
			[[ -n "$_llm_opts_inline" ]] && fields+=("${_llm_opts_inline}")
			[[ -n "$thinking_mode" ]] && fields+=("${thinking_mode}")

			local IFS=,
			printf -v _api_body_out '{%s}' "${fields[*]}"
			;;

		openai_resp)
			local _jq_out
			_jq_out="$(jq -c --arg model "$model_name" '
			  def native($api): if (.x_rs.api == $api and .x_rs.model == $model) then .x_rs.items else [] end;
			  def strip_think: sub("^\\s*<think>[\\s\\S]*?</think>\\s*"; "");

			  (map(select(.role == "system")) | .[0]?.content) as $sys
			  | [ .[] | select(.role != "system") |
				  if .role == "user" then
					{ type:"message", role:"user",
					  content: (.content
						| if type == "array" then
							map(
							  if .type == "image_url" then
								{type:"input_image", image_url:.image_url.url}
							  elif .type == "file" then
								(.file.file_data) as $u
								| if ($u | startswith("data:"))
								  then {type:"input_file", filename:.file.filename, file_data:$u}
								  else {type:"input_file", file_url:$u} end
							  elif .type == "input_audio" then
							    {type:"input_text", text:"[audio attachment omitted]"}
							  else {type:"input_text", text:.text} end
							)
						  else [{type:"input_text", text:.}] end) }
				  elif .role == "assistant" then
					native("openai_resp") as $rs
					| ( $rs[],
						( (.content | if ($rs|length) > 0 and type == "string" then strip_think else . end) as $t
						  | if ($t // "") != "" then {type:"message", role:"assistant", content:[{type:"output_text", text:$t}]} else empty end ),
						( (.tool_calls // [])[] | {type:"function_call", call_id:.id, name:.function.name, arguments:.function.arguments} ) )
				  elif .role == "tool" then
					{ type:"function_call_output", call_id:.tool_call_id, output:.content }
				  else empty end
				],
				($sys // null)
			' <<< "$_session_json" 2>/dev/null)"

			local -a _jq_lines=()
			mapfile -t _jq_lines <<< "$_jq_out"
			local input_json=''
			input_json="${_jq_lines[0]:-}"
			system_msg="${_jq_lines[1]:-}"

			[[ -z "$input_json" ]] && input_json='[]'
			[[ "$system_msg" = "null" ]] && system_msg=''

			if [[ "$thinking_enabled" = false ]]; then
				thinking_mode='"reasoning":{"effort":"none"}'
			else
				local _effort=$_eff_label
				case $_effort in
					off)       _effort=none ;;
					xhigh|max) _effort=high ;;
				esac
				printf -v thinking_mode '"reasoning":{"effort":"%s","summary":"auto"}' "$_effort"
			fi

			[[ -z "$provider" && ${MA_DISABLE_KWARGS:-} != "true" ]] && {
				if [[ "$thinking_enabled" = false ]]; then
					thinking_mode+=',"chat_template_kwargs":{"enable_thinking":false}'
				elif [[ "$thinking_enabled" = true ]]; then
					thinking_mode+=',"chat_template_kwargs":{"preserve_thinking":true}'
				fi
			}

			[[ "$use_tools" != false ]] && tools_field="\"tools\":${tools_json}"

			local -a fields=(
				"\"model\":\"${model_name}\""
				"\"input\":${input_json}"
				"\"max_output_tokens\":${max_tokens}"
				"\"stream\":${streaming}"
			)

			[[ -n "$system_msg" ]] && fields+=("\"instructions\":${system_msg}")
			[[ -n "$tools_field" ]] && fields+=("${tools_field}")
			[[ -n "$_llm_opts_inline" ]] && fields+=("${_llm_opts_inline}")
			[[ -n "$thinking_mode" ]] && fields+=("${thinking_mode}")

			if [[ $provider == openai ]]; then
				fields+=('"store":false')
				[[ $thinking_enabled == true ]] && fields+=('"include":["reasoning.encrypted_content"]')
			fi

			local IFS=,
			printf -v _api_body_out '{%s}' "${fields[*]}"
			;;

		anthropic)
			local _jq_out effort_field='' messages_json=''
			_jq_out="$(jq -c --arg model "$model_name" '
			  def native($api): if (.x_rs.api == $api and .x_rs.model == $model) then .x_rs.items else [] end;
			  def strip_think: sub("^\\s*<think>[\\s\\S]*?</think>\\s*"; "");
			  def blocks:
				if type == "string" then (if . == "" then [] else [{type:"text", text:.}] end)
				elif type == "array" then
				  map(
					if .type == "image_url" then
					  (.image_url.url) as $u
					  | if ($u | startswith("data:")) then
						  ($u | capture("^data:(?<mime>[^;]+);base64,(?<data>.*)$")) as $d
						  | {type:"image", source:{type:"base64", media_type:$d.mime, data:$d.data}}
						else {type:"image", source:{type:"url", url:$u}} end
					elif .type == "file" then
					  (.file.file_data) as $u
					  | if ($u | startswith("data:")) then
						  ($u | capture("^data:(?<mime>[^;]+);base64,(?<data>.*)$")) as $d
						  | {type:"document", source:{type:"base64", media_type:$d.mime, data:$d.data}}
						else {type:"document", source:{type:"url", url:$u}} end
					elif .type == "input_audio" then
					  {type:"text", text:"[audio attachment omitted]"}
					else . end
				  )
				else (. // []) end;
			  def safe_id: (. // "") | gsub("[^a-zA-Z0-9_-]"; "_");

			  (map(select(.role == "system")) | .[0]?.content) as $sys
			  | (
				  [ .[] | select(.role != "system")
					| if .role == "assistant" then
						native("anthropic") as $rs
						| { role: "assistant",
							content: ( $rs
							  + ((.content | if ($rs|length) > 0 and type == "string" then strip_think else . end) | blocks)
							  + [ (.tool_calls // [])[]
								  | { type: "tool_use", id: (.id | safe_id), name: .function.name,
									  input: ((.function.arguments // "")
											  | if . == "" then {} else (try fromjson catch {}) end) } ] ) }
					  elif .role == "tool" then
						{ role: "user",
						  content: [{ type: "tool_result", tool_use_id: (.tool_call_id | safe_id),
									  content: (.content | tostring) }] }
					  else
						{ role: .role, content: (.content | blocks) }
					  end
				  ]
				  | map(select(.content | length > 0))
				  | reduce .[] as $m ([];
					  if length > 0 and .[-1].role == $m.role
					  then .[-1].content += $m.content
					  else . + [$m] end)
				) as $msgs
			  | $msgs,
				(if $sys == "" then null else $sys end),
				( ($msgs[-1].content | type == "array")
				  and ($msgs[-1].content | any(.type == "tool_result"))
				  and ((($msgs[-2].content[0].type // "") | IN("thinking","redacted_thinking")) | not) )
			' <<< "$_session_json" 2>/dev/null)"

			local -a _jq_lines=()
			mapfile -t _jq_lines <<< "$_jq_out"
			messages_json="${_jq_lines[0]:-}"
			system_msg="${_jq_lines[1]:-}"

			[[ -z "$messages_json" ]] && messages_json='[]'
			[[ "$system_msg" = "null" ]] && system_msg=''

			# tool loop without a replayable signed thinking block: disable thinking for this request
			[[ "${_jq_lines[2]:-}" == true ]] && thinking_enabled=false

			if [[ "$thinking_enabled" = true ]]; then
				local _budget _effort=$_eff_label
				_get_budget_from_pct _budget "$_eff_pct"
				(( _budget > max_tokens - 4096 )) && _budget=$(( max_tokens - 4096 ))
				[[ $_effort == minimal ]] && _effort=low

				case "$model_name" in
					claude-opus-4-7*|claude-opus-4-8*|claude-fable-5*)
						printf -v thinking_mode '"thinking":{"type":"adaptive","display":"summarized"}'
						printf -v effort_field '"output_config":{"effort":"%s"}' "$_effort"
						;;
					*)
						(( _budget >= 1024 )) && \
							printf -v thinking_mode '"thinking":{"type":"enabled","budget_tokens":%s,"display":"summarized"}' "$_budget"
						;;
				esac
			fi

			[[ "$use_tools" != false ]] && tools_field="\"tools\":${tools_json}"

			local cache='"cache_control":{"type":"ephemeral"}'
			[[ ${MA_ANTHROPIC_LONG_TTL:-} == true ]] && { cache='"cache_control":{"type":"ephemeral","ttl":"1h"}'; }

			local -a fields=(
				"\"model\":\"${model_name}\""
				"\"messages\":${messages_json}"
				"\"max_tokens\":${max_tokens}"
				"\"stream\":${streaming}"
			)

			[[ -n "$effort_field" ]] && fields+=("${effort_field}")
			[[ -n "$thinking_mode" ]] && fields+=("${thinking_mode}")
			[[ -n "$_llm_opts_inline" ]] && fields+=("${_llm_opts_inline}")
			[[ -n "$cache" ]] && fields+=("${cache}")
			[[ -n "$system_msg" ]] && fields+=("\"system\":${system_msg}")
			[[ -n "$tools_field" ]] && fields+=("${tools_field}")

			local IFS=,
			printf -v _api_body_out '{%s}' "${fields[*]}"
			;;
	esac
}

ma_toolcall_output() { # 1:fn_name 2:body 3:footer_extra 4:color 5:force(0|1)
	local fn=$1 body=$2 extra=$3 color=$4 force=${5:-0}
	local show=1 seps=1

	[[ ${MA_TOOL_DISPLAY_OUTPUT[$fn]:-}     == false ]] && show=0
	[[ ${MA_TOOL_DISPLAY_SEPARATORS[$fn]:-} == false ]] && seps=0
	(( force )) && show=1

	if (( show )) && [[ -n $body ]]; then
		(( seps )) && _draw_separator right ─ "${A_TOOL_SEP}"
		printf '%s%s%s\n' "${A_TOOL_BODY}" "$body" "${A_R}"
		(( seps )) && _draw_separator right ─ "${A_TOOL_SEP}" "${extra:+$extra }[$fn]" "$color"
	fi
	printf '\n' >&2
}

ma_toolcall_resolve_real() { # 1:fn_name(ref) 2:fn_args(ref)
	local -n out_fn_name=$1 out_fn_args=$2
	[[ $out_fn_name == 'execute' && -v 'MA_ROLE_TOOLS[execute]' ]] && {
		local real_fname='' real_args=''
		{ 
			IFS= read -r -d '' real_fname;
			IFS= read -r -d '' real_args; 
		} < <(jq -jb '
				(.function // ""), "\u0000",
				(if (.params | type) == "string"
					then (.params // "" | if length then . else "{}" end)
					else (.params // {} | tostring)
				end), "\u0000"
				' <<< "$out_fn_args" 2>/dev/null) && {
					out_fn_name=${real_fname:-$out_fn_name}
					out_fn_args=${real_args:-$out_fn_args}
				}
	}


}

thread_reprint() {
	local -n _session_json=${1}
	local _from=${2:-0}
	[[ ${MA_ONE_SHOT_MODE:-} == true ]] && return

	local count
	count="$(jq -b 'length // 0' <<< "$_session_json" 2>/dev/null)"
	if [[ "$count" -le 1 ]]; then return; fi

	MA_TOOL_IS_REPRINTING=true
	_MA_USE_SHORT_COLUMNS=0
	ma_term_update
	local -A _ma_call_args=() _ma_call_name=()

	while IFS=$'\x1e' read -r -d $'\x1f' role content tool_calls tool_name call_id; do

		case "$role" in
			user)
				printf "${A_R}\n" >&2
				if [[ ${MA_REPL_STYLE:-} != separator ]]; then
					_draw_user_message content >&2
				else
					_prompt_draw_header
					printf '%s\n' "$content" >&2
					_draw_separator_after_prompt
				fi
				printf "${A_R}" >&2
				;;
			assistant)
				if [[ -n "$content" ]]; then
					local processed="$content"
					if [[ "$processed" == *"<think>"* ]]; then
						if [[ ${MA_HIDE_THINKING:-} == true ]]; then
							if (( _HAS_PERL )); then
								processed="${A_RESP}$(perl -0777 -pe 's/<think>.*?<\/think>//gs; s/\n{3,}/\n/g' <<< "$content")${A_R}"
							else
								local start end left right
								start="<think>"
								end="</think>"
								left=${processed%%"$start"*}
								right=${processed#*"$end"}
								processed="${A_THINK}$left${A_RESP}$right"
							fi
						elif [[ "$processed" == *"<think>"*"</think>"* ]]; then
							local _rest="${processed#*<think>}"
							local _reasoning="${_rest%%</think>*}"
							local _after="${_rest#*</think>}"
							_after="${_after#$'\n'}"
							_reasoning="${_reasoning%$'\n'}"
							processed="${A_THINK}${_reasoning}"$'\n\n'"${A_RESP}${_after}${A_RESP}"
						else
							processed="${processed//<think>/"${A_THINK}"}"
						fi
						printf "${A_R}%s\n" "$processed" >&2
					else
						printf "${A_R}%s\n" "${A_RESP}$processed${A_R}" >&2
					fi
				fi

				if [[ -n "$tool_calls" ]]; then
					while IFS=$'\x02' read -r cid fname farg; do
						[[ -z "$cid" ]] && continue
						_ma_call_args["$cid"]="$farg"
						_ma_call_name["$cid"]="$fname"
					done <<< "$tool_calls"
				fi
				;;
			tool)
				_MA_USE_SHORT_COLUMNS=1
				(( _MA_SHOULD_PRINT )) && {

					local fn_name="${tool_name:-${_ma_call_name[$call_id]:-}}"
					local fn_args="${_ma_call_args[$call_id]:-}"

					ma_toolcall_resolve_real fn_name fn_args

					ma_toolcall_header "$fn_name" "$fn_args" >&2

					local last_line='' exit_color="${A_INFO}"
					if [[ $fn_name == bash ]]; then
						content="${content#Result:$'\n'}"
						last_line="${content##*$'\n'}"
						content="${content%$'\n'*}"
						[[ $last_line == *"exit code"* ]] && exit_color="${A_TOOL_FAIL}"
					fi
					local _force=0; [[ ${MA_TOOL_DISPLAY_REPRINT[$fn_name]:-} == true ]] && _force=1
					ma_toolcall_output "$fn_name" "$content" "$last_line" "$exit_color" "$_force"

				}
				_MA_USE_SHORT_COLUMNS=0

				;;
		esac
	done < <(
		jq -jrb --argjson from "$_from" '
			def esc_nl: gsub("\n"; " ");
			[.[] | select(.role != "system")] | .[$from:][]
			| [ .role,
				(.content // "" | if type == "string" then .
					elif type == "array" then
						([.[] | if .type == "text" then .text
							elif .type == "image_url" then "[image]"
							elif .type == "file" then "[" + (.file.filename // "file") + "]"
							elif .type == "input_audio" then "[audio]"
							else empty end] | join(" "))
					else tojson end),
				((.tool_calls // [])
				  | map(.id + "\u0002" + .function.name + "\u0002"
						+ ((.function.arguments // "{}") | if type == "string" then . else tojson end | esc_nl))
				  | join("\n")),
				(.name // ""),
				(.tool_call_id // "") ]
			| join("\u001e") + "\u001f"
		' <<< "$_session_json" 2>/dev/null
	)

	unset MA_TOOL_IS_REPRINTING

	printf '\n' >&2
}

doc_init() { 
	MA_DOC_VERSION=$MA_VERSION
	MA_CTX_USAGE=([main]=0)
	MA_THREADS=([main]=)
	MA_USER_THREADS=([main]=)
	MA_MODEL_USAGE=()
	MA_THREAD_NAME=main
	MA_ROLE_NAME=main
	MA_TOOLS_CALLS=()
	MA_TOOLS_FAILURES=()

	MA_DELEGATED=()
	MA_EVALUATED=()

	unset -v "${!MA_THREAD_OBJ_@}" "${!MA_DELEGATED_QUEUE_@}" "${!MA_SUBMITTED_@}"

	MA_APPROVED_CALLS=()
	MA_DISALLOW_CALLS=()

	MA_DOC_JSON='{"metadata":{},"current_thread":"main","threads":{}}'; 
	MA_THREAD_NAME=""
	doc_thread_switch "main" true main 0
}

declare -gA _META_TYPE=()
declare -gA _META_VAL=()
declare -gA _META_CACHE_TYPE=()
declare -gA _META_CACHE=()

# $1:key $2:ref
meta_set()		{ local -n _in=$2; _META_TYPE[$1]=str;  _META_VAL[$1]=$_in; }
meta_set_num()  { local -n _in=$2; _META_TYPE[$1]=num;  _META_VAL[$1]=${_in:-0}; }
meta_set_bool() { local -n _in=$2; _META_TYPE[$1]=bool; _META_VAL[$1]=$_in; }
meta_set_json() { local -n _in=$2; _META_TYPE[$1]=json; _META_VAL[$1]=${_in:-"{}"}; }

meta_del() { _META_TYPE[$1]=del; _META_VAL[$1]=; }
meta_set_array() {
	local -n _dmsa_arr=$2
	local -r _RS2=$'\x02'
	local e joined=
	for e in "${_dmsa_arr[@]}"; do joined+="${e}${_RS2}"; done
	if [[ -z $joined ]]; then meta_del "$1"; return 0; fi
	_META_TYPE[$1]=arr; _META_VAL[$1]="$joined"
}
meta_set_assoc() {
	local -n _dmsa_map=$2
	local -r _RS2=$'\x02' _FS2=$'\x03'
	local k joined=
	for k in "${!_dmsa_map[@]}"; do joined+="${k}${_FS2}${_dmsa_map[$k]}${_RS2}"; done
	if [[ -z $joined ]]; then meta_del "$1"; return 0; fi
	_META_TYPE[$1]=assoc; _META_VAL[$1]="$joined"
}

meta_flush() { # $1:_doc
	local -n _dmf_doc=${1:-MA_DOC_JSON}
	(( ${#_META_TYPE[@]} == 0 )) && return 0
	[[ -v _META_FLUSH_FILTER ]] || {
		IFS= read -r -d '' _META_FLUSH_FILTER <<'EOF'
			def conv(t; v; cur):
				if   t == "num"  then (v | tonumber)
				elif t == "bool" then (v == "true")
				elif t == "json" then (v | fromjson)
				elif t == "arr"  then (if v == "" then [] else (v | rtrimstr("\u0002") | split("\u0002")) end)
				elif t == "assoc" then
					(if v == "" then {} else
						(v | rtrimstr("\u0002") | split("\u0002")
						   | map(split("\u0003") | {(.[0]): .[1]})
						   | add // {})
					 end)
				else v end;
			( $patch | rtrimstr("\u001f") | split("\u001f") ) as $p
			| reduce range(0; ($p | length); 3) as $i (
				.;
				if $p[$i] == "del"
				then del(.metadata[$p[$i+1]])
				else .metadata[$p[$i+1]] = conv($p[$i]; $p[$i+2]; .metadata[$p[$i+1]])
				end
			)
EOF
	}
	local _doc_change k _stream= _raw_bytes _jq_rc _patch_file=
	local -r _US=$'\x1f'
	for k in "${!_META_TYPE[@]}"; do
		_stream+="${_META_TYPE[$k]}${_US}${k}${_US}${_META_VAL[$k]}${_US}"
	done
	local LC_ALL=C; 
	_raw_bytes=${#_stream};
	if (( _raw_bytes < ${MA_ARG_MAX_BYTES:-25000} )); then # MinGW ARG limit seems to be very LOW, 32KB
		_doc_change="$(jq -bc --arg patch "$_stream" "$_META_FLUSH_FILTER" <<< "$_dmf_doc" 2>/dev/null)"
		_jq_rc=$?
	else
		_patch_file="$(mktemp)" || { err "meta_flush: mktemp failed\n"; return 1; }
		printf '%s' "$_stream" > "$_patch_file"
		_doc_change="$(jq -bc --rawfile patch "$_patch_file" "$_META_FLUSH_FILTER" <<< "$_dmf_doc" 2>/dev/null)"
		_jq_rc=$?
		rm -f "$_patch_file"
	fi
	_META_TYPE=()
	_META_VAL=()
	if (( _jq_rc != 0 )) || [[ -z "$_doc_change" ]]; then
		err "meta_flush: jq patch failed, metadata left unchanged\n"
		return 1
	fi
	_dmf_doc=$_doc_change
}

meta_load() {
	local -n _dml_doc=${1:-MA_DOC_JSON}
	local raw rec key rest type val
	_META_CACHE=()
	_META_CACHE_TYPE=()
	raw="$( jq -bj '
			.metadata | to_entries[]
			| .key + "\u001f"
			  + (.value|type) + "\u001f"
			  + (if (.value|type) == "string" then .value else (.value|tojson) end)
			  + "\u001e"
		' <<< "$_dml_doc" 2>/dev/null
	)" || { ma_spinner_stop; err "meta_load: jq failed, cache left empty\n"; return 1; }
	[[ -z "$raw" ]] && return 0
	while IFS= read -r -d $'\x1e' rec; do
		key="${rec%%$'\x1f'*}"
		rest="${rec#*$'\x1f'}"
		type="${rest%%$'\x1f'*}"
		val="${rest#*$'\x1f'}"
		_META_CACHE[$key]="$val"
		_META_CACHE_TYPE[$key]="$type"
	done <<< "$raw"
}

# $1:key $2:_outvar
meta_get() { local -n _dmgi_out=$2; _dmgi_out="${_META_CACHE[$1]:-}"; }
meta_get_num() { local -n _dmgi_out=$2; _dmgi_out="${_META_CACHE[$1]:-}"; }
meta_get_bool() { local -n _dmgi_out=$2; _dmgi_out="${_META_CACHE[$1]:-}"; }
meta_get_json() { local -n _dmgi_out=$2; _dmgi_out="${_META_CACHE[$1]:-}"; }
meta_get_array() { # $1:key $2:_outarray
	local -n _dmgai_out=$2
	_dmgai_out=()
	local raw="${_META_CACHE[$1]:-}"
	[[ -z "$raw" || "$raw" == "null" ]] && return 0
	mapfile -t _dmgai_out < <(jq -br '.[]' <<< "$raw" 2>/dev/null)
}
meta_get_assoc() { # $1:key $2:_outassoc
	local -n _dmga_out=$2
	_dmga_out=()
	local raw="${_META_CACHE[$1]:-}"
	[[ -z "$raw" || "$raw" == "null" ]] && return 0
	local line k v
	while IFS=$'\t' read -r k v; do
		_dmga_out[$k]="$v"
	done < <(jq -br 'to_entries[] | [.key, .value] | @tsv' <<< "$raw" 2>/dev/null)
}

meta_sync() { # 1:set/get
	[[ $1 == set || $1 == get ]] || { ma_spinner_stop; err "meta_sync: invalid param (expected set|get).\n"; return 1; }

	[[ $1 == get ]] && meta_load

	meta_${1}		version				MA_DOC_VERSION
	meta_${1}		working-dir			MA_PROJECT_DIR

	meta_${1}_assoc threads				MA_THREADS
	meta_${1}_assoc user_threads		MA_USER_THREADS

	meta_${1}_assoc model_usage			MA_MODEL_USAGE
	meta_${1}		model_usage_last	MA_MODEL_USAGE_LAST

	meta_${1}_assoc ctx_usage			MA_CTX_USAGE
	meta_${1}_assoc tools_calls			MA_TOOLS_CALLS
	meta_${1}_assoc tools_failures		MA_TOOLS_FAILURES

	meta_${1}_assoc delegated			MA_DELEGATED
	meta_${1}_assoc evaluated			MA_EVALUATED

	local t
	for t in "${!MA_THREADS[@]}"; do
		declare -gA "MA_DELEGATED_QUEUE_$t"
		local -n _delegated_queue="MA_DELEGATED_QUEUE_$t"
		meta_${1}_assoc "delegated_queue_$t" _delegated_queue

		declare -gA "MA_SUBMITTED_$t"
		local -n _submitted="MA_SUBMITTED_$t"
		meta_${1}_assoc "submitted_$t" _submitted
	done

	[[ ${MA_REMEMBER_CALLS:-} != false ]] &&  { 
		meta_${1}_assoc approved_calls MA_APPROVED_CALLS; 
		meta_${1}_assoc disallow_calls MA_DISALLOW_CALLS; 
	}

	[[ ${MA_STORE_HISTORY:-} == true ]] &&			{ meta_${1}_array history MA_PROMPT_HISTORY_MAIN; }

	[[ $1 == set ]] && meta_flush
}

meta_threads_pack() { # $1:name $2:role $3:parent $4:child
	local _sep="|"; MA_THREADS["$1"]="${2:-main}${_sep}${3:-}${_sep}${4:-}"; 
}

meta_threads_unpack() {  # $1:name $2:role(ref) $3:parent(ref) $4:child(ref)
	local -n _a=$2 _b=$3 _c=$4; IFS="|" read -r _a _b _c <<< "${MA_THREADS["$1"]:-}"; 
}

meta_thread_get_subest() { # $1:out_name(ref) $2:thread_name
	local -n _subest_out=$1
	local thread_name="${2:-$MA_THREAD_NAME}"
	local th_role th_parent th_child
	while :; do
		meta_threads_unpack "$thread_name" th_role th_parent th_child
		[[ -z "$th_child" ]] && break
		thread_name=$th_child
	done
	_subest_out="$thread_name"
}

meta_thread_get_uppest() {  # $1:out_name(ref) $2:thread_name 3$:parent_count_out(ref)
	local -n _uppest_out=$1
	local thread_name="${2:-$MA_THREAD_NAME}"
	local -n _parent_count_out=$3
	local th_role th_parent th_child
	local count=0
	while :; do
		meta_threads_unpack "$thread_name" th_role th_parent th_child
		[[ -z "$th_parent" ]] && break
		(( ++count ))
		thread_name=$th_parent
	done
	_uppest_out="$thread_name"
	_parent_count_out=$count
}

doc_thread_sync() {
    local -n _dpa_msgs=$1
    local thread_name=$2
    [[ -z "$MA_DOC_JSON" || -z "$_dpa_msgs" ]] && { ma_spinner_stop; err "doc_thread_sync: empty doc or messages for thread_name '$thread_name'\n"; return 1; }
    local -n _dpa_skills="MA_ACTIVE_SKILLS_${thread_name}"
    MA_DOC_JSON="$(
        printf '%s\n%s' "$MA_DOC_JSON" "$_dpa_msgs" | jq -bcs --arg a "$thread_name" --arg sk "${!_dpa_skills[*]}" '
            .[0] as $doc | .[1] as $msgs |
            $doc
            | .threads[$a].messages = $msgs
            | .threads[$a].active_skills = (($sk | split(" ") | map(select(length>0)) | map({(.):1}) | add) // {})
        '
    )"
}

_doc_threads_update_on_reload() {
    local thread_name pairs=()

	local not_found=0
    for thread_name in "${!MA_THREADS[@]}"; do
		declare -gA "MA_THREAD_OBJ_$thread_name"
		local -n thread_obj="MA_THREAD_OBJ_$thread_name"
		local pcount=0 uppset_name role=main p c
		if [[ -v 'thread_obj[parents_count]' ]]; then
			if ! thread_obj_set "$thread_name"  "${thread_obj[role]:-}" ${thread_obj[parents_count]:-0}; then not_found=1; fi
		else
			meta_thread_get_uppest uppset_name "$thread_name" pcount
			meta_threads_unpack "$thread_name" role p c
			if ! thread_obj_set "$thread_name"  "$role" $pcount; then not_found=1; fi
		fi
        pairs+=("$thread_name" "${thread_obj[system_prompt]:-}")
    done

	[[ ${MA_ONE_SHOT_MODE:-} != true ]] && (( not_found )) && { ma_spinner_stop; ma_press_enter_to_continue; }

    MA_DOC_JSON="$(jq -bc '
        ($ARGS.positional) as $flat
        | (reduce range(0; ($flat|length); 2) as $i
            ({}; .[$flat[$i]] = $flat[$i+1])
          ) as $prompts
        | .threads |= with_entries(
            if $prompts[.key] and (.value.messages[0] != null)
            then .value.messages[0].content = $prompts[.key]
            else . end
        )
    ' --args "${pairs[@]}" <<< "$MA_DOC_JSON")"

	local -n thread_obj="MA_THREAD_OBJ_${MA_THREAD_NAME:-main}"

	MA_THREAD_JSON="$(jq -bc --arg sp "${thread_obj[system_prompt]}" '
		if (.[0] != null) then .[0].content = $sp else . end
	' <<< "$MA_THREAD_JSON")"

	_thread_switch_global_references "$MA_THREAD_NAME"
}

_doc_thread_adv() {  # $1:reuse(0/1) $2:new_name $3:is_user_thread $4:role $5:parents_count $6:is_task_evaluator
    local _reuse=$1 th_name=$2 is_user_thread=${3:-true} role=${4:-${MA_ROLE_NAME:-main}} parents_count=${5:-0} is_task_evaluator=${6:-}

    local _old="$MA_THREAD_NAME" existing existing_skills

    if [[ -n "$_old" ]]; then
        local -n _old_sk="MA_ACTIVE_SKILLS_$_old"
        mapfile -t _p < <(printf '%s\n%s' "$MA_DOC_JSON" "$MA_THREAD_JSON" | jq -bcs --arg o "$_old" --arg n "$th_name" --arg osk "${!_old_sk[*]}" '
            .[0] as $doc | .[1] as $msgs |
            ($doc
                | .threads[$o].messages = $msgs
                | .threads[$o].active_skills = (($osk | split(" ") | map(select(length>0)) | map({(.):1}) | add) // {})
                | .current_thread = $n
            ) as $d
            | $d, ($d.threads[$n].messages // null), ($d.threads[$n].active_skills // null)')
    else
        mapfile -t _p < <(jq -bc --arg n "$th_name" '(.current_thread = $n) as $d | $d, null, null' <<< "$MA_DOC_JSON")
    fi
    MA_DOC_JSON="${_p[0]}"; existing="${_p[1]}"; existing_skills="${_p[2]}"

    declare -gA "MA_ACTIVE_SKILLS_$th_name"
    declare -gn MA_ACTIVE_SKILLS="MA_ACTIVE_SKILLS_$th_name"
    MA_ACTIVE_SKILLS=()
    if [[ "$_reuse" == 1 && "$existing" != "null" && -n "$existing" ]]; then
        MA_THREAD_JSON="$existing"
        if [[ "$existing_skills" != "null" && -n "$existing_skills" ]]; then
            while IFS= read -r _k; do [[ -n "$_k" ]] && MA_ACTIVE_SKILLS["$_k"]=1; done < <(jq -br 'keys[]?' <<< "$existing_skills")
        fi
    else
		thread_obj_set "$th_name" "$role" $parents_count "$is_task_evaluator"
		local -n thread_obj="MA_THREAD_OBJ_$th_name"
        thread_init MA_THREAD_JSON "${thread_obj[system_prompt]:-}"
        MA_CTX_USAGE["$th_name"]=0
		MA_THREADS["$th_name"]=
        [[ ${is_user_thread:-} == true ]] && MA_USER_THREADS["$th_name"]=
        meta_threads_pack "$th_name" "$role"
    fi

	_thread_switch_global_references "$th_name"
}

# 1:name 2:is_user_thread 3:role 4:parents_count 5:is_task_evaluator
doc_thread_switch() { _doc_thread_adv 1 "$@" ; }
doc_thread_fresh()  { _doc_thread_adv 0 "$@" ; }
doc_thread_delete() {  # $1:thread_name
    local _td_name="$1"

	[[ "$_td_name" == "$MA_THREAD_NAME" || "$_td_name" == "main" ]] && { err "\nAttempted removing current thread or main thread.\n\n"; return 1; }

	local th_role th_parent th_child
	meta_threads_unpack $_td_name th_role th_parent th_child

	[[ -n "$th_child" ]] && { err "\nAttempted removing thread with child. Remove child first.\n\n"; return 1; }
	[[ -n $th_parent ]] && {
		local p_role p_parent p_child
		meta_threads_unpack "$th_parent" p_role p_parent p_child
		meta_threads_pack "$th_parent" "$p_role" "$p_parent" ""
	}

    unset "MA_CTX_USAGE["$_td_name"]"
    unset "MA_THREADS["$_td_name"]"
    unset "MA_USER_THREADS["$_td_name"]"
    unset "MA_THREAD_OBJ_$_td_name"
    unset "MA_ACTIVE_SKILLS_$_td_name"

    MA_DOC_JSON="$( jq -bc --arg n "$_td_name" '
        if (.threads | has($n)) then
            del(.threads[$n]) | if .current_thread == $n then .current_thread = null else . end
        else . end
    ' <<< "$MA_DOC_JSON")"
}

doc_save() { # 1:SESSION_JSON(ref) 2:thread_name 3:target_path
	local -n _ds_msgs=$1
	local thread_name="$2"
	local filepath=${3:-}
	[[ -z "$filepath" ]] && return 0

	MA_MODEL_USAGE_LAST="${_MA_LAST_CALL_MODEL_KEY:-}|$_TOKENS_PROMPT|$_TOKENS_COMPLETION|$_TOKENS_CACHE_READ|$_TOKENS_CACHE_WRITE"

	meta_sync set
	doc_thread_sync _ds_msgs "$thread_name" || return 1

	_hook_call session_store
	local tmpsessionfile="${filepath}.$$.tmp"
	[[ -n "${_ma_saving_pid:-}" ]] && wait "$_ma_saving_pid" 2>/dev/null
	{
		if printf '%s' "$MA_DOC_JSON" > "$tmpsessionfile"; then
			mv -f "$tmpsessionfile" "$filepath"
		else
			rm -f "$tmpsessionfile"; false
		fi || err "\n\nFailed to save session to $filepath\n\n"
	} &
	_ma_saving_pid=$!
	return 0
}

doc_load() { # 1:target_file
    [[ -r "$1" ]] || { err "Could not open file: $1\n"; return 1; }
	ma_spinner_start "loading session, please stand by…"
    local parsed
    mapfile -t parsed < <(
        jq -rbc '
            if has("threads") then
                (.current_thread // "main") as $thread_name
                | . as $doc
                | ($doc | .current_thread = $thread_name) as $newdoc
                | $newdoc, $thread_name, ($newdoc.threads[$thread_name].messages // null), ($newdoc.threads[$thread_name].active_skills // null)
            else
                "MALFORMED", "main", null, null
            end
        ' "$1" 2>/dev/null
    )
    if [[ -z ${parsed[0]:-} || "${parsed[0]:-}" == "MALFORMED" ]]; then
		ma_spinner_stop
        err "Cannot load '$1': not a valid session file.\n\n"
        return 1
    else
        MA_DOC_JSON="${parsed[0]}"
        MA_THREAD_NAME="${parsed[1]}"
        MA_THREAD_JSON="${parsed[2]}"

        declare -gA "MA_ACTIVE_SKILLS_$MA_THREAD_NAME"
        declare -gn MA_ACTIVE_SKILLS="MA_ACTIVE_SKILLS_$MA_THREAD_NAME"
        MA_ACTIVE_SKILLS=()
        local _sk_json="${parsed[3]:-null}"
        if [[ "$_sk_json" != "null" && -n "$_sk_json" ]]; then
            local _k
            while IFS= read -r _k; do [[ -n "$_k" ]] && MA_ACTIVE_SKILLS["$_k"]=1; done < <(
				jq -br 'keys[]?' <<< "$_sk_json")
        fi

		MA_DOC_PATH=$(realpath "$1");
		MA_DOC_NAME=$1
		if [[ -n "$MA_SESSIONS_DIR" && "$1" == "$MA_SESSIONS_DIR"* ]]; then
			local display_name=
			display_name="${1#"$MA_SESSIONS_DIR"/}"
			display_name="${display_name%.mrk}"
			MA_DOC_NAME=$display_name
		fi

		meta_sync get
		_doc_threads_update_on_reload

		local f=('' 0 0 0 0)
		[[ -n ${MA_MODEL_USAGE_LAST:-} ]] && { _model_lastcall_unpack f "$MA_MODEL_USAGE_LAST"; }
		_MA_LAST_CALL_MODEL_KEY=${f[0]:-''}
		_TOKENS_PROMPT=${f[1]:-0}; _TOKENS_COMPLETION=${f[2]:-0}; _TOKENS_CACHE_READ=${f[3]:-0}; _TOKENS_CACHE_WRITE=${f[4]:-0}

		[[ -n "${MA_PROJECT_DIR:-}" && "${MA_PROJECT_DIR:-}" != "$MA_WORKING_DIR" ]] && {
			_PROJECT_DIR_MISMATCH=true; 
		}

		if [ -d "$MA_PROJECT_DIR" ] && cd "$MA_PROJECT_DIR"; then MA_WORKING_DIR="$PWD"; else _PROJECT_DIR_NOT_FOUND=$MA_PROJECT_DIR; fi
		MA_PROJECT_DIR=$MA_WORKING_DIR

		local wd="${MA_WORKING_DIR:-$PWD}"
		if [[ "$wd" == /* ]]; then ma_normalize_path "$wd"; else ma_normalize_path "${PWD%/}/$wd"; fi

		ma_spinner_stop
		_hook_call session_load
        return 0
    fi
}

doc_gen_name() {
    local ts dirname abs
    printf -v ts '%(%Y%m%d-%H%M%S)T' -1
    abs=${MA_WORKING_DIR:-$PWD}
    dirname=${abs##*/}
    dirname=${dirname:-root}
	MA_DOC_NAME="${ts}-${BASHPID:-${$}}-${dirname}"
}

doc_file_path_for() { # $1:session_name $2:filename(ref)
	printf -v "$2" '%s/%s.mrk' "$MA_SESSIONS_DIR" "$1"
}

_session_import_check_working_dir() {
	[[ -n ${_PROJECT_DIR_NOT_FOUND:-} ]] && {
		err "Working directory for session '$MA_DOC_NAME' was not found:\n $_PROJECT_DIR_NOT_FOUND.\n"
		info " A user message was inserted automatically to warn the LLM.\n\n"
		unset _PROJECT_DIR_NOT_FOUND
		thread_add_msg MA_THREAD_JSON "user" \
			"[Warning: Session resumed with different working-dir: $MA_WORKING_DIR. Previous working-dir not found]"
	}
	[[ ${_PROJECT_DIR_MISMATCH:-} == true ]] && {
		warn "Working directory is now $MA_PROJECT_DIR.\n\n"
		unset _PROJECT_DIR_MISMATCH
	}

}

_thread_switch_global_references() { # $1: thread_name
	MA_THREAD_NAME=$1
	declare -gn MA_THREAD_OBJ="MA_THREAD_OBJ_$MA_THREAD_NAME"
	declare -gn MA_ENDPOINT_OBJ="MA_ENDPOINT_OBJ_${MA_THREAD_OBJ[endpoint]:-main}"
	MA_ROLE_NAME="${MA_THREAD_OBJ[role]:-main}"
    declare -gn MA_ROLE_TOOLS="MA_ROLE_TOOLS_$MA_ROLE_NAME"
    declare -gn MA_LAZY_TOOLS="MA_ROLE_LAZY_TOOLS_$MA_ROLE_NAME"
    declare -gn MA_ACTIVE_SKILLS="MA_ACTIVE_SKILLS_$MA_THREAD_NAME"

	declare -gA "MA_DELEGATED_QUEUE_$MA_THREAD_NAME"
	declare -gn delegated_calls="MA_DELEGATED_QUEUE_$MA_THREAD_NAME"
	declare -gA "MA_SUBMITTED_$MA_THREAD_NAME"
	declare -gn submitted_results="MA_SUBMITTED_$MA_THREAD_NAME"

}

_boot_init() {
	MA_WORKING_DIR="${MA_WORKING_DIR:-$PWD}"
	[[ "${MA_CONFINE:-}" == "true" ]] && {
		MA_WORKING_DIR="$(realpath "$MA_WORKING_DIR" 2>/dev/null)" || die "Aborting: working-dir is not a valid path.\n";
	}
	MA_USER_AGENT="markov/$MA_VERSION"
	MA_DOC_VERSION=$MA_VERSION
	MA_DOC_JSON=							# session JSON data in memory: {"metadata":{...},"current_thread":"main","threads":{...}}
	MA_DOC_PATH=							# full path for session file (when not ephemeral)
	MA_DOC_NAME=${MA_DOC_NAME:-}			# empty for ephemeral
	MA_THREAD_JSON=${MA_THREAD_JSON:-}		# active thread messages
	MA_THREAD_NAME=main						# active thread name
	MA_MODEL_USAGE_LAST=

	declare -gA MA_MODEL_USAGE=()
	declare -gA MA_THREADS=()
	meta_threads_pack main main
	declare -gA MA_CTX_USAGE=( [main]= )
	declare -gA MA_USER_THREADS=( [main]= )

	declare -gA MA_TOOL
	declare -gA MA_TOOLS_FAILURES=()
	declare -gA MA_TOOLS_CALLS=()
	declare -gA MA_APPROVED_CALLS
	declare -gA MA_DISALLOW_CALLS

	declare -gA MA_DELEGATED=()

	declare -gA MA_EVALUATED

	declare -gA MA_COMMAND_DESCR
	declare -ga MA_LIST_LLM_PARAMS=(
		temperature max_tokens top_p top_k min_p seed
		presence_penalty repetition_penalty frequency_penalty
		reset
	)

	declare -gA MA_ROLE_TOOLS_main=()
	declare -gn MA_ROLE_TOOLS=MA_ROLE_TOOLS_main
	declare -gA MA_ROLE_LAZY_TOOLS_main
	declare -gn MA_LAZY_TOOLS=MA_ROLE_LAZY_TOOLS_main

	declare -ga MA_BASH_ENV_PREFIX
	declare -gA MA_TOOL_DISPLAY_OUTPUT
	declare -gA MA_TOOL_DISPLAY_NAME
	declare -gA MA_TOOL_DISPLAY_SEPARATORS
	declare -gA MA_TOOL_DISPLAY_REPRINT
	declare -gi MA_SESSION_TOOL_CALLS=0
	declare -gir idx_reasoning=0
	declare -gir idx_content=1
	declare -gir idx_tool_calls=2
	declare -gir idx_rstate=3
	declare -gir idx_http_code=4
	declare -gir idx_err_body=5
	_MA_SHOULD_PRINT=0
	[[ "${MA_ONE_SHOT_MODE:-}" != true || "${MA_PRINT_ALL:-}" == true ]] && _MA_SHOULD_PRINT=1

}

ma_bootup() {
	_boot_init

	if command -v setsid >/dev/null; then
		_MA_SETSID=(setsid)
	elif command -v perl >/dev/null; then
		_MA_SETSID=(perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV or die "$!"' --)
	elif command -v python3 >/dev/null; then
		_MA_SETSID=(python3 -c 'import os,sys; os.setsid(); os.execvp(sys.argv[1], sys.argv[1:])')
	else # no group isolation
		_MA_SETSID=(); warn "setsid not found: background processes spawned by the bash tool may not be killed properly.\n"
	fi
	if ! command -v tree-sitter >/dev/null 2>&1 && ! command -v ctags >/dev/null 2>&1; then
		_SYMBOLS_REQUIREMENT_FOUND=false
	fi

	if ! ma_reload; then ma_press_enter_to_continue; fi

	declare -gA MA_ALWAYS_ALLOWED_TOOLCALLS=( 
		[delegate]=1 [submit]=1 [feedback]=1 [search]=1 [docs]=1 [websearch]=1 [ask]=1 [skills]=1
	)

	[[ -z "${MA_DOC_NAME:-}" && ${MA_DOC_EPHEMERAL:-} != true ]] && { doc_gen_name; }

	[[ ${_MA_RESUME_LAST_SESSION:-} == true ]] && {
		local latest="" latest_mtime=-1 entry mtime f
		while IFS= read -r -d '' entry; do
			mtime=${entry%% *}
			f=${entry#* }
			mtime=${mtime%%.*}
			if (( mtime > latest_mtime )); then
				latest_mtime=$mtime
				latest=$f
			fi
		done < <(find "$MA_SESSIONS_DIR" -maxdepth 1 -type f -name '*.mrk' -printf '%T@ %p\0' 2>/dev/null)
		if [[ -z $latest ]]; then
			warn "No session found in $MA_SESSIONS_DIR\n\n"
		else
			MA_DOC_PATH=$latest
			MA_DOC_NAME=$(basename "$latest" .mrk)
		fi
	}

	if [[ -n "${MA_DOC_NAME:-}" ]]; then
		if [[ -s "$MA_DOC_NAME" ]]; then
			MA_DOC_PATH="$MA_DOC_NAME"
		else
			doc_file_path_for "$MA_DOC_NAME" MA_DOC_PATH
			mkdir -p "$(dirname "$MA_DOC_PATH")" 2>/dev/null
		fi
		if [[ "${MA_NEW_SESSION:-}" == "true" || ! -f "$MA_DOC_PATH" ]]; then # new named session
			doc_init
		else # resume previous session
			if doc_load "$MA_DOC_PATH"; then
				thread_reprint MA_THREAD_JSON
				_session_import_check_working_dir
			else
				err "Error loading $MA_DOC_PATH\n"
				warn "Starting fresh ephemeral session.\n\n"
				MA_DOC_PATH=''; MA_DOC_NAME=''
				doc_init 
			fi
		fi
		[[ ${MA_FORK_SESSION:-} == true ]] && {
			doc_gen_name
			doc_file_path_for "$MA_DOC_NAME" MA_DOC_PATH
			warn "Session forked to: $MA_DOC_NAME\n\n"
		}
	else # ephemeral (unnamed) session
		MA_THREAD_NAME="main"
		thread_obj_set main main 0
		thread_init MA_THREAD_JSON "${MA_THREAD_OBJ_main[system_prompt]}"
		MA_DOC_JSON='{"metadata":{},"current_thread":"main","threads":{"main":{"messages":'"$MA_THREAD_JSON"'}}}'
	fi

	MA_PROJECT_DIR=$MA_WORKING_DIR

	local wd="${MA_WORKING_DIR:-$PWD}"
	if [[ "$wd" == /* ]]; then ma_normalize_path "$wd"; else ma_normalize_path "${PWD%/}/$wd"; fi

	_thread_switch_global_references "$MA_THREAD_NAME"

	trap 'ma_term_update' WINCH
}


_collect_from_suffixes() { # 1:array_out(ref) 2:prefix_match
	local -n _out=$1
	local _prefix=$2 _var
	local -a _vars
	_out=()
	mapfile -t _vars < <(compgen -A variable -- "$_prefix" || :)
	for _var in ${_vars[@]+"${_vars[@]}"}; do
		local -n _ref=$_var
		[[ ${_ref[@]@A} == "declare -A "* ]] && _out+=("${_var#"$_prefix"}")
		unset -n _ref
	done
}
_collect_quoted_from_suffixes() { # 1:array_out(ref) 2:prefix_match
	local -n _qout=$1
	local -a _plain
	_collect_from_suffixes _plain "$2"
	_qout=("${_plain[@]/#/\"}")
	_qout=("${_qout[@]/%/\"}")
}

ma_builtin_tools() {

	MA_TOOL[read]='
	{
	  "type": "function",
	  "name": "read",
	  "description": "Read path or fetch URL (full or partial). PDFs and HTML pages are rendered to text",
	  "parameters": {
		"type": "object",
		"properties": {
		  "path": { "type": "string", "description": "Local path or http(s):// URL" },
		  "range_lines": { "type": "string", "description": "1-indexed inclusive, e.g. 10-50, 10- (to end), or 10" },
		  "line_numbers": { "type": "boolean" },
		  "markers": { "type": "boolean", "description": "cat -A style ($=EOL, ^I=tab)" },
		  "format": { "type": "string", "enum": ["text", "bytes_hex"], "description": "Default 'text'. 'bytes_hex' dumps raw bytes" },
		  "range_bytes": { "type": "string", "description": "For format=bytes_hex; 1-indexed inclusive, in bytes" }
		},
		"required": [ "path" ]
	  }
	}'

	header_read() {
		local _path_info
		_path_info="$(jq -r 'try (if type == "string" then fromjson else . end) |
			"\(.path)\(if .range_lines then ":\(.range_lines)" else "" end)"' <<< "$1" 2>/dev/null)"
		[[ "$_path_info" =~ ^https?:// ]] && printf "🌐 "
		printf "%s\n" "${_path_info:-unknown_file}"
	}

	_dump_hex() {
		if command -v xxd >/dev/null 2>&1; then
			xxd
		elif command -v hexdump >/dev/null 2>&1; then
			hexdump -C
		elif command -v od >/dev/null 2>&1; then
			od -A x -t x1z
		else
			echo "ERROR: no hex utility available (need one of: xxd, hexdump, od)"
			return 1
		fi
	}

	_parse_range() {
		local range="$1" start_name="$2" end_name="$3" s e
		if [[ -z "$range" ]]; then
			printf -v "$start_name" '%s' ""
			printf -v "$end_name" '%s' ""
			return
		fi
		if [[ "$range" == *-* ]]; then
			s="${range%%-*}"
			e="${range#*-}"
		else
			s="$range"
			e="$range"
		fi
		printf -v "$start_name" '%s' "$s"
		printf -v "$end_name" '%s' "$e"
	}

	_hash_url() {
		local -n _uck_hash=$1
		local url="$2" hash
		ma_hash hash "$url"
		[[ -z $hash ]] && { hash="${url//[^A-Za-z0-9]/_}"; hash="${hash:0:64}"; }
		_uck_hash="$hash"
	}

	_url_cache_key() { # chosing the first available algo...
		local -n _uck_cashekey=$1
		local url="$2" _hash_out= prefix=
		_hash_url _hash_out "$url"
		if [[ "$url" =~ ^[A-Za-z][A-Za-z0-9+.-]*://(.*)$ ]]; then prefix="${BASH_REMATCH[1]}"; else prefix="$url"; fi
		prefix="${prefix//[^A-Za-z0-9._-]/_}"
		prefix="${prefix:0:60}"
		printf -v _uck_cashekey '%s' "${prefix}__${_hash_out}"
	}

	_pdf_to_text() {
		local src="$1" dst="$2"
		if command -v mutool &>/dev/null; then mutool draw -q -F text -o "$dst" "$src" 2>/dev/null && return 0; fi
		if command -v gs &>/dev/null; then gs -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=txtwrite -sOutputFile="$dst" "$src" 2>/dev/null && return 0; fi
		if command -v pdftotext &>/dev/null; then pdftotext -q -nopgbrk -eol unix -nodiag -raw "$src" "$dst" 2>/dev/null && return 0; fi
		if command -v python3 &>/dev/null; then
			if python3 -c "import pdfminer" &>/dev/null; then python3 -m pdfminer.high_level "$src" > "$dst" 2>/dev/null && return 0; fi
			if python3 -c "import pypdf" &>/dev/null; then
				python3 -c "
					import sys, pypdf
					r = pypdf.PdfReader(sys.argv[1])
					print('\n'.join((p.extract_text() or '') for p in r.pages))
					" "$src" > "$dst" 2>/dev/null && return 0
			fi
		fi
		return 1
	}

	_ocr_pdf_to_text() {
		local src="$1" dst="$2"
		local max_pages="${MA_OCR_MAX_PAGES:-200}"
		local dpi="${MA_OCR_DPI:-300}"		# trade-off speed at the cost of accuracy for fine print
		if command -v ocrmypdf &>/dev/null; then
			local ocr_pdf
			ocr_pdf="$(mktemp --suffix=.pdf)"
			if ocrmypdf --skip-text --pages "1-${max_pages}" --oversample "$dpi" --quiet "$src" "$ocr_pdf" &>/dev/null; then
				_pdf_to_text "$ocr_pdf" "$dst"
				local rc=$?
				rm -f "$ocr_pdf"
				[[ $rc -eq 0 && -s "$dst" ]] && return 0
			else
				rm -f "$ocr_pdf"
			fi
		fi
		if command -v tesseract &>/dev/null && command -v pdftoppm &>/dev/null; then
			local page_dir
			page_dir="$(mktemp -d)"
			if pdftoppm -r "$dpi" -png -l "$max_pages" "$src" "$page_dir/page" 2>/dev/null; then
				: > "$dst"
				local f ok=""
				for f in "$page_dir"/page*.png; do
					[[ -f "$f" ]] || continue
					tesseract "$f" - 2>/dev/null >> "$dst" && ok=1
					printf '\n' >> "$dst"
				done
				rm -rf "$page_dir"
				[[ -n "$ok" && -s "$dst" ]] && return 0
			else
				rm -rf "$page_dir"
			fi
		fi
		return 1
	}

	_extract_pdf_text() {
		local src="$1" label="$2" dst="$3"
		if ! _pdf_to_text "$src" "$dst"; then
			echo "ERROR: No PDF text extraction tool available (tried pdftotext, mutool, gs, pdfminer, pypdf)"
			return 1
		fi
		if [[ ! -s "$dst" ]] || ! grep -q '[[:alnum:]]' "$dst"; then # fallback to OCR
			if _ocr_pdf_to_text "$src" "$dst" && grep -q '[[:alnum:]]' "$dst"; then
				return 0
			fi
			echo "ERROR: No extractable text found in PDF and OCR was unavailable or found nothing (tried ocrmypdf, tesseract): $label"
			return 1
		fi
	}
	_render_html_text() {
		local src="$1" dst="$2" base_url="${3:-}"
		_html() { awk -v base="$base_url" '{ print } /<[Hh][Ee][Aa][Dd][ >]/ && !done { print "<base href=\"" base "\">"; done=1 }' "$src"; }
		if command -v lynx >/dev/null 2>&1; then _html | lynx -dump -force_html -stdin | sed 's|file://[^#]*#*|#|g' >"$dst" 2>/dev/null && return 0; fi
		if command -v w3m >/dev/null 2>&1; then _html | w3m -dump -o display_link_number=1 -T text/html >"$dst" 2>/dev/null && return 0; fi
		if command -v elinks >/dev/null 2>&1; then _html | elinks -dump -force-html >"$dst" 2>/dev/null && return 0; fi
		cp "$src" "$dst"
		echo "Warning: no text browser found to render webpage (recommended 'lynx' or 'w3m'). Output is raw HTML.";
		warn "\nNo text browser available to render webpage (recommended 'lynx' or 'w3m').\nOutput is raw HTML.\n";
		return 1
	}

	execute_read() {

		local path range_lines range_bytes line_numbers visual_markers format
		local start_line end_line start_byte end_byte
		{
			IFS= read -r -d '' path
			IFS= read -r -d '' range_lines
			IFS= read -r -d '' range_bytes
			IFS= read -r -d '' line_numbers
			IFS= read -r -d '' visual_markers
			IFS= read -r -d '' format
		} < <(jq -jr '.path, "\u0000", (.range_lines // ""), "\u0000", (.range_bytes // ""), "\u0000", (if .line_numbers then "true" else "" end), "\u0000",
						(if .markers then "true" else "" end), "\u0000", (.format // "text"), "\u0000"' <<< "$1")

		_parse_range "$range_lines" start_line end_line
		_parse_range "$range_bytes" start_byte end_byte

		local read_path=""
		local tmp_pdf=""
		local tmp_file=""
		local cache_ttl="${MA_READ_RESOURCE_CACHE_TTL:-3600}"

		case "$path" in
			file:///[A-Za-z]:/*) path="${path#file:///}" ;;	# windows
			file://*) path="${path#file://}" ;;
		esac

		[[ "$start_line" == "0" || "$end_line" == "0" ]] && { echo "ERROR: start_line and end_line must be 1-indexed (zero is invalid)"; return 1; }
		[[ "$start_byte" == "0" || "$end_byte" == "0" ]] && { echo "ERROR: start_byte and end_byte must be 1-indexed (zero is invalid)"; return 1; }

		trap '[[ -n "${tmp_file:-}" ]] && rm -f "${tmp_file:-}"; [[ -n "${tmp_pdf:-}" ]] && rm -f "${tmp_pdf:-}"; trap - RETURN' RETURN

		local is_url="" is_local_pdf=""
		[[ "$path" =~ ^https?:// ]] && is_url=1;
		[[ "${path,,}" == *.pdf ]] && is_local_pdf=1;

		(( ! is_url )) && {
			if [[ "${MA_CONFINE:-}" == true ]] && is_path_out_of_confinement "$path"; then
				err "DENIED: confinement in working directory is enabled.\n"
				echo "DENIED: path '$path' is outside the working directory ($MA_WORKING_DIR)"; 
				return 1;
			fi
		}

		local cache_key cache_file cache_hit=""
		if [[ -n "$is_url" || -n "$is_local_pdf" ]]; then
			_url_cache_key cache_key "$path"
			cache_file="${_ma_cache_dir}/${cache_key}"
			[[ "$cache_ttl" != "0" && -f "$cache_file" ]] && {
				local now mtime age
				now="$(date +%s)"
				mtime="$(ma_get_mtime "$cache_file")"
				[[ -n "$mtime" ]] && {
					age=$(( now - mtime ))
					if [[ "$cache_ttl" == "-1" ]] || (( age <= cache_ttl )); then cache_hit=1; fi
				}
			}
		fi

		if [[ -n "$is_url" ]]; then

			if [[ -n "$cache_hit" ]]; then
				read_path="$cache_file"
			else
				tmp_pdf="$(mktemp)"
				local ctype

				local ua="${MA_WEB_USER_AGENT:-"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"}"
				ctype="$(curl ${MA_WEB_PROXY:-} -sS -L -A "$ua" --max-time "${MA_MAX_FETCH_SECONDS:-600}" -o "$tmp_pdf" -w '%{content_type}' "$path" 2>/dev/null)"
				local curl_rc=$?
				[[ $curl_rc -ne 0 ]] && { echo "ERROR: Failed to fetch URL: $path"; return 1; }

				local is_pdf=""
				[[ "${path,,}" == *.pdf* ]] && is_pdf=1
				[[ "${ctype,,}" == *pdf* ]] && is_pdf=1
				[[ -z "$is_pdf" ]] && { # fallback for servers that mislabel/omit the content-type header
					local magic
					magic="$(head -c4 "$tmp_pdf" 2>/dev/null)"
					[[ "$magic" == "%PDF" ]] && is_pdf=1
				}

				tmp_file="$(mktemp)"
				if [[ -n "$is_pdf" ]]; then
					_extract_pdf_text "$tmp_pdf" "$path" "$tmp_file" || return 1
				else
					_render_html_text "$tmp_pdf" "$tmp_file" "$path" 
					[[ -s "$tmp_file" ]] || { echo "ERROR: Fetched page was empty: $path"; return 1; }
				fi
			fi
		else
			[[ -f "$path" ]] || {
				[[ -d "$path" ]] && { echo "$path is a directory:" ; execute_ls "$1"; return; }
				echo "ERROR: File not found: $path";
				return 1;
			}
			read_path="$path"
			if [[ -n "$is_local_pdf" ]]; then
				if [[ -n "$cache_hit" ]]; then
					read_path="$cache_file"
				else
					tmp_file="$(mktemp)"
					_extract_pdf_text "$path" "$path" "$tmp_file" || return 1
				fi
			else
				[[ ${MA_LLAMACPP_FIX:-} == true ]] && echo "Result:"	# llama.cpp strips leading whitespaces with some models.
			fi
		fi

		[[ -z $cache_hit && -n "$tmp_file" && -s "$tmp_file" ]] && {
			if [[ "$(ma_get_size "$tmp_file")" -gt "${MA_READ_MIN_CACHE_SIZE:-1024}" ]]; then	# just to avoid caching some failure cases
				if ! mv -f "$tmp_file" "$cache_file" 2>/dev/null; then cp -f "$tmp_file" "$cache_file" && rm -f "$tmp_file"; fi
				tmp_file=""
				read_path="$cache_file"
			else
				read_path="$tmp_file"
			fi
		}

		case $format in
			bytes_hex)
				local max_bytes="${MA_READ_MAX_HEX_BYTES:-16384}"
				local file_size
				file_size="$(ma_get_size "$read_path")"
				if [[ -n "$start_byte" || -n "$end_byte" ]]; then # Byte range takes precedence
					local sb="${start_byte:-1}"
					local requested_total take
					if [[ -n "$end_byte" ]]; then
						requested_total=$(( end_byte - sb + 1 ))
					else
						requested_total=$(( file_size - sb + 1 ))
					fi
					[[ "$requested_total" -lt 0 ]] && requested_total=0
					take=$requested_total
					(( take > max_bytes )) && take=$max_bytes
					tail -c +"$sb" "$read_path" | head -c "$take" | _dump_hex
					(( requested_total > max_bytes )) && printf "\n[TRUNCATED: showing %d of %d requested bytes; narrow start_byte/end_byte for more precision]\n" "$max_bytes" "$requested_total"
				elif [[ -n "$start_line" || -n "$end_line" ]]; then
					local sl="${start_line:-1}"
					local line_bytes total_line_bytes
					if [[ -n "$end_line" ]]; then
						line_bytes="$(sed -n "${sl},${end_line}p" "$read_path" | head -c "$max_bytes")"
						total_line_bytes="$(sed -n "${sl},${end_line}p" "$read_path" | wc -c)"
					else
						line_bytes="$(tail -n +"$sl" "$read_path" | head -c "$max_bytes")"
						total_line_bytes="$(tail -n +"$sl" "$read_path" | wc -c)"
					fi
					printf '%s' "$line_bytes" | _dump_hex
					(( total_line_bytes > max_bytes )) && printf "\n[TRUNCATED: showing %d of %d bytes from the selected lines; narrow start_line/end_line or switch to start_byte/end_byte]\n" "$max_bytes" "$total_line_bytes"
				else
					head -c "$max_bytes" "$read_path" | _dump_hex
					[[ -n "$file_size" ]] && (( file_size > max_bytes )) && printf "\n[TRUNCATED: showing %d of %d bytes; use start_byte/end_byte for a specific range]\n" "$max_bytes" "$file_size"
				fi
				;;
			*)
				local total_lines
				total_lines="$(wc -l < "$read_path")"
				local sl="${start_line:-1}"
				local awk_el=0
				[[ -n "$end_line" && "$end_line" =~ ^[0-9]+$ ]] && awk_el=$(( end_line - sl + 1 ))

				tail -n +"$sl" "$read_path" | awk -v el="$awk_el" -v max="${MA_READ_MAX_LINES:-2000}" -v raw="$visual_markers" \
					 -v lnum="$line_numbers" -v width="${#total_lines}" -v first="$sl" -v total="$total_lines" \
				'BEGIN { ORS=""; count=0 }
				el > 0 && NR > el { exit }
				{
					count++
					if (count > max) { next }
					line = $0
					if (raw == "true") {
						gsub(/\r/, "^M", line)
						gsub(/\t/, "^I", line)
						line = line "$"
					}
					if (lnum == "true") {
						printf "%0*d|%s\n", width, first + count - 1, line
					} else {
						print line "\n"
					}
				}
				END {
					if (count > max) {
						printf "[TRUNCATED: showing %d of %d lines; use start_line/end_line to read a specific range (%d lines total)]\n", max, count, total
					}
				}'
				;;
		esac

	}
	MA_TOOL_DISPLAY_OUTPUT[read]=false 




	MA_TOOL[write]='
	{
		"type": "function",
		"name": "write",
		"description": "Write/overwrite a file. Use only for new files or complete rewrites",
		"parameters": {
			"type": "object",
		   	"properties": {
				"path": { "type": "string" },
				"content": { "type": "string" }
			},
		"required": [ "path", "content" ]
		}
	}'

	header_write() { jq -r '"\(.path // "") (\(.content|length) characters)"'  <<< "$1" 2>/dev/null ; }

	execute_write() {
		local path content
		{
			IFS= read -r -d '' path
			IFS= read -r -d '' content
		} < <(jq -jb '(.path // ""), "\u0000", (.content // ""), "\u0000"' <<< "$1") || { echo "ERROR: Failed to parse path or content" >&2; return 1; }

		if [[ "${MA_CONFINE:-}" == true ]] && is_path_out_of_confinement "$path"; then
			err "DENIED: confinement in working directory is enabled.\n"
			echo "DENIED: path '$path' is outside the working directory ($MA_WORKING_DIR)"; 
			return 1;
		fi

		local dir="${path%/*}"; [[ "$dir" == "$path" ]] && dir="."
		mkdir -p "$dir"	|| { echo "ERROR: Failed to create directory" >&2; return 1; }
		if ! printf '%s' "$content" > "$path"; then	 echo "ERROR: Failed to write $path" >&2; return 1; fi
		local bytes="$(wc -c < "$path")" || { echo "ERROR: Failed to stat written file" >&2; return 1; }
		echo "OK: Written $bytes bytes to $path"
	}


	MA_TOOL[edit]='
	{
		"type": "function",
		"name": "edit",
		"description": "Sequential text replacements, each on the previous result. Atomic: if any edit fails, the file is unchanged",
		"parameters": {
			"type": "object",
			"properties": {
				"path": { "type": "string" },
				"edits": {
					"type": "array", "description": "No overlapping/nested edits",
					"items": {
						"type": "object",
						"properties": {
							"match": { "type": "string", "description": "Shortest unique text to replace" },
							"new_text": { "type": "string" }
						},
						"required": [ "match", "new_text" ]
					}
				}
			},
			"required": [ "path", "edits" ]
		}
	}'

	header_edit() {
		jq -br '
			"\(.path // "") (\(.edits|length) edits)",
			(.edits[] |
				"  [\(.match // "" | .[0:40] | gsub("[\\n\\r\\t]";" "))]" +
				"  →  " +
				if .cache_id != null then "#\(.cache_id)"
				elif (.new_text // "") != "" then "\"" + (.new_text | .[0:40] | gsub("[\\n\\r\\t]";" ")) + "…\""
				else "(empty)"
				end
			)
		' <<< "$1" 2>/dev/null
	}

	execute_edit() {
		[[ "${MA_CONFINE:-}" == true ]] && {
			local path=$(jq -br '.path // ""' <<< "$1")
			if is_path_out_of_confinement "$path"; then
				err "DENIED: confinement in working directory is enabled.\n"
				echo "DENIED: path '$path' is outside the working directory ($MA_WORKING_DIR)"; 
				return 1;
			fi
		}
		if (( _HAS_PERL )); then	# fastest path
			jq -jrb '
				(.path // ""), "\u0000",
				(.edits[] | .match, "\u0000", .new_text, "\u0000")
			' <<< "$1" | perl -0 -e '
				my $file_path = <STDIN>;
				if (!defined $file_path) { exit 1; }
				chomp($file_path);
				if (! -f $file_path) { print "ERROR: File not found: $file_path\n"; exit 1; }
				my @edits;
				while (my $old = <STDIN>) {
					chomp($old);
					my $new = <STDIN>;
					if (!defined $new) {
						print "ERROR: malformed edits payload (odd field count)\n";
						exit 1;
					}
					chomp($new);
					push @edits, { old => $old, new => $new };
				}
				my $n_edits = scalar(@edits);
				if ($n_edits == 0) { print "OK: 0 edits applied to $file_path\n"; exit 0; }
				my $content;
				{
					open my $fh, "<", $file_path or do {
						print "ERROR: Cannot open $file_path\n";
						exit 1;
					};
					local $/ = undef;
					$content = <$fh>;
					close $fh;
				}
				for my $i (0 .. $#edits) {
					my $old = $edits[$i]{old};
					my $new = $edits[$i]{new};

					if ($old eq "") { print "ERROR: edits[$i].match is empty\n"; exit 1; }

					my ($before, $after);
					my $idx = index($content, $old);

					if ($idx != -1) { # FAST PATH: Exact Match
						$before = substr($content, 0, $idx);
						$after = substr($content, $idx + length($old));
						if (index($after, $old) != -1) { print "ERROR: edits[$i].match matched multiple times\n"; exit 1; }

					} else { # whitespace-agnostic match
						my $regex_str = "";
						while ($old =~ m/(\s+)|([^\s]+)/g) {
							if (defined $1) {
								if (index($1, "\n") != -1) {
									$regex_str .= "[^\\S\\n]*\\n[^\\S\\n]*";
								} else {
									$regex_str .= "[^\\S\\n]+";
								}
							} else {
								$regex_str .= quotemeta($2);
							}
						}
						my $regex = qr/$regex_str/;
						if ($content =~ m/$regex/) {
							$before = substr($content, 0, $-[0]);
							$after  = substr($content, $+[0]);
							if ($after =~ m/$regex/) { print "ERROR: edits[$i].match matched multiple times\n"; exit 1; }
						} else { print "ERROR: edits[$i].match not found in $file_path\n"; exit 1; }
					}
					$content = $before . $new . $after;
				}
				open my $out, ">", $file_path or do { print "ERROR: Cannot write to $file_path\n"; exit 1; };
				print $out $content;
				close $out;
				print "OK: $n_edits edits applied to $file_path\n";
			'

			return "${PIPESTATUS[1]}"
		elif [[ -n ${_PYTHON:-} ]]; then
			local file_path
			file_path="$(jq -jr '.path // ""' <<< "$1")"
			(( _HAS_CYGPATH )) && file_path="$(cygpath -w "$file_path")"	# fix MinGW python not recognizing MSYS paths
			jq -jrb '(.edits[] | .match, "\u0000", .new_text, "\u0000")' <<< "$1" \
			| $_PYTHON -c '
				import sys, re, os

				def die(msg):
					print(msg)
					sys.exit(1)

				def read_field():
					buf = b""
					while True:
						ch = sys.stdin.buffer.read(1)
						if not ch:
							return None
						if ch == b"\x00":
							return buf.decode("utf-8")
						buf += ch

				def build_smart_regex(old):
					regex_str = ""
					for token in re.split(r"(\s+)", old):
						if not token:
							continue
						if re.fullmatch(r"\s+", token):
							regex_str += r"[^\S\n]*\n[^\S\n]*" if "\n" in token else r"[^\S\n]+"
						else:
							regex_str += re.escape(token)
					return regex_str

				file_path = sys.argv[1]

				if not os.path.isfile(file_path):
					die(f"ERROR: File not found: {file_path}")

				edits = []
				while True:
					old = read_field()
					if old is None:
						break
					new = read_field()
					if new is None:
						die("ERROR: malformed edits payload (odd field count)")
					edits.append((old, new))

				if not edits:
					print(f"OK: 0 edits applied to {file_path}")
					sys.exit(0)

				try:
					with open(file_path, "r") as fh:
						content = fh.read()
				except OSError:
					die(f"ERROR: Cannot open {file_path}")

				for i, (old, new) in enumerate(edits):
					if old == "":
						die(f"ERROR: edits[{i}].match is empty")

					idx = content.find(old)
					if idx != -1:
						before = content[:idx]
						after  = content[idx + len(old):]
						if old in after:
							die(f"ERROR: edits[{i}].match matched multiple times in {file_path}")

					else:
						regex_str = build_smart_regex(old)
						m = re.search(regex_str, content)
						if not m:
							die(f"ERROR: edits[{i}].match not found in {file_path}")
						before = content[:m.start()]
						after  = content[m.end():]
						if re.search(regex_str, after):
							die(f"ERROR: edits[{i}].match matched multiple times in {file_path}")

					content = before + new + after

				try:
					with open(file_path, "w") as fh:
						fh.write(content)
				except OSError:
					die(f"ERROR: Cannot write to {file_path}")

				print(f"OK: {len(edits)} edits applied to {file_path}")
				' "$file_path"
			return "${PIPESTATUS[1]}"
		else
			# WARNING: Extremely slow, and no whitespace normalization
			local full_path val
			local -a texts=()
			{
				IFS= read -r -d '' full_path
				while IFS= read -r -d '' val; do
					texts+=("$val")
				done
			} < <(jq -jrb '
				(.path // ""), "\u0000",
				(.edits[] | .match, "\u0000", .new_text, "\u0000")
			' <<< "$1")

			[[ ! -f "$full_path" ]] && { echo "ERROR: File not found: $full_path"; return 1; }

			local n_edits=$(( ${#texts[@]} / 2 ))
			(( ${#texts[@]} % 2 == 0 )) || { echo "ERROR: malformed edits payload (odd field count)"; return 1; }
			(( n_edits == 0 )) && { echo "OK: 0 edits applied to $full_path"; return 0; }

			local content
			IFS= read -r -d '' content < "$full_path" || true
			local i old_text new_text before after after_last
			for ((i = 0; i < n_edits; i++)); do
				old_text="${texts[i*2]}"
				new_text="${texts[i*2+1]}"

				[[ -z "$old_text" ]] && { echo "ERROR: edits[$i].match is empty"; return 1; }
				before="${content%%"${old_text}"*}"
				[[ "$before" == "$content" ]] && { echo "ERROR: edits[$i].match not found in $full_path"; return 1; }
				after="${content#*"${old_text}"}"
				after_last="${content##*"${old_text}"}"
				[[ "$after" != "$after_last" ]] && { echo "ERROR: edits[$i].match matched multiple times in $full_path"; return 1; }
				content="${before}${new_text}${after}"

			done
			printf '%s' "$content" > "$full_path"
			echo "OK: $n_edits edits applied to $full_path"
		fi
	}


	MA_TOOL[bash]='{
	  "type": "function",
		"name": "bash",
		"description": "Run shell command. All processes killed on return. To keep one alive (server/watcher): setsid CMD >/tmp/NAME.log 2>&1 & (redirect output or the call hangs)",
		"parameters": {
		  "type": "object",
		  "properties": {
			"command": { "type": "string" },
			"timeout_seconds": { "type": "integer", "description": "Default '${MA_BASH_TIMEOUT_SEC:-120}', max '${MA_BASH_TIMEOUT_MAX:-1800}'" }
		  },
		  "required": [ "command" ]
		}
	}'
	_TOOL_UNBASH='{
	  "type": "function",
		"name": "bash",
		"description": "Not available in this session",
		"parameters": {
		  "type": "object",
		  "properties": { "command": { "type": "string" } }
		}
	}'
	[[ ${_UNBASH:-} == true ]] && { MA_TOOL[bash]="$_TOOL_UNBASH"; }

	header_bash(){
		local _cmd _header_extra='' _timeout
		if [[ "$1" =~ \"timeout_seconds\":([0-9]+) ]]; then _timeout="${BASH_REMATCH[1]}"; else _timeout=""; fi
		if [[ -z "$_timeout" || ! "$_timeout" =~ ^[0-9]+$ ]]; then _timeout="${MA_BASH_TIMEOUT_SEC:-120}"; else _header_extra="(timeout ${_timeout}s)"; fi
		if [[ "$1" =~ \"command\":\"(([^\"]|\\\")*) ]]; then
			_cmd="${BASH_REMATCH[1]}"
			_cmd="${_cmd//\\\"/\"}"
		else
			_cmd="$(jq -r '.command // ""' <<< "$1" 2>/dev/null)"
		fi
		[[ -n "$_header_extra" ]] && printf "%s ${A_D}%s${A_D0}\n" "$_cmd" "$_header_extra" || printf '%s\n' "$_cmd"
	}


	_ma_run_group() { # $1=timeout_secs  $2=cmd
		local pid= rc interrupted=0
		trap 'interrupted=1; [[ -n $pid ]] && kill -TERM -- "-$pid" 2>/dev/null' INT
		"${MA_BASH_ENV_PREFIX[@]}" "${_MA_SETSID[@]}" timeout -k 2 "$1" bash --noprofile --norc -c '
				'"${MA_BASH_PRELOAD_CONTENT:-}"'
				cd -- "$1" && eval "$2"
			' _ "$MA_WORKING_DIR" "$2" < /dev/null 2>&1 &
		pid=$!
		(( interrupted )) && kill -TERM -- "-$pid" 2>/dev/null
		wait "$pid"; rc=$?
		(( rc > 128 )) && kill -0 "$pid" 2>/dev/null && { wait "$pid" 2>/dev/null; rc=$?; }
		kill -KILL -- "-$pid" 2>/dev/null
		trap - INT
		(( interrupted )) && rc=130
		printf '%d' "$rc" > "$_bash_rc_file"
	}

	IFS= read -r -d '' _MA_BASH_AWK <<'AWK'
	{
		gsub(/\x00/, "")
		out_line = $0
		disp_line = $0
		if (strip_out)  { gsub(/\033\[[0-9;?]*[ -\/]*[@-~]/, "", out_line) }
		if (strip_disp) { gsub(/\033\[[0-9;?]*[ -\/]*[@-~]/, "", disp_line) }
		n++
		if (live) {
			if (tunlimited || n <= tmaxh) {
				print pre disp_line suf > "/dev/stderr"
				fflush()
			} else {
				ttailbuf[n % tmaxt] = disp_line
			}
		}
		if (n <= maxh) {
			print out_line
			if (flush) fflush()
		} else {
			tailbuf[n % maxt] = out_line
		}
	}
	END {
		if (live && !tunlimited && n > tmaxh) {
			if (n > tmaxh + tmaxt) {
				print pre "[TRUNCATED: omitting " (n - tmaxh - tmaxt) " of " n " lines from the middle]" suf > "/dev/stderr"
				fflush()
				for (i = n - tmaxt + 1; i <= n; i++) { print pre ttailbuf[i % tmaxt] suf > "/dev/stderr"; fflush() }
			} else {
				for (i = tmaxh + 1; i <= n; i++) { print pre ttailbuf[i % tmaxt] suf > "/dev/stderr"; fflush() }
			}
		}
		if (n > maxh && n <= maxh + maxt) {
			for (i = maxh + 1; i <= n; i++) print tailbuf[i % maxt]
		} else if (n > maxh + maxt) {
			print "[TRUNCATED: omitting " (n - maxh - maxt) " of " n " lines from the middle]"
			for (i = n - maxt + 1; i <= n; i++) print tailbuf[i % maxt]
		}
	}
AWK

	execute_bash() {
		[[ ${MA_TOOL_DISPLAY_SEPARATORS[bash]:-} != false ]] && _draw_separator right ─ "${A_TOOL_SEP}"
		[[ ${_UNBASH:-} == true || ${MA_CONFINE:-} == true ]] && {
			echo "ERROR: bash tool is disabled in confinement mode."
			echo "0s"
			[[ ${MA_TOOL_DISPLAY_SEPARATORS[bash]:-} != false ]] && _draw_separator right ─ "${A_TOOL_SEP}"
			return 1
		}

		local cmd timeout_secs
		{
			IFS= read -r -d '' cmd
			IFS= read -r -d '' timeout_secs
		} < <(jq -jb '(.command // ""), "\u0000", (.timeout_seconds // ""), "\u0000"' <<< "$1" 2>/dev/null)

		[[ -z "$cmd" ]] && { echo "ERROR: Empty command"; return 1; }
		[[ -z "$timeout_secs" || ! "$timeout_secs" =~ ^[0-9]+$ ]] && timeout_secs="${MA_BASH_TIMEOUT_SEC:-120}"
		(( timeout_secs > ${MA_BASH_TIMEOUT_MAX:-1800} )) && timeout_secs=${MA_BASH_TIMEOUT_MAX:-1800}

		# output limits (sent to the model)
		local max_lines="${MA_BASH_MAX_OUTPUT_LINES:-400}"
		local head_n=$(( (max_lines + 1) / 2 ))
		local tail_n=$(( max_lines - head_n ))
		(( tail_n < 1 )) && tail_n=1

		# output limits (terminal display)
		local term_max_lines="${MA_BASH_TERM_MAX_OUTPUT_LINES:-0}"
		local term_head_n term_tail_n term_unlimited=0
		if [[ -z "$term_max_lines" || "$term_max_lines" == "0" ]]; then
			term_unlimited=1
			term_head_n=0
			term_tail_n=1
		else
			term_head_n=$(( (term_max_lines + 1) / 2 ))
			term_tail_n=$(( term_max_lines - term_head_n ))
			(( term_tail_n < 1 )) && term_tail_n=1
		fi

		local exit_code t_start_us t_end_us elapsed
		ma_now t_start_us

		local _bash_rc_file="$_ma_tmp_dir/bash_$$_${BASHPID:-"${RANDOM}"}_rc"
		: > "$_bash_rc_file"

		if (( $$ != BASHPID )); then
			trap 'rm -f "${_bash_rc_file:-}" "${_bash_output_file:-}"; trap - RETURN' RETURN EXIT
		else # same shell
			trap 'rm -f "${_bash_rc_file:-}" "${_bash_output_file:-}"; trap - RETURN' RETURN
		fi

		local output=
		local display_live=0 strip_ansi_display=0 strip_ansi_output=0
		(( _MA_SHOULD_PRINT )) && display_live=1
		[[ "${MA_BASH_STRIP_ANSI_DISPLAY:-}" == "true" ]] && strip_ansi_display=1
		[[ "${MA_BASH_STRIP_ANSI_OUTPUT:-}"  == "true" ]] && strip_ansi_output=1

		local awk_maxh=$head_n awk_flush=0
		if [[ ${MA_BASH_FILE_OUTPUT:-} == true ]]; then
			awk_maxh=2147483647
			awk_flush=1
		fi

		local -a awk_args=(
			-v pre="${A_K}${A_TOOL_BODY}" -v suf="${A_K}${A_R}"
			-v maxh="$awk_maxh" -v maxt="$tail_n" -v flush="$awk_flush"
			-v tmaxh="$term_head_n" -v tmaxt="$term_tail_n"
			-v tunlimited="$term_unlimited" -v live="$display_live"
			-v strip_disp="$strip_ansi_display" -v strip_out="$strip_ansi_output"
		)

		if [[ ${MA_BASH_FILE_OUTPUT:-} == true ]]; then # survive interrupt
			local _bash_output_file="$_ma_tmp_dir/bash_$$_${BASHPID:-"${RANDOM}"}_out"
			: > "$_bash_output_file"

			{ _ma_run_group "$timeout_secs" "$cmd"; } | awk "${awk_args[@]}" "$_MA_BASH_AWK" > "$_bash_output_file"

			local total
			total=$(wc -l < "$_bash_output_file")
			if (( total > max_lines )); then
				output="$(head -n "$head_n" "$_bash_output_file")"
				output+=$'\n'"[TRUNCATED: omitting $(( total - head_n - tail_n )) of ${total} lines from the middle]"$'\n'
				output+="$(tail -n "$tail_n" "$_bash_output_file")"
			elif [[ -s "$_bash_output_file" ]]; then
				output="$(< "$_bash_output_file")"
			fi
			rm -f "$_bash_output_file"
		else
			output="$({ _ma_run_group "$timeout_secs" "$cmd"; } | awk "${awk_args[@]}" "$_MA_BASH_AWK")"
		fi

		printf '%s' "${A_R}${A_K}" >&2

		exit_code=0
		[[ -f "$_bash_rc_file" ]] && exit_code="$(< "$_bash_rc_file")"
		[[ -z "$exit_code" || ! "$exit_code" =~ ^[0-9]+$ ]] && exit_code=124

		ma_now t_end_us
		elapsed=$(( (t_end_us - t_start_us) / 1000 ))

		local elapsed_fmt exit_color footer
		elapsed_fmt="$(( elapsed / 1000 )).$(printf '%03d' $(( elapsed % 1000 )))s"
		if (( exit_code == 0 )); then
			exit_color="${A_TOOL_OK}"
			footer="${elapsed_fmt}"
		elif (( exit_code == 124 )); then
			exit_color="${A_TOOL_FAIL}"
			footer="exit code: $exit_code | timed out after ${timeout_secs}s | ${elapsed_fmt}"
		else
			exit_color="${A_TOOL_FAIL}"
			footer="exit code: $exit_code | ${elapsed_fmt}"
		fi

		[[ ${MA_TOOL_DISPLAY_SEPARATORS[bash]:-} != false ]] && \
			_draw_separator right ─ "${A_TOOL_SEP}" "$footer [bash]" "$exit_color"

		[[ ${MA_LLAMACPP_FIX:-} == true ]] && echo "Result:" # llama.cpp strips leading whitespace with some models
		printf '%s\n%s' "$output" "$footer"
		return "$exit_code"
	}

	MA_TOOL_DISPLAY_OUTPUT[bash]=false 
	MA_TOOL_DISPLAY_REPRINT[bash]=true



	MA_TOOL[websearch]='
	{
	  "type": "function",
		"name": "websearch",
		"description": "Returns a list of URLs and snippets. Imortant: Use the read tool to fetch and inspect a specific URL in more detail. Use query=front for fetching latest entries on news-sites",
		"parameters": {
		  "type": "object",
		  "properties": {
			"query": { "type": "string", "description": "Search query (or DOI for unpaywall)" },
			"provider": { "type": "string", "enum": ["web", "wikipedia", "arxiv", "openalex", "pubmed", "archive", "unpaywall", "hackernews"], "description": "Default web" },
			"max_results": { "type": "integer", "description": "Default 20" },
			"lang": { "type": "string", "description": "Default en" }
		  },
		  "required": [ "query" ]
		}
	}'

	header_websearch(){
		jq -r '"\(.query // "")\(if .provider and .provider != "web" then " [provider=\(.provider)]" else "" end)\(if .max_results then " [n=\(.max_results)]" else "" end)\(if .site then " [site=\(.site)]" else "" end)"' <<< "$1" 2>/dev/null
	}

	_ddg_parse_html() {
		local input="${1:-}"   # path to an HTML file, or empty/'-' to read stdin
		if (( _HAS_PERL )); then
			perl -0777 -e '
				my $html = do { local $/; <> };
				my @chunks = split /<div class="result results_links/, $html;
				shift @chunks;
				for my $chunk (@chunks) {
					my ($href, $title) = $chunk =~ m{<a[^>]*class="result__a"[^>]*href="([^"]*)"[^>]*>(.*?)</a>}s;
					next unless $href;
					my ($snippet) = $chunk =~ m{<a[^>]*class="result__snippet"[^>]*>(.*?)</a>}s;
					$snippet //= "";
					my $url = $href;
					$url = $1 if $url =~ /uddg=([^&]+)/;
					$url = uri_decode($url);
					$title   = clean($title);
					$snippet = clean($snippet);
					print "$title\n" if length $title;
					print "$url\n";
					print "$snippet\n" if length $snippet;
					print "\n";
				}
				sub uri_decode { my ($s) = @_; $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge; return $s; }
				sub clean {
					my ($s) = @_;
					$s =~ s/<[^>]+>//g;
					$s =~ s/&amp;/&/g;
					$s =~ s/&quot;/"/g;
					$s =~ s/&#x27;/'"'"'/g;
					$s =~ s/&#39;/'"'"'/g;
					$s =~ s/&lt;/</g;
					$s =~ s/&gt;/>/g;
					$s =~ s/&nbsp;/ /g;
					$s =~ s/^\s+|\s+$//g;
					$s =~ s/\s+/ /g;
					return $s;
				}
			' ${input:+"$input"}
		else
			awk '
				BEGIN {
					RS = "<div class=\"result results_links"
					ORS = ""
					hexdigits = "0123456789abcdef"
					for (i = 0; i < 16; i++) {
						c = substr(hexdigits, i + 1, 1)
						hexval[c] = i
						hexval[toupper(c)] = i
					}
				}
				function urldecode(s,    out, i, n, c1) {
					out = ""; n = length(s); i = 1
					while (i <= n) {
						c1 = substr(s, i, 1)
						if (c1 == "%" && i + 2 <= n) {
							out = out sprintf("%c", hexval[substr(s,i+1,1)] * 16 + hexval[substr(s,i+2,1)])
							i += 3
						} else if (c1 == "+") {
							out = out " "; i += 1
						} else {
							out = out c1; i += 1
						}
					}
					return out
				}
				function clean(s) {
					gsub(/<[^>]*>/, "", s)
					gsub(/&amp;/, "\x01", s)   # protect & until other entities are done
					gsub(/&quot;/, "\"", s)
					gsub(/&#x27;/, "'"'"'", s)
					gsub(/&#39;/, "'"'"'", s)
					gsub(/&lt;/, "<", s)
					gsub(/&gt;/, ">", s)
					gsub(/&nbsp;/, " ", s)
					gsub(/\x01/, "\&", s)
					gsub(/[ \t\r\n]+/, " ", s)
					gsub(/^ +| +$/, "", s)
					return s
				}
				NR > 1 {
					chunk = $0
					a_pos = index(chunk, "class=\"result__a\"")
					if (a_pos == 0) next
					href_start = index(substr(chunk, a_pos), "href=\"")
					if (href_start == 0) next
					href_start += a_pos + 5
					href_end = index(substr(chunk, href_start), "\"")
					href = substr(chunk, href_start, href_end - 1)
					title_start = index(substr(chunk, href_start + href_end), ">") + href_start + href_end
					title_end   = index(substr(chunk, title_start), "</a>")
					title = substr(chunk, title_start, title_end - 1)
					snippet = ""
					s_pos = index(chunk, "class=\"result__snippet\"")
					if (s_pos > 0) {
						sn_start = index(substr(chunk, s_pos), ">") + s_pos
						sn_end   = index(substr(chunk, sn_start), "</a>")
						snippet  = substr(chunk, sn_start, sn_end - 1)
					}
					u_pos = index(href, "uddg=")
					if (u_pos > 0) {
						url = substr(href, u_pos + 5)
						amp = index(url, "&")
						if (amp > 0) url = substr(url, 1, amp - 1)
					} else {
						url = href
					}
					url = urldecode(url)
					title   = clean(title)
					snippet = clean(snippet)
					if (title != "") print title "\n"
					print url "\n"
					if (snippet != "") print snippet "\n"
					print "\n"
				}
			' ${input:+"$input"}
		fi
	}


	execute_websearch() {
		local query max_results provider lang
		{
			IFS= read -r -d '' query
			IFS= read -r -d '' max_results
			IFS= read -r -d '' provider
			IFS= read -r -d '' lang
		} < <(jq -jr '.query, "\u0000", (.max_results // "10"), "\u0000", (.provider // "web"), "\u0000", (.lang // "en"), "\u0000"' <<< "$1")
		[[ -z "$query" ]] && { echo "ERROR: query is required"; return 1; }

		local ua="${MA_WEB_USER_AGENT:-"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"}"
		local email="${MA_WEB_SEARCH_EMAIL:-}"

		case "$provider" in
		wikipedia)
			curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs "https://$lang.wikipedia.org/w/api.php" \
				--data-urlencode "srlimit=$max_results" --data-urlencode 'action=query' --data-urlencode 'list=search' \
				--data-urlencode "srsearch=$query" --data-urlencode 'utf8=1' --data-urlencode 'format=json' |
			jq -r --arg lang "$lang" '
				.query.search[] |
				.title as $t |
				"\($t) (URL=https://\($lang).wikipedia.org/wiki/\($t|gsub(" ";"_")|@uri), size=\(.size))",
				(.snippet | gsub("<[^>]+>"; "")),
				""
			'
			return 0
			;;

		openalex) # Free, no key. "polite pool" (faster/more reliable) if we pass a mailto.
			local email_param=(); [[ -n "$email" ]] && email_param=(--data-urlencode "mailto=$email")
			curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs "https://api.openalex.org/works" \
				--data-urlencode "search=$query" --data-urlencode "per-page=$max_results" \
				--data-urlencode "select=title,doi,publication_year,open_access,primary_location,authorships" \
				"${email_param[@]}" |
			jq -r '
				.results[]? |
				"\(.title) (\(.publication_year // "n.d."))",
				"  authors: \([.authorships[]?.author.display_name] | join(", "))",
				"  doi: \(.doi // "none")  oa: \(.open_access.is_oa)  pdf: \(.primary_location.pdf_url // .open_access.oa_url // "none")",
				""
			'
			return 0
			;;

		pubmed)
			# Free, no key. NCBI asks for email (and ideally api_key) if you go beyond ~3 req/s.
			local email_param=(); [[ -n "$email" ]] && email_param=(--data-urlencode "email=$email")
			local pmids
			pmids="$(curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi" \
				--data-urlencode "db=pubmed" --data-urlencode "retmode=json" --data-urlencode "retmax=$max_results" --data-urlencode "term=$query" \
				"${email_param[@]}" | jq -r '.esearchresult.idlist[]?')"
			[[ -z "$pmids" ]] && { echo "No PubMed results."; return 0; }
			curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi" \
				--data-urlencode "db=pubmed" --data-urlencode "retmode=json" \
				--data-urlencode "id=$(paste -sd, <<< "$pmids")" "${email_param[@]}" |
			jq -r '
				.result.uids[] as $id |
				.result[$id] |
				"\(.title) (\(.pubdate)) PMID=\($id)",
				"  journal: \(.fulljournalname // .source // "n/a")",
				"  URL: https://pubmed.ncbi.nlm.nih.gov/\($id)/",
				""
			'
			return 0
			;;

		hackernews)
			case "$query" in
				""|latest|top|front|frontpage|"front page")
					curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs "https://hn.algolia.com/api/v1/search_by_date" \
						--data-urlencode "tags=front_page" --data-urlencode "hitsPerPage=$max_results"
					;;
				*)
					curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs "https://hn.algolia.com/api/v1/search" \
						--data-urlencode "query=$query" --data-urlencode "tags=story" --data-urlencode "hitsPerPage=$max_results"
					;;
			esac | jq -r '
				.hits[]? |
				"\(.title) (\(.points // 0) pts, \(.num_comments // 0) comments)",
				"  URL: \(.url // ("https://news.ycombinator.com/item?id=" + (.objectID // "")))",
				"  HN: https://news.ycombinator.com/item?id=\(.objectID // "")",
				""
			'
			return 0
			;;

		archive) # Full-text/metadata search of archive.org items (not a Wayback URL lookup).
			curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs "https://archive.org/advancedsearch.php" \
				--data-urlencode "q=$query" --data-urlencode "rows=$max_results" --data-urlencode 'fl[]=identifier' --data-urlencode 'fl[]=title' \
				--data-urlencode 'fl[]=description' --data-urlencode 'fl[]=date' --data-urlencode 'output=json' |
			jq -r '
				.response.docs[]? |
				"\(.title // .identifier) (\(.date // "n.d."))",
				"  URL: https://archive.org/details/\(.identifier)",
				(if .description then (.description | if type=="array" then join(" ") else . end | gsub("<[^>]+>";"") | .[0:280]) else empty end),
				""
			'
			return 0
			;;

		unpaywall) # no key, but requires an email param per Unpaywall's TOS
			[[ -z "$email" ]] && { echo "ERROR: provider=unpaywall requires MA_WEB_SEARCH_EMAIL to be set"; return 1; }
			local doi="${query#https://doi.org/}"
			local resp http_code body

			resp="$(curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs -w $'\n%{http_code}' "https://api.unpaywall.org/v2/$doi" --data-urlencode "email=$email")"
			http_code="${resp##*$'\n'}"
			body="${resp%$'\n'*}"

			[[ "$http_code" == "404" ]] && { echo "No record found for DOI: $doi"; return 0; }
			[[ "$http_code" != "200" ]] && { echo "ERROR: Unpaywall returned HTTP $http_code for DOI $doi"; return 1; }
			if ! jq -e . >/dev/null 2>&1 <<< "$body"; then echo "ERROR: Unpaywall returned a non-JSON response (possibly rate-limited)"; return 1; fi

			jq -r '
				if .best_oa_location then
					"OA available (\(.oa_status)): \(.best_oa_location.url_for_pdf // .best_oa_location.url)"
				else
					"No open-access location found for this DOI"
				end
			' <<< "$body"
			return 0
			;;
		arxiv)
			if command -v websearch &>/dev/null; then websearch -p arxiv -m "$max_results" -l "${lang}" -s off "$query"; return; fi
			command -v xmllint &>/dev/null || { echo "ERROR: provider=arxiv requires 'websearch' binary or 'xmllint' (neither found)"; return 1; }
			local xml
			xml="$(curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs "http://export.arxiv.org/api/query" \
				--data-urlencode "search_query=all:$query" --data-urlencode "start=0" --data-urlencode "max_results=$max_results")"
			xmllint --xpath '
				/*[local-name()="feed"]/*[local-name()="entry"]/concat(
					*[local-name()="title"], "|||",
					*[local-name()="id"], "|||",
					*[local-name()="published"], "|||",
					string-join(*[local-name()="author"]/*[local-name()="name"], ", ")
				)
			' <<< "$xml" 2>/dev/null | tr -d '\n'
			return 0
			;;
		esac

		# web
		query=${query//\"/}	# ddgr would return no results with quotes on the query
		if command -v ddgr &>/dev/null; then
			ddgr --np -xC --noua "$query" # -n "$max_results" 
		elif command -v websearch &>/dev/null; then
			websearch -p duckduckgo -m "$max_results" -l "${lang}" -s off "$query"
		else
			curl ${MA_WEB_PROXY:-} -m 15 -A "$ua" -Gs 'https://html.duckduckgo.com/html' --data-urlencode "q=$query" | _ddg_parse_html;
		fi
		return
	}




	MA_TOOL[symbols]='
	{
	  "type": "function",
	  "name": "symbols",
	  "description": "Symbols navigation helper for code repo",
	  "parameters": {
		"type": "object",
		"properties": {
		  "action": { "type": "string", "enum": ["definitions", "references", "outline", "search"], "description": "definitions=exact lookup. references=all usages. outline=symbols in one file. search=fuzzy" },
		  "symbol": { "type": "string", "description": "Name to match. search: supports * ? glob, anchored; plain text = substring" },
		  "path": { "type": "string" },
		  "lang": { "type": "string", "description": "File extension, e.g. py, js, rs" },
		  "whole_word": { "type": "boolean", "description": "definitions/references default true (exact). search default false (fuzzy)" },
		  "kinds": { "type": "string", "description": "Comma-separated: function, method, class, variable, type. Default: no filter" },
		  "max_results": { "type": "integer", "description": "Default 50" }
		},
		"required": ["action"]
	  }
	}'

	header_symbols(){
		jq -br '
			"\(.action)" +
			(if .symbol then " \(.symbol)" else "" end) +
			(if .path then " in \(.path)" else "" end) +
			(if .lang then " [lang=\(.lang)]" else "" end) +
			(if .backend and .backend != "auto" then " [backend=\(.backend)]" else "" end) +
			(if .whole_word == false then " [substring]" else "" end) +
			(if .whole_word == true then " [exact]" else "" end) +
			(if .kinds and .kinds != "" then " [kinds=\(.kinds)]" else "" end) +
			(if .max_results and .max_results != 50 then " [n=\(.max_results)]" else "" end)
		' <<< "$1" 2>/dev/null
	}

	bootstrap_symbols() {
		_markov_symcache_dir="${MA_SYMCACHE_DIR:-"/var/tmp/markov/symcache"}"
		mkdir -p "$_markov_symcache_dir" || {
			err "Could not create temporary directory in ${_markov_symcache_dir}\n";
			_markov_symcache_dir="/var/tmp/markov/symcache"
			mkdir -p "$_markov_symcache_dir" || exit 1;
			info "Fallback to ${_markov_symcache_dir}\n";
		}
		_markov_have_ctags=false
		_markov_have_treesitter=false
		_markov_have_rg=false

		command -v rg >/dev/null 2>&1 && _markov_have_rg=true
		if command -v ctags >/dev/null 2>&1 && ctags --version 2>/dev/null | grep -qi 'universal ctags'; then
			_markov_have_ctags=true
		fi
		if command -v tree-sitter >/dev/null 2>&1; then
			_ts_init_paths
			[ "${#_ma_ts_lib_dirs[@]}" -gt 0 ] && _markov_have_treesitter=true
		fi

		_ma_sym_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
		local _root_hash=; _hash_url _root_hash "$_ma_sym_root"
		_ma_ctags_cache_file="$_markov_symcache_dir/${_root_hash}.jsonl"
		_ma_sym_backend=
		[[ -n ${MA_SYMBOLS_BACKEND:-} ]] && {
			case ${MA_SYMBOLS_BACKEND} in
				ctags) [[ $_markov_have_ctags == true ]] && _ma_sym_backend=${MA_SYMBOLS_BACKEND} ;;
				tree-sitter) [[ $_markov_have_treesitter == true ]] && _ma_sym_backend=${MA_SYMBOLS_BACKEND} ;;
				grep) _ma_sym_backend=${MA_SYMBOLS_BACKEND} ;;
			esac
		}

		[[ -z $_ma_sym_backend ]] && {
			if $_markov_have_ctags; then
				_ma_sym_backend='ctags'
			elif $_markov_have_treesitter; then
				_ma_sym_backend='tree-sitter'
			else
				_ma_sym_backend='grep'
			fi
		}
	}

	_CTAGS_KIND_CANON_JSON='{
		"function":"function","func":"function","subroutine":"function",
		"method":"method","singletonMethod":"method",
		"class":"class",
		"member":"variable","field":"variable","property":"variable",
		"variable":"variable","var":"variable","const":"variable","constant":"variable",
		"struct":"type","union":"type","enum":"type","enumerator":"type",
		"typedef":"type","interface":"type","type":"type"
	}'

	_symbols_filelist_at() { # .gitignore-aware if in a git repo; lists files under $1
		local scope="$1"
		if git -C "$_ma_sym_root" rev-parse >/dev/null 2>&1; then
			git -C "$_ma_sym_root" ls-files --cached --others --exclude-standard -- "$scope" 2>/dev/null | sed "s#^#$_ma_sym_root/#"
		else
			find "$scope" -type f \
				\( -path '*/.git/*' -o -path '*/node_modules/*' -o -path '*/vendor/*' \
				   -o -path '*/dist/*' -o -path '*/build/*' -o -path '*/.venv/*' \
				   -o -path '*/venv/*' -o -path '*/__pycache__/*' -o -path '*/target/*' \) -prune -o \
				-type f -print
		fi
	}
	_symbols_filelist() { _symbols_filelist_at "${path:-$_ma_sym_root}"; }

	_symbols_refs(){
		local wflag="-w"; [ "$whole_word" = false ] && wflag=""
		local scope="${path:-$_ma_sym_root}"
		if $_markov_have_rg; then
			local rg_glob_args=()
			[ -n "$lang" ] && rg_glob_args=(-g "*.${lang}")
			rg -n $wflag --no-heading "${rg_glob_args[@]}" -- "$symbol" "$scope" 2>/dev/null | _symbols_finalize
		elif [[ -n "$lang" ]]; then
			_symbols_filelist | grep "\\.${lang}$" | xargs -r grep -nH $wflag -- "$symbol" 2>/dev/null | _symbols_finalize
		else
			grep -rnH $wflag -- "$symbol" "$scope" \
				--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor \
				--exclude-dir=dist --exclude-dir=build --exclude-dir=.venv \
				--exclude-dir=venv --exclude-dir=__pycache__ --exclude-dir=target \
				2>/dev/null | _symbols_finalize
		fi
	}

	_symbols_search_pattern() { # $1: glob (contains * or ?)? used by action=search
		case "$1" in
			*[*?]*) _symbols_search_pattern_result="$1" ;;
			*) _symbols_search_pattern_result="*$1*" ;;
		esac
	}

	_symbols_finalize() { # dedupe + strip root prefix + cap at max_results
		local -a _roots=()
		[[ -n "${_ma_sym_root:-}" ]] && _roots+=("${_ma_sym_root%/}/")
		local _gitroot
		_gitroot="$(git -C "${_ma_sym_root:-.}" rev-parse --show-toplevel 2>/dev/null)"
		[[ -n "$_gitroot" ]] && _roots+=("${_gitroot%/}/")
		[[ -n "${_ma_sym_root:-}" ]] && {
			local _rp
			_rp="$(cd "$_ma_sym_root" 2>/dev/null && pwd -P)"
			[ -n "$_rp" ] && _roots+=("${_rp%/}/")
		}

		awk -v roots="$(printf '%s\n' "${_roots[@]}")" -v max="$max_results" '
			function normpath(s,   d) {
				gsub(/\\/, "/", s)
				if (match(s, /^[A-Za-z]:/)) {
					d = tolower(substr(s, 1, 1))
					s = "/" d substr(s, 3)
				}
				return s
			}
			BEGIN {
				nr = split(roots, R, "\n")
				for (i = 1; i <= nr; i++) R[i] = normpath(R[i])  # normalize once, up front
			}
			function strip_root(s,   i, r, ns, idx) {
				ns = normpath(s)
				for (i = 1; i <= nr; i++) {
					r = R[i]
					if (r == "") continue
					idx = index(ns, r)
					if (idx > 0) return substr(ns, 1, idx - 1) substr(ns, idx + length(r))
				}
				return s
			}
			{
				line = $0
				# only rewrite the file-path portion; never touch trailing
				# content, or backslashes in real code get mangled. Matches
				# ":line:" (definitions/references/outline: path leads) as well as bare
				# ":line" at end-of-string (search: path trails, no colon after
				# the line number since nothing follows it).
				if (match(line, /:[0-9]+(:|$)/)) {
					file = substr(line, 1, RSTART - 1)
					rest = substr(line, RSTART)
					line = strip_root(file) rest
				}
				if (!seen[line]++) {
					print line
					if (++n >= max) exit
				}
			}
		'
	}

	_ctags_build_cache() {
		local lockdir="$_ma_ctags_cache_file.lock"
		local tmp="$_ma_ctags_cache_file.tmp.$$"
		local got_lock=false i=0
		while ! mkdir "$lockdir" 2>/dev/null; do
			i=$((i+1)); [[ "$i" -gt 30 ]] && break
			sleep 0.1
		done
		[ -d "$lockdir" ] && got_lock=true

		_symbols_filelist_at "$_ma_sym_root" | ctags --output-format=json --fields=+n-P -L - -f "$tmp" 2>/dev/null
		if [[ -s "$tmp" ]]; then mv -f "$tmp" "$_ma_ctags_cache_file"; else rm -f "$tmp"; fi

		$got_lock && rmdir "$lockdir" 2>/dev/null
	}


	# tree-sitter dirs for compiled parsers (*.so), and queries/<lang>/locals.scm
	# specify manualy in colon-separated paths, like in $PATH: MA_TS_PARSER_DIR and MA_TS_QUERY_DIR
	# MA_TS_STRICT_PATHS=true to use only the override dirs
	_ts_init_paths() {
		_ma_ts_lib_dirs=()
		_ma_ts_query_dirs=()
		[[ "${MA_TS_STRICT_PATHS:-}" == true ]] && {
			local IFS=':' d
			for d in ${MA_TS_PARSER_DIR:-}; do [ -n "$d" ] && [ -d "$d" ] && _ma_ts_lib_dirs+=("$d"); done
			for d in ${MA_TS_QUERY_DIR:-};  do [ -n "$d" ] && [ -d "$d" ] && _ma_ts_query_dirs+=("$d"); done
			return 0
		}
		local lib_candidates=() query_candidates=()
		case "$(uname -s 2>/dev/null)" in
			Linux*)
				local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
				lib_candidates+=(	"$xdg_data/nvim/site/parser" "$HOME/.tree-sitter/bin"
									"/usr/local/lib/tree-sitter" "/usr/lib/tree-sitter")
				query_candidates+=( "$xdg_data/nvim/site/queries" "$xdg_data/nvim/lazy/nvim-treesitter/queries"
									 "/usr/share/tree-sitter/queries")
				;;
			Darwin*)
				lib_candidates+=(	"$HOME/.local/share/nvim/site/parser" "$HOME/.tree-sitter/bin"
									"/opt/homebrew/lib/tree-sitter" "/usr/local/lib/tree-sitter")
				query_candidates+=( "$HOME/.local/share/nvim/site/queries"
									"$HOME/.local/share/nvim/lazy/nvim-treesitter/queries")
				;;
			MINGW*|MSYS*|CYGWIN*)
				local lad; lad="$(cygpath -u "${LOCALAPPDATA:-}" 2>/dev/null)"
				lib_candidates+=( "$lad/nvim-data/site/parser" "$lad/tree-sitter/lib")
				query_candidates+=( "$lad/nvim-data/site/queries")
				;;
		esac
	 
		[[ -n "${MA_TS_PARSER_DIR:-}" ]] && {
			local IFS=':'; local d
			for d in ${MA_TS_PARSER_DIR:-}; do lib_candidates=("$d" "${lib_candidates[@]}}"); done
		}
		[[ -n ${MA_TS_QUERY_DIR:-} ]] && {
			local IFS=':'; local d
			for d in ${MA_TS_QUERY_DIR:-}; do query_candidates=("$d" "${query_candidates[@]}"); done
		}
	 
		local d seen=""
		for d in "${lib_candidates[@]}"; do
			[[ -n "$d" && -d "$d" ]] || continue
			case ":$seen:" in *":$d:"*) continue ;; esac
			_ma_ts_lib_dirs+=("$d"); seen="$seen:$d"
		done
		seen=""
		for d in "${query_candidates[@]}"; do
			[[ -n "$d" &&  -d "$d" ]] || continue
			case ":$seen:" in *":$d:"*) continue ;; esac
			_ma_ts_query_dirs+=("$d"); seen="$seen:$d"
		done
	}
	 
	_ts_lang_from_ext() {
		case "$1" in
			sh|bash)            _ts_ext_lang="bash" ;;
			c|h)                _ts_ext_lang="c" ;;
			cpp|cc|cxx|hpp|hh)  _ts_ext_lang="cpp" ;;
			py)                 _ts_ext_lang="python" ;;
			js|mjs|cjs|jsx)     _ts_ext_lang="javascript" ;;
			ts)                 _ts_ext_lang="typescript" ;;
			tsx)                _ts_ext_lang="tsx" ;;
			go)                 _ts_ext_lang="go" ;;
			rs)                 _ts_ext_lang="rust" ;;
			rb)                 _ts_ext_lang="ruby" ;;
			java)               _ts_ext_lang="java" ;;
			lua)                _ts_ext_lang="lua" ;;
			md)                 _ts_ext_lang="markdown" ;;
			vim)                _ts_ext_lang="vim" ;;
			json)               _ts_ext_lang="json" ;;
			yaml|yml)           _ts_ext_lang="yaml" ;;
			*)                  _ts_ext_lang="" ;;
		esac
	}
	 
	declare -gA _ts_lib_cache
	declare -gA _ts_query_cache
	_ts_lib() {
		local lang="$1" d
		[[ -n "${_ts_lib_cache[$lang]+x}" ]] && {
			_ts_lib_result="${_ts_lib_cache[$lang]}"
			[[ -n "$_ts_lib_result" ]]
			return
		}
		_ts_lib_result=""
		for d in "${_ma_ts_lib_dirs[@]+"${_ma_ts_lib_dirs[@]}"}"; do
			[[ -f "$d/${lang}.so" ]] && { _ts_lib_result="$d/${lang}.so"; break; }
		done
		_ts_lib_cache[$lang]="$_ts_lib_result"
		[[ -n "$_ts_lib_result" ]]
	}
	_ts_query_file() {
		local lang="$1" name="$2" d
		local key="${lang}:${name}"
		if [[ -n "${_ts_query_cache[$key]+x}" ]]; then
			_ts_query_file_result="${_ts_query_cache[$key]}"
			[[ -n "$_ts_query_file_result" ]]
			return
		fi
		_ts_query_file_result=""
		for d in "${_ma_ts_query_dirs[@]+"${_ma_ts_query_dirs[@]}"}"; do
			[[ -f "$d/$lang/$name.scm" ]] && { _ts_query_file_result="$d/$lang/$name.scm"; break; }
		done
		_ts_query_cache[$key]="$_ts_query_file_result"
		[[ -n "$_ts_query_file_result" ]]
	}


	_ts_query_output_parse() {
		sed -nE 's/.*capture: [0-9]+ - ([a-zA-Z._]*), start: \(([0-9]+),[^)]*\), end: \([0-9]+,[^)]*\), text: `(.*)`/\2\t\1\t\3/p' | sort -n
	}

	_ts_canon_kind() {
		case "$1" in
			function|func|subroutine) _symbols_canon_kind_result=function ;;
			method|singletonMethod)   _symbols_canon_kind_result=method ;;
			class)                    _symbols_canon_kind_result=class ;;
			member|field|property|variable|var|const|constant|parameter)
									   _symbols_canon_kind_result=variable ;;
			struct|union|enum|enumerator|typedef|interface|type)
									   _symbols_canon_kind_result="type" ;;
			*)                         _symbols_canon_kind_result="$1" ;;
		esac
	}

	_ts_defs() {
		local mode="$1"
		local f ext lg lib qf hit_any=false count=0
		local kind_filter="$kinds"
		local cap_budget=$((max_results * 3))
		local -A lg_cache lib_cache qf_cache resolved_bad
		local search_pattern=""
		if [[ "$mode" == search ]]; then
			if [[ "$whole_word" == false ]]; then
				_symbols_search_pattern "$symbol"
				search_pattern="$_symbols_search_pattern_result"
			else
				search_pattern="$symbol"
			fi
		fi

		while IFS= read -r f; do
			[[ -n "$lang" && "$f" != *".${lang}" ]] && continue
			ext="${f##*.}"
			[[ -n "${resolved_bad[$ext]:-}" ]] && continue

			[[ -z "${lg_cache[$ext]:-}" ]] && {
				_ts_lang_from_ext "$ext"; lg="$_ts_ext_lang"
				[[ -z "$lg" ]] && { resolved_bad[$ext]=1; continue; }
				_ts_lib "$lg" || { resolved_bad[$ext]=1; continue; }
				_ts_query_file "$lg" "locals" || { resolved_bad[$ext]=1; continue; }
				lg_cache[$ext]="$lg"; lib_cache[$ext]="$_ts_lib_result"; qf_cache[$ext]="$_ts_query_file_result"
			}
			lg="${lg_cache[$ext]}"; lib="${lib_cache[$ext]}"; qf="${qf_cache[$ext]}"
			hit_any=true

			while IFS=$'\t' read -r ln cap txt; do
				[[ "$cap" == local.definition* ]] || continue
				local kind="${cap#local.definition.}"
				if [[ -n "$kind_filter" ]]; then
					_ts_canon_kind "$kind"
					local ck="$_symbols_canon_kind_result"
					[[ ",${kind_filter}," == *",${kind},"* || ",${kind_filter}," == *",${ck},"* ]] || continue
				fi
				if [[ "$mode" == definitions ]]; then
					if [[ "$whole_word" == false ]]; then
						[[ "$txt" == *"$symbol"* ]] || continue
					else
						[[ "$txt" == "$symbol" ]] || continue
					fi
				else
					shopt -s nocasematch
					if [[ "$txt" != $search_pattern ]]; then shopt -u nocasematch; continue; fi
					shopt -u nocasematch
				fi
				if [[ "$mode" == definitions ]]; then
					echo "$f:$((ln + 1)): [${kind}] $txt"
				else
					echo "$txt [${kind}] : $f:$((ln + 1))"
				fi
				count=$((count + 1))
				[[ "$count" -ge "$cap_budget" ]] && return 0
			done < <(tree-sitter query --lib-path "$lib" --lang-name "$lg" "$qf" "$f" 2>/dev/null | _ts_query_output_parse)

		done < <(_symbols_filelist)

		if ! $hit_any; then
			local dirs_str="none"
			(( "${#_ma_ts_lib_dirs[@]}" > 0 )) && dirs_str="${_ma_ts_lib_dirs[*]}"
			echo "NOTE: no tree-sitter parser+locals.scm available for the matched files; results may be incomplete. Parser dirs searched: $dirs_str"
		fi
	}

	_ts_outline() {
		local ext lg lib qf
		ext="${path##*.}"
		_ts_lang_from_ext "$ext"; lg="$_ts_ext_lang"
		if [[ -z "$lg" ]]; then
			echo "ERROR: no known tree-sitter language mapped for .$ext files"
			return 1
		fi
		_ts_lib "$lg" || {
			local dirs_str="none"
			(( "${#_ma_ts_lib_dirs[@]}" > 0 )) && dirs_str="${_ma_ts_lib_dirs[*]}"
			echo "ERROR: no tree-sitter parser installed for '$lg' (searched: $dirs_str)"
			return 1
		}
		lib="$_ts_lib_result"
		_ts_query_file "$lg" "locals" || {
			local dirs_str="none"
			(( "${#_ma_ts_query_dirs[@]}" > 0 )) && dirs_str="${_ma_ts_query_dirs[*]}"
			echo "ERROR: no locals.scm query found for '$lg' (searched: $dirs_str)"
			return 1
		}
		qf="$_ts_query_file_result"

		tree-sitter query --lib-path "$lib" --lang-name "$lg" "$qf" "$path" 2>/dev/null \
			| _ts_query_output_parse \
			| awk -F'\t' -v kinds="$kinds" '
				function canon(k) {
					if (k=="function"||k=="func"||k=="subroutine") return "function"
					if (k=="method"||k=="singletonMethod") return "method"
					if (k=="class") return "class"
					if (k=="member"||k=="field"||k=="property"||k=="variable"||k=="var"||k=="const"||k=="constant"||k=="parameter") return "variable"
					if (k=="struct"||k=="union"||k=="enum"||k=="enumerator"||k=="typedef"||k=="interface"||k=="type") return "type"
					return k
				}
				BEGIN {
					n = split(kinds, ks, ",")
					for (i = 1; i <= n; i++) allow[ks[i]] = 1
					hasFilter = (kinds != "")
				}
				$2 ~ /^local\.definition\./ {
					kind = $2
					sub(/^local\.definition\./, "", kind)
					if (hasFilter && !(kind in allow) && !(canon(kind) in allow)) next
					line = $1 + 1
					key = line SUBSEP kind
					if (!(key in seen)) { order[++cnt] = key; seen[key] = 1; klines[key] = line; kkinds[key] = kind }
					if (index("," names[key] ",", "," $3 ",") == 0) {
						names[key] = names[key] (names[key] == "" ? "" : ", ") $3
					}
				}
				END {
					for (i = 1; i <= cnt; i++) {
						k = order[i]
						printf "%s: [%s] %s\n", klines[k], kkinds[k], names[k]
					}
				}
			' \
			| _symbols_finalize
	}

	execute_symbols() {

		local action symbol path lang whole_word max_results kinds
		{
			IFS= read -r -d '' action
			IFS= read -r -d '' symbol
			IFS= read -r -d '' path
			IFS= read -r -d '' lang
			IFS= read -r -d '' whole_word
			IFS= read -r -d '' max_results
			IFS= read -r -d '' kinds
		} < <( jq -jr '
				.action, "\u0000",
				(.symbol // ""), "\u0000",
				(.path // ""), "\u0000",
				(.lang // ""), "\u0000",
				(if .whole_word == null then "" elif .whole_word == false then "false" else "true" end), "\u0000",
				(.max_results // 50), "\u0000",
				(.kinds // ""), "\u0000"
			' <<< "$1")


		if [[ "${MA_CONFINE:-}" == true ]] && is_path_out_of_confinement "$path"; then
			err "DENIED: confinement in working directory is enabled.\n"
			echo "DENIED: path '$path' is outside the working directory ($MA_WORKING_DIR)"; 
			return 1;
		fi

		local lang_filter=""; [[ -n "$lang" ]] && lang_filter="\\.${lang}$"

		[[ -z "$whole_word" ]] && {
			[[ "$action" == search ]] && whole_word=false || whole_word=true
		}

		case "$action" in
			definitions|search) [[ "$_ma_sym_backend" == ctags ]] && _ctags_build_cache; ;;
		esac

		case $action in
			definitions|references|search)
				[[ -z "$symbol" ]] && { echo "ERROR: symbol is required for action=${action}"; return 1; }
				;;
			outline)
				[[ -z "$path" ]] && { echo "ERROR: path is required for action=outline"; return 1; }
				[[ ! -f "$path" ]] && { echo "ERROR: file not found: $path"; return 1; }
				;;
			*) echo "ERROR: unknown action '$action'"; return 1 ;;
		esac

		case "$_ma_sym_backend" in
			ctags)
				case $action in
					definitions)
						local _out
						_out="$(jq -r --arg s "$symbol" --arg lf "$lang_filter" --arg kinds "$kinds" --arg ww "$whole_word" --argjson kindmap "$_CTAGS_KIND_CANON_JSON" '
							select(._type == "tag")
							| select(if $ww == "false" then (.name | contains($s)) else .name == $s end)
							| select($lf == "" or (.path | test($lf)))
							| (.kind // "symbol") as $rawkind
							| ($kindmap[$rawkind] // $rawkind) as $ck
							| select($kinds == "" or (($kinds | split(",")) as $want | (($want|index($ck)) or ($want|index($rawkind)))))
							| "\(.path):\(.line): [\($rawkind)] \(.name)" + (if .scope then " (in \(.scope))" else "" end)
						' "$_ma_ctags_cache_file")"
						if [[ -n "$_out" ]]; then
							printf '%s\n' "$_out" | _symbols_finalize
						elif [[ -n "$kinds" ]]; then
							local _anykind
							_anykind="$(jq -r --arg s "$symbol" --arg lf "$lang_filter" --arg ww "$whole_word" '
								select(._type == "tag")
								| select(if $ww == "false" then (.name | contains($s)) else .name == $s end)
								| select($lf == "" or (.path | test($lf)))
								| .kind
							' "$_ma_ctags_cache_file" | head -1)"
							[[ -n "$_anykind" ]] && echo "NOTE: '$symbol' exists but not with kinds=$kinds (its kind is: $_anykind)"
						fi
						;;
					references) _symbols_refs ;;
					outline)
						ctags --output-format=json --fields=+n-P -f - "$path" 2>/dev/null \
							| jq -s -r --arg kinds "$kinds" --argjson kindmap "$_CTAGS_KIND_CANON_JSON" '
								[ .[] | select(._type=="tag") ]
								| ( if $kinds == "" then . else
									  [ .[] | select((.kind // "") as $k | ($kindmap[$k] // $k) as $ck |
											  ($kinds | split(",")) as $want | (($want|index($ck)) or ($want|index($k)))) ]
									end )
								| sort_by(.line)
								| group_by(.line)[]
								| group_by(.kind)[]
								| "\(.[0].line): [\(.[0].kind // "symbol")] " + ([.[].name] | unique | join(", "))
							' \
							| _symbols_finalize
						;;
					search)
						local pattern
						if [[ "$whole_word" == false ]]; then
							_symbols_search_pattern "$symbol"
							pattern="$_symbols_search_pattern_result"
						else
							pattern="$symbol"
						fi
						jq -r --arg kinds "$kinds" --argjson kindmap "$_CTAGS_KIND_CANON_JSON" '
							select(._type == "tag")
							| (.kind // "symbol") as $rawkind
							| ($kindmap[$rawkind] // $rawkind) as $ck
							| select($kinds == "" or (($kinds | split(",")) as $want | (($want|index($ck)) or ($want|index($rawkind)))))
							| "\(.name)\t\($rawkind)\t\(.path)\t\(.line)"
						' "$_ma_ctags_cache_file" \
						| { shopt -s nocasematch
							while IFS=$'\t' read -r name kind fpath fline; do
								[[ "$name" == $pattern ]] && echo "$name [$kind] : $fpath:$fline"
							done
							shopt -u nocasematch
						  } | sort -u | _symbols_finalize
						;;
				esac
				;;
			tree-sitter)
				case $action in
					definitions) _ts_defs definitions | _symbols_finalize ;;
					references) _symbols_refs ;;
					outline) _ts_outline ;;
					search) _ts_defs search | _symbols_finalize ;;
				esac
				;;
			grep)
				case $action in
					definitions) echo "ERROR: no ctags/tree-sitter available. Only references supported" ;;
					references) _symbols_refs ;;
					outline) echo "ERROR: no ctags/tree-sitter available. Only references supported" ;;
					search)
						echo "WARNING: no ctags/tree-sitter available: search not supported, falling back to references:"
						local whole_word=false
						_symbols_refs
						;;
				esac
		esac

		return 0
	}




	# Skills tool
	declare -gA MA_SKILLS_DESCR=()
	declare -gA MA_SKILLS_FILES=()
	if [[ ${MA_USE_SKILLS:-} != false ]]; then
		local skill_catalog=
		local _skill_dirs=("$MA_CONFIG_DIR/skills")
		[[ -n ${MA_SKILLS_DIR:-} ]] && _skill_dirs+=("${MA_SKILLS_DIR}")
		[[ "${MA_TRUST_DIR:-}" == "true" ]] && _skill_dirs=("./.markov/skills" "${_skill_dirs[@]}")
		shopt -s nullglob
		local dir s_dir s_name s_desc s_desc_raw line rest _md_in_desc _md_disable _fm_count
		for dir in "${_skill_dirs[@]}"; do
			if [[ -d "$dir" ]]; then
				for s_dir in "$dir"/*; do
					if [[ -d "$s_dir" && -f "$s_dir/SKILL.md" ]]; then
						s_name="${s_dir##*/}"
						if [[ "$skill_catalog" != *" - ${s_name} :"* ]]; then
							s_desc_raw=
							_md_in_desc=0
							_md_disable=false
							_fm_count=0
							while IFS= read -r line || [[ -n $line ]]; do
								line="${line%$'\r'}"
								[[ $line == "---"* ]] && {
									((_fm_count++))
									[[ $_fm_count -ge 2 ]] && break
									continue
								}
								[[ $_md_in_desc -eq 1 ]] && {
									if [[ $line =~ ^[A-Za-z0-9_-]+: ]]; then
										_md_in_desc=0
									else
										s_desc_raw+="${line}"$'\n'
										continue
									fi
								}
								[[ $line =~ ^description:[[:space:]]*(.*)$ ]] && {
									rest="${BASH_REMATCH[1]}"
									rest="${rest%$'\r'}"
									if [[ $rest == ">"* || $rest == "|"* ]]; then
										s_desc_raw=
									else
										s_desc_raw="${rest}"$'\n'
									fi
									_md_in_desc=1
									continue
								}
								[[ $line =~ disable-model-invocation:[[:space:]]*true ]] && _md_disable=true
							done < "$s_dir/SKILL.md"
							MA_SKILLS_FILES["${s_name}"]="$s_dir/SKILL.md"
							MA_SKILLS_DESCR["${s_name}"]="${s_desc_raw:-}"
							[[ $_md_disable == true ]] && continue
							[[ -n "$s_desc_raw" ]] && skill_catalog+=" - ${s_name} : ${s_desc_raw}"$'\n'
						fi
					fi
				done
			fi
		done
		shopt -u nullglob

		skill_catalog=$'Skills:\n'"$skill_catalog"' - any specified by user manually (user may say load <name>)'
		MA_TOOL[skills]=$(jq -bn \
			--arg desc "Activate or disable a skill. Use a skill by name when the task matches its description. User may explicitly request a skill by name.${skill_catalog}" \
			'{
				type: "function",
				name: "skills",
				description: $desc,
				parameters: {
					type: "object",
					properties: {
						name: { type: "string" },
						active: { type: "boolean" },
						args: { type: "string", description: "Optional modifiers" }
					},
					required: ["name","active"]
				}
			}')

		header_skills(){
			local skill_name skill_args active
			{
				IFS= read -r -d '' skill_name
				IFS= read -r -d '' active
				IFS= read -r -d '' skill_args
			} < <(
				jq -jrb '(.name // ""), "\u0000", (.active // false), "\u0000", (.args // ""), "\u0000"' <<< "$1" 2>/dev/null
			)

			if [[ $active != true ]]; then
				[[ ${MA_TOOL_IS_REPRINTING:-} != true ]] && unset 'MA_ACTIVE_SKILLS["$skill_name"]'
				printf '%s (disabled)\n' "$skill_name"
			else
				[[ ${MA_TOOL_IS_REPRINTING:-} != true ]] && MA_ACTIVE_SKILLS["$skill_name"]=1
				printf '%s %s\n' "$skill_name" "$skill_args"
			fi
		}

		execute_skills() {
			local skill_name skill_args active
			{
				IFS= read -r -d '' skill_name
				IFS= read -r -d '' active
				IFS= read -r -d '' skill_args
			} < <(
				jq -jrb '(.name // ""), "\u0000", (.active // false), "\u0000", (.args // ""), "\u0000"' <<< "$1" 2>/dev/null
			)
			[[ -z "$skill_name" ]] && { echo "ERROR: Skill name parameter cannot be empty."; return 1; }
			local skill_content=
			if [[ $active != true ]]; then
				printf '%s\n' "Skill \"$skill_name\" is now DISABLED"
			else
				if ma_skill_load skill_content "$skill_name" "$skill_args"; then
					printf '%s' "$skill_content"
				else
					echo "ERROR: Skill '$skill_name' could not be found on skills directories"
				fi
			fi
		}

		MA_TOOL_DISPLAY_OUTPUT[skills]=false 

	fi


	MA_TOOL[ask]='
	{
		"type": "function",
		"name": "ask",
		"description": "Use this to ask the user multiple questions. It makes responding easier from the terminal",
		"parameters": {
			"type": "object",
			"properties": { "questions": { "type": "array", "items": { "type": "string" } } },
			"required": [ "questions" ]
		}
	}'
	header_ask() { printf "Asking questions\n"; }
	execute_ask() {
		local -a questions=()
		local val
		while IFS= read -r -d '' val; do
			questions+=("$val")
		done < <(
			jq -jer '
				(.questions // [])
				| .[]
				| select(type == "string" and length > 0)
				| ., "\u0000"
			' <<<"$1"
		)
		if (( ${#questions[@]} == 0 )); then echo 'ERROR: No valid questions found arguments'; return 1; fi

		if tty -s </dev/tty 2>/dev/null; then
			stty echo </dev/tty 2>/dev/null; printf "${A_CURSOR_ON}" >&2 >/dev/tty;
			trap 'stty -echo </dev/tty 2>/dev/null; printf "${A_CURSOR_OFF}" >&2 >/dev/tty; trap - RETURN' RETURN
		fi

		local -a answers=()
		local q answer n=1
		for q in "${questions[@]}"; do
			printf '%s\n' "$q"
			printf "\n${A_RESP}${A_B}•${A_R} ${A_RESP}%s\n" "$q" >/dev/tty
			if ! IFS= read -r -p '' answer </dev/tty; then
				answers+=("$answer")
				break
			fi
			answers+=("$answer")
			printf 'Answer: %s\n\n' "$answer"
			(( ++n ))
		done
	}
	MA_TOOL_DISPLAY_OUTPUT[ask]=false 


	MA_TOOL[grep]='
	{
	  "type": "function",
		"name": "grep",
	   	"description": "Search files",
		"parameters": {
		  "type": "object",
		  "properties": {
			"path": { "type": "string" },
			"pattern": { "type": "string", "description": "POSIX ERE regex" },
			"show_content": { "type": "boolean", "description": "Show line contents. Default false" }
		  },
		  "required": [ "pattern" ]
		}
	}'

	header_grep() { jq -r '"\(.pattern // "") in \(.path // ".")"'  <<< "$1" 2>/dev/null ; }

	execute_grep() {
		local pattern path show_content
		{
			IFS= read -r -d '' pattern
			IFS= read -r -d '' path
			IFS= read -r -d '' show_content
		} < <(jq -jrb '(.pattern // ""), "\u0000", (.path // "."), "\u0000", (if .show_content then "1" else "0" end), "\u0000"' <<< "$1")


		[[ ! -d "$path" && ! -f "$path" ]] && { echo "ERROR: Path not found: $path"; return 1; }

		if [[ "${MA_CONFINE:-}" == true ]] && is_path_out_of_confinement "$path"; then
			err "DENIED: confinement in working directory is enabled.\n"
			echo "DENIED: path '$path' is outside the working directory ($MA_WORKING_DIR)"; 
			return 1;
		fi

		local MA_GREP_MAX_LINES=${MA_GREP_MAX_LINES:-300}
		local out n_lines

		if [[ "$show_content" == "1" ]]; then
			out="$( grep -rn -I -E -e "$pattern" "$path" --color=never 2>/dev/null || true)"
		else
			out="$(grep -rn -I -E -e "$pattern" "$path" --color=never 2>/dev/null | awk -F: -v max="$MA_GREP_MAX_LINES" '
				NR > max {
					truncated = 1
					exit
				}
				{
					if ($1 != prev && NR > 1)
						printf "\n"

					if ($1 != prev)
						printf "%s:%s", $1, $2
					else
						printf ",%s", $2

					prev = $1
				}
				END {
					if (NR > 0)
						printf "\n"
					if (truncated)
						printf "[TRUNCATED: showing first %d matches]\n", max
				}')"
		fi
		n_lines="$(printf '%s' "$out" | wc -l)"
		if (( n_lines > MA_GREP_MAX_LINES )); then
			printf '%s\n' "$out" | head -n "$MA_GREP_MAX_LINES"
			echo "[TRUNCATED: showing $MA_GREP_MAX_LINES of $n_lines lines]"
		else
			printf '%s\n' "$out"
		fi
	}





	MA_TOOL[find]='
	{
	  "type": "function",
		"name": "find",
		"description": "Find files/directories",
		"parameters": {
		  "type": "object",
		  "properties": {
			"path": { "type": "string" },
			"name": { "type": "string", "description": "Glob pattern" },
			"type": { "type": "string", "description": "f=file, d=dir" },
			"max_depth": { "type": "integer" }
		  }
		}
	}'


	header_find() { jq -r '"\(.name // "*") in \(.path // ".")\(if .type then " [type=\(.type)]" else "" end)\(if .max_depth then " [depth=\(.max_depth)]" else "" end)"' <<< "$1" 2>/dev/null ;}

	execute_find() {
		local path name type max_depth
		{
			IFS= read -r -d '' path
			IFS= read -r -d '' name
			IFS= read -r -d '' type
			IFS= read -r -d '' max_depth
		} < <(jq -jr '(.path // "."), "\u0000", (.name // ""), "\u0000", (.type // ""), "\u0000", (.max_depth // ""), "\u0000"' <<< "$1")
		[[ ! -d "$path" ]] && { echo "ERROR: Directory not found: $path"; return 1; }
		if [[ "${MA_CONFINE:-}" == true ]] && is_path_out_of_confinement "$path"; then
			err "DENIED: confinement in working directory is enabled.\n"
			echo "DENIED: path '$path' is outside the working directory ($MA_WORKING_DIR)"; 
			return 1;
		fi

		local cmd=(find "$path")
		[[ -n "$max_depth" ]] && cmd+=(-maxdepth "$max_depth")
		cmd+=(
			\(
				-path '*/.git' -o
				-path '*/node_modules' -o
				-path '*/.cache' -o
				-path '*/__pycache__' -o
				-path '*/.venv' -o
				-path '*/venv'
			\) -prune
			-o
		)
		[[ -n "$type" ]] && cmd+=(-type "$type")
		[[ -n "$name" ]] && cmd+=(-name "$name")
		cmd+=(-print)
		MA_FIND_MAX_LINES=${MA_FIND_MAX_LINES:-400}
		local out
		out="$("${cmd[@]}" 2>/dev/null | sort)"
		local n_lines
		n_lines="$(printf '%s\n' "$out" | wc -l)"
		if (( n_lines > MA_FIND_MAX_LINES )); then
			printf '%s\n' "$out" | head -n "$MA_FIND_MAX_LINES"
			echo "[TRUNCATED: showing $MA_FIND_MAX_LINES of $n_lines paths]"
		else
			printf '%s\n' "$out"
		fi
	}


	MA_TOOL[ls]='
	{
	  "type": "function",
		"name": "ls",
		"description": "List directory contents",
		"parameters": {
		  "type": "object",
		  "properties": {
			"path": { "type": "string" },
			"long": { "type": "boolean" }
		  }
		}
	}'

	header_ls(){ jq -r '.path // "."' <<< "$1" 2>/dev/null ; }

	execute_ls() {
		local path long_flag
		{
			IFS= read -r -d '' path
			IFS= read -r -d '' long_flag
		} < <(jq -jrb '(if .path == null or .path == "" then "." else .path end), "\u0000", (.long // false | tostring), "\u0000"' <<< "$1")


		if [[ "${MA_CONFINE:-}" == true ]] && is_path_out_of_confinement "$path"; then
			err "DENIED: confinement in working directory is enabled.\n"
			echo "DENIED: path '$path' is outside the working directory ($MA_WORKING_DIR)"; 
			return 1;
		fi

		local out
		if [[ "$long_flag" == "true" ]]; then
			out="$(find "${path}" -maxdepth 1 -mindepth 1 -printf '%y %TY-%Tm-%Td %TH:%TM %s %f\n')"
		else
			out="$(ls -1AXF "${path}")"	#out="$(find "${path}" -maxdepth 1 -mindepth 1 -printf '%y %f\n')"
		fi
		local n_lines
		local MA_LS_MAX_LINES=${MA_LS_MAX_LINES:-400}
		n_lines="$(printf '%s\n' "$out" | wc -l)"
		if (( n_lines > MA_LS_MAX_LINES )); then
			printf '%s\n' "$out" | head -n "$MA_LS_MAX_LINES"
			echo "[TRUNCATED: showing $MA_LS_MAX_LINES of $n_lines paths]"
		else
			printf '%s\n' "$out"
		fi
	}


	MA_TOOL[search]='
	{
		"type": "function",
		"name": "search",
		"description": "Discover available tools and their parameters",
		"parameters": {
			"type": "object",
			"properties": {
				"tools": {
					"type": "array",
					"items": { "type": "string" },
					"description": "Tool names or glob patterns to search for"
				}
			}
		}
	}'
	header_search()
	{
		local t
		t=$(jq -br '[(.tools[]? | strings)] | join(",")' <<< "$1" 2>/dev/null)
		printf 'search(%s)\n' "${t:-*}"
	}

	execute_search() {
		[[ -z ${MA_LAZY_TOOLS[*]+x} ]] && { echo "No tools available"; return 1; }
		MA_SEARCH_MAX_RESULTS=${MA_SEARCH_MAX_RESULTS:-20}

		local -a patterns
		mapfile -t patterns < <(jq -br '.tools[]? | strings' <<< "${1:-"{}"}" 2>/dev/null)
		(( ${#patterns[@]} == 0 )) && patterns=("*")

		local -a sorted_names
		mapfile -t sorted_names < <(printf '%s\n' "${!MA_LAZY_TOOLS[@]}" | sort)

		local -a pairs=()
		local tname pattern schema total_matched=0
		for tname in "${sorted_names[@]}"; do
			schema="${MA_TOOL[$tname]-}"
			[[ -n "$tname" && -n "$schema" ]] || continue
			for pattern in "${patterns[@]}"; do
				[[ "$tname" == $pattern ]] || continue
				(( total_matched++ ))
				(( total_matched <= MA_SEARCH_MAX_RESULTS )) && pairs+=("$tname" "$schema")
				break
			done
		done

		(( total_matched == 0 )) && { echo "No tools matched (${#MA_LAZY_TOOLS[@]} available)"; return 1; }

		printf '%s\0' "${pairs[@]}" | jq -bRrs '
			split("\u0000") as $p
			| [range(0; ($p|length)-1; 2) as $i
				| {name: $p[$i], schema: ($p[$i+1] | fromjson? // {})}]
			| .[]
			| "[\(.name)]\nDescription: \(.schema.description // "No description")\nParameters: \((.schema.parameters // {}) | tostring)\n"
		'

		(( total_matched > MA_SEARCH_MAX_RESULTS )) && \
			printf '\n... %d more tools matched but were omitted. Narrow your search to see them\n' "$(( total_matched - MA_SEARCH_MAX_RESULTS ))"

		return 0
	}



	MA_TOOL[docs]=' { "type": "function", "name": "docs", "description": "Print Markov Documentation" }'
	header_docs() { ma_init_docs; printf "reading markov documentation\n" >&2; }
	execute_docs() { 
		printf '%s\n' "$MA_DOCS"; 
		printf 'Current Configuration Paths:\n'
		printf 'Markov path:   %s\n' "$MA_MARKOV_PATH"
		printf 'Config dir:    %s\n' "$MA_CONFIG_DIR"
		printf 'Modules dir:   %s\n' "$MA_MODULES_DIR"
		printf 'Skills dir:    %s\n' "$MA_SKILLS_DIR"
		printf 'Prompts dir:   %s\n' "$MA_PROMPTS_DIR"
		printf 'Personas dir:  %s\n' "$MA_PERSONAS_DIR"
	}

	MA_TOOL_DISPLAY_OUTPUT[docs]=false 
	[[ ${MA_USE_LAZY_DOCS:-} != false ]] && MA_LAZY_TOOLS[docs]=1

	local docs_exe_msg='.\nUse function=\"docs\" to read markov documentation if user needs help to extend the harness'

	MA_TOOL[reload]=' { "type": "function", "name": "reload", "description": "Reload the context files, configuration, and modules used by the Markov harness. Useful for applying changes immediately" }'
	header_reload() { printf "(scheduled for next turn)\n" >&2; MA_TRIGGER_RELOAD=true; }
	execute_reload() { echo 'Reload applied'; }
	local reload_exe_msg=
	MA_TOOL_DISPLAY_OUTPUT[reload]=false 
	[[ ${MA_USE_LAZY_RELOAD:-} != false ]] && {
		reload_exe_msg='. Use function=\"reload\" to reload context files, configuration, and modules used by the Markov harness, applying any changes immediately'
	   	MA_LAZY_TOOLS[reload]=1; 
	}

	MA_TOOL[execute]='
	{
		"type": "function",
		"name": "execute",
		"description": "Call any other tool by name.\\nUse function=\"search\" with params={\"tools\":[\"name1\",...]} to discover new tools and their parameters, with glob pattern support'${docs_exe_msg}${reload_exe_msg}'",
		"parameters": {
			"type": "object",
			"properties": {
				"function": { "type": "string" },
				"params": { "type": "string", "description": "JSON string of arguments for the target tool" }
			},
			"required": ["function"]
		}
	}'

	header_execute() {
		local func= params=
		{
			IFS= read -r -d '' func;
			IFS= read -r -d '' params; 
		} < <( jq -jb '
				(.function // ""), "\u0000",
				(if (.params | type) == "string"
					then (.params // "" | if length then . else "{}" end)
					else (.params // {} | tostring)
				end), "\u0000"
			' <<< "$1" 2>/dev/null) || { printf '\n'; return 0; }
		printf "%s" "${A_TOOL_NAME}[${func}] ${A_TOOL_HEAD}"
		if declare -F "header_${func}" >/dev/null; then "header_${func}" "$params"; else printf '\n'; fi
	}

    execute_execute() {
        local func params
        { 
            IFS= read -r -d '' func;
            IFS= read -r -d '' params; 
		} < <(jq -jb '
				(.function // ""), "\u0000",
				(if (.params | type) == "string"
					then (.params // "" | if length then . else "{}" end)
					else (.params // {} | tostring)
				end), "\u0000"
				' <<< "$1" 2>/dev/null) || { echo "ERROR: Failed to parse arguments"; return 1; }
        [[ -z "$func" ]] && { echo "ERROR: Missing 'function'"; return 1; }
		case $func in
			execute) echo "ERROR: calling 'execute' tool recursively is not allowed"; return 1 ;;
			search) execute_search "$params"; return ;;
			docs) execute_docs "$params"; return;; # always in execute descr, so always callable
			*)
				[[ -v 'MA_LAZY_TOOLS[$func]' || -v 'MA_ROLE_TOOLS[$func]' ]] || {
					echo "ERROR: '$func' is not a valid function to call"; return 1; 
				}
				if declare -F "execute_${func}" >/dev/null; then
					"execute_${func}" "$params";
				else
				   	echo "ERROR: Unknown tool $func"; 
					return 1;
				fi
			;;
			esac
    }
	MA_TOOL_DISPLAY_OUTPUT[execute]=false 


	_builtin_delegate_schema() {
		local -a _delegate_roles=()
		_collect_quoted_from_suffixes _delegate_roles delegate_role_
		local r
		for r in "${_delegate_roles[@]}"; do r=${r//\"/}; MA_DELEGATE_ROLES+=($r); MA_ROLES[$r]=delegate_role_$r; done

		local role_prop=""
		(( ${#_delegate_roles[@]} > 1 )) && {
			local enum_json
			printf -v enum_json '%s,' "${_delegate_roles[@]}"
			enum_json=${enum_json%,}
			local role_descr="" r_clean desc
			for r in "${_delegate_roles[@]}"; do
				r_clean=${r//\"/}
				local -n _rd="delegate_role_${r_clean}" 2>/dev/null
				desc="${_rd[description]:-}"
				[[ -n $desc ]] && role_descr+="${r_clean}: ${desc}"$'\n'
			done
			local role_descr_json
			if [[ -n "$role_descr" ]]; then
				role_descr_json="$(jq -n --arg s "${role_descr%$'\n'}" '$s')"
				role_prop="\"role\": { \"type\": \"string\", \"enum\": [${enum_json}], \"description\": ${role_descr_json} },"
			else
				role_prop="\"role\": { \"type\": \"string\", \"enum\": [${enum_json}] },"
			fi
		}

		local final_prop=
		[[ ${MA_DELEGATE_USE_SMART_RETURN:-} != false ]] && {
		   	final_prop='"final": { "type": "boolean", "description": "Return result directly to the user. Set to true when there is no need to invoke you after the task completes successfully" },'
		}

		MA_TOOL["delegate"]='
		{
			"type": "function",
			"name": "delegate",
			"description": "Delegate a self-contained task to a sub-agent. Use when the task needs iteration or tool use that would pollute main context",
			"parameters": {
				"type": "object",
				"properties": {
					'"$role_prop"'
					'"$final_prop"'
					"summary": { "type": "string", "description": "One-sentence task summary for UI display" },
					"task": { "type": "string", "description": "Complete, self-contained task. Write as if briefing someone with zero prior context" }
				},
				"required": ["summary", "task"]
			}
		}'
	}

	_builtin_delegate_schema

	header_delegate() {
		local task role final summary
		{
			IFS= read -r -d '' task 
			IFS= read -r -d '' final
			IFS= read -r -d '' role
			IFS= read -r -d '' summary
		} < <(jq -jbr '.task, "\u0000", 
					 (.final // ""), "\u0000",
					 (.role // ""), "\u0000",
					 (.summary // ""), "\u0000"' <<< "$1")
		(( ${#MA_DELEGATE_ROLES[@]} == 0 )) && role=inherit
		(( ${#MA_DELEGATE_ROLES[@]} == 1 )) && role="${MA_DELEGATE_ROLES[0]}"
		printf "${A_INFO}(%s)${A_RESP}${A_I} %s\n" "${role:-inherit}" "$summary"
	}

	execute_delegate() { echo 'ERROR: cannot delegate'; }

	_execute_delegate() {
		local task role final summary
		{
			IFS= read -r -d '' task 
			IFS= read -r -d '' final
			IFS= read -r -d '' role
			IFS= read -r -d '' summary
		} < <(jq -jbr '.task, "\u0000", 
					 (.final // ""), "\u0000",
					 (.role // ""), "\u0000",
					 (.summary // ""), "\u0000"' <<< "$1")
		local call_id="$2" parent_thread=$MA_THREAD_NAME

		local uppest=$MA_THREAD_NAME
		local n_parents=0
		meta_thread_get_uppest uppest "$MA_THREAD_NAME" n_parents

		local _thread_id; ma_uid _thread_id
		local new_name="${uppest}_sub_${_thread_id}"


		(( ${#MA_DELEGATE_ROLES[@]} == 0 )) && role="main"
		(( ${#MA_DELEGATE_ROLES[@]} == 1 )) && role="${MA_DELEGATE_ROLES[0]:-}"

		[[ ${MA_DELEGATE_USE_NOTES:-} != false ]] && {
			local notes_file="${_ma_notes_dir}/task-${_thread_id}.md"
			rm -f "${_ma_notes_dir}/task-${_thread_id}.md"
		}

		doc_thread_fresh "$new_name" false "$role" $(( n_parents + 1 ))

		local thread_role thread_parent thread_child
		meta_threads_unpack "$parent_thread" thread_role thread_parent thread_child
		meta_threads_pack "$parent_thread" "$thread_role" "$thread_parent" "$new_name"
		local sub_role sub_parent sub_child
		meta_threads_unpack $new_name sub_role sub_parent sub_child
		meta_threads_pack "$new_name" "$sub_role" "$parent_thread" ""
		thread_add_msg MA_THREAD_JSON "user" "${task}${MA_SUBMIT_MSG}"

		[[ $final == true ]] && MA_DELEGATED["${MA_THREAD_NAME}@final"]=$final
		MA_DELEGATED["${MA_THREAD_NAME}@call_id"]=$call_id
		MA_DELEGATED["${MA_THREAD_NAME}@task"]=$task
		MA_DELEGATED["${MA_THREAD_NAME}@snip"]=$summary
	}


	MA_TOOL[submit]='
	{
	    "type": "function",
		"name": "submit",
		"description": "Submit the final task result. Call this to finish the task",
		"parameters": {
			"type": "object",
			"properties": {
				"result": { "type": "string", "description": "Complete task result. Shown to the user" },
				"status": { "type": "string", "enum": ["completed", "partial", "aborted"] },
				"confidence": { "type": "integer", "description": "Confidence 0-100" },
				"files": { "type": "string", "description": "List each file created, modified, or deleted in the project dir. Explicitly state if created, modified, or deleted" },
				"verification": { "type": "string", "description": "Checks run to verify the result" },
				"caveats": { "type": "string", "description": "Important limitations only" }
			},
			"required": ["result", "status", "confidence"],
			"additionalProperties": false
		}
	}'


	header_submit() {
		local result status confidence files verification caveats
		{
			IFS= read -r -d '' result
			IFS= read -r -d '' status
			IFS= read -r -d '' confidence
			IFS= read -r -d '' files
			IFS= read -r -d '' verification
			IFS= read -r -d '' caveats
		} < <(jq -jbr '
			(.result // "[unknown]"), "\u0000",
			(.status // "aborted"), "\u0000",
			(.confidence // 0), "\u0000",
			(.files // ""), "\u0000",
			(.verification // ""), "\u0000",
			(.caveats // ""), "\u0000"
		' <<< "$1")
		printf "Task %s ${A_INFO}(%s%%)\n" "$status" "$confidence"
	}

	execute_submit() { echo "OK: Submitted"; }
	MA_TOOL_DISPLAY_OUTPUT[submit]=false 
	MA_TOOL_DISPLAY_NAME[submit]=false 

	_has_content() { local v=${1,,}; v=${v%.}; [[ -n $v && $v != none && $v != n/a ]]; }
	_submit_build_result() { # 1:out_var(ref) 2:status 3:confidence 4:result 5:caveats 6:verification 7:files 8:thread_id
		local -n _bfr_out=$1
		local _bfr_status=$2 _bfr_conf=$3 _bfr_result=$4
		local _bfr_caveats=$5 _bfr_verif=$6 _bfr_files=$7 _bfr_tid=$8
		[[ $_bfr_status != complete* ]] || (( _bfr_conf < 100 )) && {
			_bfr_out="Status: $_bfr_status (confidence $_bfr_conf%)"$'\n\n'
		}
		_bfr_out+="$_bfr_result"
		_has_content "$_bfr_caveats" && _bfr_out+=$'\n'"Caveats: $_bfr_caveats"
		_has_content "$_bfr_verif"   && _bfr_out+=$'\n'"Verification: $_bfr_verif"
		_has_content "$_bfr_files"   && _bfr_out+=$'\n'"File changes: $_bfr_files"
		if [[ ${MA_DELEGATE_USE_NOTES:-} != false && ${MA_DELEGATE_PERSISTENT_NOTES:-} != false ]]; then
			local _bfr_notes="${_ma_notes_dir}/task-${_bfr_tid}.md"
			[[ -s $_bfr_notes ]] && _bfr_out+=$'\n'"[Sub-agent internal task notes: $_bfr_notes]"
		fi
		return 0
	}


	_execute_submit() { # 1:sub_farg 2:sub_call_id 3:force_submission(bool)
		local result status confidence files verification caveats
		{
			IFS= read -r -d '' result
			IFS= read -r -d '' status
			IFS= read -r -d '' confidence
			IFS= read -r -d '' files
			IFS= read -r -d '' verification
			IFS= read -r -d '' caveats
		} < <(jq -jbr '
			(.result // "Task aborted by the user"), "\u0000",
			(.status // "aborted"), "\u0000",
			(.confidence // 0), "\u0000",
			(.files // ""), "\u0000",
			(.verification // ""), "\u0000",
			(.caveats // ""), "\u0000"
		' <<< "$1")
		local sub_call_id=$2 _force_submission=${3:-}

		local sub_thread_name=$MA_THREAD_NAME
		local _thread_id=
		[[ "$MA_THREAD_NAME" =~ _sub_([a-zA-Z0-9_-]+)$ ]] && _thread_id="${BASH_REMATCH[1]}"

		local -n _role="${MA_ROLES["$MA_ROLE_NAME"]}"
		local evaluator_role='' is_evaluator=''
		local custom_eval_name=${_role[evaluator]:-}
		[[ -n ${custom_eval_name} ]] && {
			if [[ -v 'MA_ROLES[$custom_eval_name]' ]]; then
				evaluator_role=$custom_eval_name; is_evaluator=true
			else
				warn "Custom evaluator role for $MA_ROLE_NAME role was not found: ${custom_eval_name}\n"
			fi
		}

		local max_attempts=${_role[max_evaluations]:-}
		[[ $max_attempts =~ ^[0-9]+$ ]] || max_attempts=8
		(( ${MA_EVALUATED["$sub_thread_name@attempts"]:-1} >= max_attempts )) && {
			unset 'MA_EVALUATED["$sub_thread_name@attempts"]'
			is_evaluator=false
		}

		if [[ $status == complete* && $is_evaluator == true && ${_force_submission:-} != true ]]; then
			thread_add_tool_result MA_THREAD_JSON "$sub_call_id" "submit" "OK: Submitted"

			local uppest=$MA_THREAD_NAME n_parents=0
			meta_thread_get_uppest uppest "$MA_THREAD_NAME" n_parents

			ma_now() { local -n _r=$1; _r=${EPOCHREALTIME/[,.]/}; [[ -z $_r ]] && _r="$(date +%s%6N)"; }
			local _eval_thread_id; ma_uid _eval_thread_id
			local _eval_thread_name="${uppest}_eval_${_eval_thread_id}"

			doc_thread_fresh "$_eval_thread_name" false "$evaluator_role" 0 "$is_evaluator"

			local final_response=''
			_submit_build_result final_response "$status" "$confidence" "$result" "$caveats" "$verification" "$files" "$_thread_id"

			local eval_prompt="[Task assigned by the user to the worker]"$'\n\n'"${MA_DELEGATED["${sub_thread_name}@task"]}"$'\n\n'
			eval_prompt+="[Result submitted by the worker]"$'\n\n'"$final_response"$'\n'"${MA_FEEDBACK_MSG}"

			local n_attempts=1
			[[ -v 'MA_EVALUATED["$sub_thread_name@attempts"]' ]] && n_attempts=$(( n_attempts + ${MA_EVALUATED["$sub_thread_name@attempts"]:-0} ))
			MA_EVALUATED["$sub_thread_name@attempts"]=$n_attempts
			MA_EVALUATED["$sub_thread_name@evaluator"]=$MA_THREAD_NAME
			MA_EVALUATED["$MA_THREAD_NAME@prompt"]=$eval_prompt
			MA_EVALUATED["$MA_THREAD_NAME@evaluated"]=$sub_thread_name

			thread_add_msg MA_THREAD_JSON user "$eval_prompt"
			info " • Evaluating task as ${A_INFO}${A_B}$MA_ROLE_NAME${A_INFO} in ${A_MARKOV}$MA_THREAD_NAME${A_INFO} thread.\n\n";
			(( _MA_SHOULD_PRINT )) && { ma_toolcall_output "submit" "$final_response" "" "${A_INFO}"; }
		else

			local sub_role sub_parent sub_child
			meta_threads_unpack $MA_THREAD_NAME sub_role sub_parent sub_child
			doc_thread_switch "${sub_parent:-main}"

			local final_response=''
			_submit_build_result final_response "$status" "$confidence" "$result" "$caveats" "$verification" "$files" "$_thread_id"
			(( _MA_SHOULD_PRINT )) && {
				local exit_color="${A_TOOL_OK}"; [[ $status != complete* ]] && exit_color=${A_TOOL_FAIL}
				ma_toolcall_output "delegate" "$final_response" "" "$exit_color"
			}

			local delegate_call_id=${MA_DELEGATED["${sub_thread_name}@call_id"]:-}
			if [[ -n $delegate_call_id ]]; then
				thread_add_tool_result MA_THREAD_JSON "$delegate_call_id" "delegate" "$final_response"
			else
				err "Failed to retrieve delegate call ID returning from ${sub_thread_name} thread.\nNo results submitted.\n"
			fi

			[[ "$MA_THREAD_NAME" != "$sub_thread_name" && ! -v 'MA_USER_THREADS["$sub_thread_name"]' ]] && {
				[[ -v 'MA_USER_THREADS["$MA_THREAD_NAME"]' && ${MA_DELEGATED["$sub_thread_name@final"]:-} == true && $status == complete* ]] && _MA_SMART_RETURN=true;
				unset "MA_SUBMITTED_$sub_thread_name"
				unset "MA_DELEGATED_QUEUE_$sub_thread_name"
				unset 'MA_DELEGATED["$sub_thread_name@call_id"]'
				unset 'MA_DELEGATED["$sub_thread_name@final"]'
				unset 'MA_DELEGATED["$sub_thread_name@task"]'
				unset 'MA_DELEGATED["$sub_thread_name@snip"]'
				doc_thread_delete "$sub_thread_name"
				[[ ${MA_DELEGATE_USE_NOTES:-} != false && ${MA_DELEGATE_PERSISTENT_NOTES:-} == false ]] && {
					rm -f "${_ma_notes_dir}/task-${_thread_id}.md"
				}
				info " • Returned to ${A_MARKOV}$MA_THREAD_NAME${A_INFO} from ${A_MARKOV}$sub_thread_name${A_INFO} thread.\n\n";
				return 0
			}
			return 1
		fi
	}




	MA_TOOL[feedback]='
	{
		"type": "function",
		"name": "feedback",
		"description": "Review the task result and submit pass or revise. On revise, steering is the only message sent to the worker, who cannot see your review; make it self-contained",
		"parameters": {
			"type": "object",
			"properties": {
				"verdict": { "type": "string", "enum": ["pass", "revise"], "description": "pass = accept. revise = reject and continue" },
				"steering": { "type": "string", "description": "Required for revise; omit for pass. State the problem, cite file/line/command evidence, and give exact imperative fixes. Most important first" }
			},
			"required": ["verdict"],
			"additionalProperties": false
		}
	}'

	header_feedback() {
		local verdict steering
		{
			IFS= read -r -d '' verdict
			IFS= read -r -d '' steering
		} < <(jq -jbr '
			(.verdict // "pass"), "\u0000",
			(.steering // ""), "\u0000"
		' <<< "$1")
		case $verdict in
			pass)	printf "Verdict: ${A_TOOL_OK}${A_B}pass\n" ;;
			revise) printf "Verdict: ${A_TOOL_FAIL}${A_B}revise\n${A_RESP}${A_I}%s\n" "$steering"
		esac
	}

	execute_feedback() { 
		local verdict steering
		{
			IFS= read -r -d '' verdict
			IFS= read -r -d '' steering
		} < <(jq -jbr '
			(.verdict // "pass"), "\u0000",
			(.steering // ""), "\u0000"
		' <<< "$1")
		[[ $verdict == revise && -z $steering ]] && { echo "ERROR: revise requires steering"; return 1; }
		echo "OK: Feedback sent";
	}
	MA_TOOL_DISPLAY_OUTPUT[feedback]=false 
	MA_TOOL_DISPLAY_NAME[feedback]=false 

	_execute_feedback() {
		local verdict steering
		{
			IFS= read -r -d '' verdict
			IFS= read -r -d '' steering
		} < <(jq -jbr '
			(.verdict // "pass"), "\u0000",
			(.steering // ""), "\u0000"
		' <<< "$1")
		local thread_evaluated=${MA_EVALUATED["$MA_THREAD_NAME@evaluated"]:-}
		[[ -n $thread_evaluated && -v 'MA_THREADS["$thread_evaluated"]' ]] || {
		   	err "Error: No sub-thread to return for $MA_THREAD_NAME (sub-thread not found: $thread_evaluated)\n";
			return 1; 
		}
		local eval_thread=$MA_THREAD_NAME
		doc_thread_switch "$thread_evaluated"
		doc_thread_delete "$eval_thread"
		unset 'MA_EVALUATED["$thread_evaluated@evaluator"]'
		unset 'MA_EVALUATED["$eval_thread@prompt"]'
		unset 'MA_EVALUATED["$eval_thread@evaluated"]'
		if [[ $verdict == *pass* ]]; then
			local cid= d_args=
			[[ ${submitted_results[*]+x} ]] && {
				for cid in "${!submitted_results[@]}"; do 
					d_args="${submitted_results[$cid]}";
					unset 'submitted_results[$cid]'
					break;
				done
			}
			unset 'MA_EVALUATED["$thread_evaluated@attempts"]'
			meta_sync set
			_execute_submit "$d_args" "$cid" true
			return 0;
		fi
		thread_add_msg MA_THREAD_JSON user "$steering"
		return 1;
	}

}

ma_toolcall_header() { # $1:tool_name $2:args
	local show=1
	[[ ${MA_TOOL_DISPLAY_NAME[*]+x} && ${MA_TOOL_DISPLAY_NAME[$1]:-} == false ]] && { show=0; }
	(( show )) && {
		case "$1" in
			bash)	 printf "${A_K}${A_TOOL_NAME}\$${A_R} " >&2 ;;
			execute) printf "${A_K}${A_TOOL_NAME}(execute)${A_R} " >&2 ;;
			*)		 printf "${A_K}${A_TOOL_NAME}[%s]${A_R} " "$1" >&2 ;;
		esac
	}
	printf "${A_TOOL_HEAD}" >&2
	if declare -F "header_${1}" >/dev/null; then "header_${1}" "$2" >&2; else printf '\n' >&2; fi
	printf "${A_R}" >&2
}

ma_toolcall_execute() { # $1:tool_name $2:args
	cd "$MA_WORKING_DIR"
	if declare -F "execute_${1}" >/dev/null; then "execute_${1}" "$2"; else echo "ERROR: Unknown tool $1"; return 1; fi
}


_TOKENS_PROMPT=0				# TOTAL prompt tokens (cache-inclusive)
_TOKENS_COMPLETION=0			# output tokens
_TOKENS_CACHE_READ=0			# subset of prompt that was a cache hit
_TOKENS_CACHE_WRITE=0			# subset of prompt that was written to cache
_CUR_INPUT_ADDED=0
_CUR_CACHE_READ_ADDED=0
_CUR_CACHE_WRITE_ADDED=0

_api_parse_usage() {
    local -n json=$1
    local api_type=$2
    local prompt=0 completion=0 cached_read=0 cached_write=0
    local should_track=0
    case ${api_type} in
        openai_chat)
            [[ $json =~ \"prompt_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && prompt=${BASH_REMATCH[1]}
            [[ $json =~ \"completion_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && completion=${BASH_REMATCH[1]}
            [[ $json =~ \"cached_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_read=${BASH_REMATCH[1]}
            _TOKENS_PROMPT=$prompt; _TOKENS_COMPLETION=$completion
            _TOKENS_CACHE_READ=$cached_read; _TOKENS_CACHE_WRITE=0
            should_track=1
            ;;
        openai_resp)
            [[ $json =~ \"input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && prompt=${BASH_REMATCH[1]}
            [[ $json =~ \"output_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && completion=${BASH_REMATCH[1]}
            [[ $json =~ \"cached_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_read=${BASH_REMATCH[1]}
            _TOKENS_PROMPT=$prompt; _TOKENS_COMPLETION=$completion
            _TOKENS_CACHE_READ=$cached_read; _TOKENS_CACHE_WRITE=0
            should_track=1
            ;;
        anthropic)
            if [[ $json =~ \"type\"[[:space:]]*:[[:space:]]*\"message_start\" ]]; then
                [[ $json =~ \"input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && prompt=${BASH_REMATCH[1]}
                [[ $json =~ \"cache_read_input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_read=${BASH_REMATCH[1]}
                [[ $json =~ \"cache_creation_input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_write=${BASH_REMATCH[1]}
                _TOKENS_PROMPT=$(( prompt + cached_read + cached_write ))
                _TOKENS_CACHE_READ=$cached_read
                _TOKENS_CACHE_WRITE=$cached_write
                _TOKENS_COMPLETION=0
            elif [[ $json =~ \"type\"[[:space:]]*:[[:space:]]*\"message_delta\" ]]; then
                [[ $json =~ \"output_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && completion=${BASH_REMATCH[1]}
                _TOKENS_COMPLETION=$completion
                # Some proxies report full usage only here
                if [[ $json =~ \"input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
                    prompt=${BASH_REMATCH[1]}
                    [[ $json =~ \"cache_read_input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_read=${BASH_REMATCH[1]}
                    [[ $json =~ \"cache_creation_input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_write=${BASH_REMATCH[1]}
                    _TOKENS_PROMPT=$(( prompt + cached_read + cached_write ))
                    _TOKENS_CACHE_READ=$cached_read
                    _TOKENS_CACHE_WRITE=$cached_write
                fi
                should_track=1
            else # Non-streamed
                [[ $json =~ \"input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && prompt=${BASH_REMATCH[1]}
                [[ $json =~ \"output_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && completion=${BASH_REMATCH[1]}
                [[ $json =~ \"cache_read_input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_read=${BASH_REMATCH[1]}
                [[ $json =~ \"cache_creation_input_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && cached_write=${BASH_REMATCH[1]}
                _TOKENS_PROMPT=$(( prompt + cached_read + cached_write ))
                _TOKENS_COMPLETION=$completion
                _TOKENS_CACHE_READ=$cached_read
                _TOKENS_CACHE_WRITE=$cached_write
                should_track=1
            fi
            ;;
    esac

    (( should_track )) || return 0

    local model_id="${MA_ENDPOINT_OBJ[model.id]:-"no-model"}"
    local ukey; _pricing_key "$model_id" "$_TOKENS_PROMPT" ukey

    local f=(0 0 0 0 0)
    [[ -n "${MA_MODEL_USAGE["$ukey"]:-}" ]] && _model_usage_unpack f "${MA_MODEL_USAGE["$ukey"]}"

    local raw=$(( _TOKENS_PROMPT - _TOKENS_CACHE_READ - _TOKENS_CACHE_WRITE ))
    f[0]=$(( f[0] + 1 ))
    f[1]=$(( f[1] + raw ))
    f[2]=$(( f[2] + _TOKENS_COMPLETION ))
    f[3]=$(( f[3] + _TOKENS_CACHE_READ ))
    f[4]=$(( f[4] + _TOKENS_CACHE_WRITE ))

	local IFS=:
    MA_MODEL_USAGE["$ukey"]="${f[*]}"
	_MA_LAST_CALL_MODEL_KEY=$ukey
    MA_CTX_USAGE["$MA_THREAD_NAME"]=$(( _TOKENS_PROMPT + _TOKENS_COMPLETION ))
}


_pricing_lookup() { # 1:key 2:prices(out array)
	local -n _out=$2
	IFS=' ' read -r -a _out <<< "${MARKOV_PRICING[$1]:-}"
	_out[0]="${_out[0]:-0}"; _out[1]="${_out[1]:-0}"
	_out[2]="${_out[2]:-0}"; _out[3]="${_out[3]:-0}"
}

# get effective pricing key for a call: highest tier whose threshold < prompt tokens
_pricing_key() { # 1:model_id 2:prompt_tokens 3:out_var
	local -n _out_k=$3
	local k t best=0
	_out_k=$1
	for k in "${!MARKOV_PRICING[@]}"; do
		[[ $k == "$1@"* ]] || continue
		t=${k##*@}
		(( t < $2 && t > best )) && { best=$t; _out_k=$k; }
	done
}


_model_usage_unpack() { IFS=: read -r -a "$1" <<< "$2"; }

_model_lastcall_unpack() { IFS="|" read -r -a "$1" <<< "$2"; }

_model_usage_aggregate() {
    local -n _calls=$1 _input=$2 _output=$3 _cread=$4 _cwrite=$5
    _calls=0; _input=0; _output=0; _cread=0; _cwrite=0
    local key f
    for key in "${!MA_MODEL_USAGE[@]}"; do
        f=()
        _model_usage_unpack f "${MA_MODEL_USAGE["$key"]}"
        _calls=$(( _calls + f[0] ))
        _input=$(( _input + f[1] ))
        _output=$(( _output + f[2] ))
        _cread=$(( _cread + f[3] ))
        _cwrite=$(( _cwrite + f[4] ))
    done
}

# Prints: cost_input cost_output cost_cache_read cost_cache_write total
_costs_calc_awk() { # raw cache_read cache_write completion p_input p_output p_cache_read p_cache_write
    awk -v raw="$1" -v cache_read="$2" -v cache_write="$3" -v completion="$4" \
        -v p_input="$5" -v p_output="$6" -v p_cache_read="$7" -v p_cache_write="$8" \
    'BEGIN {
        M = 1000000
        ci = raw / M * p_input
        co = completion / M * p_output
        cr = cache_read / M * p_cache_read
        cw = cache_write / M * p_cache_write
        printf "%.6f %.6f %.6f %.6f %.6f\n", ci, co, cr, cw, ci + co + cr + cw
    }'
}

_costs_print_last_call() { # Per-call cost display
    local raw=$(( _TOKENS_PROMPT - _TOKENS_CACHE_READ - _TOKENS_CACHE_WRITE ))
    local price=()
    local model_id="${MA_ENDPOINT_OBJ[model.id]:-"no-model"}"
	local k="${_MA_LAST_CALL_MODEL_KEY:-"$model_id"}"
	local pkey; _pricing_key "$k" "$_TOKENS_PROMPT" pkey
	_pricing_lookup "$pkey" price
    read -r ci co cr cw total < <(_costs_calc_awk \
        "$raw" "$_TOKENS_CACHE_READ" "$_TOKENS_CACHE_WRITE" "$_TOKENS_COMPLETION" \
        "${price[0]}" "${price[1]}" "${price[2]}" "${price[3]}")
	printf "${A_INFO}${A_B}Last Call:\n"
    printf "  ${A_INFO}──────────────────────────────────────────\n"
    printf "  ${A_R}${A_B}%s\n" "$pkey"
    printf "  ${A_INFO}${A_B}input:        ${A_MARKOV}%16s  ${A_INFO}%6d tok\n" "\$$ci" "$raw"
    printf "  ${A_INFO}${A_B}output:       ${A_MARKOV}%16s  ${A_INFO}%6d tok\n" "\$$co" "$_TOKENS_COMPLETION"
    printf "  ${A_INFO}${A_B}cache read:   ${A_MARKOV}%16s  ${A_INFO}%6d tok\n" "\$$cr" "$_TOKENS_CACHE_READ"
    printf "  ${A_INFO}${A_B}cache write:  ${A_MARKOV}%16s  ${A_INFO}%6d tok\n" "\$$cw" "$_TOKENS_CACHE_WRITE"
    printf "  ${A_INFO}──────────────────────────────────────────\n"
    printf "  ${A_INFO}${A_B}total:        ${A_MARKOV}%16s\n" "\$$total"
}

_costs_calc_session_total() { # 1:out_var (6 decimal string)
    local -n _out=$1
    local grand=0 key total
    for key in "${!MA_MODEL_USAGE[@]}"; do
        local f=()
        _model_usage_unpack f "${MA_MODEL_USAGE["$key"]}"
        local price=()
        _pricing_lookup "$key" price
        IFS=' ' read -r _ _ _ _ total < <(_costs_calc_awk \
            "${f[1]}" "${f[3]}" "${f[4]}" "${f[2]}" \
            "${price[0]}" "${price[1]}" "${price[2]}" "${price[3]}")
        grand=$(awk -v a="$grand" -v b="$total" 'BEGIN{printf "%.6f", a+b}')
    done
    _out="$grand"
}

_costs_print() {
	ma_term_update
    local key f price total grand=0
    local cols="$_MA_COLUMNS"
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=80

    local -a keys=() calls_a=() in_a=() out_a=() cread_a=() cwrite_a=() cost_a=()

    for key in "${!MA_MODEL_USAGE[@]}"; do
        f=()
        _model_usage_unpack f "${MA_MODEL_USAGE["$key"]}"
        price=()
        _pricing_lookup "$key" price
        read -r _ _ _ _ total < <(_costs_calc_awk \
            "${f[1]}" "${f[3]}" "${f[4]}" "${f[2]}" \
            "${price[0]}" "${price[1]}" "${price[2]}" "${price[3]}")
        grand=$(awk -v a="$grand" -v b="$total" 'BEGIN{printf "%.6f", a+b}')

        keys+=("${key:0:32}")
        calls_a+=("${f[0]}")
        in_a+=("${f[1]}")
        out_a+=("${f[2]}")
        cread_a+=("${f[3]}")
        cwrite_a+=("${f[4]}")
        cost_a+=("$total")
    done

    local i n=${#keys[@]}
    local fmt="  %-32s %6s %7s %7s %7s %7s %16s"
    local fmt_e="  ${A_R}${A_B}%-32s${A_R} %6s %7s %7s %7s %7s ${A_MARKOV}%16s"
    local fmt_t="  ${A_INFO}${A_B}%-32s %6s %7s %7s %7s %7s ${A_MARKOV}%16s"

	printf "${A_INFO}${A_B}Costs:\n"

    local header rule
    header=$(printf "$fmt" "model" "calls" "IN" "OUT" "CR" "CW" "cost")

    if (( cols >= ${#header} )); then
		local hdr=$(( ${#header} - 2 ))
        rule=$(printf '%.0s─' $(seq 1 $hdr))
        printf "  ${A_INFO}%s${A_R}\n" "$rule"
        printf "${A_INFO}${A_B}%s\n" "$header"
        printf "  ${A_INFO}%s${A_R}\n" "$rule"
        for (( i=0; i<n; i++ )); do
            local h_in h_out h_cr h_cw
            ma_human_num "${in_a[i]}"     h_in
            ma_human_num "${out_a[i]}"    h_out
            ma_human_num "${cread_a[i]}"  h_cr
            ma_human_num "${cwrite_a[i]}" h_cw
            printf "$fmt_e\n" "${keys[i]}" "${calls_a[i]}" "$h_in" "$h_out" "$h_cr" "$h_cw" "\$${cost_a[i]}"
        done
        printf "  ${A_INFO}%s${A_R}\n" "$rule"
        printf "$fmt_t\n" "total:" "" "" "" "" "" "\$$grand"
    else
		printf "  ${A_INFO}──────────────────────────────────────────\n"
        for (( i=0; i<n; i++ )); do
            printf "  ${A_R}${A_B}%s\n" "${keys[i]}"
            printf "  ${A_INFO}${A_B}calls:        ${A_R}%16d\n"  "${calls_a[i]}"
            printf "  ${A_INFO}${A_B}input:        ${A_R}%16d\n"  "${in_a[i]}"
            printf "  ${A_INFO}${A_B}output:       ${A_R}%16d\n"  "${out_a[i]}"
            printf "  ${A_INFO}${A_B}cache_read:   ${A_R}%16d\n"  "${cread_a[i]}"
            printf "  ${A_INFO}${A_B}cache_write:  ${A_R}%16d\n"  "${cwrite_a[i]}"
            printf "  ${A_INFO}${A_B}cost:         ${A_MARKOV}%16s${A_R}\n" "\$${cost_a[i]}"
			printf "  ${A_INFO}──────────────────────────────────────────\n"
        done
        printf "  ${A_INFO}${A_B}Total:        ${A_MARKOV}%16s${A_R}\n" "\$$grand"
    fi
	printf "\n"
	_costs_print_last_call
	printf "\n"
}





_endpoint_request_models() {

	_endpoint_check_api_type

    if [[ "$MA_API_URL" == *"/messages"* ]]; then
        models_url="${MA_API_URL%/messages}/models"
    else
		if [[ $MA_API_TYPE == "openai_chat" ]]; then
			models_url="${MA_API_URL%/chat/completions}/models"
		else
			models_url="${MA_API_URL%/responses}/models"
		fi
    fi

	local _h_auth=(); _api_set_call_header _h_auth "$MA_API_TYPE" "$MA_API_KEY"
    raw="$(curl ${MA_API_PROXY:-} -m 11 -N --tcp-nodelay -sS "${models_url}" "${_h_auth[@]}" 2>/dev/null)"
}


_endopint_parse_models() {
	local ret_code=0
    local json="${1}"
    local model_id=${2:-}

    local out
    out="$(printf '%s' "${json}" | jq -br --arg want "$model_id" '
        def ctx_of(e):
            e.meta.n_ctx //
            e.meta.n_ctx_train //
            (e.status.args? | arrays |
                . as $a | indices("--ctx-size")[0] | if . then . + 1 | $a[.] else null end) //
            0;

        def loaded(e): e.status.value? == "loaded";

        (if type == "array" then .
         elif .data then .data
         elif .models then [ .models[] | .id = (.name | ltrimstr("models/")) ]
         else [] end) as $items |

        ($items | map(.id // "")) as $ids |
        (first($items[] | select(loaded(.))) // $items[0]) as $fallback |

        ($want | ascii_downcase) as $w_low |
		(if $want == "" then null else
			first($items[] | select(.id != null and (.id | tostring | ascii_downcase) == $w_low)) //
			first($items[] | select(.id != null and (.id | tostring | ascii_downcase | contains($w_low)))) //
			null
		 end) as $match |

        ($match // $fallback) as $chosen |

        (if ($items | length) == 0 then "nolist"
         elif $want == "" then "ok"
         elif $match then "ok"
         else "nomatch" end) as $status |

        if $chosen then
            [$chosen.id, (ctx_of($chosen) | tostring), $status, ($ids | join("\u001f"))] | @tsv
        else
            [$want, "0", $status, ($ids | join("\u001f"))] | @tsv
        end
    ' 2>/dev/null)"

    local _EP_IDS
    IFS=$'\t' read -r _EP_MODEL _EP_CTX _match_status _EP_IDS <<< "$out"

    if [[ "$_match_status" == "nomatch" ]]; then
		ret_code=1
        err "Model '$model_id' not found.\n"
        info " Available:\n"
        local _mid _mids
        IFS=$'\x1f' read -ra _mids <<< "$_EP_IDS"
        for _mid in "${_mids[@]}"; do
            info " $_mid\n"
        done
    elif [[ "$_match_status" == "nolist" && -z "$_EP_MODEL" ]]; then
		ret_code=2
        err "Could not retrieve model list and no model specified.\n"
    fi

    local is_ip_address=false
    [[ "$MA_API_URL" =~ ^https?://(localhost|([0-9]{1,3}\.){3}[0-9]{1,3})(:[0-9]+)?(/|$) ]] && {
        is_ip_address=true
        local tmp="${MA_API_URL#*://}"
        _EP_IPPORT="${tmp%%/*}"
        MA_LLAMACPP_FIX=true	# assuming connection via IP is with llama.cpp inference engine
    }

    [[ $is_ip_address == true ]] &&
        [[ -z "$_EP_CTX" || "$_EP_CTX" == "0" || ! "$_EP_CTX" =~ ^[0-9]+$ || -z "$_EP_MODEL" || "$_EP_MODEL" == "null" ]] && {
        local props_url="${MA_API_URL%/v1/*}/props"
        local props
        # shellcheck disable=SC2086
        props="$(curl ${MA_API_PROXY:-} -m 11 -N --tcp-nodelay -sS "$props_url" 2>/dev/null)"
        if [[ -n "$props" && "$props" != *'"error"'* ]]; then
            local _ctx _alias _slots tsv
            tsv="$(jq -br '
                [
                    (.default_generation_settings.n_ctx // 0),
                    (.model_alias // ""),
                    (.total_slots // 0)
                ] | @tsv
            ' <<< "$props")" || return 1
            IFS=$'\t' read -r _ctx _alias _slots <<< "$tsv"

            [[ -n "$_ctx"   && "$_ctx"   =~ ^[0-9]+$ && $_ctx -gt 0 ]] && _EP_CTX=$_ctx
            [[ -n "$_slots" ]] && MA_LLAMA_SLOTS="$_slots"
            [[ -n "$_alias" ]] && _EP_ALIAS="$_alias"
        fi
    }

    [[ -z "$_EP_CTX" || "$_EP_CTX" == "0" || ! "$_EP_CTX" =~ ^[0-9]+$ ]] && _EP_CTX=128000
	return $ret_code
}




_list_providers() {
	_modelsdev_to_cache
	local -A providers=()
	local provider
	while IFS= read -r provider; do
		providers["$provider"]=1
	done < <(jq -br 'keys[]' "$_modelsdev_cachedfile")
	for provider in "${!MARKOV_PROVIDERS[@]}"; do
		providers["$provider"]=1
	done
	printf '%s\n' "${!providers[@]}"
}

_list_provider_models() {
	MA_PROVIDER=
	[[ ${MA_MODEL:-} == */* ]] && { MA_PROVIDER=${MA_MODEL%%/*}; MA_MODEL=${MA_MODEL#*/}; }
	[[ -n ${MA_PROVIDER:-} ]] && {
		_modelsdev_to_cache
		local -a matches=()
		_modelsdev_list_models_arr matches "$MA_PROVIDER"
		(( ${#matches[@]} > 0 )) && { printf "%s\n" "${matches[@]}"; return; }
		local custom_provider="${MARKOV_PROVIDERS[$MA_PROVIDER]:-}"
		if [[ -n $custom_provider ]]; then
			local key_env= url=
			if [[ $custom_provider == *'|'* ]]; then
				IFS='|' read -r key_env url <<< "$custom_provider"
			else
				url="$custom_provider"
			fi
			[[ -n $key_env ]] && {
			   	eval 'MA_API_KEY="${MA_API_KEY:-${'$key_env':-}}"'
				[[ -z ${!key_env:-} ]] && warn "env $key_env not set.\n"
			}
			MA_API_URL="${MA_API_URL:-$url}"
		else
			_err_ep_unknown_provider "$MA_PROVIDER";
			exit 1
		fi
	}

	_endpoint_check_api_type

	local models_url='' raw=''

	[[ -z $MA_API_URL ]] && { 
		raw=; 
		ma_spinner_stop;
		_err_ep_no_url
		return 1; 
	}

	if ! _endpoint_request_models; then ma_spinner_stop; return 1; fi


	[[ -z "$raw" || "$raw" == *'"error"'* || "$raw" == *'<!DOCTYPE'* ]] && {
		ma_spinner_stop
		[[ -n "$raw" ]] && printf '%s' "$raw" | jq .
		err "Failed to fetch models from $models_url\n"
		return 1
	}
	printf '%s' "$raw" | jq -br '
		(if type == "array" then .
		 elif .data then .data
		 elif .models then [.models[] | .id = (.name | ltrimstr("models/"))]
		 else []
		 end) as $items |
		$items[] | .id // empty
	' 2>/dev/null
}




_api_set_call_header() {
	local -n out_h_auth=$1
	local api_type=${2:-openai_chat} api_key=${3:-}
	out_h_auth=()
	[[ -n "$api_key" ]] && {
		if [[ $api_type == "anthropic" ]]; then
			out_h_auth=("-H" "X-Api-Key: $api_key" "-H" "anthropic-version: 2023-06-01")
		else
			out_h_auth=("-H" "Authorization: Bearer $api_key")
		fi
	}
}

_api_call() { # non-streaming
	local -n body=$1
	local -n api_response=$2

	local api_type=${MA_ENDPOINT_OBJ["api_type"]}
	local api_key=${MA_ENDPOINT_OBJ["api_key"]}

	local raw response http_code sep=$'\x1f' error_code=

	ma_spinner_start

	_curl_cmd_blocking(){
		local _h_auth=(); _api_set_call_header _h_auth "$api_type" "$api_key"
		# shellcheck disable=SC2086
		printf '%s' "$body" | curl ${MA_ENDPOINT_OBJ["api_proxy"]} "${MA_USER_AGENT_ARRAY[@]}" -H 'Accept: application/json' --keepalive-time 60 -sS -w "${sep}%{http_code}" \
			  -X POST "${MA_ENDPOINT_OBJ["api_url"]}" -H 'Content-Type: application/json' "${_h_auth[@]}" --data-binary @- 2>/dev/null
	}
	_curl_out(){ trap '' INT; _curl_cmd_blocking; }

	if [[ ${MA_USE_IPC:-} == true ]]; then ma_ipc_run raw error_code _curl_out; else raw=$(_curl_out); fi

	ma_spinner_stop

	[[ "$_INTERRUPTED" == "true" ]] && { return 1; }

	http_code=${raw##*"$sep"}
	response=${raw%"$sep"*}

	_api_parse_usage response "$api_type"

	api_response=();	# Assumed indeices: idx_reasoning=0, idx_content=1, idx_tool_calls=2
	case "$api_type" in
		openai_chat)
			mapfile -d '' -t api_response < <(
				jq -brj '
					(.choices[0].message.reasoning // .choices[0].message.reasoning_content // .choices[0].message.thinking // ""),
					"\u0000",
					(.choices[0].message.content // ""),
					"\u0000",
					(
						(.choices[0].message.tool_calls // []) +
						(if .choices[0].message.function_call then [{type: "function", function: .choices[0].message.function_call}] else [] end)
						| tostring
					),
					"\u0000"
				' <<< "$response" 2>/dev/null
				)
			;;
		openai_resp)
			mapfile -d '' -t api_response < <(
				jq -brj '
					(
						[
							.output[]?
							| select(.type=="reasoning")
							| (
								(.summary[]?.text // empty),
								(.content[]? | select(.type=="reasoning_text") | .text)
							  )
						] | join("")
					),
					"\u0000",
					(
						[
							.output[]?
							| select(.type=="message")
							| .content[]?
							| select(.type=="output_text")
							| .text
						] | join("")
					),
					"\u0000",
					(
						[
							.output[]?
							| select(.type=="function_call")
							| { id: .call_id, type: "function", function: { name: .name, arguments: .arguments } }
						] | tostring
					),
					"\u0000"
				' <<< "$response" 2>/dev/null
			)
			;;
		anthropic)
			mapfile -d '' -t api_response < <(
				jq -brj '
					([.content[]? | select(.type=="thinking") | (.thinking // .text // .content // "")] | join("")),
					"\u0000",
					([.content[]? | select(.type=="text") | .text] | join("")),
					"\u0000",
					([.content[]? | select(.type=="tool_use") | {
						id: .id,
						type: "function",
						function: {
							name: .name,
							arguments: (.input | tostring)
						}
					}] | tostring),
					"\u0000"
				' <<< "$response" 2>/dev/null
			)
			;;
	esac

	local _rs='[]'
	case "$api_type" in
		anthropic)   _rs="$(jq -c '[.content[]? | select(.type=="thinking" or .type=="redacted_thinking")]' <<< "$response" 2>/dev/null)" ;;
		openai_resp) _rs="$(jq -c '[.output[]? | select(.type=="reasoning" and (.encrypted_content // "") != "")]' <<< "$response" 2>/dev/null)" ;;
	esac
	api_response[idx_rstate]=${_rs:-[]}

	api_response[idx_http_code]=$http_code
	api_response[idx_err_body]="$response";
	[[ "$http_code" == "200" ]] && return 0
	[[ -n "${_MA_COMPACTING:-}" ]] && return 1
	[[ "$http_code" == "000" || -z "$http_code" ]] && { err "Connection failed (API URL: ${MA_ENDPOINT_OBJ["api_url"]:-unset})\n"; return 1; }
	err "Server error (HTTP $http_code)\n\n"; [[ -n "$response" ]] && printf '%s' "$response" | jq -br '.' 2>/dev/null
	return 1
}


_api_call_stream() {

	local -n body=$1
	local -n api_response=$2

	local provider=${MA_ENDPOINT_OBJ["provider"]:-}
	local api_type=${MA_ENDPOINT_OBJ["api_type"]}
	local api_key=${MA_ENDPOINT_OBJ["api_key"]}

	local _h_auth=(); _api_set_call_header _h_auth "$api_type" "$api_key"

	api_response=();

	local -a _stream_content_parts=() _stream_reasoning_parts=()
	local -a _tc_name=() _tc_id=() _tc_args=()
	local _tc_count=0

	local http_code= line payload
	local -a _stdout_buffer=() _stderr_buffer=()

	local nl=$'\n'
	_flush_stderr() {
		(( ${#_stderr_buffer[@]} > 0 )) && [[ ${MA_HIDE_THINKING:-} != true ]] || return
		local s; printf -v s '%s' "${_stderr_buffer[@]}";
		_hook_call response_stream "$s" ""
		[[ ${MA_ANSI:-} != false ]] && s="${s//"$nl"/${A_K}${nl}}"
		printf "${A_R}${A_THINK}%s${A_K}" "$s" >&2
		_stderr_buffer=()
	}

	if [[ -n ${A_RESP} ]]; then
		_flush_stdout() {
			(( ${#_stdout_buffer[@]} > 0 )) || return
			local s; printf -v s '%s' "${_stdout_buffer[@]}";
			_hook_call response_stream "" "$s"
			[[ ${MA_ANSI:-} != false ]] && s="${s//"$nl"/${A_K}${nl}}"
			printf "${A_R}${A_RESP}%s${A_K}" "$s"
			_stdout_buffer=()
		}
	else
		_flush_stdout() {
			(( ${#_stdout_buffer[@]} > 0 )) || return
			local s; printf -v s '%s' "${_stdout_buffer[@]}";
			_hook_call response_stream "" "$s"
			printf "%s" "$s"
			_stdout_buffer=()
		}
	fi


	local _MAX_BATCH=${MA_BATCH_BUFSIZE:-256}
	local _BATCH_MAX_MICROSEC=${MA_BATCH_MICROSEC:-160000}

	local _now_us; ma_now _now_us
	local -a _batch_content=() _batch_reasoning=() _batch_tools=()
	local _content_last_batch_us=$_now_us
	local _reasoning_last_batch_us=$_now_us
	local _tools_last_batch_us=$_now_us

	local _LOOP_CHECK_MAX_MICROSEC=${MA_LOOP_CHECK_MICROSEC:-10000000}
	local _LOOP_CHECK_MIN_CHARS=${MA_LOOP_CHECK_MIN_CHARS:-2000}
	local _loop_check_last_us=$_now_us

	_detect_loops() {
		tail -n 50 <<< "$1" | awk '
		{ lines[NR]=$0; for(d=1;d<=150;d++){
			if(NR>d && lines[NR]==lines[NR-d]){ streak[d]++
				if(d==1  && streak[1]>=5)           { loop_detected=1; exit 0 }
				if(d>1   && d<=10 && streak[d]>=d*2) { loop_detected=1; exit 0 }
				if(d>10  && streak[d]>=15)           { loop_detected=1; exit 0 }
			} else { streak[d]=0 }
		}}
		END { if(loop_detected==1) exit 0; exit 1 }'
	}

	_process_content_batch() {
		(( ${#_batch_content[@]} > 0 )) || return
		local jq_path
		case "$api_type" in
			anthropic)   jq_path='.delta.text' ;;
			openai_resp) jq_path='.delta' ;;          # response.output_text.delta event
			*)           jq_path='.choices[0].delta.content' ;;
		esac
		local _chunks
		_chunks="$(printf '%s\n' "${_batch_content[@]}" | jq -rjb "$jq_path // empty" 2>/dev/null; echo x)"
		_chunks="${_chunks%x}"; _batch_content=(); 
		_content_last_batch_us=$_now_us;
		[[ -n "$_chunks" ]] || return
		_stream_content_parts+=("$_chunks"); _stdout_buffer+=("$_chunks")
		_flush_stdout

		if (( _now_us - _loop_check_last_us >= _LOOP_CHECK_MAX_MICROSEC )); then
			_loop_check_last_us=$_now_us
			local _ct; printf -v _ct '%s' "${_stream_content_parts[@]}"
			if (( ${#_ct} >= _LOOP_CHECK_MIN_CHARS )) && _detect_loops "$_ct"; then
				warn '\n[Loop detected - Aborting operation]\n'
				_LOOP_DETECTED=true; _INTERRUPTED="true";
			fi
		fi

	}

	_process_reasoning_batch() {
		(( ${#_batch_reasoning[@]} > 0 )) || return
		local jq_path
		case "$api_type" in
			anthropic)   jq_path='.delta.thinking' ;;
			openai_resp) jq_path='.delta' ;;
			*)           jq_path='.choices[0].delta.reasoning_content // .choices[0].delta.thinking // .choices[0].delta.reasoning' ;;
		esac
		local _rchunks
		_rchunks="$(printf '%s\n' "${_batch_reasoning[@]}" | jq -rjb "$jq_path // empty" 2>/dev/null; echo x)"
		_rchunks="${_rchunks%x}"; _batch_reasoning=();
		_reasoning_last_batch_us=$_now_us;
		[[ -n "$_rchunks" && "$_INTERRUPTED" != "true" ]] || return
		_stream_reasoning_parts+=("$_rchunks")
		(( _MA_SHOULD_PRINT )) && [[ ${MA_HIDE_THINKING:-} != true ]] && {
			_stderr_buffer+=("$_rchunks")
			_flush_stderr
		}
		if (( _now_us - _loop_check_last_us >= _LOOP_CHECK_MAX_MICROSEC )); then
			_loop_check_last_us=$_now_us
			local _ct; printf -v _ct '%s' "${_stream_reasoning_parts[@]}"
			if (( ${#_ct} >= _LOOP_CHECK_MIN_CHARS )) && _detect_loops "$_ct"; then
				warn '\n[Loop detected - Aborting operation]\n'
				_LOOP_DETECTED=true; _INTERRUPTED="true";
			fi
		fi
	}

	_process_tools_batch() {
		(( ${#_batch_tools[@]} > 0 )) || return
		if [[ "$api_type" == "anthropic" ]]; then
			local _chunks
			_chunks="$(printf '%s\n' "${_batch_tools[@]}" | jq -rjb '.delta.partial_json // empty' 2>/dev/null; echo x)"
			_chunks="${_chunks%x}"; _batch_tools=();
			_tools_last_batch_us=$_now_us;
			[[ -n "$_chunks" ]] && _anthropic_tool_args_buf+="$_chunks"; return
		fi

		local f_sep=$'\x1e' r_sep=$'\x1f' parsed_stream

		parsed_stream="$(printf '%s\n' "${_batch_tools[@]}" | jq -rjb --arg f_sep "$f_sep" --arg r_sep "$r_sep" '
		  .choices[0].delta as $d
		  | (
			  ($d.tool_calls // $d.toolCalls // []) | to_entries[]?
			  | {
				  index: (.value.index // .key),
				  name: (.value.function.name // ""),
				  id: (.value.id // ""),
				  args: (.value.function.arguments // ""),
				  sig: (.value.extra_content.google.thought_signature // "")
				}
			)
		  | [(.index|tostring), .name, .id, .args, .sig] | join($f_sep) + $r_sep
		' 2>/dev/null)"

		_batch_tools=(); _tools_last_batch_us=$_now_us
		[[ -z "$parsed_stream" ]] && return

		local plist idx name_frag id_frag args_frag sig_frag remainder
		while IFS= read -r -d "$r_sep" plist; do
			[[ -z "$plist" ]] && continue
			idx="${plist%%"$f_sep"*}"; remainder="${plist#*"$f_sep"}"
			name_frag="${remainder%%"$f_sep"*}"; remainder="${remainder#*"$f_sep"}"
			id_frag="${remainder%%"$f_sep"*}"; remainder="${remainder#*"$f_sep"}"
			args_frag="${remainder%%"$f_sep"*}"; sig_frag="${remainder#*"$f_sep"}"

			[[ "$idx" =~ ^[0-9]+$ ]] || continue
			[[ -n "$name_frag" ]] && _tc_name[idx]+="$name_frag"
			[[ -n "$id_frag"   ]] && _tc_id[idx]+="$id_frag"
			[[ -n "$args_frag" ]] && _tc_args[idx]+="$args_frag"
			[[ -n "$sig_frag"  ]] && _tc_sig[idx]="$sig_frag"

			(( idx + 1 > _tc_count )) && _tc_count=$(( idx + 1 ))
			if [[ $_tools_seen == false && -n "$name_frag" ]]; then
				ma_spinner_stop;
				ma_spinner_start "[$name_frag]" tool; _tools_seen=true
			fi
		done <<< "$parsed_stream"
	}


	local _anthropic_type="" _anthropic_tool_name="" _anthropic_tool_id=""
	local _anthropic_stop_reason="" _anthropic_tool_args_buf="" _anthropic_tool_idx=0

	_flush_anthropic_tool() {
		_process_tools_batch
		if [[ -n "$_anthropic_tool_args_buf" && -n "$_anthropic_tool_name" \
			  && -n "$_anthropic_tool_id" && "$_INTERRUPTED" != "true" ]]; then
			local i="$_anthropic_tool_idx"
			_tc_name[i]+="$_anthropic_tool_name"; _tc_id[i]+="$_anthropic_tool_id"
			_tc_args[i]+="$_anthropic_tool_args_buf"
			(( _anthropic_tool_idx + 1 > _tc_count )) && _tc_count=$(( _anthropic_tool_idx + 1 ))
			_anthropic_tool_args_buf=""
		fi
		_anthropic_tool_name="" _anthropic_tool_id=""
	}

	local -a _rs_blocks=(); local _rs_items="[]" _think_from=0 _think_sig=""

	_finish_thinking_block() {
		[[ -n $_think_sig ]] || return 0   # no signature (llama.cpp, proxies) -> nothing replayable
		local txt; printf -v txt '%s' "${_stream_reasoning_parts[@]:_think_from}"
		_rs_blocks+=("$(printf '%s' "$txt" | jq -Rsc --arg sig "$_think_sig" \
			'{type:"thinking", thinking:., signature:$sig}')")
	}



	_close_reasoning() {
		_process_reasoning_batch
		[[ ${MA_HIDE_THINKING:-} == true ]] && { ma_spinner_stop; return; }
		(( ! _MA_SHOULD_PRINT )) && return
		(( ${#_stream_reasoning_parts[@]} == 0 )) && return
		printf "${A_R}\n"
		local last=${_stream_reasoning_parts[-1]}
		[[ $last != *$'\n' ]] && { printf "${A_R}\n"; }
	}
	_close_content() {
		_process_content_batch
		(( ! _MA_SHOULD_PRINT )) && return
		(( ${#_stream_content_parts[@]} == 0 )) && return
		local last=${_stream_content_parts[-1]}
		[[ $last != *$'\n' ]] && { printf "${A_R}\n"; }
	}


	_process_anthropic_event() {
	   	local evt_type=""
		local type_regex='"type":[[:space:]]*"([^"]+)"'
		[[ "$payload" =~ $type_regex ]] && evt_type="${BASH_REMATCH[1]}"
		case "$evt_type" in
			message_start)
				(( start_time == 0 )) && start_time=$_now_us
				ma_spinner_stop;
				;;

			content_block_start)
				ma_spinner_stop
				_process_reasoning_batch; _process_content_batch; _flush_anthropic_tool
				local _cb_info cb_type cb_id cb_name
				_cb_info="$(printf '%s' "$payload" | jq -rj \
					'(.content_block.type//"") + "\t" + (.content_block.id//"") + "\t" + (.content_block.name//"")' 2>/dev/null)"
				IFS=$'\t' read -r cb_type cb_id cb_name <<< "$_cb_info"
				_anthropic_type="$cb_type";
				case "$cb_type" in
					text)
						[[ $_content_status -ne 1 ]] && {
							_content_status=1
							[[ $_reasoning_status -eq 1 ]] && {
								 _reasoning_status=2;
								_close_reasoning
							}
						}
						;;
					thinking)
						_think_from=${#_stream_reasoning_parts[@]}; _think_sig=""
						[[ $_reasoning_status -ne 1 ]] && {
							_reasoning_status=1;
							ma_spinner_stop
							[[ ${MA_HIDE_THINKING:-} != false ]] && ma_spinner_start "thinking…"
						}
						;;
					redacted_thinking)
						_rs_blocks+=("$(jq -c '.content_block' <<< "$payload")")
						;;
					tool_use)
						[[ $_tools_status -eq 0 ]] && {
							ma_spinner_stop
							_tools_status=1
							[[ $_content_status -eq 1 ]] && { _content_status=2; _close_content; }
							[[ $_reasoning_status -eq 1 ]] && {
								_reasoning_status=2; _close_reasoning;
							}
						}
						_anthropic_tool_id="$cb_id" _anthropic_tool_name="$cb_name"
						_anthropic_tool_args_buf="" _anthropic_tool_idx=$_tc_count
						[[ $_tools_seen == false && -n "$_anthropic_tool_name" ]] && {
							ma_spinner_stop; ma_spinner_start "[$_anthropic_tool_name]" tool; _tools_seen=true
						}
						;;
				esac ;;

			content_block_delta)
				local d_type=""
				local delta_regex='"delta":[[:space:]]*\{[[:space:]]*"type":[[:space:]]*"([^"]+)"'
				[[ "$payload" =~ $delta_regex ]] && d_type="${BASH_REMATCH[1]}"
				case "$d_type" in
					text_delta)
						_batch_content+=("$payload")
						(( ${#_batch_content[@]} >= _MAX_BATCH || _now_us - _content_last_batch_us >= _BATCH_MAX_MICROSEC )) \
							&& _process_content_batch
						;;
					thinking_delta)
						_batch_reasoning+=("$payload")
						(( ${#_batch_reasoning[@]} >= _MAX_BATCH || _now_us - _reasoning_last_batch_us >= _BATCH_MAX_MICROSEC )) && {
							_process_reasoning_batch; }
						;;
					signature_delta)
						_think_sig="$(jq -r '.delta.signature // empty' <<< "$payload")"
						;;

					input_json_delta)
						_batch_tools+=("$payload")
						(( ${#_batch_tools[@]} >= _MAX_BATCH || _now_us - _tools_last_batch_us >= _BATCH_MAX_MICROSEC )) \
							&& _process_tools_batch
						;;
				esac ;;

			content_block_stop)
				ma_spinner_stop;
				case "$_anthropic_type" in
					text)     _process_content_batch ; ;;
					thinking) _close_reasoning; _finish_thinking_block ;;
					tool_use) _flush_anthropic_tool ;;
				esac
				_anthropic_type="" ;;

			message_delta)
				local stop_reason=""
				local stop_regex='"stop_reason":[[:space:]]*"([^"]+)"'
				[[ "$payload" =~ $stop_regex ]] && stop_reason="${BASH_REMATCH[1]}"
				[[ -n "$stop_reason" ]] || return
				_anthropic_stop_reason="$stop_reason"
				_process_reasoning_batch; _process_content_batch; _flush_anthropic_tool
				[[ $_reasoning_status -lt 2 ]] && { ma_spinner_stop; _reasoning_status=2; }
				[[ "$stop_reason" == "tool_use" ]] && _tools_seen=false ;;

			message_stop)  #|ping
				printf '\n' >&2
				;;
		esac
	}

	# OpenAI Responses API
	local -A _resp_call_id_to_idx=()
	local -A _resp_tc_args_buf=()
	_process_openai_resp_event() {
	   	local evt_type=""
		local type_regex='"type":[[:space:]]*"([^"]+)"'
		[[ "$payload" =~ $type_regex ]] && evt_type="${BASH_REMATCH[1]}"

		case "$evt_type" in
			response.output_text.delta)
				[[ $_content_status -ne 1 ]] && {
					ma_spinner_stop
					_content_status=1
					[[ $_reasoning_status -eq 1 ]] && {
						_reasoning_status=2;
						_close_reasoning
					}
				}
				_batch_content+=("$payload")
				(( ${#_batch_content[@]} >= _MAX_BATCH || _now_us - _content_last_batch_us >= _BATCH_MAX_MICROSEC )) \
					&& _process_content_batch
				;;
			response.output_text.done)
				_process_content_batch
				;;

			response.reasoning.delta|response.reasoning_summary_text.delta|response.reasoning_text.delta)
				[[ $_reasoning_status -ne 1 ]] && {
					_reasoning_status=1
					ma_spinner_stop
					[[ ${MA_HIDE_THINKING:-} != false ]] && ma_spinner_start "thinking…" think
				}
				_batch_reasoning+=("$payload")
				(( ${#_batch_reasoning[@]} >= _MAX_BATCH || _now_us - _reasoning_last_batch_us >= _BATCH_MAX_MICROSEC )) && {
					_process_reasoning_batch; }
				;;

			response.reasoning_text.done|response.reasoning_summary_text.done)
				_close_reasoning
				;;

			response.output_item.added)	# before any assistant,functioncall,reasoningblock,tooloutputcontainer
				(( start_time == 0 )) && start_time=$_now_us

				[[ $_reasoning_status -eq 1 ]] && {
					_reasoning_status=2;
					_close_reasoning
				}

				[[ $_content_status -eq 1 ]] && {
					_content_status=2
					_process_content_batch
				}

				local _item_info item_type tc_name tc_call_id
				_item_info="$(printf '%s' "$payload" | jq -rj \
					'(.item.type//"") + "\t" + (.item.name//"") + "\t" + (.item.call_id//"")' \
					2>/dev/null)"
				IFS=$'\t' read -r item_type tc_name tc_call_id <<< "$_item_info"
				[[ "$item_type" != "function_call" ]] && return

				[[ -z "$tc_call_id" ]] && return

				local tc_idx="$_tc_count"
				_resp_call_id_to_idx["$tc_call_id"]="$tc_idx"
				_tc_name[tc_idx]="$tc_name"
				_tc_id[tc_idx]="$tc_call_id"
				_resp_tc_args_buf["$tc_call_id"]=""
				(( _tc_count++ ))
				[[ $_tools_seen == false ]] && {
					ma_spinner_stop; ma_spinner_start "[$tc_name]" tool; _tools_seen=true
				}
				;;

			response.output_item.done)
				local _item_info item_type tc_call_id tc_name tc_args_final
				_item_info="$(printf '%s' "$payload" | jq -rj \
					'(.item.type//"") + "\t" + (.item.call_id//"") + "\t" + (.item.name//"") + "\t" + (.item.arguments//"")' \
					2>/dev/null)"
				IFS=$'\t' read -r item_type tc_call_id tc_name tc_args_final <<< "$_item_info"
				[[ "$item_type" != "function_call" ]] && return
				[[ -z "$tc_call_id" ]] && return
				ma_spinner_stop
				# Recover index, or create one if output_item.added never fired
				local tc_idx="${_resp_call_id_to_idx[$tc_call_id]:-}"
				if [[ -z "$tc_idx" ]]; then
					tc_idx="$_tc_count"
					_resp_call_id_to_idx["$tc_call_id"]="$tc_idx"
					_tc_name[tc_idx]="$tc_name"
					_tc_id[tc_idx]="$tc_call_id"
					(( _tc_count++ ))
				fi
				# Prefer delta-accumulated args; fall back to the complete field on the item
				if [[ -n "${_resp_tc_args_buf[$tc_call_id]+x}" && -n "${_resp_tc_args_buf[$tc_call_id]}" ]]; then
					_tc_args[tc_idx]="${_resp_tc_args_buf[$tc_call_id]}"
				elif [[ -n "$tc_args_final" ]]; then
					_tc_args[tc_idx]="$tc_args_final"
				fi
				_tools_seen=false
				;;

			response.function_call_arguments.delta)
				[[ $_tools_status -ne 1 ]] && {
					_tools_status=2
					[[ $_reasoning_status -eq 1 ]] && {
						_reasoning_status=2
						ma_spinner_stop
						_close_reasoning
					}
					[[ $_content_status -eq 1 ]] && {
						_content_status=2
						_process_content_batch
					}
				}

				local _delta_info delta item_id
				_delta_info="$(printf '%s' "$payload" | jq -rj \
					'(.delta//"") + "\t" + (.item_id//"")' 2>/dev/null)"
				IFS=$'\t' read -r delta item_id <<< "$_delta_info"
				[[ -n "$delta" && -n "$item_id" ]] \
					&& _resp_tc_args_buf["$item_id"]+="$delta"
				;;

			response.completed)
				[[ $_reasoning_status -lt 2 ]] && { ma_spinner_stop; _reasoning_status=2; }
				_process_reasoning_batch;
				_process_content_batch;

				#_rs_items="$(jq -c '[.response.output[]? | select(.type=="reasoning")]' <<< "$payload" 2>/dev/null)"
				_rs_items="$(jq -c '[.response.output[]? | select(.type=="reasoning" and (.encrypted_content // "") != "")]' <<< "$payload" 2>/dev/null)"
				[[ -z $_rs_items ]] && _rs_items="[]"

				printf "${A_R}\n"
				[[ "$payload" == *'"usage"'* ]] && { _api_parse_usage payload "$api_type"; }
				;;

			# response.created|response.in_progress|\
			# response.content_part.added|response.content_part.done|\
			# response.failed|response.cancelled|response.incomplete) ;;

		esac
	}


	local start_time=0 err_body=()


	ma_spinner_start

	local _reasoning_status=0 _tools_status=0 _content_status=0 _tools_seen=false

	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ "$_INTERRUPTED" == "true" ]] && break

		_ipc_serve

		[[ "$line" == "HTTP_STATUS:"* ]] && { http_code="${line#HTTP_STATUS:}"; continue; }
		if [[ "$line" != "data: "* ]]; then
			[[ "$line" == "event: "* || -z "$line" ]] && continue
			err_body+=("$line")
			continue
		fi
		payload="${line#data: }"
		[[ "$payload" == "[DONE]" || -z "$payload" ]] && continue

		ma_now _now_us

		case "$api_type" in
			openai_chat)
				case "$payload" in
					(*'"tool_calls"'*|*'"toolCalls"'*|*'"function_call"'*)
						[[ $_tools_status -ne 1 ]] && {
							_tools_status=1
							(( start_time == 0 )) && start_time=$_now_us
							ma_spinner_stop;
							[[ $_content_status -eq 1 ]] && { _process_content_batch; _content_status=2; }
							[[ $_reasoning_status -eq 1 ]] && { _close_reasoning; _reasoning_status=2; }
						}
						_batch_tools+=("$payload")
						(( ${#_batch_tools[@]} >= _MAX_BATCH || _now_us - _tools_last_batch_us >= _BATCH_MAX_MICROSEC )) && _process_tools_batch
						;;
					(*'"content":'*)
						[[ "$payload" != *'"content":null'* && "$payload" != *'"content":""'* ]] && {
							[[ $_content_status -ne 1 ]] && {
								_content_status=1;

								(( start_time == 0 )) && start_time=$_now_us
								ma_spinner_stop;
								[[ $_reasoning_status -eq 1 ]] && { _close_reasoning; _reasoning_status=2; }
								[[ $_tools_status -eq 1 ]] && { _process_tools_batch; _tools_status=2; }
							}

							_batch_content+=("$payload")
							(( ${#_batch_content[@]} >= _MAX_BATCH || _now_us - _content_last_batch_us >= _BATCH_MAX_MICROSEC )) \
								&& _process_content_batch
						}
						;;
					(*'"reasoning_content"'*|*'"thinking"'*|*'"reasoning":'*)
						[[ "$payload" != *'"reasoning":null'* && "$payload" != *'"reasoning":""'* ]] && {

							[[ $_content_status -eq 1 ]] && { _process_content_batch; _content_status=2; }

							[[ $_reasoning_status -ne 1 ]] && {
								_reasoning_status=1
								(( start_time == 0 )) && start_time=$_now_us
								ma_spinner_stop
								[[ ${MA_HIDE_THINKING:-} != false ]] && ma_spinner_start "thinking…" think
								[[ $_tools_status -eq 1 ]] && { _process_tools_batch; _tools_status=2; }
							}

							_batch_reasoning+=("$payload")
							(( ${#_batch_reasoning[@]} >= _MAX_BATCH || _now_us - _reasoning_last_batch_us >= _BATCH_MAX_MICROSEC )) && {
								_process_reasoning_batch;
							}
						}
						;;
				esac
				[[ "${line}" == *'"usage"'* ]] && { _api_parse_usage payload "$api_type"; }
				;;

			openai_resp)
				_process_openai_resp_event
				;;

			anthropic)
				_process_anthropic_event
				[[ "$payload" == *'"usage"'* ]] && { _api_parse_usage payload "$api_type"; }
				;;
		esac

	done < <(
		printf '%s' "$body" | curl ${MA_ENDPOINT_OBJ["api_proxy"]} "${MA_USER_AGENT_ARRAY[@]}" -sS -N --tcp-nodelay -w '\nHTTP_STATUS:%{http_code}\n' \
			-X POST "${MA_ENDPOINT_OBJ["api_url"]}" -H "Content-Type: application/json" "${_h_auth[@]}" --data-binary @- 2>/dev/null
	)

	local _ma_streamproc_pid=$!
	kill "$_ma_streamproc_pid" 2>/dev/null;
	ma_spinner_stop

	_process_reasoning_batch; _process_content_batch

	[[ "$api_type" == "anthropic" ]] && _flush_anthropic_tool || _process_tools_batch

	[[ "$api_type" == openai_chat ]] && {
		[[ $_content_status -gt 0 ]] || [[ $_reasoning_status -gt 0 ]] && {
			(( _MA_SHOULD_PRINT )) && printf "${A_R}\n" >&2
		}
	}

	printf -v "api_response[idx_content]"   '%s' "${_stream_content_parts[@]}"
	printf -v "api_response[idx_reasoning]" '%s' "${_stream_reasoning_parts[@]}"

	if [[ ${MA_SHOW_TG:-} == true ]] && (( _MA_SHOULD_PRINT )) && (( start_time > 100 )); then
		local end_time; ma_now end_time
		local elapsed_us=$(( end_time - start_time ))
		(( elapsed_us > 0 )) && {
			MA_STATS_MODEL_TG=$(( _TOKENS_COMPLETION * 1000000 / elapsed_us ))
			#printf "${A_INFO}\n(TG %d t/s)\n${A_R}" $MA_STATS_MODEL_TG >&2
		}
	fi

	[[ "$_INTERRUPTED" == "true" ]] && return 1

	local tc_json="[]" flat=()
	for ((i=0; i<_tc_count; i++)); do
		local name="${_tc_name[$i]:-}" id="${_tc_id[$i]:-}" args="${_tc_args[$i]:-}" sig="${_tc_sig[$i]:-}"
		[[ -n "$name" && -n "$id" && -n "$args" ]] || continue
		flat+=("$id" "$name" "$args" "$sig")
	done

	(( ${#flat[@]} > 0 )) && { 
		tc_json="$(jq -n --arg provider "$provider" '
			$ARGS.positional as $d |
			[ range(($d|length)/4) as $i | {
				id: $d[$i*4],
				type: "function",
				function: {
					name: $d[$i*4+1],
					arguments: ($d[$i*4+2] | fromjson | tostring)
				}
			} + (if $provider == "google" then {
				extra_content: {
					google: { thought_signature: $d[$i*4+3] }
				}
			} else {} end)]
		' --args "${flat[@]}")"
	}

	if [[ $api_type == anthropic ]]; then
		local _x; printf -v _x '%s,' "${_rs_blocks[@]}"; _rs_items="[${_x%,}]"
	fi
	api_response[idx_rstate]="$_rs_items"

	api_response[idx_tool_calls]="$tc_json"

	api_response[idx_http_code]="$http_code"
	[[ "$http_code" == "200" ]] && return 0
	[[ "$http_code" == "000" || -z "$http_code" ]] && { err "Connection failed (API URL: ${MA_ENDPOINT_OBJ["api_url"]:-unset})\n"; return 1; }
	err "Server error (HTTP $http_code)\n\n"
	api_response[idx_err_body]="${err_body[*]}"
	[[ -n "${api_response[idx_err_body]}" ]] && printf '%s' "${api_response[idx_err_body]}" | jq -br '.' 2>/dev/null
	return 1

}



_agent_run_interrupt() {
	ma_spinner_stop
	[[ ${_INTERRUPTED:-} == true ]] && return
	_INTERRUPTED=true
	printf "${A_R}\n${A_WARN}Operation aborted${A_R}\n" >&2
}



_compact_extract_skill_msgs() { # $1:_msgs_json_array $2:_out_json_array_var (flat array of raw messages: call+result) $3:_active_names_ref(array) $4:_matched_names_out_ref(array)
	local JQ_SKILL_DEFS='
		def skill_msg_pairs:
			. as $msgs
			| reduce ($msgs | to_entries[]) as $e (
				{calls: {}, results: {}};
				($e.value) as $m
				| (if ($m.content|type)=="array" then
					reduce ($m.content[] | select(.type=="tool_use" and .name=="skills")) as $tu (.;
						.calls[$tu.id] = {name: ($tu.input.name // "unknown"), idx: $e.key})
				   else . end)
				| (if ($m.tool_calls|type)=="array" then
					reduce ($m.tool_calls[] | select(.function.name=="skills")) as $tc (.;
						.calls[$tc.id] = {
							name: ((($tc.function.arguments|type)=="string")
								as $isstr
								| if $isstr then (($tc.function.arguments | try fromjson catch {}).name // "unknown")
								  else ($tc.function.arguments.name // "unknown") end),
							idx: $e.key})
				   else . end)
				| (if ($m.content|type)=="array" then
					reduce ($m.content[] | select(.type=="tool_result")) as $tr (.;
						.results[$tr.tool_use_id] = $e.key)
				   else . end)
				| (if $m.role == "tool" then .results[$m.tool_call_id] = $e.key else . end)
			)
			| . as $r
			| [ $r.calls | to_entries[]
				| {id: .key, name: .value.name, call_idx: .value.idx,
				   result_idx: ($r.results[.key] // null)} ];
 
		# dedup by name, keep the pair with the highest call_idx (most recent), preserve order by call_idx
		def dedup_skill_pairs:
			group_by(.name) | map(sort_by(.call_idx) | last) | sort_by(.call_idx);
		'
	local -n _esm_msgs=$1
	local -n _esm_out=$2
	local -n _esm_active=$3
	local -n _esm_matched=$4
 
	local _active_json
	_active_json="$(printf '%s\n' "${_esm_active[@]}" | jq -bRn '[inputs] - [""]')"
 
	local -a _res=()
	mapfile -t _res < <(jq -br --argjson active "$_active_json" "$JQ_SKILL_DEFS"'
		. as $msgs | (skill_msg_pairs | dedup_skill_pairs)
		| map(select(.name as $n | $active | index($n) != null)) as $ordered
		| ( [ $ordered[]
		      | . as $p
		      | ( $msgs[$p.call_idx]
		          | if (.tool_calls|type)=="array"
		            then .tool_calls |= map(select(.id == $p.id))
		            else . end ),
		        (if $p.result_idx != null then $msgs[$p.result_idx] else empty end)
		    ] | tojson),
		  ($ordered[] | .name)
	' <<< "$_esm_msgs")
	_esm_out="${_res[0]}"
	_esm_matched=("${_res[@]:1}")
}

_compact_prep() { # $1:_session_json $2:head_budget $3:tail_budget $4:first_trigger $5:_out
	local -n _scp_msgs=$1
	local head_budget="$2" tail_budget="$3" first_trigger="$4"
	local -n _scp_out=$5

	mapfile -t _scp_out < <(jq -br \
		--argjson head_budget "$head_budget" \
		--argjson tail_budget "$tail_budget" \
		--arg trigger "$first_trigger" \
		"$JQ_BOUNDARY_DEFS"'
		. as $msgs
		| ($msgs | boundary_reduce) as $r
		| ($r.boundaries) as $b
		| ($r.size) as $total
		| ($r.idx) as $total_len
		| ( [ $b[] | select(.size <= $head_budget) | .idx ] | max // 0 ) as $raw_head_cut
		| ( [ $b[] | select(($total - .size) <= $tail_budget) | .idx ] | min // $total_len ) as $tail_cut_raw
		| (if $tail_cut_raw < $raw_head_cut then $raw_head_cut else $tail_cut_raw end) as $tail_cut
		| ((($msgs[0].role // "") == "system")) as $has_system
		| (if $has_system and $raw_head_cut < 1 then 1 else $raw_head_cut end) as $head_cut
		| ($msgs[:$head_cut]) as $head_msgs
		| ($msgs[$tail_cut:]) as $tail_msgs
		| ($msgs[$head_cut:$tail_cut]) as $middle_msgs
		| ($msgs[:$tail_cut]) as $head_plus_middle
		| ([$head_plus_middle[]|strip_heavy|tojson|length]|add // 0) as $hm_size
		| ([$head_msgs[]|strip_heavy|tojson|length]|add // 0) as $head_size
		| ($head_plus_middle + [{role:"user",content:$trigger}]) as $fastpath_payload
		| ($total_len|tostring),
		  ($head_cut|tostring),
		  ($tail_cut|tostring),
		  ($hm_size|tostring),
		  ($head_size|tostring),
		  ($head_msgs|tojson),
		  ($tail_msgs|tojson),
		  ($middle_msgs|tojson),
		  ($fastpath_payload|tojson)
	' <<< "$_scp_msgs" 2>/dev/null)
}

_compact_bucket_middle_fast() { # $1:_msgs $2:budget $3:_out
	local -n _bkf_msgs=$1
	local budget="$2"
	local -n _bkf_out=$3

	local -a _bnd_lines=()
	mapfile -t _bnd_lines < <(jq -br "$JQ_BOUNDARY_DEFS"' (. | boundary_reduce).boundaries[] | "\(.idx) \(.size)" ' <<< "$_bkf_msgs")

	local -a range_s=() range_e=()
	local last_idx=0 last_size=0
	local cand_idx=-1 cand_size=0
	local idx size

	for line in "${_bnd_lines[@]}"; do
		idx="${line%% *}"; size="${line#* }"
		(( idx == 0 )) && continue
		(( size - last_size <= budget )) && { cand_idx=$idx; cand_size=$size; continue; }

		(( cand_idx == -1 )) && {
			err "compaction: a single turn exceeds the compaction budget (forcing oversized bucket ending at message $idx)\n"
			range_s+=("$last_idx"); range_e+=("$idx")
			last_idx=$idx; last_size=$size
			cand_idx=-1
			continue
		}

		range_s+=("$last_idx"); range_e+=("$cand_idx")
		last_idx=$cand_idx; last_size=$cand_size
		cand_idx=-1

		if (( size - last_size <= budget )); then
			cand_idx=$idx; cand_size=$size
		else
			err "compaction: a single turn exceeds the compaction budget (forcing oversized bucket ending at message $idx)\n"
			range_s+=("$last_idx"); range_e+=("$idx")
			last_idx=$idx; last_size=$size
			cand_idx=-1
		fi
	done
	(( cand_idx != -1 && cand_idx > last_idx )) && { range_s+=("$last_idx"); range_e+=("$cand_idx"); }

	local ranges="[" i
	for (( i=0; i<${#range_s[@]}; i++ )); do
		(( i > 0 )) && ranges+=","
		ranges+="[${range_s[$i]},${range_e[$i]}]"
	done
	ranges+="]"
	_bkf_out="$ranges"
}

_compact_build_bucket_call() { # $1:_head_msgs $2:rolling_json_literal $3:_bucket_msgs $4:trigger_text $5:_out
	local -n _bbc_head=$1
	local rolling_literal="$2"
	local -n _bbc_bucket=$3
	local trigger_text="$4"
	local -n _bbc_out=$5
	local summary_field="null"
	[[ -n "$rolling_literal" ]] && summary_field="$rolling_literal"
	_bbc_out="$(
		printf '%s\n%s\n%s' "$_bbc_head" "$summary_field" "$_bbc_bucket" |
			jq -bcs --arg trig "$trigger_text" '
				.[0] as $head | .[1] as $summary | .[2] as $bucket
				| $head
				  + (if $summary == null then [] else [{role:"assistant",content:$summary}] end)
				  + $bucket
				  + [{role:"user",content:$trig}]
			'
	)"
}

_compact_summarize_call() { # 1:messages(ref) 2:summary_response(ref)
	local -n _summary_literal=$2
	local _api_response=() _api_rc=1
	ma_spinner_start "summarizing…"
	ma_api_send_request $1 _api_response _api_rc &>/dev/null
	ma_spinner_stop
	local response_content="${_api_response[idx_content]:-}"
	if [[ "$_INTERRUPTED" == "true" ]]; then warn "compaction: interrupted (session unchanged).\n"; return 1; fi
	(( _api_rc != 0 )) && { err "compaction: summarization request failed (session unchanged).\n"; return 1; }
	[[ "${_api_response[idx_tool_calls]:-[]}" != "[]" || -z "$response_content" ]] && { err "compaction: summarization request failed (session unchanged).\n"; return 1; }
	_summary_literal="$(jq -bcn --arg t "$response_content" '$t' 2>/dev/null)"
}

ma_agent_compact() { # $1:head_budget(chars) $2:tail_budget(chars) $3:compact_budget(chars)
	local _prev_int_trap
	_INTERRUPTED=false
	_prev_int_trap="$(trap -p INT)"
	trap '_agent_run_interrupt' INT
	_ma_compaction_cleanup() {
		ma_spinner_stop
		unset _MA_COMPACTING
		if [[ -n "${_prev_int_trap:-}" ]]; then eval "$_prev_int_trap"; else trap - INT; fi
	}
	trap '_ma_compaction_cleanup; trap - RETURN' RETURN

	_MA_COMPACTING=true
	warn "Compaction in progress (Ctrl+C to interrupt).\n\n"
	local -n _sc_session=MA_THREAD_JSON

	local ctx=${MA_ENDPOINT_OBJ["model.ctx"]:-120000}
	local n_ctx_chars=$(( ctx * 4 )) # approximate amount of chars for english

	MA_COMPACT_BUDGET_HEAD=${MA_COMPACT_BUDGET_HEAD:-0}
	MA_COMPACT_BUDGET_TAIL=${MA_COMPACT_BUDGET_TAIL:-10000}
	local head_budget=${1:-$MA_COMPACT_BUDGET_HEAD} tail_budget=${2:-$MA_COMPACT_BUDGET_TAIL} compact_budget="${3:-$n_ctx_chars}"

	local compaction_prompt="${MA_COMPACT_PROMPT:-\

CRITICAL: Respond with TEXT ONLY. Do NOT call any tools.

Identify the tasks the user has explicitly asked you to solve. Summarize the partial transcript above into
a concise, self-contained Handoff that preserves the context needed to continue the work in a future context
where the original history may no longer be available. Include useful information only: the current state,
important decisions and learnings, remaining work, next steps, and any other information needed to make
continued progress.

Respond with ONLY the handoff text, no preamble, no tool calls.
}"

	local _first_trigger="$compaction_prompt"
	local _continue_trigger="${MA_COMPACT_CONTINUE_PROMPT:-\
Update the existing handoff with the conversation turns below. 
$compaction_prompt}"

	JQ_BOUNDARY_DEFS='
	def strip_heavy:
		if (.content|type) == "array" then
			.content |= map(
				if .type == "image_url" then {type:"text", text:"[image omitted]"}
				elif .type == "file" then {type:"text", text:"[file: " + (.file.filename // "attachment") + " omitted]"}
				elif .type == "input_audio" then {type:"text", text:"[audio omitted]"}
				else . end)
		else . end;
	def add_ids($m):
		(if ($m.content|type) == "array"
		 then [$m.content[]? | select(.type=="tool_use") | .id] else [] end)
		+ (if ($m.tool_calls|type) == "array"
		   then [$m.tool_calls[]? | .id] else [] end);
	def remove_ids($m):
		(if ($m.content|type) == "array"
		 then [$m.content[]? | select(.type=="tool_result") | .tool_use_id] else [] end)
		+ (if $m.role == "tool" then [$m.tool_call_id] else [] end);
	def boundary_reduce:
		reduce .[] as $m (
			{pending: [], size: 0, idx: 0, boundaries: [{idx:0, size:0}]};
			($m | strip_heavy | tojson | length) as $msz
			| ((.pending + add_ids($m)) - remove_ids($m)) as $newpending
			| (.size + $msz) as $newsize
			| (.idx + 1) as $newidx
			| {
				pending: $newpending, size: $newsize, idx: $newidx,
				boundaries: (.boundaries + (if ($newpending|length) == 0
					then [{idx: $newidx, size: $newsize}] else [] end))
			  }
		);'


	local -a _prep=()
	_compact_prep _sc_session "$head_budget" "$tail_budget" "$_first_trigger" _prep
	[[ "$_INTERRUPTED" == "true" ]] && { warn "compaction: interrupted during preparation (session unchanged).\n"; return 1; }

	local _total_len="${_prep[0]:-}" head_cut="${_prep[1]:-}" tail_cut="${_prep[2]:-}"
	local _hm_size="${_prep[3]:-}" _head_size="${_prep[4]:-}"
	local _head_msgs="${_prep[5]:-}" _tail_msgs="${_prep[6]:-}" _middle_msgs="${_prep[7]:-}"
	local _fastpath_payload="${_prep[8]:-}"
	[[ -n "${_fastpath_payload:-}" ]] || { warn "compaction: interrupted during preparation (session unchanged).\n"; return 1; }

	(( _total_len <= 2 )) && { info "compaction: nothing to compact (session has $(( _total_len - 1 )) messages).\n"; return 0; }
	(( head_cut >= tail_cut )) && { info "compaction: nothing to compact (session already fits within head+tail budgets).\n"; return 0; }

	info "compaction: started (session has $(( _total_len - 1 )) messages)\n"

	local _final_summary_literal=""   # jq-encoded

	if (( _hm_size <= compact_budget )); then	# fast path, just use the same session messages
		local _temp_thread_json="$_fastpath_payload"

		if ! _compact_summarize_call _temp_thread_json _final_summary_literal; then return 1; fi

	else
		local _reserve="${MA_COMPACT_RESERVE:-2000}"
		local _bucket_budget=$(( compact_budget - _head_size - _reserve ))
		if (( _bucket_budget <= 0 )); then err "compaction: compact_budget too small relative to head_budget (session unchanged).\n"; return 1; fi

		local _bucket_ranges=""
		_compact_bucket_middle_fast _middle_msgs "$_bucket_budget" _bucket_ranges
		[[ "$_INTERRUPTED" == "true" ]] && { err "compaction: interrupted during bucketing (session unchanged).\n"; return 1; }

		local -a _bucket_msgs_arr=()
		mapfile -t _bucket_msgs_arr < <(jq -bc --argjson ranges "$_bucket_ranges" ' . as $mid | $ranges[] | $mid[.[0]:.[1]] ' <<< "$_middle_msgs")

		[[ "$_INTERRUPTED" == "true" ]] && { err "compaction: interrupted during bucketing (session unchanged).\n"; return 1; }

		local _n_buckets=${#_bucket_msgs_arr[@]}
		info "compaction: head+middle exceeds compact_budget.\n"

		local _bidx=0
		while (( _bidx < _n_buckets )); do
			local _cur_bucket="${_bucket_msgs_arr[$_bidx]}"
			local _trigger_text
			if [[ -n "$_final_summary_literal" ]]; then _trigger_text="$_continue_trigger"; else _trigger_text="$_first_trigger"; fi

			local _temp_thread_json=""
			_compact_build_bucket_call _head_msgs "$_final_summary_literal" _cur_bucket "$_trigger_text" _temp_thread_json
			[[ "$_INTERRUPTED" == "true" ]] && { err "compaction: interrupted during bucketing (session unchanged).\n"; return 1; }

			if ! _compact_summarize_call _temp_thread_json _final_summary_literal; then return 1; fi

			_bidx=$(( _bidx + 1 ))
		done
	fi

	local _compacted_away
	_compacted_away="$(printf '%s\n%s' "$_head_msgs" "$_middle_msgs" | jq -bcs '.[0] + .[1]')"

	local -a _active_names=("${!MA_ACTIVE_SKILLS[@]}")

	# don't reinsert skills already present in the tail
	local -a _tail_names=() _reinsert_names=()
	local _tail_skill_msgs="[]"
	_compact_extract_skill_msgs _tail_msgs _tail_skill_msgs _active_names _tail_names
	for _n in "${_active_names[@]}"; do
		if jq -e --arg n "$_n" 'any(.[]; (.content|type)=="string"
			and (.content|contains("<activated_skill name=\"" + $n + "\">")))' \
			<<< "$_tail_msgs" &>/dev/null; then
			_tail_names+=("$_n")
		fi
	done
	for _n in "${_active_names[@]}"; do
		[[ " ${_tail_names[*]} " == *" $_n "* ]] || _reinsert_names+=("$_n")
	done

	# skills above outside tail
	local -a _matched_names=()
	local _skill_msgs="[]"
	_compact_extract_skill_msgs _compacted_away _skill_msgs _reinsert_names _matched_names

	local -a _missing_names=()
	for _n in "${_reinsert_names[@]}"; do
		[[ " ${_matched_names[*]} " == *" $_n "* ]] || _missing_names+=("$_n")
	done

	local _manual_msgs="[]"
	for _n in "${_missing_names[@]}"; do
		local skill_content=
		if ma_skill_load skill_content "$_n" ""; then
			skill_content=$'<activated_skill name="'"$_n"$'">\n'"$skill_content"$'\n</activated_skill>'
			_manual_msgs="$(jq -bc --arg c "$skill_content" '. + [{role:"user", content:$c}]' <<< "$_manual_msgs")"
		else
			unset 'MA_ACTIVE_SKILLS[$_n]'
		fi
	done
 
	local _n_skill_msgs _n_manual_msgs
	_n_skill_msgs="$(jq 'length' <<< "$_skill_msgs")"
	_n_manual_msgs="$(jq 'length' <<< "$_manual_msgs")"
	(( _n_skill_msgs > 0 )) && info "compaction: reinserting $_n_skill_msgs skill messages (call+result pairs)\n"
	(( _n_manual_msgs > 0 )) && info "compaction: manually reinjecting $_n_manual_msgs skills\n"
 
	local _summary_prefix="${MA_COMPACT_SUMMARY_PREFIX:-[Session was compacted. What follows is a handoff summary of the earlier conversation.]

}"
	_sc_session="$(
		printf '%s\n%s\n%s\n%s\n%s' "$_head_msgs" "$_tail_msgs" "$_final_summary_literal" "$_skill_msgs" "$_manual_msgs" |
		jq -bcs --arg prefix "$_summary_prefix" \
			'.[0] as $head | .[1] as $tail | .[2] as $summary | .[3] as $skillmsgs | .[4] as $manualmsgs
			| $head + [{role:"user", content:($prefix + $summary)}] + $skillmsgs + $manualmsgs + $tail'
	)"
 
	local _new_len=$(( _n_skill_msgs + _n_manual_msgs + head_cut + 1 + (_total_len - tail_cut) ))
	info "compaction: done. $(( _total_len - 1 )) messages -> $(( _new_len - 1 )) messages\n"

	MA_CTX_USAGE["$MA_THREAD_NAME"]=-1

	if [[ -v 'MA_DELEGATED["${MA_THREAD_NAME}@task"]' ]] && (( head_budget < 100 )); then
		thread_add_msg_after_system MA_THREAD_JSON "user" "${MA_DELEGATED["${MA_THREAD_NAME}@task"]}"$'\n'"${MA_SUBMIT_MSG}"
	fi

	if [[ 'MA_EVALUATED["$MA_THREAD_NAME@prompt"]' ]] && (( head_budget < 100 )); then
		thread_add_msg_after_system MA_THREAD_JSON "user" "${MA_EVALUATED["$MA_THREAD_NAME@prompt"]}"
	fi

	return 0
}






# pattern matching examples
declare -a MA_PATTERNS_BASH=(
	"recursive delete|rm[[:space:]]+-[^[:space:]]*r"
	"root filesystem wipe|rm[[:space:]]+-rf[[:space:]]*/[[:space:]]"
	"filesystem format|mkfs"
	"raw device write|dd[[:space:]].*of=/dev/"
	"raw device overwrite|>[[:space:]]*/dev/sd[a-z]"
	"kill all processes|kill[[:space:]]+-9[[:space:]]+-1"
	"fork bomb|:\(\)[[:space:]]*\{[[:space:]]*:[[:space:]]*\|[[:space:]]*:[[:space:]]*&[[:space:]]*\}[[:space:]]*;"
	"sudo command|[[:space:]]sudo[[:space:]]|^sudo[[:space:]]"
	"dangerous permissions|(chmod|chown)[[:space:]].*777"
	"pacman install|pacman[[:space:]]+-S"
	"global npm install|npm[[:space:]]+install[[:space:]].*(--global|-g)"
	"global pip install|pip[[:space:]]+install[[:space:]]+--user"
	"pipenv install|pipenv[[:space:]]+install"
	"pipe remote script to shell|(curl|wget)[[:space:]].*\|[[:space:]]*(ba)?sh"
	"force git push|git[[:space:]]+push[[:space:]].*(--force|-f[[:space:]])"
	"Windows recursive delete|rmdir[[:space:]]+.*/[Ss]"
	"Windows force delete|del[[:space:]]+.*/[Ff]"
	"disk format|format[[:space:]]"
	"disk partitioning|diskpart"
	"system shutdown|shutdown[[:space:]]"
	"user account manipulation|net[[:space:]]+user"
	"permission escalation|icacls[[:space:]].*/[Gg]rant"
	"registry manipulation|reg[[:space:]]+(add|delete|load|import)"
	"service manipulation|sc[[:space:]]+(create|delete|start)"
	"ownership takeover|takeown"
	"secure disk wipe|cipher[[:space:]]+/[Ww]"
	"process spawning via wmic|wmic[[:space:]]+process[[:space:]]+call[[:space:]]+create"
	"scheduled task creation|schtasks[[:space:]]+/[Cc]reate"
	"write to .env|>[[:space:]]*\\.env([^.]|$)"
	"write to .dev.vars|>[[:space:]]*\\.dev\\.vars"
	"write to .pem|>[[:space:]]*.*\\.pem"
	"write to .key|>[[:space:]]*.*\\.key"
	"tee to .env|tee[[:space:]]+.*\\.env([^.]|$)"
	"tee to .dev.vars|tee[[:space:]]+.*\\.dev\\.vars"
	"cp to .env|cp[[:space:]]+.*[[:space:]]+\\.env([^.]|$)"
	"mv to .env|mv[[:space:]]+.*[[:space:]]+\\.env([^.]|$)"
	"write to Windows system|>[[:space:]]*[A-Za-z]:[/\\\\]Windows[/\\\\]"
	"write to Program Files|>[[:space:]]*[A-Za-z]:[/\\\\]Program[[:space:]]*Files[/\\\\]"
	"write to System32|>[[:space:]]*[A-Za-z]:[/\\\\](Windows[/\\\\])?System32[/\\\\]"
	"tee to Windows system|tee[[:space:]]+[A-Za-z]:[/\\\\](Windows|System32)[/\\\\]"
)
declare -a MA_PATTERNS_PROTECTED_PATHS=(
	"environment file|\\.env(\\.local|\\.production|\\.staging)?$"
	"dev vars file|\\.dev\\.vars"
	"private key file|\\.(pem|key)$"
	"SSH key|id_(rsa|ed25519|ecdsa)"
	"SSH directory|\\.ssh/"
	"secrets file|secrets?\\.(json|ya?ml|toml)$"
	"credentials file|credentials"
	"git directory|(^|/)\\.git/"
	"node_modules|node_modules/"
	"Windows system directory|[/\\\\]Windows[/\\\\]"
	"Windows System32|[/\\\\]System32[/\\\\]"
	"Program Files|[/\\\\]Program[[:space:]]*Files[/\\\\]"
	"Windows AppData|[/\\\\]AppData[/\\\\]"
	"user registry hive|NTUSER\\.DAT"
	"Windows certificate|\\.(pfx|p12)$"
)
declare -a MA_PATTERNS_SECRETS=(
	"environment file|\\.env(\\.local|\\.production|\\.staging)?([^[:alnum:]_.-]|$)"
	"dev vars file|\\.dev\\.vars"
	"private key file|\\.(pem|key|pfx|p12)([^[:alnum:]_.-]|$)"
	"SSH key|id_(rsa|ed25519|ecdsa)"
	"SSH directory|\\.ssh/"
	"secrets file|secrets?\\.(json|ya?ml|toml)([^[:alnum:]_.-]|$)"
	"cloud credentials|\\.aws/|\\.netrc|credentials\\.(json|ya?ml)"
	"user registry hive|NTUSER\\.DAT"
)

ma_pattern_check() {
	local -n _sc_check_list="$1"
	local cmd="$2"
	_PATTERN_REASON=''
	local entry desc pattern
	for entry in "${_sc_check_list[@]}"; do
		desc="${entry%%|*}"
		pattern="${entry#*|}"
		if [[ "$cmd" =~ $pattern ]]; then _PATTERN_REASON="$desc"; return 0; fi
	done
	return 1
}
ma_prompt_confirm() {
    local fn_name="$1" fn_args="$2" reason="$3"
    local timeout="${SAFE_PROMPT_TIMEOUT:-600}"
	_MA_CONFIRMED_NEVER=false
    ma_spinner_stop

	MA_TOOL_IS_REPRINTING=true
    ma_toolcall_header "$fn_name" "$fn_args" >&2
	unset MA_TOOL_IS_REPRINTING

    printf "\n${A_ERR}${A_B}Risk:${A_R} ${A_I}%s${A_I0}. ${A_B}Allow?${A_B0} [y/N/never] ${A_D}(auto-deny in %ds)${A_D0} " "$reason" "$timeout" >&2

	_hook_call confirm_start "$fn_name" "$fn_args" "$reason"
    trap '_hook_call confirm_end; trap - RETURN' RETURN

	[[ -t 0 ]] && return 1

    local ans=""
    local old_stty
    old_stty="$(stty -g </dev/tty 2>/dev/null)"
    stty echo </dev/tty 2>/dev/null

    local old_trap
    old_trap=$(trap -p INT)
    local interrupted=0
    trap 'interrupted=1' INT

    local read_rc=0
    ans=$(bash -c 'IFS= read -r -t '"$timeout"' choice </dev/tty && echo "$choice"') || read_rc=$?

    stty "$old_stty" </dev/tty 2>/dev/null

	if [[ -n "$old_trap" ]]; then eval "$old_trap"; else trap - INT; fi

	ans=${ans,,}   # case-insensitive
	if (( interrupted || read_rc )) || [[ $ans != y && $ans != yes && $ans != never ]]; then
		printf "\n${A_ERR}Operation blocked.${A_R}\n\n" >&2
		return 1
	fi
	if [[ $ans == never ]]; then
		_MA_CONFIRMED_NEVER=true
		printf "\n${A_ERR}Operation blocked (never).${A_R}\n\n" >&2
		return 1
	fi
	return 0
}


is_path_out_of_confinement() {
	local real_path="$(realpath -m "$1" 2>/dev/null)" || return 0
	[[	"$real_path" != "$MA_WORKING_DIR"/* &&
		"$real_path" != "$MA_WORKING_DIR" &&
		"$real_path" != "$_ma_notes_dir"/* &&
		"$real_path" != ${TMPDIR:-/tmp}/* &&
		"$real_path" != 'C:/tmp/'* ]]
}

_tool_approval_key() {
	local -n key=$1
	local fn_name=$2 fn_args=$3
	local value hash= need_hash=0 limit=0 sep=':'
	case $fn_name in
		read|symbols|ls) value=$(jq -jbr '.path // empty' <<< "$fn_args" 2>/dev/null) ;;
		write|edit) 
			if [[ ${MA_CALLCHECK_ANALYZER:-} == true && ${MA_CALL_ANALYZER_SCAN_EDITS:-} == true ]]; then
				value=$(jq -cbr '.' <<< "$fn_args" 2>/dev/null); need_hash=1
			else
				value=$(jq -jbr '.path // empty' <<< "$fn_args" 2>/dev/null)
			fi
			;;
		bash) value=$(jq -jbr '.command // empty' <<< "$fn_args" 2>/dev/null); limit=32;  need_hash=1 ;;
		*) value=$(jq -cbr '.' <<< "$fn_args" 2>/dev/null); limit=0; need_hash=1 ;;
	esac
	[[ -n $value ]] || return 1
	if (( need_hash && ${#value} > limit )); then
		ma_hash hash "$value"
		if [[ -n $hash ]]; then value=${value:0:limit}$hash; else value=${value:0:1024}; fi
	fi
	key=$fn_name$sep$value
}

_tool_execute() {
	local call_id="$1" call_fn_name="$2" fn_name="$2" fn_args="$3" _tool_result=

	ma_toolcall_resolve_real fn_name fn_args

	(( ++MA_TOOLS_CALLS["$fn_name"] ))

	[[ -v 'MA_ROLE_TOOLS["$fn_name"]' || -v 'MA_LAZY_TOOLS["$fn_name"]' || -v 'MA_ALWAYS_ALLOWED_TOOLCALLS[$fn_name]' ]] || {
		warn "Warning: tool call not in tool list \"$fn_name\".\n"
		thread_add_tool_result MA_THREAD_JSON "$call_id" "$call_fn_name" "DENIED: tool not allowed in current session"$'\n'
		(( ++MA_TOOLS_FAILURES["$fn_name"] ))
		return 1
	}

	_hook_call tool_start "$fn_name" fn_args
	local t_ret=$?
	(( "${t_ret:-}" == 1 )) && {
		(( ++MA_TOOLS_FAILURES["$fn_name"] ))
		warn "Tool call '$fn_name' blocked by hook function.\n\n"
		thread_add_tool_result MA_THREAD_JSON "$call_id" "$call_fn_name" "DENIED: Tool call blocked by hook function"$'\n'
		return 1
	}

	[[ ${MA_CALLCHECK_ALWAYS:-} == true || ${MA_CALLCHECK_PATTERN:-} == true || ${MA_CALLCHECK_ANALYZER:-} == true ]] && {
		local approval_key='' need_confirm=false confirm_reason=''
		if [[ -v 'MA_ALWAYS_ALLOWED_TOOLCALLS[$fn_name]' ]]; then
			need_confirm=false
		else
			_tool_approval_key approval_key "$fn_name" "$fn_args" || approval_key=''
			if [[ -n $approval_key && -v 'MA_DISALLOW_CALLS[$approval_key]' ]]; then
				thread_add_tool_result MA_THREAD_JSON "$call_id" "$call_fn_name" \
					"DENIED: the user permanently refused this action. Do not retry it or look for a workaround."$'\n'
				(( ++MA_TOOLS_FAILURES["$fn_name"] ))
				return 1
			fi
			if [[ -n $approval_key && -v 'MA_APPROVED_CALLS[$approval_key]' ]]; then
				need_confirm=false
			elif [[ ${MA_CALLCHECK_ALWAYS:-} == true ]]; then
				need_confirm=true
				confirm_reason="ask-always mode"
			elif [[ ${MA_CALLCHECK_ANALYZER:-} == true ]]; then
				ma_spinner_start 'analyzing tool call…'
				local cur_thread=$MA_THREAD_NAME call_check='' _api_response=() _api_rc=1 _temp_analyzer_json reserved_name="reserved_call_analyzer"
				if ! declare -p "MA_THREAD_OBJ_$reserved_name" &>/dev/null; then
					thread_obj_set "$reserved_name" call_analyzer 0
				fi
				_thread_switch_global_references "$reserved_name"
				_temp_analyzer_json="$(printf '%s\x1f%s\x1f%s\x1f%s' \
					"${MA_THREAD_OBJ[system_prompt]}" "$fn_name" "${MA_TOOL[$fn_name]:-}" "$fn_args" |
					jq -bcRs '
						split("\u001f") as [$sys, $name, $schema, $args]
						| (try ($schema | fromjson | tojson) catch $schema) as $schema_c
						| [ {role: "system", content: $sys},
							{role: "user", content: ("Schema for \u0027" + $name + "\u0027:\n\n" + $schema_c
								+ "\n\nTool call:\n\n" + $args + "\n\nOutput FAIL or PASS")} ]
					' 2>/dev/null)"
				ma_api_send_request _temp_analyzer_json _api_response _api_rc &>/dev/null
				call_check="${_api_response[idx_content]:-}"
				_thread_switch_global_references "$cur_thread"
				(( $_api_rc != 0 )) || [[ $call_check != *PASS* ]] && { need_confirm=true; confirm_reason="flagged by call_analyzer"; }
				ma_spinner_stop
			elif [[ ${MA_CALLCHECK_PATTERN:-} == true ]]; then
				case $fn_name in
					bash)
						local _cmd=
						{ IFS= read -r -d '' _cmd; } < <( jq -brj '(.command // ""), "\u0000"' <<< "$fn_args" 2>/dev/null)
						if   ma_pattern_check MA_PATTERNS_BASH "$_cmd";    then need_confirm=true; confirm_reason=$_PATTERN_REASON
						elif ma_pattern_check MA_PATTERNS_SECRETS "$_cmd"; then need_confirm=true; confirm_reason="touches ${_PATTERN_REASON}"
						fi
					;;
					write|edit)
						local _path=
						{ IFS= read -r -d '' _path; } < <( jq -brj '(.path // ""), "\u0000"' <<< "$fn_args" 2>/dev/null)
						if ma_pattern_check MA_PATTERNS_PROTECTED_PATHS "$_path"; then need_confirm=true; confirm_reason=$_PATTERN_REASON; fi
					;;
					read|symbols|grep)
						local _path=
						{ IFS= read -r -d '' _path; } < <( jq -brj '(.path // ""), "\u0000"' <<< "$fn_args" 2>/dev/null)
						if ma_pattern_check MA_PATTERNS_SECRETS "$_path"; then need_confirm=true; confirm_reason="reads ${_PATTERN_REASON}"; fi
					;;
				esac
			fi
		fi
		[[ $need_confirm == true ]] && {
			if ! ma_prompt_confirm "$fn_name" "$fn_args" "$confirm_reason"; then
				if [[ ${_MA_CONFIRMED_NEVER:-} == true ]]; then
					[[ -n $approval_key ]] && MA_DISALLOW_CALLS["$approval_key"]=1
					thread_add_tool_result MA_THREAD_JSON "$call_id" "$call_fn_name" \
						"DENIED: the user permanently refused this action. Do not retry it or look for a workaround."$'\n'
				else
					thread_add_tool_result MA_THREAD_JSON "$call_id" "$call_fn_name" \
						"DENIED: User confirmation failed or timed out"$'\n'
				fi
				(( ++MA_TOOLS_FAILURES["$fn_name"] ))
				return 1
			fi
		}

		case $fn_name in
			edit|write) # no point in saving always unique tool calls
				[[ ${MA_CALL_ANALYZER_SCAN_EDITS:-} != true ]] && {
					[[ -n $approval_key ]] && MA_APPROVED_CALLS["$approval_key"]=1
				}
				;;
			*) [[ -n $approval_key ]] && MA_APPROVED_CALLS["$approval_key"]=1 ;;
		esac

	}

	(( _MA_SHOULD_PRINT )) && ma_toolcall_header "$fn_name" "$fn_args"

	case "$fn_name" in
		delegate) delegated_calls+=( ["$call_id"]="$fn_args" ); info '\n'; return;;
		submit)	
			[[ ! -v 'MA_USER_THREADS["$MA_THREAD_NAME"]' ]] && {
				submitted_results+=( ["$call_id"]="$fn_args" ); info '\n'; return;
			}
			;;
		feedback)
			if execute_feedback &>/dev/null; then
				[[ ! -v 'MA_USER_THREADS["$MA_THREAD_NAME"]' ]] && {
					submitted_results+=( ["$call_id"]="$fn_args" ); info '\n';
				}
			else
				thread_add_tool_result MA_THREAD_JSON "$call_id" "$call_fn_name" "ERROR: revise requires steering"$'\n'
			fi
			return
		   	;;
	esac

	if [[ ${MA_USE_IPC:-} == true ]]; then
		ma_ipc_run _tool_result err_code ma_toolcall_execute "$fn_name" "$fn_args"
	else
		if [[ ${MA_TOOLCALL_IN_SAME_SHELL:-} == true ]] && (( MA_BASH_53 )); then
			_tool_result=${ ma_toolcall_execute "$fn_name" "$fn_args"; }
		else
			_tool_result=$( ma_toolcall_execute "$fn_name" "$fn_args" )
		fi
		err_code=$?
	fi

	(( err_code != 0 )) && (( ++MA_TOOLS_FAILURES["$fn_name"] ))

	(( _MA_SHOULD_PRINT )) && {
		local _c=${A_TOOL_OK}; [[ $err_code != 0 ]] && _c=${A_TOOL_FAIL}
		ma_toolcall_output "$fn_name" "$_tool_result" "" "$_c"
	}

	_hook_call tool_end "$fn_name" _tool_result "$err_code"

	[[ -z "${_tool_result}" ]] && _tool_result="[No output]"
	local chars_limit=${MA_TOOL_CHARS_LIMIT:-120000}
	(( ${#_tool_result} >= chars_limit )) && {
		local hchars_limit; ma_human_num "$chars_limit" hchars_limit
		_tool_result="${_tool_result:0:chars_limit}"$'\n'"[Result Truncated to ${hchars_limit} chars]";
		warn "[Tool result truncated to ${hchars_limit} chars]\n\n";
	}
	[[ "$_INTERRUPTED" == "true" ]] && { _tool_result="${_tool_result}"$'\n'"[Tool interrupted by the user]"; }

	thread_add_tool_result MA_THREAD_JSON "$call_id" "$call_fn_name" "$_tool_result"
	return 0
}


_agent_maybe_compact() { # 1:thread_json_ref 2:doc_file
	[[ -n "${_MA_COMPACTING:-}" ]] && return 0

	local ctx=${MA_ENDPOINT_OBJ["model.ctx"]:-120000}
	[[ ${MA_COMPACT_AUTO:-true} != "true" || "${ctx:-0}" -le 0 ]] && return 0
	local tokens_used=${MA_CTX_USAGE["$MA_THREAD_NAME"]:-0}
	(( tokens_used > 0 )) && {
		local _pct=$(( tokens_used * 100 / ctx ))
		if (( _pct >= ${MA_COMPACT_THRES:-85} )); then
			printf "${A_WARN}[auto-compaction] Context at %d%% (%d/%d tokens)${A_R}\n" "$_pct" "$tokens_used" "$ctx" >&2
			ma_agent_compact
			local ret_code=$?
			info '\n'
			return $ret_code
		fi
	}
	return 0
}

_agent_wrap_response() { # 1:reasoning 2:content 3:out(ref)
	if [[ -n "$1" && "${_MA_COMPACTING:-}" != true && "${MA_NO_PRESERVE_THINKING:-}" != true ]]; then
		if [[ -n "$2" ]]; then printf -v "$3" '<think>%s</think>\n%s' "$1" "$2"; else printf -v "$3" '<think>%s</think>' "$1"; fi
	else
		printf -v "$3" '%s' "$2"
	fi
}

ma_api_send_request() { # 1:thread_json 2:api_response(ref) 3:api_rc 4:streaming
	local _thread_json=$1
	local -n sc_api_response=$2
	local -n sc_api_rc=$3
	local streaming=${MA_THREAD_OBJ["stream"]:-true}

	local _body
	_api_request_body "$_thread_json" _body
	_hook_call request _body
	if [[ $streaming != false ]]; then _api_call_stream _body $2; else _api_call _body $2; fi
	sc_api_rc=$?
	_hook_call response $2 

	[[ "$streaming" != "true" ]] && {
		(( _MA_SHOULD_PRINT )) && [[ -n "${_api_response[idx_reasoning]:-}" && ${MA_HIDE_THINKING:-} != true ]] && {
			printf "${A_THINK}%s\n" "${_api_response[idx_reasoning]:-}" >&2
			[[ "${_api_response[idx_reasoning]: -1}" != $'\n' ]] && printf '\n' >&2
		}
		[[ -n ${_api_response[idx_content]:-} ]] && printf "${A_RESP}%s${A_R}\n" "${_api_response[idx_content]:-}"
	}
}

_thread_switcharoo(){
	[[ ${submitted_results[*]+x} ]] && {
		local cid= d_args=
		for cid in "${!submitted_results[@]}"; do 
			d_args="${submitted_results["$cid"]}";
			break;
		done
		if [[ ${MA_THREAD_OBJ[task_evaluator]:-} == true ]]; then
			unset 'submitted_results["$cid"]'
			_execute_feedback "$d_args"
		else
			_execute_submit "$d_args" "$cid"
		fi
	}
	[[ ${delegated_calls[*]+x} ]] && {
		local cid= d_args=
		for cid in "${!delegated_calls[@]}"; do 
			d_args="${delegated_calls[$cid]}";
			unset 'delegated_calls[$cid]'
			break;
		done
		[[ -n "$d_args" ]] && {
			_execute_delegate "$d_args" "$cid"
			info " • Task delegated to ${A_MARKOV}$MA_THREAD_NAME${A_INFO} sub-thread as ${A_B}$MA_ROLE_NAME${A_INFO} role.\n\n";
		}
	}
}

ma_agent_run() { # 1:max_iterations
	_INTERRUPTED=false
	trap '_agent_run_interrupt' INT
	local max_iter="${1:-"${MA_MAX_TURNS:-500}"}" i_turn=0

	_MA_USE_SHORT_COLUMNS=1
	local _start_run_us; ma_now _start_run_us
	_hook_call loop_start MA_USER_PROMPT

	[[ -n "$MA_USER_PROMPT" ]] && {
		thread_add_msg MA_THREAD_JSON "user" "$MA_USER_PROMPT"
	}

	[[ -t 1 ]] && ma_tty_echo_off

	local rc=0
	local _last_save_us; ma_now _last_save_us
	local _now_save_us
	local _save_interval_us=${MA_SAVE_INTERVAL_US:-60000000}

	unset _MA_IS_PAUSING
	trap 'doc_save MA_THREAD_JSON "$MA_THREAD_NAME" "$MA_DOC_PATH"; trap - RETURN' RETURN

	local n_loops_error_count=0

	local num_tool_calls_loop=0
	while (( i_turn < max_iter )); do

		_thread_switcharoo

		[[ "${MA_ONE_SHOT_MODE:-}" != true ]] && {
			local _pause_key
			if IFS= read -rs -n 1 -t 0.02 _pause_key </dev/tty 2>/dev/null; then
				printf '\033[2K\r'
				case $_pause_key in [pP]|' '|''|$'\r') _MA_IS_PAUSING=true ;; esac
			fi
		}

		[[ "${_INTERRUPTED:-}" == true || ${_MA_SMART_RETURN:-} == true || ${_MA_IS_PAUSING:-} == true ]] && {
			[[ ${_MA_IS_PAUSING:-} == true ]] && info " • Paused. Use ${A_B}/continue${A_INFO} to resume normally.\n";
			[[ ${_MA_SMART_RETURN:-} == true ]] && info " • Task finsihed.\n";
		   	rc=0; unset _MA_SMART_RETURN; unset _MA_IS_PAUSING;
			break; 
		}

		ma_now _now_save_us
		(( _now_save_us - _last_save_us >= _save_interval_us )) && {
			if [[ -z "${_ma_saving_pid:-}" ]] || ! kill -0 "$_ma_saving_pid" 2>/dev/null; then
				doc_save MA_THREAD_JSON "$MA_THREAD_NAME" "$MA_DOC_PATH"
			fi
			_last_save_us=$_now_save_us
		}

		_hook_call turn_start "$i_turn"

		local _api_response=() _full_content="" _api_rc=1 _should_continue=false n_turn_calls=0
		ma_api_send_request MA_THREAD_JSON _api_response _api_rc

		if [[ "${_LOOP_DETECTED:-}" == true ]]; then
			unset _LOOP_DETECTED;
			(( ++n_loops_error_count ))
			if (( n_loops_error_count < 10 )); then 
				{ _INTERRUPTED=false; continue; }
			else
				rc=0; break;
			fi
		else
			_agent_wrap_response "${_api_response[idx_reasoning]:-}" "${_api_response[idx_content]:-}" _full_content
		fi

		[[ "${_INTERRUPTED:-}" == true ]] && { 
			[[ "${MA_INTERRUPTIONS_NO_KEEP_PARTIAL:-}" != false && -n "$_full_content" ]] && {
				thread_add_msg MA_THREAD_JSON "assistant" "$_full_content"
				[[ "${MA_INTERRUPTIONS_NOTICE:-}" != false ]] && { thread_add_msg MA_THREAD_JSON "user" "[Notice: Interruption by the user]"; }
			}
			rc=0; break; 
		}
		(( $_api_rc != 0 )) && { rc=1; break; }

		if [[ "${_api_response[idx_tool_calls]}" != "[]" ]]; then
			_should_continue=true
			thread_add_tool_calls MA_THREAD_JSON "$_full_content" "${_api_response[idx_tool_calls]}" "${_api_response[idx_rstate]}"
			while IFS= read -r -d '' call_id && IFS= read -r -d '' fn_name && IFS= read -r -d '' fn_args; do
				_ipc_serve
				_tool_execute "$call_id" "$fn_name" "$fn_args"
				(( n_turn_calls++ ))
			done < <(jq -brj '.[] | .id + "\u0000" + .function.name + "\u0000" 
						+ (.function.arguments // "") + "\u0000"' <<< "${_api_response[idx_tool_calls]}")
			[[ ${MA_TRIGGER_RELOAD:-} == true ]] && { ma_reload; unset MA_TRIGGER_RELOAD; }
			(( MA_SESSION_TOOL_CALLS += n_turn_calls )); (( num_tool_calls_loop += n_turn_calls ))
		else

			[[ ${MA_CHECK_LEAKED_TOOL_CALLS:-} != false ]] && { # fix for some local models
				[[ $_full_content == *"tool_call>"* ]] && _should_continue=true;
			}

			[[ -n "$_full_content" ]] && thread_add_msg MA_THREAD_JSON "assistant" "$_full_content"

			[[ ${MA_USE_SUBTASK_REMINDER:-} != false && ! -v 'MA_USER_THREADS["$MA_THREAD_NAME"]' ]] && {
				[[ -v 'MA_DELEGATED["${MA_THREAD_NAME}@task"]' ]] && {
					thread_add_msg MA_THREAD_JSON "user" "${MA_SUBTASK_REMINDER:-"[REMINDER: Call 'submit' when done to report the result of the task]"}"
					info "\n"
					_should_continue=true
				}
				[[ -v 'MA_EVALUATED["$MA_THREAD_NAME@prompt"]' ]] && {
					local p=${MA_EVALUATED["$MA_THREAD_NAME@prompt"]}
					thread_add_msg MA_THREAD_JSON "user" "REMINDER: Current task result awaiting review:"$'\n'$'\n'"$p"
					info "\n"
					_should_continue=true
				}
			}
		fi

		_ipc_serve

		if _ipc_queue_pop MA_USER_PROMPT MA_IPC_PROMPT_STEER_QUEUE; then 
			_should_continue=true
			printf '\n' >&2
			if [[ ${MA_REPL_STYLE:-} != separator ]]; then
				_draw_user_message MA_USER_PROMPT
			else
				_draw_separator_after_prompt
				printf "${A_R}%s\n" "$MA_USER_PROMPT" >&2
				_draw_separator_after_prompt
			fi
			thread_add_msg MA_THREAD_JSON "user" "$MA_USER_PROMPT"
		fi

		if ! _agent_maybe_compact MA_THREAD_JSON "$MA_DOC_PATH" ; then rc=1; break; fi

		_hook_call turn_end "$i_turn" "$n_turn_calls"

		[[ $_should_continue == false ]] && { rc=0; break; }
		(( i_turn++ ))
	done

	(( i_turn >= max_iter )) && {
		rc=2
		ma_spinner_stop
		[[ ${MA_ONE_SHOT_MODE:-} != true ]] && warn "\n • ${A_B}Iteration limited${A_WARN} ($max_iter).\n";
	}

	[[ -t 1 ]] && ma_tty_echo_on
	local _end_run_us; ma_now _end_run_us
	_run_elapsed_us=$((_end_run_us - _start_run_us))

	_hook_call loop_end "$((++i_turn))" "$num_tool_calls_loop" "$rc" "$_run_elapsed_us"

	return $rc
}










_ma_trunc_keep_tail() {
    local str="$1" width="$2"
    local -n out=$3
    local len=${#str} keep
    if (( len <= width )); then
        out="$str"
    elif (( width <= 1 )); then
        out="…"
        out="${out:0:width}"
    else
        keep=$(( width - 1 ))
        out="…${str: -"$keep"}"
    fi
}
_ma_trunc_keep_head() {
    local str="$1" width="$2"
    local -n out=$3
    local len=${#str}
    if (( len <= width )); then
        out="$str"
    elif (( width <= 1 )); then
        out="…"
        out="${out:0:width}"
    else
        out="${str:0:width-1}…"
    fi
}

_footer_git_repo() {
    local dir="$1"
    _IN_GIT_REPO=0
    while [[ -n "$dir" ]]; do
        if [[ -e "$dir/.git" ]]; then
            _IN_GIT_REPO=1
            return
        fi
        [[ "$dir" == "/" ]] && break
        dir="${dir%/*}"
    done
}

_footerline_project() {
    local abs display branch
    abs="$_NORM_PATH"
    if [[ -n "${HOME:-}" && "$abs" == "$HOME"* ]]; then
        display="~${abs#"$HOME"}"
    else
        display="$abs"
    fi
    _footer_git_repo "$abs"
    if (( _IN_GIT_REPO )); then
        branch=$(git -C "$abs" symbolic-ref --quiet --short HEAD 2>/dev/null || git -C "$abs" rev-parse --short HEAD 2>/dev/null)
        [[ -n "$branch" ]] && display="${display} (${branch})"
    fi

    [[ -n "${MA_DOC_NAME:-}" ]] && display="${display} • ${MA_DOC_NAME}"

    _ma_trunc_keep_tail "$display" "$_MA_COLUMNS" _MA_STATUSLINE_PROJECT
}

_footer_ctx_prc_only() {
	local ctx=${MA_ENDPOINT_OBJ["model.ctx"]:-120000}
	local -n result=$2
    local pct pct_1
	local tokens_used=${MA_CTX_USAGE["$MA_THREAD_NAME"]:-0}
	(( tokens_used < 0 )) && { result='(?)'; return; }
    [[ "${ctx:-0}" -eq 0 ]] && { result='(?)'; return; }
    pct=$(( tokens_used * 100 / ctx ))
    pct_1=$(( tokens_used * 1000 / ctx % 10 ))
    printf -v result '%d.%d%%' "${pct}" "${pct_1}"
}

_footer_calc_ctx_prc() {
	local ctx=${MA_ENDPOINT_OBJ["model.ctx"]:-120000}
	local -n result=$1
	local prc_only; _footer_ctx_prc_only $1 prc_only
	local _h_ctx;	ma_human_num "${ctx}" _h_ctx
    printf -v result '%s/%s' "$prc_only" "${_h_ctx}"
}

_footerline_stats() {
    local left right min_gap=2 avail pad

    local calls input output cread cwrite cost hin hout hcread hcwrite
    _model_usage_aggregate calls input output cread cwrite

    _costs_calc_session_total _SESSION_COST_USD

    LC_NUMERIC=C printf -v cost '%.3f' "${_SESSION_COST_USD:-0}"

    ma_human_num "$input" hin
    ma_human_num "$output" hout
    local left="↑${hin} ↓${hout}"
	(( cread > 0 )) && { ma_human_num "$cread" hcread; left+=" R${hcread}"; }
    (( cwrite > 0 )) && { ma_human_num "$cwrite" hcwrite; left+=" W${hcwrite}"; }
    left+=" \$${cost}"

    local context_prc; _footer_calc_ctx_prc context_prc
    left+=" $context_prc"

    local right="${MA_ENDPOINT_OBJ["model.display_name"]} • ${MA_THREAD_OBJ[thinking]:-medium}"

    local provider=${MA_ENDPOINT_OBJ["provider"]}
    [[ -n "${provider:-}" ]] && right="(${provider}) ${right}"

	[[ ${MA_SHOW_TG:-} == true ]] && (( ${MA_STATS_MODEL_TG:-0} > 0 )) && right="${MA_STATS_MODEL_TG:-0}t/s "$right

    if (( ${#left} >= _MA_COLUMNS )); then _ma_trunc_keep_head "$left" "$_MA_COLUMNS" _MA_STATUSLINE_STATS; return; fi
    avail=$(( _MA_COLUMNS - ${#left} - min_gap ))
    if (( avail <= 0 )); then _MA_STATUSLINE_STATS="$left"; return; fi
    if (( ${#right} > avail )); then
        _ma_trunc_keep_head "$right" "$avail" right
    fi
    pad=$(( _MA_COLUMNS - ${#left} - ${#right} ))
    (( pad < min_gap )) && pad=$min_gap
    printf -v _MA_STATUSLINE_STATS '%s%*s%s' "$left" "$pad" '' "$right"
}




_draw_separator_var() { # 1:out_var(ref) 2:align(left|center|right) 3:char 4:color 5:text 6:text_color 7:columns
	local -n _dsv_out=$1
	local _dsv_align=${2:-right} _dsv_char=$3 _dsv_color=${4:-} _dsv_text=${5:-}
	local _dsv_tcolor=${6:-$_dsv_color} _dsv_cols=${7:-}
	[[ -z $_dsv_cols ]] && {
		_dsv_cols=$_MA_COLUMNS
		[[ -v _MA_USE_SHORT_COLUMNS ]] && (( _MA_USE_SHORT_COLUMNS )) && _dsv_cols=$_MA_SHORTER_COLUMNS
	}
	local _dsv_stub=2 _dsv_fill _dsv_l _dsv_r _dsv_ll _dsv_rr
	[[ $_dsv_align == center ]] && _dsv_stub=0
	local _dsv_pad=$(( _dsv_stub + 2 ))
	if [[ -z $_dsv_text ]] || (( _dsv_cols <= _dsv_pad )); then
		printf -v _dsv_ll '%*s' "$_dsv_cols" ''
		_dsv_out="${_dsv_color}${_dsv_ll// /$_dsv_char}"
		return 0
	fi
	(( ${#_dsv_text} > _dsv_cols - _dsv_pad )) && _dsv_text=${_dsv_text:0:_dsv_cols-_dsv_pad}
	_dsv_fill=$(( _dsv_cols - ${#_dsv_text} - 2 ))
	case $_dsv_align in
		left)   _dsv_l=$_dsv_stub;                _dsv_r=$(( _dsv_fill - _dsv_stub )) ;;
		center) _dsv_l=$(( _dsv_fill / 2 ));      _dsv_r=$(( _dsv_fill - _dsv_l )) ;;
		*)      _dsv_l=$(( _dsv_fill - _dsv_stub )); _dsv_r=$_dsv_stub ;;
	esac
	printf -v _dsv_ll '%*s' "$_dsv_l" ''
	printf -v _dsv_rr '%*s' "$_dsv_r" ''
	_dsv_out="${_dsv_color}${_dsv_ll// /$_dsv_char} ${_dsv_tcolor}${_dsv_text}${_dsv_color} ${_dsv_rr// /$_dsv_char}"
	return 0
}
_draw_separator() {
	(( _MA_SHOULD_PRINT )) && {
		local sep; _draw_separator_var sep "$@"
		printf "$sep\n\n\n\n\n\n\n\n\n\n\n\n\033[12A\n" >&2
	}
}

_draw_separator_after_prompt() { printf "%s\n" "${A_RESP_SEP}${_MA_SEPARATOR}${A_R}" >&2; }

ma_editor_setup() {
	MA_EDITOR="${MA_EDITOR:-${VISUAL:-${EDITOR:-}}}"
	if [ -n "$MA_EDITOR" ]; then
		local editor_cmd=${MA_EDITOR%% *}
		command -v "$editor_cmd" >/dev/null 2>&1 || MA_EDITOR=
	fi
	if [ -z "$MA_EDITOR" ]; then
		local editor
		for editor in vim nvim micro nano emacs joe vi ; do
			if command -v "$editor" >/dev/null 2>&1; then
				MA_EDITOR="$editor"
				break
			fi
		done
	fi
}

ma_editor_on_file() { # $1:target_file_path
	ma_editor_setup
	[[ -z "$MA_EDITOR" ]] && {
		_prompt_clear
		MA_PROMPT_COMPLETION_BUFFER="No suitable editor found: set EDITOR, VISUAL or MA_EDITOR"$'\033[K'$'\n'
	   	warn "$MA_PROMPT_COMPLETION_BUFFER" >&2; 
		return 1;
   	}
	printf "$A_ASCREEN_ON" >&2
	set -- $MA_EDITOR "${1:-}"
	"$@"
	printf "$A_ASCREEN_OFF" >&2
}

ma_editor_on_nameref() { # $1:target_variable(ref) $2:extension $3:readonly(bool)
	local -n _edit_target_msg=$1
	local ext=${2:-"tmp"}
	local readonly=${3:-false}
	local _tmpfile_for_edit="$_ma_tmp_dir/_edit_prompt_$$.${ext}"
	[ -n "$_edit_target_msg" ] && printf '%s' "$_edit_target_msg" > "$_tmpfile_for_edit"
	trap 'rm -f "$_tmpfile_for_edit"; trap - RETURN' RETURN
	local tm_before=$(ma_get_mtime "$_tmpfile_for_edit")
	ma_editor_on_file "$_tmpfile_for_edit"
	local tm_after=$(ma_get_mtime "$_tmpfile_for_edit")
	[[ $readonly == false && -s "$_tmpfile_for_edit" ]] && (( tm_after > tm_before )) && {
		_edit_target_msg="$(<"$_tmpfile_for_edit")"
	}
	(( tm_after > tm_before ))
}

ma_custom_prompt_load() { # $1:_cpl_text_out(ref) $2:cmd_name $3:cmd_args
	local -n _cpl_text_out=$1
	local cmd_name=${2} cmd_args=${3}
	[[ -n ${cmd_name:-} && ${MA_CUSTOM_PROMPTS[$cmd_name]+x} ]] && {
		local prompt_file="${MA_CUSTOM_PROMPTS[$cmd_name]}"
		[[ -f $prompt_file ]] && {
			_cpl_text_out="$(<"$prompt_file")";
			[[ -n $cmd_args ]] && {
				eval "set -- $cmd_args"
				local i=1
				while [[ $_cpl_text_out == *"\$$i"* ]]; do
					_cpl_text_out="${_cpl_text_out//\$$i/${!i:-}}"
					((i++))
				done
			}
			return 0
		}
	}
	return 1
}

ma_skill_load() { # $1:_cpl_text_out(ref) $2:cmd_name $3:cmd_args
	local -n _cpl_text_out=$1
	local cmd_name="$2" cmd_args=${3:-}
	[[ -n "$cmd_name" && ${MA_SKILLS_FILES["$cmd_name"]+x} ]] && {
		local skill_file="${MA_SKILLS_FILES["$cmd_name"]}"
		[[ -s $skill_file ]] && {
			skill_dir="${skill_file%/*}"
			_cpl_text_out=$(awk '/^---/{if(++fence==2) found=1; next} found' "$skill_file")	# cut the first yaml part..
			local params=
			[[ -n "$cmd_args" ]] && params="[Parameters Active: $cmd_args]"
			printf -v _cpl_text_out '[Skill location: %s]\n%s\n%s' "$skill_dir" "$_cpl_text_out" "$params"
			return 0
		}
	}
	return 1
}









_completion_print_plain() { # <strip-prefix-or-""> <cand1> [cand2] ...
	local strip=$1; shift
	local -a candidates=("$@")
	local _comp_buffer
	local -a matches=() c
	for c in "${candidates[@]}"; do
		[[ "$c" == "$query"* ]] && {
			if [[ -n $strip && $c == "$strip"* ]]; then
				matches+=("${c#"$strip"}")
			else
				matches+=("$c")
			fi
		}
	done
	local IFS=' '
	if (( ${#matches[@]} > 50 )); then
		_comp_buffer="Too many matches (${#matches[@]})"
	else
		_comp_buffer="${matches[*]}"
	fi
	MA_PROMPT_COMPLETION_BUFFER+="$_comp_buffer"$'\n'
	printf '%s\n' "${A_COMP}${_comp_buffer}${A_R}" >&2
}

_completion_pick() { # <prompt> <query> [preview-cmd] [exact]
	local prompt=$1 query=$2 preview=${3:-} exact=${4:-}
	if command -v fzf >/dev/null 2>&1; then
		local -a opts=(
			--style=minimal --height=40% --min-height=12 --layout=reverse
			--border=none --list-border=none --input-border=none
			--no-separator --bind 'tab:accept'
			--delimiter=$'\t' --with-nth=1
			--prompt="$prompt" --query="$query"
		)
		[[ -n $preview ]] && opts+=(--preview-window=right:70%:wrap --preview="$preview")
		[[ $exact == true ]] && opts+=(-e --no-extended)
		MSYS_NO_PATHCONV=1 fzf "${opts[@]}" | cut -f1
	elif command -v sk >/dev/null 2>&1; then
		local -a opts=(
			--height=20% --reverse --bind 'tab:accept'
			--delimiter=$'\t' --with-nth=1
			--prompt="$prompt" --query="$query"
		)
		[[ -n $preview ]] && opts+=(--preview="$preview" --preview-window=right:70%:wrap)
		[[ $exact == true ]] && opts+=(--exact)
		MSYS_NO_PATHCONV=1 sk "${opts[@]}" | cut -f1
	elif command -v peco >/dev/null 2>&1; then
		cut -f1 | peco --query="$query"
	else
		return 2
	fi
}

_completion_pick_auto1() { # <prompt> <query> [preview] [exact]  -- candidates on stdin, one per line
	local prompt=$1 query=$2 preview=${3:-} exact=${4:-}
	local -a cands=() l
	while IFS= read -r l; do cands+=("$l"); done
	(( ${#cands[@]} == 0 )) && return 1
	(( ${#cands[@]} == 1 )) && { printf '%s\n' "${cands[0]}"; return 0; }
	printf '%s\n' "${cands[@]}" | _completion_pick "$prompt" "$query" "$preview" "$exact"
}

# Returns 1 (REPLY unset) if nothing was picked / not interactive
_completion_show_matches() { # <query> <desc-array-or-""> <disp-strip-or-""> <exact:true/""> <cand1> [cand2] ...
	[[ ${PROMPT_NO_PRINT_MATCHES:-} == true ]] && return 1
	local query=$1 desc_arr=$2 disp_strip=$3 exact=$4; shift 4
	local -a candidates=("$@")
	(( ${#candidates[@]} )) || return 1
	(( ${#candidates[@]} == 1 )) && { REPLY="${candidates[0]}"; return 0; }
	[[ ${MA_HAS_PICKERS:-} != true ]] && {
		_completion_print_plain "$disp_strip" "${candidates[@]}"
		return 1
	}
	local stream= c desc picked preview=
	for c in "${candidates[@]}"; do
		desc=""
		if [[ -n $desc_arr ]]; then
			local -n _desc_map="$desc_arr"
			desc=${_desc_map[$c]:-}
			desc=${desc//$'\n'/\\n}
		fi
		stream+="$c"$'\t'"$desc"$'\n'
	done
	[[ -n $desc_arr ]] && preview='printf "%b\n" {2}'
	trap 'printf "\033[?2004h"; trap - RETURN' RETURN		# re-enable bracketed paste
	picked="$(printf '%s' "$stream" | _completion_pick "" "$query" "$preview" "$exact")"
	[[ -n $picked ]] || return 1
	REPLY=$picked
	return 0
}

_completion_common_prefix() { # <cand1> [cand2] ...
	local common=$1 c
	shift
	for c in "$@"; do
		while [[ "${c:0:${#common}}" != "$common" ]]; do common=${common%?}; done
	done
	REPLY_COMMON=$common
}

_completion_resolve_adv() { # <query> <desc-array-or-""> <exact:true/""> <cand1> [cand2] ...
	local query=$1 desc_arr=$2 exact=$3; shift 3
	local -a cmatches=("$@")
	REPLY= REPLY_COMMON=
	(( ${#cmatches[@]} )) || return 2
	(( ${#cmatches[@]} == 1 )) && { REPLY=${cmatches[0]}; return 0; }
	_completion_common_prefix "${cmatches[@]}"
	(( ${#REPLY_COMMON} > ${#query} )) || REPLY_COMMON=
	_completion_show_matches "$query" "$desc_arr" "" "$exact" "${cmatches[@]}"
}

# Resolve <query> against <cand...>; REPLY is the string to insert.
_completion_pick_ins() { # <query> <desc-array-or-""> <exact:true/""> <cand...>
	local query=$1
	_completion_resolve_adv "$@"
	local rc=$? ins=
	(( rc == 0 )) && ins=$REPLY
	[[ -z $ins && -n $REPLY_COMMON ]] && ins=$REPLY_COMMON
	REPLY=$ins
	[[ -n $ins ]]
}

ma_completion_resolve() { # ma_completion_resolve <query> <cand1> [cand2] ...
	local query=$1; shift
	local -a cmatches=() c
	for c in "$@"; do
		[[ $c == "$query"* ]] && cmatches+=("$c")
	done
	(( ${#cmatches[@]} )) || return 1
	(( ${#cmatches[@]} == 1 )) && { REPLY=${cmatches[0]}; return 0; }
	_completion_common_prefix "${cmatches[@]}"
	if [[ -n $REPLY_COMMON && $REPLY_COMMON != "$query" ]]; then
		REPLY=$REPLY_COMMON
		return 0
	fi
	REPLY=$query
	return 2
}

# Resolve <query> by prefix; pick interactively on ambiguity.
# Returns: 0 = resolved, 1 = no match, 2 = picker declined
_completion_resolve_or_pick() { # <query> <desc-array-or-""> <disp-strip-or-""> <cand...>
	local query=$1 desc_arr=$2 disp_strip=$3; shift 3
	ma_completion_resolve "$query" "$@"
	local rc=$?
	(( rc != 2 )) && return $rc
	_completion_show_matches "$query" "$desc_arr" "$disp_strip" "" "$@" && return 0
	return 2
}

ma_completion_arg() { # <strip-prefix-or-""> <descr-map-name-or-""> <cand1> [cand2] ...
	local prefix=$1 desc_arr=$2; shift 2
	local arg_cur="${after_cmd%% *}"
	_completion_resolve_or_pick "$arg_cur" "$desc_arr" "$prefix" "$@"
	if (( $? == 0 )); then
		READLINE_LINE="${leading_spaces}${full_cmd} ${REPLY}"
		READLINE_POINT=${#READLINE_LINE}
		READLINE_LINE+="$tail"
	elif (( $? == 2 )); then
		return 1
	fi
	return 0
}

ma_completion_inject() {
	READLINE_LINE="${line:0:prefix_len}${1:-} "
	READLINE_POINT=${#READLINE_LINE}
	READLINE_LINE+="$tail"
}

_prompt_completion() {

	if [[ ${MA_NO_AUTODISCARD_COMPLETION:-} != true ]]; then _prompt_discard_completion; else printf '\033[J'; fi
	trap 'if _prompt_should_redraw_footer; then _prompt_draw_footer; fi; trap - RETURN' RETURN

	local full_cmd="${READLINE_LINE%% *}"
	local after_cmd="${READLINE_LINE#* }"
	local leading_spaces="${READLINE_LINE%%[^[:space:]]*}"
	local rest="${READLINE_LINE#"$leading_spaces"}"
	local cur="${rest%% *}"

	local line="$READLINE_LINE"
	local point=$READLINE_POINT
	local left="${line:0:point}"
	local word="${left##*[[:space:]]}"
	local prefix_len=$(( ${#left} - ${#word} ))
	local tail="${line:point}"

	[[ "$word" == //* ]] && return 1

	local cmd="${full_cmd#/}"
	local completion="completion_$cmd"
	if declare -F -- "$completion" >/dev/null; then
		if "$completion"; then return; fi
	fi

	[[ "$cur" == /* ]] && {
		local query="${cur#/}"
		local -a candidates=()
		local -a matches=()
		while IFS= read -r f; do
			local res="/${f#command_}"
			candidates+=("$res")
			[[ $res == /$query* ]] && matches+=("$res")
		done < <(compgen -A function "command_" )
		local key
		for key in "${!MA_SKILLS_DESCR[@]}"; do candidates+=("/$key"); [[ $key == ${query}* ]] && matches+=("/$key"); done
		for key in "${!MA_CUSTOM_PROMPTS[@]}"; do candidates+=("/$key"); [[ $key == ${query}* ]] && matches+=("/$key"); done
		(( ${#matches[@]} == 1 )) && { [[ $cur != ${matches[0]} && $word == /* ]] && ma_completion_inject "${matches[0]}"; return; }
		(( ${#matches[@]} > 1 && ${#word} > 0 )) && {
			_completion_pick_ins "$cur" MA_COMMAND_DESCR "" "${candidates[@]}" && ma_completion_inject "${REPLY}"
			return
		}
	}

	if [[ $word == '!'* ]]; then
		local bangs=${word%%[^!]*}
		local query=${word#"$bangs"}
		(( ${#query} > 0 )) && {
			local -a matches=()
			local -A seen
			local f name
			while IFS= read -r f; do
				[[ ${f,,} == *.dll || ${f,,} == *.so ]] && continue
				declare -F "$f" >/dev/null && continue
				name=${f##*/}
				[[ $name == "$query"* ]] || continue
				[[ ${seen[$f]+x} ]] && continue
				seen[$f]=1
				matches+=("$f")
			done < <(
				compgen -A variable -A command -- "$query";
				find . -path '*/.*' -prune -o -type f -executable -print
			)
			(( ${#matches[@]} )) && {
				_completion_pick_ins "$query" "" true "${matches[@]}" && ma_completion_inject "${bangs}${REPLY}"
				return
			}
		}
	elif [[ $word =~ ^([\"\'])?\$(\{)?(.*)$ ]]; then
		local quote=${BASH_REMATCH[1]} brace=${BASH_REMATCH[2]} query=${BASH_REMATCH[3]}
		(( ${#query} > 0 )) && {
			local -a candidates=() matches=() c
			mapfile -t candidates < <({ compgen -A variable -e; } | sort -u)
			for c in "${candidates[@]}"; do
				[[ "$c" == "$query"* ]] && matches+=("$c")
			done
			local ob= cb=
			[[ -n $brace ]] && ob='{' cb='}'
			(( ${#matches[@]} == 1 )) && {
				ma_completion_inject "${quote}\$${ob}${matches[0]}${cb}${quote}"
				return
			}
			(( ${#matches[@]} > 0 )) && {
				_completion_pick_ins "$query" "" "" "${candidates[@]}" && ma_completion_inject "${quote}\$${ob}${REPLY}${cb}${quote}"
				return
			}
		}
	elif [[ ${MA_HAS_PICKERS:-} == true && $word == '@'* ]]; then
		local path=
		if command -v fd >/dev/null; then
			path="$(fd | _completion_pick_auto1 "" "${word#@}" "" "")"
		else
			path="$(find . -mindepth 1 -print | _completion_pick_auto1 "" "${word#@}" "" "")"
		fi
		printf '\033[?2004h' # re-enable bracketed paste
		[[ -n $path ]] && ma_completion_inject "$path"
		return
	fi

	[[ -n "$cur" ]] && { # default file/dir completion
		local dir= base="$word"
		[[ "$word" == */* ]] && { dir="${word%/*}/"; base="${word##*/}"; }
		local -a candidates=()
		if (( MA_BASH_53 )); then
			compgen -V candidates -f -- "$dir"
		else
			while IFS= read -r f; do [[ -n $f ]] && candidates+=("$f"); done < <(compgen -f -- "$dir")
		fi
		(( ${#candidates[@]} )) || return
		local query="${dir}${base}"
		_completion_resolve_or_pick "$query" "" "$dir" "${candidates[@]}" || return
		local result=$REPLY
		[[ -d "$result" && ${result: -1} != "." ]] && result+="/"
		READLINE_LINE="${line:0:prefix_len}${result}${tail}"
		READLINE_POINT=$(( prefix_len + ${#result} ))
	}
}



_prompt_count_wrapped_rows() {
	local -n out=$1
	local cols=$2 text=$3
	local tabstop=${MA_TABSTOP:-8}
	local total=0 len rows line
	local -i i col
	local ch
	while [[ $text == *$'\n'* ]]; do
		line=${text%%$'\n'*}
		text=${text#*$'\n'}
		if [[ $line != *$'\t'* ]]; then
			len=${#line}
		else
			col=0
			for (( i=0; i<${#line}; i++ )); do
				ch=${line:i:1}
				if [[ $ch == $'\t' ]]; then
					(( col += tabstop - (col % tabstop) ))
				else
					(( col++ ))
				fi
			done
			len=$col
		fi
		(( rows = (len < cols) ? 1 : (len + cols - 1) / cols ))
		(( total += rows ))
	done

	if [[ $text != *$'\t'* ]]; then
		len=${#text}
	else
		col=0
		for (( i=0; i<${#text}; i++ )); do
			ch=${text:i:1}
			if [[ $ch == $'\t' ]]; then
				(( col += tabstop - (col % tabstop) ))
			else
				(( col++ ))
			fi
		done
		len=$col
	fi

	(( rows = (len < cols) ? 1 : (len + cols - 1) / cols ))
	(( total += rows ))
	out=$total
}
_prompt_should_redraw_footer() {
	[[ ${MA_SYNC_FOOTER:-} != false ]] && {
		((_readline_lines_count < ( _MA_LINES - ${#MA_PROMPT_HEADER_LINES[@]} - ${#MA_PROMPT_FOOTER_LINES[@]} - _MA_LINES/2 )))
		return ;
	}
	[[ $READLINE_LINE == *$'\n'* ]] && return 1
	((${#MARKOV_PROMPT_PREFIX}+${#READLINE_LINE}<_MA_COLUMNS))
}
_prompt_discard_completion() {
	local wrapped=0
	[[ -n $MA_PROMPT_COMPLETION_BUFFER ]] && _prompt_count_wrapped_rows wrapped "$_MA_COLUMNS" "$MA_PROMPT_COMPLETION_BUFFER"
	(( (wrapped-1) > 0 )) && printf '\033[%dA' "$((wrapped-1))" >&2
	MA_PROMPT_COMPLETION_BUFFER=
	printf "${A_R}\033[0J" >&2
}
_prompt_open_editor() { 
	if ma_editor_on_nameref READLINE_LINE; then
	   	READLINE_POINT=${#READLINE_LINE}; 
	fi
	if [[ ${MA_SYNC_FOOTER:-} != false ]]; then
		_prompt_count_wrapped_rows _readline_lines_count "$_MA_COLUMNS" "$READLINE_LINE"
		if _prompt_should_redraw_footer; then _prompt_draw_footer; fi
	fi
}

_prompt_clear(){
	ma_term_update
	_prompt_discard_completion
	local head_lines=${#MA_PROMPT_HEADER_LINES[@]}
	(( head_lines > 0 && _MA_LINES > head_lines && _MA_COLUMNS > 20 )) && { printf "\033[${head_lines}A" >&2; }
	_prompt_draw_header
	[[ ${MA_SYNC_FOOTER:-} != false && -v READLINE_LINE ]] && _prompt_count_wrapped_rows _readline_lines_count "$_MA_COLUMNS" "$READLINE_LINE"
	if _prompt_should_redraw_footer; then _prompt_draw_footer; fi
	[[ ${1:-} == screen ]] && {
		local CLINES=$(( _MA_LINES - (head_lines + 1) ))
		for ((i=0; i<CLINES; ++i)); do printf '\n' >&2; done
		printf "\033[${CLINES}A\r" >&2
	}
}

_prompt_soft_newline() {
	READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}"$'\n'"${READLINE_LINE:$READLINE_POINT}"
	READLINE_POINT=$(( READLINE_POINT + 1 ))
	printf '\033[0J' >&2
	if [[ ${MA_SYNC_FOOTER:-} != false ]]; then
		_prompt_count_wrapped_rows _readline_lines_count "$_MA_COLUMNS" "$READLINE_LINE"
	else
		((_readline_lines_count+=1))
	fi
	if _prompt_should_redraw_footer; then _prompt_draw_footer; fi
}
_prompt_finalize() {
	MA_USER_PROMPT=$READLINE_LINE
	[[ "${MA_PROMPT_ACCEPT_RAW:-}" != true ]] && {
		MA_USER_PROMPT="${MA_USER_PROMPT%"${MA_USER_PROMPT##*[![:space:]]}"}"
		MA_USER_PROMPT="${MA_USER_PROMPT#"${MA_USER_PROMPT%%[![:space:]]*}"}"
	}
	[[ -n "$MA_USER_PROMPT" ]] && {
		MA_PROMPT_HISTORY_MAIN+=("$MA_USER_PROMPT")
		history -s -- "$MA_USER_PROMPT" 2>/dev/null;
	}
	_readline_lines_count=1
}

_prompt_clear_intr() {
	(( _MA_COLUMNS != ${COLUMNS:-})) || (( _MA_LINES != ${LINES:-} )) && ma_term_update
	local now_us; now_us=${EPOCHREALTIME/[,.]/}; [[ -z $now_us ]] && now_us="$(date +%s%6N)"
	local delta=$(( now_us - _readline_prev_us ))
	_readline_prev_us=$now_us
	(( delta <= ${MA_SMASH_MIN_INTERVAL:-240000} )) && {
		if((_readline_clear_count > 1)); then
			(( ${#MA_PROMPT_HEADER_LINES[@]} > 0 )) && printf "\033[${#MA_PROMPT_HEADER_LINES[@]}A" >&2
			local i
			printf "\033[0J\n" >&2
			[[ -n ${prompt_fifo_file:-} ]] && { # prevent parent shell from getting stuck on reading
				printf '%s\0' "" >&"$fd_prompt"
				exec {fd_prompt}>&-
			}
			exit 0;
		fi
		((++_readline_clear_count))
	}

	[[ -v READLINE_LINE ]] && {
		_prompt_finalize
		READLINE_LINE=""; READLINE_POINT=0; MA_USER_PROMPT="";
	}

	_readline_lines_count=1
	_prompt_discard_completion
	_prompt_draw_footer

	printf "$RL_REDRAW" >/dev/tty
}


_prompt_capture_accept(){
	ma_term_update
	_prompt_finalize
	[[ -z "${READLINE_LINE//[[:space:]]/}" ]] && {
	   	READLINE_LINE=""; READLINE_POINT=0; MA_USER_PROMPT="";
		return;
	}
	[[ ${MA_REPL_STYLE:-} != separator ]] && {
		READLINE_LINE=""; READLINE_POINT=0;
		_prompt_discard_completion;
		return
   	}
	printf '\033[0J'
}

_prompt_after_history_nav(){
	printf "\033[0J" >&2
	if [[ ${MA_SYNC_FOOTER:-} != false ]]; then
		_prompt_count_wrapped_rows _readline_lines_count "$_MA_COLUMNS" "$READLINE_LINE"
		if _prompt_should_redraw_footer; then _prompt_draw_footer; fi
	fi
}


_prompt_inline_expansion() {
	local clean_input="${READLINE_LINE#"${READLINE_LINE%%[![:space:]]*}"}"
	local target="${clean_input%%[[:space:]]*}"
	local rest="${clean_input#"$target"}"
	rest="${rest#"${rest%%[![:space:]]*}"}"

	[[ -z $target ]] && return 1

	if [[ $target == /* ]]; then
		local cmd_name="${target#/}"
		local prompt_text_out=''
		if ma_custom_prompt_load prompt_text_out "$cmd_name" "$rest"; then
			printf '\033[0J' >&2
			READLINE_LINE="$prompt_text_out"
			READLINE_POINT=${#READLINE_LINE}
			[[ ${MA_SYNC_FOOTER:-} != false ]] && {
				_prompt_count_wrapped_rows _readline_lines_count "$_MA_COLUMNS" "$READLINE_LINE"
				if _prompt_should_redraw_footer; then _prompt_draw_footer; fi
			}
			return 1
		fi
	fi

	local path="$target"
	if [[ $path == "~/"* ]]; then
		path="$HOME/${path:2}"
	fi
	if [[ -f $path && -r $path ]] && grep -Iq . -- "$path"; then
		local text
		text="$(<"$path")"
		printf '\033[0J'
		READLINE_LINE="$text"
		READLINE_POINT=${#READLINE_LINE}
		[[ ${MA_SYNC_FOOTER:-} != false ]] && {
			_prompt_count_wrapped_rows _readline_lines_count "$_MA_COLUMNS" "$READLINE_LINE"
			if _prompt_should_redraw_footer; then _prompt_draw_footer; fi
		}
		return 0
	fi

	return 1
}

_prompt_draw_header() {
    local num_lines=${#MA_PROMPT_HEADER_LINES[@]}
    [[ $num_lines -eq 0 || $_MA_LINES -le $num_lines || $_MA_COLUMNS -le 20 ]] && { 
		printf '\033[2K\r' >&2;
		return; 
	}
    local output="${A_R}"
    local line
    for line in "${MA_PROMPT_HEADER_LINES[@]}"; do
        output+=$'\033[2K'"${A_D}${line}${A_D0}"$'\n'
    done
    printf "${A_CURSOR_OFF}\r%s${A_CURSOR_ON}" "$output" >&2
}

_prompt_draw_footer() {
    local num_lines=${#MA_PROMPT_FOOTER_LINES[@]}
    [[ $num_lines -eq 0 || $_MA_LINES -le $num_lines || $_MA_COLUMNS -le 20 ]] && {
        printf '\033[0J' >&2
        return
	}
    local output="${A_R}"$'\033[2K\033[0J\n'

	[[ ${MA_SYNC_FOOTER:-} != false ]] && ((_readline_lines_count-1 > 0)) && {
		#output+=$'\r\033['$((_readline_lines_count-1))'B'
		output+=$'\r'
		for ((i=0; i<$((_readline_lines_count-1)); ++i)); do output+=$'\n'; done

	}

    local line
    for line in "${MA_PROMPT_FOOTER_LINES[@]}"; do
        output+="${A_D}${line}${A_D0}"$'\n'
    done
    output+="${A_R}"$'\033['"$((num_lines + 1))A"$'\r'
	[[ ${MA_SYNC_FOOTER:-} != false ]] && ((_readline_lines_count-1 > 0)) && output+=$'\r\033['$((_readline_lines_count-1))'A'
    printf '%s' "${A_CURSOR_OFF}$output${A_CURSOR_ON}" >&2
}




_prompt_setup(){
	[[ ${_PROMPT_ID:-} == "main" ]] && { return; };
	_PROMPT_ID=main

	set -o emacs

	bind -x '"\t":		 _prompt_completion'
	bind -x '"\e\e\e\e": _prompt_completion'
	bind -x '"\e\t":	 _prompt_completion'

	bind -x '"\C-e":     _prompt_open_editor'
	bind -x '"\C-x\C-e": _prompt_open_editor'

	bind -x '"\C-c":	 _prompt_clear_intr'
	bind -x	'"\C-x\C-z": _prompt_capture_accept'
	bind -x '"\C-l":	 _prompt_clear'
	bind -x '"\el":		 _prompt_clear screen'
	bind -x '"\et":		 _prompt_inline_expansion'
	bind '"\C-x\C-a":	 accept-line'
	bind -x '"\C-j":	_prompt_soft_newline'
	bind '"\C-m":		"\C-x\C-z\C-x\C-a"'
	bind '"\C-v\C-j":	"\C-j"'

	bind -x '"\C-x\C-h": _prompt_after_history_nav'
	bind '"\C-x\C-p": previous-history'
	bind '"\C-x\C-n": next-history'
	bind '"\C-p": "\C-x\C-p\C-x\C-h"'
	bind '"\C-n": "\C-x\C-n\C-x\C-h"'
	bind '"\e[A": "\C-x\C-p\C-x\C-h"'
	bind '"\eOA": "\C-x\C-p\C-x\C-h"'
	bind '"\e[B": "\C-x\C-n\C-x\C-h"'
	bind '"\eOB": "\C-x\C-n\C-x\C-h"'

	# readline custom event signaling hack
	bind -x '"\e[1;1R": READLINE_LINE=""; READLINE_POINT=0;'; RL_ERASE=${A_CURSOR_OFF}$'\033[s\033[1;1H\033[6n\033[u'${A_CURSOR_ON}
	bind '"\e[1;2R": redraw-current-line';					  RL_REDRAW=${A_CURSOR_OFF}$'\033[s\033[1;2H\033[6n\033[u'${A_CURSOR_ON}
	bind -x '"\e[1;3R": _prompt_clear';						  RL_CLEAR=${A_CURSOR_OFF}$'\033[s\033[1;3H\033[6n\033[u'${A_CURSOR_ON}
	bind -x '"\e[1;4R": _prompt_clear_intr';				  RL_CLEAR_INTR=${A_CURSOR_OFF}$'\033[s\033[1;4H\033[6n\033[u'${A_CURSOR_ON}
	bind '"\e[1;5R": accept-line';							  RL_ACCEPT=${A_CURSOR_OFF}$'\033[s\033[1;5H\033[6n\033[u'${A_CURSOR_ON}

	[[ ${MA_IPC_ONLY_MODE:-} != true ]] && { bind -x '"\C-o":	_command_thread_inspect'; }

	history -c
	for entry in "${MA_PROMPT_HISTORY_MAIN[@]:-}"; do
		[[ -n $entry ]] && history -s -- "$entry" 2>/dev/null;
	done

}


_prompt_on_resume() {
	printf "\033[0J\033]0;markov - $MA_WORKING_DIR\a\n" # >/dev/tty
	ma_reserve_screen
	ma_term_update
    [[ -x "/git-bash" || ${MA_GITBASH_FIX:-} == true ]] || stty intr undef </dev/tty 2>/dev/null
	_prompt_draw_header
	if _prompt_should_redraw_footer; then _prompt_draw_footer; fi
	(( _readline_lines_count > 1 )) && { for ((i=0; i<$((_readline_lines_count - 1)); ++i)); do printf $'\n' >&2; done; }
	printf "$RL_REDRAW" >&2 #>/dev/tty
}

ma_prompt() {
	trap '' INT
	trap '_prompt_on_resume' SIGCONT
	[[ -n "${_stty_prompt:-}" ]] && stty "$_stty_prompt" </dev/tty 2>/dev/null
	MA_USER_PROMPT="" MA_PROMPT_COMPLETION_BUFFER=""
	_prompt_setup
	[[ ${MA_PROMPT_AUTOERASE:-} != false ]] && printf "$RL_ERASE" >/dev/tty
	local _readline_clear_count=0 _readline_prev_us=0 _readline_lines_count=1
	while true; do
		_prompt_draw_header
		_prompt_draw_footer
		IFS= read -e -r -p "${_MA_PROMPT_PREFIX:-}" line
		[[ -n "$MA_USER_PROMPT" ]] && break
		_prompt_discard_completion
		local head_lines=${#MA_PROMPT_HEADER_LINES[@]}
		if (( head_lines > 0 && _MA_LINES > head_lines && _MA_COLUMNS > 20 )); then
			printf "\033[$(( head_lines + 1 ))A" >&2; 
		else
			printf "\033[1A" >&2;
		fi
	done
	trap - SIGCONT
	[[ -n "${_stty_base:-}" ]] && stty "$_stty_base" </dev/tty 2>/dev/null
}



_prompt_on_resume_parent(){ printf '\033[0J'; trap '_prompt_on_stop' SIGTSTP; }
_prompt_on_stop(){ 
	trap - SIGTSTP; 
	printf '\r\033[0J'; 
	kill -SIGTSTP $$;
}

_ipc_setup_fd_prompt()
{
	[[ -z ${prompt_fifo_file:-} ]] && {
		prompt_fifo_file="${_ma_tmp_dir}/prompt_bg_${$}.fifo"
		rm -f "$prompt_fifo_file"
		mkfifo "$prompt_fifo_file" 2>/dev/null
		exec {fd_prompt}<>"$prompt_fifo_file"
		rm -f "$prompt_fifo_file"
		set +m
	}
}

_ipc_queue_pop() {
	[[ ${MA_USE_IPC:-} != true ]] && return 1
	local -n _ipc_flat_out=$1
	shift
	_ipc_flat_out=
	local queue prompt
	for queue in "$@"; do
		local -n _ipc_queue=$queue
		for prompt in "${_ipc_queue[@]}"; do
			[[ -n $_ipc_flat_out ]] && _ipc_flat_out+=$'\n'
			_ipc_flat_out+="$prompt"
		done
		_ipc_queue=()
	done
	[[ -n $_ipc_flat_out ]]
}

ma_prompt_ipc() {
	trap '' INT
	MA_STATUS="IDLE"

	MA_USER_PROMPT=

	_ipc_setup_fd_prompt

	if _ipc_queue_pop MA_USER_PROMPT MA_IPC_PROMPT_STEER_QUEUE MA_IPC_PROMPT_IDLE_QUEUE; then
		printf "\n\n" >&2
		MA_STATUS="RUNNING"
		MA_PROMPT_HISTORY_MAIN+=("$MA_USER_PROMPT")
		history -s -- "$MA_USER_PROMPT" 2>/dev/null;
	   	return; 
	fi

	trap '_prompt_on_stop' SIGTSTP; 
	trap '_prompt_on_resume_parent' SIGCONT

	[[ -n "${_stty_prompt:-}" ]] && stty "$_stty_prompt" </dev/tty 2>/dev/null
	MA_USER_PROMPT="" MA_PROMPT_COMPLETION_BUFFER=""
	_prompt_setup

	(
		# FIX for Git-Bash: readline UNABLE to correctly bind '\C-c in subshell (for some arcane reason), even when intr undefined
		[[ -x "/git-bash" || ${MA_GITBASH_FIX:-} == true ]] && {
			_gitbash_fix_intr(){ printf '%s' "$RL_CLEAR_INTR" > /dev/tty; }
			stty intr ^C </dev/tty 2>/dev/null
			trap '_gitbash_fix_intr' INT
		}

		trap '_prompt_on_resume' SIGCONT
		local _readline_clear_count=0 _readline_prev_us=0 _readline_lines_count=1
		[[ ${MA_PROMPT_AUTOERASE:-} != false ]] && printf "$RL_ERASE" >/dev/tty
		while true; do
			_prompt_draw_header
			_prompt_draw_footer
			IFS= read -e -r -p "${_MA_PROMPT_PREFIX:-}" line </dev/tty
			[[ -n "$MA_USER_PROMPT" ]] && { printf '%s\0' "$MA_USER_PROMPT" >&"$fd_prompt"; break; }
			_prompt_discard_completion
			local head_lines=${#MA_PROMPT_HEADER_LINES[@]}
			if (( head_lines > 0 && _MA_LINES > head_lines && _MA_COLUMNS > 20 )); then
				printf "\033[$(( head_lines + 1 ))A" >&2; 
			else
				printf "\033[1A" >&2;
			fi
		done
	) &
    _prompt_bg_pid=$!

	_ipc_msg=
	while true; do
		IFS= read -r -d '' -t 0.15 -u "$fd_prompt" line
		local ret=$?
		if _ipc_serve; then continue; fi
		[[ -z "$_ipc_msg" ]] && _ipc_queue_pop _ipc_msg MA_IPC_PROMPT_STEER_QUEUE MA_IPC_PROMPT_IDLE_QUEUE
		[[ $line == IPCIGNORE ]] && continue

		[[ -n "$_ipc_msg" ]] && { MA_USER_PROMPT="$_ipc_msg"; break; }
		[[ -n $line ]] && MA_USER_PROMPT+="$line"
		(( ret == 0 )) && break
		if [[ -z $MA_USER_PROMPT && -n "${_prompt_bg_pid:-}" ]] && ! kill -0 "$_prompt_bg_pid" 2>/dev/null; then break; fi
	done

    [[ -n "${_prompt_bg_pid:-}" ]] && kill "$_prompt_bg_pid" 2>/dev/null

	[[ -z "$MA_USER_PROMPT" ]] && { exit; }
	[[ -n "$MA_USER_PROMPT" ]] && {
		MA_PROMPT_HISTORY_MAIN+=("$MA_USER_PROMPT")
		history -s -- "$MA_USER_PROMPT" 2>/dev/null;
	}

	MA_STATUS="RUNNING"
	trap - SIGCONT;
   	trap - SIGTSTP
	[[ -n "${_stty_base:-}" ]] && stty "$_stty_base" </dev/tty 2>/dev/null
}


_ipc_setup() {
	[[ ${MA_USE_IPC:-} != true ]] && { trap ':' USR1; trap ':' USR2; return; }

	_ipc_rand_hex() {
		local -n _out=$1
		if [ -r /dev/urandom ] && command -v od >/dev/null 2>&1; then
			local raw=$(od -An -N16 -tx1 /dev/urandom 2>/dev/null)
			printf -v _out '%s' "${raw//[$' \t\n']/}"
		elif command -v openssl >/dev/null 2>&1; then
			_out="$(openssl rand -hex 16)"
		else
			printf -v _out '%08x%08x%08x%08x' "$RANDOM$RANDOM" "$RANDOM$RANDOM" "$RANDOM$RANDOM" "$RANDOM$RANDOM"
		fi
	}

	[[ -n ${MA_IPC_DIR:-} ]] && return
	_IPC_SHOULD_EXIT=0
	MA_IPC_PENDING=0
	MA_STATUS="IDLE"
	declare -ga MA_IPC_PROMPT_IDLE_QUEUE=()
	declare -ga MA_IPC_PROMPT_STEER_QUEUE=()
	local bpid=${BASHPID}
	if [[ ${MA_IPC_SECURE:-} == true ]]; then
		MA_IPC_SECRET=${MA_IPC_SECRET:-}
		[[ -z ${MA_IPC_SECRET} ]] && _ipc_rand_hex MA_IPC_SECRET
		MA_IPC_AUTH_TOKEN="ipc-${bpid}-$MA_IPC_SECRET"
	else
		MA_IPC_AUTH_TOKEN="ipc-${bpid}"
	fi
	MA_IPC_DIR="$(mktemp -d "$_ma_tmp_dir/ipc-${bpid}-XXXXXX")" || die "mktemp -d failed"
	MA_REPLIES_DIR="$MA_IPC_DIR/replies"
	mkdir -m 700 "$MA_REPLIES_DIR" 2>/dev/null
	MA_IPC_FIFO="$MA_IPC_DIR/req.fifo"
	mkfifo -m 600 "$MA_IPC_FIFO" 2>/dev/null
	exec {_ipc_fd_req}<>"$MA_IPC_FIFO"
	_ipc_setup_fd_prompt
	_ipc_on_request_trap() {
		MA_IPC_PENDING=1
		printf 'IPCIGNORE\0' >&"$fd_prompt"
	}
	trap '_ipc_on_request_trap' USR1
	trap ':' USR2
	info "${A_B}IPC AUTH Token:${A_INFO} $MA_IPC_AUTH_TOKEN\n\n"
}

# safe to call between reads, but never from the trap or while another 'read' is in progress
_ipc_serve() {
	(( "${MA_IPC_PENDING:-0}" == 0 )) && return 1
	MA_IPC_PENDING=0
	_ipc_reply() { # $1:reply_fifo $2:msg
		local reply_fifo="$1" msg="$2" fd
		[ -p "$reply_fifo" ] || return 0
		exec {fd}<>"$reply_fifo" || return 0
		printf '%s\n' "$msg" >&"$fd"
		exec {fd}<&-
	}

	local token reply_fifo cmd payload_ref payload
	while IFS= read -t 0 -u "$_ipc_fd_req"; do
		IFS='|' read -r token reply_fifo cmd payload_ref <&"$_ipc_fd_req" || break
		[[ ${MA_IPC_SECURE:-} == true && "$token" != "${MA_IPC_AUTH_TOKEN:-}" ]] && { _ipc_reply "$reply_fifo" "ERR invalid-token"; continue; }
		case "$cmd" in
			status)
				_ipc_reply "$reply_fifo" "OK $MA_STATUS"
				;;
			session)
				local session_json
				doc_thread_sync MA_THREAD_JSON "$MA_THREAD_NAME"
				session_json="$(jq -bc --arg name "$MA_DOC_NAME" --arg path "$MA_DOC_PATH" --arg working_dir "$MA_WORKING_DIR" \
					'{
						name: (if $name != "" then $name else null end),
						file: (if $path != "" then $path else null end),
						"working-dir": (if $working_dir != "" then $working_dir else null end),
						threads: (
							.threads
							| with_entries(.value = (.value.messages | length) - 1)
						)
					}' <<< "$MA_DOC_JSON"
				)"
				_ipc_reply "$reply_fifo" "$session_json"
				;;
			thread)
				_ipc_reply "$reply_fifo" "$MA_THREAD_JSON"
				;;
			queue|steer)
				payload=
				[[ "$payload_ref" != "-" && -r "$payload_ref" ]] &&
					IFS= read -r -d '' payload < "$payload_ref"
				if [ -z "$payload" ]; then
					_ipc_reply "$reply_fifo" "ERR empty-prompt"
				else
					if [[ "$cmd" == steer ]]; then
						MA_IPC_PROMPT_STEER_QUEUE+=("$payload")
					else
						MA_IPC_PROMPT_IDLE_QUEUE+=("$payload")
					fi
					_ipc_reply "$reply_fifo" "OK queued"
				fi
				;;
			interrupt|abort)
				_ipc_reply "$reply_fifo" "OK interrupted"
				kill -INT "${$}" 2>/dev/null
				;;
			shutdown)
				_ipc_reply "$reply_fifo" "OK shutting-down"
				printf '\n\033[J\n';
				exit 0; #kill -TERM "${$}" 2>/dev/null
				;;
			pause)
				if [[ "$MA_STATUS" != IDLE ]]; then
					_MA_IS_PAUSING=true
				   	_ipc_reply "$reply_fifo" "OK pausing"
				else
				   	_ipc_reply "$reply_fifo" "OK already in IDLE state"
				fi
				;;
			continue)
				if [[ "$MA_STATUS" == IDLE ]]; then
					(( ${#MA_IPC_PROMPT_IDLE_QUEUE[@]} == 0 )) && {
						MA_IPC_PROMPT_IDLE_QUEUE+=("/continue")
					}
				   	_ipc_reply "$reply_fifo" "OK continuing"
				else
				   	_ipc_reply "$reply_fifo" "OK already in RUNNING state"
				fi
				;;
			*)
				_ipc_reply "$reply_fifo" "ERR unknown-command:$cmd"
				;;
		esac
	done
	return 0
}

_ipc_cleanup() { [[ -n "${MA_IPC_DIR:-}" ]] && rm -rf "$MA_IPC_DIR"; }

 
# Run a blocking command while servicing IPC requests
ma_ipc_run() { # 1:stdout_result(ref) 2:exit_code(ref) <cmd> [args...]
	local -n __ma_out="$1" __ma_rc="$2"
	shift 2
	local __ma_fd
	exec {__ma_fd}< <( 
		trap - INT
		"$@"; 
		printf '\0%d' "$?")
	while ! IFS= read -t 0 -u "$__ma_fd"; do _ipc_serve; ma_sleep 0.1; done
	IFS= read -r -d '' __ma_out <&"$__ma_fd"
	IFS= read -r -d '' __ma_rc  <&"$__ma_fd"
	exec {__ma_fd}<&-
	[[ "${__ma_out: -1}" == $'\n' ]] && __ma_out="${__ma_out:0:${#__ma_out}-1}";
}
 

_ipc_resolve_pid() { # $1:ipc-token $2:out-pid-var $3:out-dir-var
	local __token="$1"
	local -n __out_pid="$2" __out_dir="$3"
	local __pid __dirs __d __fifo
	__pid="${__token#ipc-}"
	__pid="${__pid%%-*}"
	[[ -n "$__pid" && "$__pid" != "$__token" && "$__pid" != "$BASHPID" ]] || { err "Invalid token.\n"; return 1; }
	shopt -s nullglob
	__dirs=("$_ma_tmp_dir"/ipc-"$__pid"-*/)
	shopt -u nullglob
	[[ "${#__dirs[@]}" -gt 0 ]] || { err "No harness found with pid: $__pid\n" >&2; return 1; }
	for __d in "${__dirs[@]}"; do
		__d="${__d%/}"
		__fifo="$__d/req.fifo"
		[[ -p "$__fifo" && -d "$__d/replies" ]] && { __out_pid="$__pid"; __out_dir="$__d"; return 0; }
	done
	err "No harness found with pid: $__pid\n" >&2
	return 1
}

_ipc_client_send() { # _ipc_client_send $1:ipc-token $2:cmd $3:payload
	local token="$1" cmd="$2"
	shift 2 2>/dev/null || true
	local payload="$*"
	local pid d fifo reply_fifo payload_ref response rc replyfd sendfd
	_ipc_resolve_pid "$token" pid d || return 1
	fifo="$d/req.fifo"
	reply_fifo="$d/replies/r$$-$RANDOM"
	mkfifo -m 600 "$reply_fifo" || { err "mkfifo failed\n"; return 1; }
	exec {replyfd}<>"$reply_fifo"
	payload_ref="-"
	[[ -n "$payload" ]] && {
		payload_ref="$d/replies/p$$-$RANDOM"
		printf '%s' "$payload" > "$payload_ref"
	}
	local msg="$token|$reply_fifo|$cmd|$payload_ref"
	[[ "${#msg}" -gt 512 ]] && {
		exec {replyfd}<&-
		rm -f "$reply_fifo" "$payload_ref" 2>/dev/null
		err "Request too long\n"
		return 1
	}
	if exec {sendfd}<>"$fifo"; then
		printf '%s\n' "$msg" >&"$sendfd"
		exec {sendfd}<&-
	fi
	kill -USR1 "$pid" 2>/dev/null
	if IFS= read -r -t 5 response <&"$replyfd"; then
		rc=0
	else
		response="ERR timeout"
		rc=2
	fi
	exec {replyfd}<&-
	local cleanup=("$reply_fifo")
	[ "$payload_ref" != "-" ] && cleanup+=("$payload_ref")
	rm -f "${cleanup[@]}" 2>/dev/null
	if [[ "$response" != "ERR"* ]]; then
		printf '%s\n' "$response" >&2
	else
		printf '%s\n' "${A_ERR}$response${A_R}" >&2
	fi
	return "$rc"
}





_picker_custom_readline() {
    local prompt="$1"
    local -n _out="$2"

    local buf= ch rc
    local pos=0

    local -r ESC=$'\x1b'
    local -r BACKSPACE=$'\x7f'
    local -r BACKSPACE2=$'\x08'
    local -r TAB=$'\x09'
    local -r CTRL_C=$'\x03'
    local -r CTRL_D=$'\x04'
    local -r CTRL_U=$'\x15'
    local -r CTRL_K=$'\x0b'
    local -r CTRL_W=$'\x17'
    local -r CTRL_L=$'\x0c'

    _insert_char() {
        local c="$1"
        local tail="${buf:pos}"
        buf="${buf:0:pos}${c}${tail}"
        printf '%s%s' "$c" "$tail" >&2
        [[ -n "$tail" ]] && printf '\x1b[%dD' "${#tail}" >&2;
        ((pos++))
    }
    _backspace() {
        ((pos == 0)) && return
        local tail="${buf:pos}"
        buf="${buf:0:pos-1}${tail}"
        ((pos--))
        printf '\b%s \x1b[%dD' "$tail" "$(( ${#tail} + 1 ))" >&2
    }
    _delete_forward() {
        ((pos >= ${#buf})) && return
        local tail="${buf:pos+1}"
        buf="${buf:0:pos}${tail}"
        printf '%s \x1b[%dD' "$tail" "$(( ${#tail} + 1 ))" >&2
    }
    _move_left() { ((pos == 0)) && return; printf '\x1b[D' >&2; ((pos--)); }
    _move_right() { ((pos >= ${#buf})) && return; printf '\x1b[C' >&2; ((pos++)); }
    _move_home() { ((pos == 0)) && return; printf '\x1b[%dD' "$pos" >&2; pos=0; }
    _move_end() {
        local remaining=$(( ${#buf} - pos ))
        ((remaining == 0)) && return
        printf '\x1b[%dC' "$remaining" >&2
        pos=${#buf}
    }

    printf '%s' "$prompt" >&2

    local ch
    while true; do
        IFS= read -rsn1 -t 0.1 ch
        rc=$?
        (( rc > 128 )) && {
            [[ $_RESIZED == true ]] && { _out="$buf"; return 2; }
            continue
        }
        case "$ch" in
            "$ESC")
                read -rsn1 -t 0.01 seq1
                if [[ "$seq1" == "[" || "$seq1" == "O" ]]; then
                    read -rsn1 -t 0.01 seq2
                    case "$seq2" in
                        A) _out="p"; return ;;
                        B) _out="n"; return ;;
                        C) _move_right ;;
                        D) _move_left ;;
                        H) _out="start"; return;; #_move_home ;;
                        F) _out="end"; return  ;; #_move_end ;;
                    esac
                    if [[ "$seq2" =~ [0-9] ]]; then
                        read -rsn1 -t 0.01 seq3
                        case "$seq2" in
                            1) _move_home ;;
                            3) _delete_forward ;;
                            4) _move_end ;;
                            5) _out="p"; return ;; # Page Up
                            6) _out="n"; return ;; # Page Down
                            7) _out="start"; return  ;; # Start (Home)
                            8) _out="end"; return  ;;   # End
                        esac
                    fi
                fi
                continue
                ;;
            "$CTRL_C") _out="q"; return 130 ;;
            "$CTRL_D"|j) _out="n"; return 2 ;;
            "$CTRL_U"|k) _out="p"; return 2 ;;
            "$CTRL_L") _RESIZED=true; return 2 ;;
            "$BACKSPACE"|"$BACKSPACE2") _backspace ;;
            "$TAB") continue ;;
            ""|$'\x0a'|$'\x0d') break ;;
            *) _insert_char "$ch" ;;
        esac
    done
    _out="$buf"
}


_picker_default_render_line() { printf "${A_INFO}${A_B}%-4d${A_R} %s${cl}\n" "$1" "$2" >&2; }

#	render_line i "${items[i]}" 
#		Write a row (ending in "$cl\n") to stderr
#		Defaults to a plain "idx value" row
_picker() { # 1:out_idx(ref) 2:lines(ref) 3:start_from_last(bool) 4:action_msg 5:render_fn  6:title_msg
    local -n _lp_idx=$1
    local -n _lp_items=$2
    local start_from_last="${3:-}"
    local action_message="${4:-}"
    local render_fn="${5:-_picker_default_render_line}"
    local header="${6:-Items}"

    _lp_idx=
    local n=${#_lp_items[@]}
    (( n == 0 )) && { warn "No items to show.\n"; return 1; }

    local page_size=$(( _MA_LINES - 6 ))
    local start=0
    if [[ -n "$start_from_last" ]]; then
        start=$(( n - page_size ))
        (( start < 0 )) && start=0
    fi

    _INTERRUPTED=false
    _RESIZED=false
    _prev_int_trap="$(trap -p INT)"

    _picker_cleanup() {
        if [[ -n "${_prev_int_trap:-}" ]]; then eval "$_prev_int_trap"; else trap - INT; fi
        trap 'ma_term_update' WINCH
		printf "$A_ASCREEN_OFF" >&2
    }

    trap '_picker_cleanup; trap - RETURN' RETURN
	printf "$A_ASCREEN_ON" >&2
    trap '_INTERRUPTED=true; return 1;' INT
    trap '_RESIZED=true' WINCH

    local choice=
    local cl=$'\033[K' cursor_on=$'\033[?25h' cursor_off=$'\033[?25l'

    while true; do
        printf "${cursor_off}" >&2
	   	tput cup 0 0
        ma_term_update
        page_size=$(( _MA_LINES - 6 ))
        warn "${cursor_off}${header}${A_R} [showing $((start))-$(( start+page_size-1 < n-1 ? start+page_size-1 : n-1 )) of ${n} total]${cl}\n" >&2
        _draw_separator_after_prompt
        local i
        for (( i=start; i<start+page_size && i<n; i++ )); do
            "$render_fn" "$i" "${_lp_items[i]}"
        done
        _draw_separator_after_prompt
        [[ -n $action_message ]] && warn "$action_message${cl}\n"
        printf "${A_D}[ Scroll page:up/down | Exit:q ]${cl}\n\033[J${cursor_on}" >&2
        _picker_custom_readline "${A_MARKOV}❯ ${A_R}" choice
        [[ $_RESIZED == true ]] && { _RESIZED=false; continue; }
        [[ $_INTERRUPTED == true ]] && { _INTERRUPTED=false; return 1; }
        case "$choice" in
            q|Q) break ;;
            n|N) (( start + page_size < n )) && (( start += page_size )) ;;
            p|P) (( start - page_size >= 0 )) && (( start -= page_size )) || start=0 ;;
            start) start=0 ;;
            end) start=$(( n - page_size )); (( start < 0 )) && start=0 ;;
            ''|*[!0-9]*) : ;;
            *) (( choice >= 0 && choice < n )) && { _lp_idx="$choice"; break; } ;;
        esac
    done
    [[ -n "$_lp_idx" ]] || return 1
}


_picker_message_render_line() {
    local i="$1" role preview ansi_c=${A_R}${A_SPECIAL}
    IFS=$'\t' read -r role preview <<<"$2"
    local size_chars ss=${#preview}
    ma_human_num "${ss:-0}" size_chars
    case $role in
        user) ansi_c=${A_INPUT} ;;
        assistant) ansi_c=${A_RESP} ;;
        *tool*) ansi_c=${A_R}${A_D} ;;
    esac
    local trunc=$(( _MA_COLUMNS - 24 ))
    printf "${A_INFO}${A_B}%-4d${A_RESP_SEP}|$ansi_c%-10s${A_R}${A_RESP_SEP}|$ansi_c%-${trunc}s${A_RESP_SEP}|${A_INFO}%6s${cl}\n" \
        "$i" "$role" "${preview:0:trunc}" "${size_chars:0:6}" >&2
}

_picker_message() {
    local start_from_last="${2:-}"
    local action_message="${3:-}"
    [[ -v JQ_THREAD_PREVIEW ]] || {
		read -r -d '' JQ_THREAD_PREVIEW <<'EOF'
		def one_preview:
		if (.content | type) == "string" then
			.content
		elif (.content | type) == "array" then
			(.content | map(
				if .type == "text" or .type == "input_text" or .type == "output_text" then
					(.text // "")
				elif .type == "tool_use" then
					"[tool_use:" + (.name // "?") + "]"
				elif .type == "tool_result" then
					"[tool_result" + (if .is_error then ":error" else "" end) + "] " +
					(
						if (.content | type) == "string" then
							.content
						elif (.content | type) == "array" then
							(.content | map(
								if .type == "text" then (.text // "")
								elif .type == "image" then "[image]"
								else "[" + (.type // "unknown") + "]"
								end
							) | join(" "))
						else
							""
						end
					)
				elif .type == "image" or .type == "image_url" then
					"[image]"
				elif .type == "input_audio" then
					"[audio]"
				else
					"[" + (.type // "unknown") + "]"
				end
				) | join(" ")
			)
		elif (.content == null) and (.tool_calls != null) then
			("[tool_call:" + ((.tool_calls | map(.function.name) | join(",")) // "?") + "]")
		else
			"[empty]"
		end;
		.[] | [.role, (one_preview | gsub("\n"; " "))] | @tsv
EOF

    }
    local n
    n=$(jq 'length' <<<"$MA_THREAD_JSON")
    (( n == 0 )) && { warn "Thread has no messages.\n"; return 1; }
    local -a lines
    mapfile -t lines < <(jq -br "$JQ_THREAD_PREVIEW" <<<"$MA_THREAD_JSON")
    local cl=$'\033[K'   # used by _picker_message_render_line
	_picker "$1" lines "$start_from_last" "$action_message" _picker_message_render_line "${A_R}Messages in thread ${A_MARKOV}$MA_THREAD_NAME"
}

_picker_file_render_line() { printf "${A_INFO}${A_B}%-4d${A_R} %s${cl}\n" "$1" "${2##*/}" >&2; }
_picker_file() {
    local -n _out=$1
    local dir="${2:-.}"
    local -a files
    mapfile -t files < <(find "$dir" -maxdepth 1 -type f | sort)
    local cl=$'\033[K'
	local _file_idx=
    _picker _file_idx files "" "Select a file" _picker_file_render_line "${A_R}Files in ${A_MARKOV}$dir"
	[[ -n "$_file_idx" && -f "${files[_file_idx]}" ]] && { _out="${files[_file_idx]}"; }
}



_builtin_ipc_commands() {
	_ipc_command_send() {
		local __command=$1
		shift
		if ! _ipc_client_send "$MA_IPC_TOKEN" "$__command" "$@"; then
			info " Use ${A_B}/ipc-token <ipc-token>${A_INFO} to set a valid token.\n"
		fi
		printf "${A_R}\n" >&2
	}
	MA_IPC_TOKEN=${MA_IPC_TOKEN:-}
	MA_COMMAND_DESCR["/ipc-token"]="Set new IPC token"
	command_ipc-token() {
		if _ipc_resolve_pid "${1:-}" pid dir; then
			MA_IPC_TOKEN=$1
			printf "${A_TOOL_OK}Peer found.${A_R}\n" >&2
		fi
		info "\n"
	}
	MA_COMMAND_DESCR["/ipc-queue"]="Queue prompt for the next IDLE time"
	command_ipc-queue() {
		[[ -n "${1:-}" ]] || { warn "Prompt required.\n\n"; return; }
		_ipc_command_send queue "$1"
	}
	MA_COMMAND_DESCR["/ipc-steer"]="Queue prompt for the next turn"
	command_ipc-steer() {
		[[ -n "${1:-}" ]] || { warn "Prompt required.\n\n"; return; }
		_ipc_command_send steer "$1"
	}
	MA_COMMAND_DESCR["/ipc-status"]="Return current status: IDLE or RUNNING"
	command_ipc-status() { _ipc_command_send status; }
	MA_COMMAND_DESCR["/ipc-session"]="Get session informaton in JSON format"
	command_ipc-session() { _ipc_command_send session; }
	MA_COMMAND_DESCR["/ipc-pause"]="Gracefully return IDLE after current turn"
	command_ipc-pause() { _ipc_command_send pause; }
	MA_COMMAND_DESCR["/ipc-continue"]="Trigger RUNNING state without new messages"
	command_ipc-continue() { _ipc_command_send continue; }
	MA_COMMAND_DESCR["/ipc-thread"]="Return the current thread (message history) in JSON format"
	command_ipc-thread() { 
		MA_IPC_THREAD_JSON=$(_ipc_command_send thread 2>&1);
		[[ -n "$MA_IPC_THREAD_JSON" ]] && { thread_reprint MA_IPC_THREAD_JSON; }
	}
	MA_COMMAND_DESCR["/ipc-abort"]="Abort the running operation"
	command_ipc-abort() { _ipc_command_send interrupt; }
	MA_COMMAND_DESCR["/ipc-shutdown"]="Shut down the instance"
	command_ipc-shutdown() { _ipc_command_send shutdown; }
	[[ ${MA_IPC_ONLY_MODE:-} == true ]] && {
		MA_COMMAND_DESCR["/ipc-quit"]="Exit Markov"
		command_ipc-quit() { printf '\033[1A\033[J\n'; exit 0; }
	}
}

ma_builtin_commands() {

	_builtin_ipc_commands

	MA_COMMAND_DESCR["/quit"]="Exit Markov"
	command_quit() { printf '\033[1A\033[J\n'; exit 0; }

	MA_COMMAND_DESCR["/help"]="Print the docs"
	command_help() { 
		ma_init_docs; 
		printf '%s' "$MA_DOCS" | less -R -P 'Documentation' ;
	   	return 0;
   	}

	MA_COMMAND_DESCR["/config"]="Setup or edit you config file:\n${MA_CONFIG_DIR}/config.sh"
	command_config() {
		local config=${MA_CONFIG_DIR}/config.sh
		[[ ! -f "$config" ]] && {

		IFS= read -r -d '' stub <<'EOF'
#!/usr/bin/env bash

# Markov configuration file.
# Use the /help command or --docs CLI option for further information.

# Add or override an existing provider:
#   MARKOV_PROVIDERS[local]="http://127.0.0.1:8080/v1"
#   MARKOV_PROVIDERS[new-provider]="ENV_API_KEY_NAME|https://<address>/v1"

# Set a default model (always use the provider prefix before the model ID):
#   MARKOV_MODEL=zai/glm	# You can use a partial match on the model ID
#   MARKOV_MODEL=local/		# Pick any available model

# Custom endpoint examples:
#   declare -gA custom_endpoint_mylocal=([model]="local/")
#   declare -gA custom_endpoint_myonline=([model]="zai/glm-5.2")

# Delegate roles are available to the delegate tool:
#   declare -gA delegate_role_researcher=(
#     [description]="Research and summarize information"
#     [append_system_prompt]='Find and summarize relevant information.'
#     [allowed_tools]="read,websearch"
#     [use_context_files]=false
#   )

# A delegate role can enable automatic evaluation of its results.
# For convenience, Markov provides "task_evaluator" as a built-in evaluator.
#   delegate_role_coder[evaluator]=task_evaluator
#   delegate_role_coder[max_evaluations]=8

# Custom roles are available for user threads only:
#
# declare -gA custom_role_reviewer=(
#   [description]="Review changes without modifying files"
#   [endpoint]=myonline
#   [tools]="read,bash"
# )

# Call analyzer
# Enable the call analyzer and configure a trusted endpoint to analyze
# your tool calls:
#   MARKOV_CALLCHECK_ANALYZER=true
#   custom_role_call_analyzer[endpoint]=mytrusted_endpoint_here

# Add a custom directory for context files and skills:
#   MARKOV_MODULES_DIR="path-for/modules"
#   MARKOV_PERSONAS_DIR="path-for/personas"
#   MARKOV_SKILLS_DIR="path-for/skills"
#   MARKOV_PROMPTS_DIR="path-for/prompts"

# Config can be used to define custom commands and new tools.
# However, you cannot override built-in ones (use modules for that).
#   MA_COMMAND_DESCR["/example"]="Example command description"
#   command_example() { echo your Bash code here; }

EOF
			mkdir -p "${MA_CONFIG_DIR}"
			printf '%s' "$stub" > "$config"
		}
		ma_editor_on_file "$config"
		info "Config File: ${config}.\nUse ${A_B}/reload${A_B0}${A_INFO} to apply changes.\n\n"
		return 0
	}



	MA_COMMAND_DESCR["/model"]="Switch the model. All threads will be updated
Optionally specify for what role (default 'main')
Usage:
  /model '<provider/model-name>' [role]"
	command_model() {
		local args=${1:-}
		[[ -z ${args} ]] && { err "Expected provider/model_id as command argument.\n\n"; return 0; }

		local model_id="${args%% *}"
		model_id="${model_id#"${model_id%%[![:space:]]*}"}"
		model_id="${model_id%"${model_id##*[![:space:]]}"}"

		local ep_name="${args#* }"
		[[ "$ep_name" == "$args" ]] && ep_name="main"
		ep_name="${ep_name#"${ep_name%%[![:space:]]*}"}"
		ep_name="${ep_name%"${ep_name##*[![:space:]]}"}"
		local IFS=','
		[[ -v 'MA_ENDPOINTS[$ep_name]' ]] || { warn "Unknown endpoint: $ep_name.\n"; info "Endpoints available: ${!MA_ENDPOINTS[*]}.\n\n"; return 1; }

		local ep_provider="${model_id%%/*}"
		[[ -n $ep_provider ]] && custom_provider="${MARKOV_PROVIDERS[$ep_provider]:-}";
		_modelsdev_get "$ep_provider" ""
		[[ -n $ep_provider && $MDV_PROVIDER_FOUND != true && -z $custom_provider ]] && { _err_ep_unknown_provider "$ep_provider"; return 0; }
		[[ -n $ep_provider && -z $custom_provider && -z $MDV_API_URL ]] && { 
			warn "\nNo API URL found for provider '$ep_provider'.\nSet manually with !MA_API_URL_CLI='..' or from /config, then /reload.\n\n"; return 0; 
		}
		MA_API_URL_CLI=
		MA_API_URL=
		MA_API_KEY="${MA_API_KEY_CLI:-${MARKOV_API_KEY:-}}"
		if [[ ${model_id:-} == *"/"* ]]; then MA_MODEL_CLI="${model_id}"; else MA_MODEL_CLI="${model_id}/"; fi

		endpoint_obj_set "${ep_name:-main}" "$MA_MODEL_CLI"

		declare -gA MA_ENDPOINT_MODEL_OVERRIDE
		MA_ENDPOINT_MODEL_OVERRIDE["${ep_name:-main}"]="$MA_MODEL_CLI"

		local -n endpoint="MA_ENDPOINT_OBJ_$ep_name"
		info "Using model: ${A_B}${endpoint[provider]}/${endpoint[model.name]}${A_INFO} for ${A_TOOL_OK}$ep_name${A_INFO} endpoint.\n\n"
		_doc_threads_update_on_reload
		return 0
	}
	completion_model() {
		[[ -v '_COMP_CACHED_MODELS_' ]] || { 
			declare -ga _MA_ALL_MODELS;
			declare -gA _MA_ALL_MODELS_SEEN
			_modelsdev_list_all_models_arr _MA_ALL_MODELS;
			for model in "${!MARKOV_PROVIDERS[@]}"; do
				[[ -v _MA_ALL_MODELS_SEEN[$model] ]] && continue
				_MA_ALL_MODELS+=("$model")
				_MA_ALL_MODELS_SEEN[$model]=1
			done
			_COMP_CACHED_MODELS_=true
		}
		if [[ "$after_cmd" != *' '* ]]; then
			local query="${after_cmd%% *}"
			prefix="${query%%/*}"
			rest="${query#*/}"
			[[ $rest == */* ]] && prefix+="/${rest%%/*}"
			[[ $prefix != "$query" ]] && prefix+="/"
			ma_completion_arg "$prefix" "" "${_MA_ALL_MODELS[@]}"
			return
		fi
		local arg1="${after_cmd%% *}"
		local rest="${after_cmd#* }"
		local arg_cur="${rest%% *}"
		_completion_resolve_or_pick "$arg_cur" '' '' "${!MA_ENDPOINTS[@]}"
		case $? in
			0)	READLINE_LINE="${leading_spaces}${full_cmd} ${arg1} ${REPLY}${tail}"
				READLINE_POINT=$(( ${#leading_spaces} + ${#full_cmd} + 1 + ${#arg1} + 1 + ${#REPLY} ))
				;;
			2) return 1 ;;
		esac
		return 0
	}


	MA_COMMAND_DESCR["/reload"]="Reload all the context files and re-source config and modules.
May invalidate the 'cached prompt prefix' if context files, module tools, or skill descriptions have changed"
	command_reload(){ ma_reload; info "Reloding completed.\n\n"; }


	MA_COMMAND_DESCR["/reprint"]="Reprint thread messages on the terminal
Optionally specify a message index
Usage:
  /reprint [N | -N]  (N: from message N, -N: last N messages)"
	command_reprint() {
		local from=${1:-0}
		[[ $from =~ ^-?[0-9]+$ ]] || { warn "Usage: /reprint [N | -N]  (N: from message N, -N: last N messages)\n\n"; return 1; }
		local sign=
		[[ $from == -* ]] && { sign=-; from=${from#-}; }
		from="$sign$((10#$from))"
		_draw_separator center ─ "${A_MARKOV}" "[$MA_THREAD_NAME]" "${A_RESP}"
		info '\n'
		thread_reprint MA_THREAD_JSON "$from"
		return 0
	}


	MA_COMMAND_DESCR["/continue"]="Trigger LLM loop without inserting any new message unless the last one is another 'assistant' message"
	command_continue() {
		MA_USER_PROMPT=
		local _file_ext= _original_text= _msg_role=
		_extract_msg -1 _original_text _file_ext _msg_role
		[[ -z "$_file_ext" ]] && { return 1; }
		[[ "$_msg_role" == 'assistant' ]] && { MA_USER_PROMPT="continue"; }
		MA_TRIGGER_LOOP=true; 
	}

	MA_COMMAND_DESCR["/usage"]="Print estimated session costs"
	command_usage() { _costs_print; }

	MA_COMMAND_DESCR["/message"]="Insert a custom message to session\nUsage:\n /message 'role' 'content'\n\nRole must be 'user' or 'assistant'"
	command_message() {
		local first=${1%%[[:space:]]*}
		local rest=${1#"$first"}
		rest=${rest#?}
		[[ -n "$first" ]] && [[ "$first" == 'user' || "$first" == 'assistant' ]] && [[ -n "$rest" ]] && {
			thread_add_msg MA_THREAD_JSON "$first" "$rest"
			info "Message stored.\n"
			return 0
		}
		warn "${MA_COMMAND_DESCR["/message"]}\n\n"
	}


	MA_COMMAND_DESCR["/file"]="Send a message with a file attachment.
Non-text files require a model that supports non-text inputs (such as images, PDFs, or audio).
If no message is provided, the attachment is inserted without triggering the LLM.
Usage:
  /file <filepath> [<message>]
"

	command_file() {
		local raw=${1:-} file rest
		raw="${raw#"${raw%%[![:space:]]*}"}"  # trim leading whitespace
		if [[ $raw == \"* ]]; then
			if [[ $raw =~ ^\"([^\"]*)\"[[:space:]]*(.*)$ ]]; then
				file="${BASH_REMATCH[1]}"; rest="${BASH_REMATCH[2]}"
			else
				file="${raw:1}"; rest=''
			fi
		elif [[ $raw == \'* ]]; then
			if [[ $raw =~ ^\'([^\']*)\'[[:space:]]*(.*)$ ]]; then
				file="${BASH_REMATCH[1]}"; rest="${BASH_REMATCH[2]}"
			else
				file="${raw:1}"; rest=''
			fi
		else
			file="${raw%%[[:space:]]*}"
			rest="${raw#"$file"}"
			rest="${rest#"${rest%%[![:space:]]*}"}"
		fi
		[[ -s "$file" ]] || { 
			warn "Invalid file: '$file'.\n\n"
			info "Usage:\n"
			info " /file <filepath> [<message>]\n\n"
		   	return 0;
	   	}
		thread_add_msg_with_file MA_THREAD_JSON "$rest" "$file"
		if [[ -n "$rest" ]]; then
			MA_TRIGGER_LOOP=true
		else
			info "File attached: $file\n\n"
		fi
	}
	completion_file() {
		local before="${line:0:prefix_len}"
		local after_before="${before#"$full_cmd"}"
		after_before="${after_before#"${after_before%%[![:space:]]*}"}"
		[[ -n $after_before ]] && return 1
		local quote='' body="$word"
		[[ $word == \"* ]] && { quote='"'; body="${word:1}"; }
		[[ $word == \'* ]] && { quote="'"; body="${word:1}"; }
		local dir= base="$body"
		[[ $body == */* ]] && { dir="${body%/*}/"; base="${body##*/}"; }
		local -a candidates=()
		while IFS= read -r f; do [[ -n $f ]] && candidates+=("$f"); done < <(compgen -f -- "$dir")
		(( ${#candidates[@]} )) || return 0
		_completion_resolve_or_pick "${dir}${base}" "" "$dir" "${candidates[@]}" || return 0
		local result=$REPLY is_dir=false
		[[ -d "$result" ]] && { result+="/"; is_dir=true; }
		[[ -z $quote && $result == *[[:space:]]* ]] && quote='"'
		local insert="${quote}${result}"
		[[ $is_dir == false && -n $quote ]] && insert+="$quote"
		READLINE_LINE="${line:0:prefix_len}${insert}${tail}"
		READLINE_POINT=$(( prefix_len + ${#insert} ))
		return 0
	}




	MA_COMMAND_DESCR["/session"]="Session sub-commands:
/session (info)           Show session name, file, and message count.
/session make-ephemeral   Make session ephemeral (not saved on disk).
"
	_threads_print_tree() { # 1:name 2:depth ; reads thread_counts and _kids from the caller's scope
		local name=$1 depth=$2 role parent child indent k
		(( depth > 16 )) && return 0
		meta_threads_unpack "$name" role parent child
		printf -v indent '%*s' $(( depth * 2 )) ''
		info "${indent} • ${A_MARKOV}${name}${A_INFO} as ${A_B}${role:-main}${A_INFO} ($(( ${thread_counts[$name]:-1} - 1 )))\n"
		for k in ${_kids[$name]:-}; do
			_threads_print_tree "$k" $(( depth + 1 ))
		done
	}

	threads_show() {
		local -A thread_counts _kids
		local -a _names _roots
		local name role parent child count
		while IFS=$'\t' read -r name count; do
			thread_counts["$name"]=$count
		done < <(jq -br '.threads | to_entries[] | "\(.key)\t\(.value.messages | length)"' <<< "$MA_DOC_JSON" 2>/dev/null)
		mapfile -t _names < <(printf '%s\n' "${!MA_THREADS[@]}" | sort)
		for name in "${_names[@]}"; do
			meta_threads_unpack "$name" role parent child
			if [[ -z $parent ]]; then
				_roots+=("$name")
			else
				_kids["$parent"]+="$name "
			fi
		done
		info "${A_B}Total threads:${A_INFO} ${#_names[@]}\n"
		for name in "${_roots[@]}"; do
			_threads_print_tree "$name" 0
		done
	}

	_command_session_info() {
		if [[ -n "$MA_DOC_NAME" ]]; then
			info "${A_B}Name:${A_INFO} $MA_DOC_NAME\n"
			info "${A_B}File:${A_INFO} $MA_DOC_PATH\n"
		else
			info "${A_B}Ephemeral session (no file)\n"
		fi

		doc_thread_sync MA_THREAD_JSON "$MA_THREAD_NAME"

		[[ -n ${MA_IPC_AUTH_TOKEN:-} ]] && info "${A_B}IPC AUTH Token:${A_INFO} $MA_IPC_AUTH_TOKEN\n"
		[[ -n ${MA_IPC_TOKEN:-} ]] && info "${A_B}IPC Peer Token:${A_INFO} $MA_IPC_TOKEN\n"
		printf '\n'
		_context_info_print

		printf '\n'
		threads_show
		printf '\n'

		local total_calls=0 count
		for count in "${MA_TOOLS_CALLS[@]}"; do
			((total_calls += count))
		done

		info "${A_B}Total tool calls:${A_INFO} $total_calls\n"
		for name in "${!MA_TOOLS_CALLS[@]}"; do
			local failures=${MA_TOOLS_FAILURES[$name]:-0}
			if ((failures > 0)); then
				printf " ${A_INFO}%s: %s (%s failures)\n" "$name" "${MA_TOOLS_CALLS[$name]}" "$failures"
			else
				printf " ${A_INFO}%s: %s\n" "$name" "${MA_TOOLS_CALLS[$name]}"
			fi
		done

		printf '\n'
	}

	_command_session_make_ephemeral() {
		MA_DOC_NAME=
		MA_DOC_PATH=
		info "Ephemeral session.\n\n"
	}
 
	command_session() {
		local args="${1:-}"
		local sub="${args%% *}"
		local sub_args=""
		[[ "$args" == *' '* ]] && sub_args="${args#* }"
		case "$sub" in
			''|info) _command_session_info ;;
			make-ephemeral) _command_session_make_ephemeral ;;
			*)       warn "Unknown /session subcommand: '$sub'. Available: info, make-ephemeral\n\n" ;;
		esac
		return 0; 
	}
	completion_session() {
		local _sub_commands=(info make-ephemeral)
		[[ "$after_cmd" != *' '* ]] && { ma_completion_arg "" "" "${_sub_commands[@]}"; return; }
		return
	}


MA_COMMAND_DESCR["/roles"]="List all the roles"
command_roles() {
	local name endpoint model_id desc line name_color
	local -a _names
	mapfile -t _names < <(printf '%s\n' "${!MA_ROLES[@]}" | sort)
	info "${A_B}Roles:${A_INFO} ${#_names[@]} (${A_TOOL_OK}roles usable by delegate tool${A_INFO})\n"
	printf '\n'
	for name in "${_names[@]}"; do
		local -n _role=${MA_ROLES[$name]}
		endpoint=${_role[endpoint]:-main}
		desc=${_role[description]:-}
		local -n _ep="MA_ENDPOINT_OBJ_$endpoint"
		model_id=${_ep["model.id"]:-?}
		name_color=${A_B}
		[[ ${MA_ROLES[$name]} == delegate_role* ]] && name_color="${A_TOOL_OK}"
		[[ -z ${MA_DELEGATE_ROLES[*]+x} && $name == main ]] && name_color="${A_TOOL_OK}"
		line="• ${name_color}${name}${A_INFO} ($endpoint: ${A_B}${model_id}${A_INFO})"
		[[ -n $desc ]] && line+=" '${A_I}$desc'"
		[[ ${_role[use_tools]:-} != false ]] && {
			local -n role_tools="MA_ROLE_TOOLS_$name"
			line+=$'\n'"  ${A_INFO}[${!role_tools[*]}]"
		}
		info "${line}\n"
	done
	printf '%s\n' "${A_R}"
}



	MA_COMMAND_DESCR["/thread"]="Thread sub-commands:
/thread                  View the raw JSON messages (pretty, paged).
/thread edit             Open the raw JSON messages in your editor.
/thread tools            See current tools and lazy tools.
/thread context [raw]    View the system prompt & tools (pretty, or raw JSON)."

	_command_thread_tools() {
		{	warn "Thread Tools\n\n"
			[[ ${#MA_ROLE_TOOLS[@]} -gt 0 ]] && {
			   	printf "${A_D}${A_B}Core tools:\n ${A_R}${A_D}%s\n\n" "${!MA_ROLE_TOOLS[*]}" >&2; 
				[[ -v 'MA_ROLE_TOOLS[execute]' ]] && { 
					printf "${A_D}${A_B}Lazy tools:\n ${A_R}${A_D}%s\n\n" "${!MA_LAZY_TOOLS[*]}" >&2; 
				}
			}
		} 2>&1 | less -R -P 'Thread Tools'
	}

	_command_thread_inspect() {
		if ma_is_json "$MA_THREAD_JSON"; then
			printf '%s' "$MA_THREAD_JSON" | jq -b '.' -C 2>/dev/null | less -R -P "JSON messages for '$MA_THREAD_NAME' thread" 
		else
			printf "${A_ERR}WARNING: JSON is invalid. Use /thread edit to manually fix.${A_R}\n%s" "$MA_THREAD_JSON" | less -R "JSON messages for '$MA_THREAD_NAME' thread"
		fi
	}
	 
	_command_thread_edit() {
		local _temp_session_messages="" is_valid=false
		if ma_is_json "$MA_THREAD_JSON"; then
			_temp_session_messages="$(printf '%s' "$MA_THREAD_JSON" | jq . -b)"; is_valid=true
		else
			_temp_session_messages="$(printf '%s' "$MA_THREAD_JSON")"
		fi
		if ma_editor_on_nameref _temp_session_messages "json"; then
			if ! ma_is_json "$_temp_session_messages"; then
				[[ $is_valid == false ]] && {
					MA_THREAD_JSON="$(printf '%s' "$_temp_session_messages")"
					warn "Invalid JSON. Messages modified anyway.\n\n"
					return 0
				}
				warn "Invalid JSON. Messages not modified.\n\n"
				return 0
			fi
			MA_THREAD_JSON="$(printf '%s' "$_temp_session_messages" | jq . -bc)"
			info "JSON modified.\n\n"
		else
			info "No modification detected.\n\n"
		fi
		return 0
	}
 
	_command_thread_context() {
		local cmd_args="${1:-}"
		local _out_ctx=''
		_out_ctx+="──── System Prompt"$'\n'
		_out_ctx+="${MA_THREAD_OBJ[system_prompt]:-}"$'\n'
		(( ${#MA_ROLE_TOOLS[@]} > 0 )) && {
			if [[ -n "$cmd_args" && "$cmd_args" == "raw" ]]; then
				_out_ctx+="──── Tools (raw)"$'\n'
				_out_ctx+="${MA_THREAD_OBJ["tools_json"]}"$'\n'
			else
				_out_ctx+="──── Tools (pretty)"$'\n'
				_out_ctx+="$(printf "%s" "${MA_THREAD_OBJ["tools_json"]}" | jq '.' -C)"$'\n'
			fi
		}
		printf '%s\n' "$_out_ctx" | less -R -P 'Context (System prompt & Tools)'
	}
 
	command_thread() {
		local args="${1:-}"
		local sub="${args%% *}"
		local sub_args=""
		[[ "$args" == *' '* ]] && sub_args="${args#* }"
		case "$sub" in
			''|inspect) _command_thread_inspect ;;
			edit)    _command_thread_edit ;;
			tools)   _command_thread_tools ;;
			context) _command_thread_context "$sub_args" ;;
			*)       warn "Unknown /thread subcommand: '$sub'. Available: inspect, context, edit, tools\n\n" ;;
		esac
		return 0; 
	}

	completion_thread() {
		local _sub_commands=(inspect edit tools context)
		local sub="${after_cmd%% *}"
		[[ "$after_cmd" != *' '* ]] && { ma_completion_arg "" "" "${_sub_commands[@]}"; return; }
		[[ "$sub" == context ]] && {
			local sub_rest="${after_cmd#"$sub"}"; sub_rest="${sub_rest# }"
			local arg_cur="${sub_rest%% *}"
			[[ "$arg_cur" != *raw* ]] && {
				ma_completion_resolve "$arg_cur" raw
				[[ -n ${REPLY} ]] && ma_completion_inject "${REPLY}"
			}
			return 1
		}
		return
	}



	MA_COMMAND_DESCR["/new"]="Start anew, wiping the current session and all threads
Pass a new name to create a fresh session file
\n\nUsage:\n /new [session_name]\n"
	command_new() {
		if [[ -n "$1" ]]; then
			[[ "$1" == *$'\n'* ]] && { err "This command only accepts single-line arguments.\n\n"; return 0; }
			MA_DOC_NAME="$1"
			doc_file_path_for "$1" MA_DOC_PATH
			info "Started new file-based session '$1'\n\n"
		else
			if [[ -n "$MA_DOC_NAME" ]]; then
				warn "Session file ${A_SPECIAL}$MA_DOC_NAME${A_WARN} wiped and reset. All threads gone.\n"
				info "If this was not intended exit without saving or ${A_B}/import${A_INFO} that session again.\n\n"
			else
				info "Started a brand new ephemeral session.\nAll threads gone. Context cleared.\n\n"
			fi
		fi
		doc_init
	}


	MA_COMMAND_DESCR["/thinking"]="Change thinking options.
Allowed options:\n/thinking [effort|toggle]\n
effort: [0-100|off|low|medium|high|xhigh|max]\n
toggles: [hide|nopreserve]\n
'hide': will not show thinking process.\n
'nopreserve': will not insert thinking portion back to assistant message."
	completion_thinking() { ma_completion_arg "" "" off low medium high xhigh max hide nopreserve; }
	command_thinking() {
		local cmd_args="${1:-}"
		cmd_args="${cmd_args#"${cmd_args%%[![:space:]]*}"}"
		cmd_args="${cmd_args%"${cmd_args##*[![:space:]]}"}"

		if [[ -z "$cmd_args" || ! "$cmd_args" =~ ^(off|low|medium|high|xhigh|max|hide|nopreserve|([0-9]|[1-9][0-9]|100))$ ]]; then
			err "Usage: /thinking [0-100|off|low|medium|high|xhigh|max|hide|nopreserve]\n\n"
		else
			if [[ "$cmd_args" == hide ]]; then
				ma_toggle_var MA_HIDE_THINKING "Hide thinking in output"
			elif [[ "$cmd_args" == nopreserve ]]; then
				ma_toggle_var MA_NO_PRESERVE_THINKING "No preserve thinking (reasoning trace stripped)"
			else
				MA_THREAD_OBJ["thinking"]="$cmd_args"
				info "Thinking effort for thread '${A_MARKOV}$MA_THREAD_NAME${A_INFO}' set to: ${A_B}$cmd_args\n\n"
			fi
		fi
	}


	MA_COMMAND_DESCR["/llm-opts"]="Set LLM parameters for current thread
Parameters:
 temperature, max_tokens, top_p, top_k, min_p, seed,
 presence_penalty, repetition_penalty, frequency_penalty
Usage:
 /llm-opts <parameter> <value>
 /llm-opts reset"
	command_llm-opts(){
		local cmd_args="${1:-}"
		[[ "$cmd_args" == *$'\n'* ]] && { err "This command only accepts single-line arguments.\n\n"; return 0; }
		cmd_args="${cmd_args#"${cmd_args%%[![:space:]]*}"}"
		cmd_args="${cmd_args%"${cmd_args##*[![:space:]]}"}"

		local _llm_opts=${MA_THREAD_OBJ[llm_opts]:-}
		if [[ -z "$cmd_args" ]]; then
			info "LLM opts: ${_llm_opts:-<default>}\n\n"
		elif [[ "$cmd_args" == "reset" ]]; then
			unset MA_THREAD_OBJ[llm_opts]
			info "LLM opts reset to defaults\n\n"
		elif [[ "$cmd_args" =~ ^([a-z_]+)[[:space:]]+(-?[0-9]+\.?[0-9]*)$ ]]; then
			local _key="${BASH_REMATCH[1]}"
			local _val="${BASH_REMATCH[2]}"
			_llm_opts="$(printf '%s' "$_llm_opts" | sed "s/${_key}=[0-9.-]*//g" | sed 's/  */ /g;s/^ //;s/ $//')"
			_llm_opts+=" ${_key}=${_val}"
			MA_THREAD_OBJ["llm_opts"]="$_llm_opts"
			info "Set $_key=$_val\n\n"
		else
			warn "Usage: /llm-opts <key> <value> | reset\n"
			local IFS=','
			warn "Keys: ${MA_LIST_LLM_PARAMS[*]}\n\n"
		fi
	}
	completion_llm-opts() { 
		local -A MA_LLM_PARAM_DESC=(
			[max_tokens]="Maximum output tokens (1+ to 128k)"
			[temperature]="Sampling temperature (0-2)"
			[top_p]="Nucleus sampling threshold (0-1)"
			[top_k]="Top-K sampling limit (0+)"
			[min_p]="Minimum probability threshold (0-1)"
			[presence_penalty]="Presence penalty (-2 to 2)"
			[frequency_penalty]="Frequency penalty (-2 to 2)"
			[repetition_penalty]="Repetition penalty (0+)"
			[reset]="Reset sampling parameters"
		)
		ma_completion_arg "" MA_LLM_PARAM_DESC "${MA_LIST_LLM_PARAMS[@]}"; 
	}


	MA_COMMAND_DESCR["/persona"]="Rebuild the system prompt and inject a Persona file into it,
replacing the current Persona if one is already set
Only threads using the 'main' role are affected
May invalidate the 'cached prompt prefix' of the model"
	command_persona() {
		local pname="${1:-}"
		MA_PERSONA_NAME= 
		[[ -n $pname && ! -v 'MA_PERSONAS[$pname]' ]] && { warn "Not a valid persona file name.\n\n"; return 0; }
		if [[ -n $pname ]]; then
			MA_PERSONA_NAME="$pname"
			warn "Persona selected: $pname.\n\n";
		else
		   	warn "Clearing any persona content from system prompt.\n\n";
		fi
		ma_reload
		return 0
	}
	completion_persona() {
		local persona_names=( "${!MA_PERSONAS[@]}" )
		ma_completion_arg "" "" "${persona_names[@]}"; 
	}




	MA_COMMAND_DESCR["/compact"]="Compact messages in the thread manually (summarize thread)
Compaction is also triggered automatically when context usage
exceeds MA_COMPACT_THRES (enabled by default)
Active skills are reinjected after compaction

Customize:
 MA_COMPACT_AUTO: true
 MA_COMPACT_THRES: 85
 MA_COMPACT_BUDGET_HEAD: 0
 MA_COMPACT_BUDGET_TAIL: 10000
 MA_COMPACT_PROMPT: replace default compaction prompt
Head/tail budgets are approximate character counts specifying
how much of the beginning and end of the thread to preserve

Optional head and tail budgets can be passed to /compact:
 /compact [head_budget] [tail_budget]

Example:
 /compact 0 5000"
	command_compact(){
		local cmd_args="${1:-}"
		local head_budget= tail_budget=
		local _a1="${cmd_args%% *}"
		local _rest=""
		[[ "$cmd_args" == *' '* ]] && _rest="${cmd_args#* }"
		local _a2="${_rest%% *}"
		[[ -n "$_a1" && "$_a1" =~ ^[0-9]+$ ]] && head_budget="$_a1"
		[[ -n "$_a2" && "$_a2" =~ ^[0-9]+$ ]] && tail_budget="$_a2"
		ma_agent_compact "$head_budget" "$tail_budget"
		info '\n'
	}


	MA_COMMAND_DESCR["/export"]="Export session to a file"
	command_export(){
		local cmd_args="${1:-}"
		[[ "$cmd_args" == *$'\n'* ]] && { err "This command only accepts single-line arguments.\n\n"; return 0; }
		local target_file flat=false _export_args="$cmd_args"
		if [[ "$_export_args" == --flat* ]]; then
			flat=true
			_export_args="${_export_args#--flat}"
			_export_args="${_export_args# }"
		fi
		if [[ -n "$_export_args" ]]; then
			target_file="$_export_args"
			[[ "$target_file" != *.mrk ]] && target_file="${target_file}.mrk"
		else
			target_file="markov_$(date +%Y%m%d_%H%M%S)_$$.mrk"
		fi
		if doc_save MA_THREAD_JSON "$MA_THREAD_NAME" "$target_file"; then
			info "Session exported to $target_file.\n\n"
		else
			err "Failed exporting session to $target_file.\n\n"
		fi
		return 0
	}

	MA_COMMAND_DESCR["/import"]="Load session from a file"

	_import_session() {
		local cmd_args="${1:-}"
		[[ "$cmd_args" == *$'\n'* ]] && { err "This command only accepts single-line arguments.\n\n"; return 1; }
		cmd_args="${cmd_args#"${cmd_args%%[![:space:]]*}"}"
		cmd_args="${cmd_args%"${cmd_args##*[![:space:]]}"}"
		if [[ -z "$cmd_args" ]]; then
			err "Usage: /import <file.mrk>\n\n"
			return 1
		elif [[ ! -f "$cmd_args" ]]; then
			local _found=""
			for _dir in . "$MA_SESSIONS_DIR"; do
				[[ ! -d "$_dir" ]] && continue
				_found="$(find "$_dir" -maxdepth 2 -name "${cmd_args}*" -type f \( -name '*.mrk' -o -name '*.markov' \) 2>/dev/null | head -n 1)"
				[[ -n "$_found" ]] && break
			done
			if [[ -n "$_found" ]]; then
				cmd_args="$_found"
			else
				err "File not found: $cmd_args\n\n"
				return 1
			fi
		fi

		if doc_load "$cmd_args"; then
			info "\n"; _draw_separator_after_prompt
			warn "Session imported from $cmd_args\n"
			_draw_separator_after_prompt; info "\n"
			return 0
		fi
		return 1
	}


	command_import(){
		local path=${1:-}
		[[ -z "$path" ]] && {
			local -a candidates=()
			local _dir f _t
			for _dir in . "$MA_SESSIONS_DIR"; do
				[[ -d $_dir ]] || continue
				while IFS= read -r -d '' f; do
					candidates+=("$f")
				done < <(find "$_dir" -maxdepth 1 -type f \( -name '*.mrk' -o -name '*.markov' \) -printf '%T@ %p\0' 2>/dev/null)
			done
			(( ${#candidates[@]} )) && {
				mapfile -d '' -t candidates < <(printf '%s\0' "${candidates[@]}" | sort -z -rn | sed -z 's/^[0-9.]* //')
			}
			(( ${#candidates[@]} )) && {
				local idx=
				_picker idx candidates
				[[ -n "$idx" && -f "${candidates[idx]}" ]] && { path="${candidates[idx]}"; }
			}
		}
		if _import_session "${path:-}"; then
			thread_reprint MA_THREAD_JSON
			_session_import_check_working_dir
		fi
		return 0
	}

	completion_import() {
		local arg_cur="${after_cmd%% *}"
		local -a candidates=()
		local _dir f entry
		for _dir in . "$MA_SESSIONS_DIR"; do
			[[ -d $_dir ]] || continue
			while IFS= read -r entry; do
				f="${entry#* }"
				[[ -n $f && ${f##*/} == "$arg_cur"* ]] && candidates+=("$entry")
			done < <(find "$_dir" -maxdepth 1 -type f \( -name '*.mrk' -o -name '*.markov' \) -printf '%T@ %p\n' 2>/dev/null)
		done
		(( ${#candidates[@]} )) || return 1
		mapfile -t candidates < <(printf '%s\n' "${candidates[@]}" | sort -rn -k1,1)
		candidates=("${candidates[@]#* }")
		if _completion_show_matches "$arg_cur" "" "" "" "${candidates[@]}"; then
			READLINE_LINE="${leading_spaces}${full_cmd} ${REPLY}"
			READLINE_POINT=${#READLINE_LINE}
		fi
		return 0
	}

	MA_COMMAND_DESCR["/fork"]="Fork the current or specified session into a new session"
	completion_fork() { completion_import "$@"; }
	command_fork() {
		local need_reprint=0
		if [[ -n ${1:-} ]]; then
			if ! _import_session "$@"; then
				err "Fork failed.\n\n"
				return 0
			fi
			need_reprint=1
		elif [[ -z $MA_DOC_NAME ]]; then
			warn "Forking an ephemeral session does nothing.\n"
			info " Use ${A_B}/export${A_INFO} to save current ephemeral session.\n\n"
			return 0
		fi
		doc_gen_name
		doc_file_path_for "$MA_DOC_NAME" MA_DOC_PATH
		mkdir -p "$(dirname "$MA_DOC_PATH")" 2>/dev/null
		(( need_reprint )) && thread_reprint MA_THREAD_JSON
		warn "Session forked to: $MA_DOC_NAME\n\n"
		_session_import_check_working_dir
		return 0
	}


	MA_COMMAND_DESCR["/save"]="Manually save the session to disk
Also converts ephemeral sessions into files
NOTE: Sessions are saved automatically during agent runs
Manual changes (e.g. /compact, /rewind) are not saved
automatically and must be saved manually with /save"
	command_save(){
		[[ -z $MA_DOC_NAME ]] && {
			doc_gen_name
			doc_file_path_for "$MA_DOC_NAME" MA_DOC_PATH
			warn "Created new session: $MA_DOC_NAME\n"
		}
		if doc_save MA_THREAD_JSON "$MA_THREAD_NAME" "$MA_DOC_PATH"; then
			printf "${A_TOOL_OK}Session saved: $MA_DOC_PATH${A_R}\n\n"
		fi
	}

	MA_COMMAND_DESCR["/rewind"]="Rewind to a previous message and discard everything after it"
	command_rewind(){
		local _msg_index= _cur_len=0
		_cur_len="$(jq 'length' <<< "$MA_THREAD_JSON" 2>/dev/null || echo 0)"
		(( _cur_len < 2 )) && { warn "No thread messages.\n\n"; return 0; }
		if ! _picker_message _msg_index true "Rewind to a previous message (discard everything after it)"; then return 0; fi
		local _jump_target=$(( _msg_index + 1 ))  # +1 to account for system prompt at index 0
		if (( _jump_target >= _cur_len )); then
			warn "Message at index $_msg_index is at or beyond the last message ($(( _cur_len - 1 ))).\n\n"
		else
			# truncation
			{
				local current
				(( _jump_target < 1 )) && _jump_target=1   # always keep system prompt
				local -a _parts
				mapfile -t _parts < <( jq -bc --argjson n "$_jump_target" 'length, .[:$n]' <<< "$MA_THREAD_JSON" 2>/dev/null)
				current="${_parts[0]:-0}"
				(( _jump_target >= current )) && { info "Nothing to discard (thread has $((current - 1)) messages).\n\n"; return 1; }
				[[ -n "${_parts[1]}" ]] && MA_THREAD_JSON="${_parts[1]}"
			}
			info "\n"; _draw_separator_after_prompt
			warn "Reprinting truncated session\n"
			_draw_separator_after_prompt; info "\n"
			thread_reprint MA_THREAD_JSON;
			info "Jumped to message $_msg_index. $(( _cur_len - _jump_target )) messages discarded.\n\n"
		fi
	}


	_pick_index() {
		local -n _out_index=$2
		if [[ -n "$1" ]]; then
			if [[ "$1" =~ ^-?[0-9]+$ ]]; then
				_out_index="$1"
			else
				err "Invalid index format: '$1'. Must be a number.\n\n"
				return 1
			fi
		else
			if ! _picker_message _out_index true "${3:-}"; then 
				return 1;
		   	fi
		fi
	}
	_extract_msg() {
		local idx=$1
		local -n _out_content=$2
		local -n _out_ext=$3
		local -n _out_role=$4
		local sep=$'\x1e'
		local raw
		raw=$(jq -br --argjson i "$idx" --arg sep "$sep" '
			(if $i < 0 then length + $i else $i end) as $idx |
			if ($idx >= 0 and $idx < length) then
			  .[$idx] as $m |
			  (if $m.role == "tool" then "txt" else "md" end) as $ext |
			  $ext + $sep + ($m.role // "unknown") + $sep
				+ (($m.content // "") | if type == "string" then .
					elif type == "array" then ([.[] | select(.type=="text") | .text] | join("\n"))
					else tojson end)
			else empty end
		' <<< "$MA_THREAD_JSON")
		_out_ext="${raw%%"$sep"*}"
		raw="${raw#*"$sep"}"
		_out_role="${raw%%"$sep"*}"
		_out_content="${raw#*"$sep"}"
	}


	MA_COMMAND_DESCR["/copy"]="Copy a message from history.\nOptional pass the index as argument.\nNegative indices supported."
	command_copy() {
		local _msg_index= _result= _file_ext= _original_text= _new_text= _updated_json= _msg_role=
		if ! _pick_index "$1" _msg_index "Select message to copy"; then return 0; fi
		_extract_msg "$_msg_index" _original_text _file_ext _msg_role
		[[ -z "$_file_ext" ]] && { warn "Invalid index $_msg_index (out of bounds).\n\n"; return 0; }
		printf '%s' "$_original_text" | ma_clipboard_copy || {
				err "Could not copy to clipboard\n"
				warn " No supported tool found.\n"; 
				info " Please install one of the following:\n  - ${A_B}win32yank${A_INFO} (Windows/WSL)\n  - ${A_B}wl-copy${A_INFO} (Wayland)\n  - ${A_B}xclip${A_INFO} or ${A_B}xsel${A_INFO} (X11)\n\n"
				info " Or use ${A_B}/edit${A_INFO} to copy message from your editor.\n\n"
				return 0;
			}
		info "Message $_msg_index copied to clipboard.\n\n"
	}

	MA_COMMAND_DESCR["/edit"]="Edit a message from session history.\nOptional pass the index as argument.\nNegative indices supported."
	command_edit() {
		local _msg_index= _result= _file_ext= _original_text= _new_text= _updated_json= _msg_role=
		if ! _pick_index "${1:-}" _msg_index "Select message to edit"; then return 0; fi
		_extract_msg "$_msg_index" _original_text _file_ext _msg_role
		[[ -z "$_file_ext" ]] && { warn "Invalid index $_msg_index (out of bounds).\n\n"; return 0; }
		local _edit_buffer="$_original_text"
		if ma_editor_on_nameref _edit_buffer "$_file_ext"; then
			_new_text="$_edit_buffer"
			_updated_json=$(
				local _encoded
				_encoded=$(printf '%s' "$_new_text" | base64 | tr -d '\n')
				printf '{"txt":"%s","session":%s}' "$_encoded" "$MA_THREAD_JSON" | jq -b '
					def think: (if type == "string"
								then ((capture("^\\s*(?<t><think>[\\s\\S]*?</think>)") | .t) // "")
								else "" end);
					(.txt | @base64d) as $txt
					| .session
					| (if $i < 0 then length + $i else $i end) as $idx
					| .[$idx] as $m
					| .[$idx].content = (
						if ($m.content|type) == "array" then
							($m.content | map(if .type == "text" then .text = $txt else . end))
						elif $txt == "" and (($m.tool_calls // []) | length) > 0 then null
						else $txt end
					  )
					| if ($m.x_rs != null) and (($m.content // "" | think) != ($txt | think))
					  then del(.[$idx].x_rs) else . end
				' --argjson i "$_msg_index"
			)
			if [[ -n "$_updated_json" ]]; then
				MA_THREAD_JSON="$_updated_json"
				info "Message at index $_msg_index updated.\n\n"
			else
				err "Error: Failed to update session JSON.\n\n"
			fi
		fi
	}

	MA_COMMAND_DESCR["/discard"]="Delete a message from session history.\nOptionally pass the index as argument. Negative indices supported."
	command_discard() {
		local _msg_index= _updated_json=
		if ! _pick_index "$1" _msg_index "Select message to delete"; then return 1; fi
		_updated_json=$(jq -b --argjson i "$_msg_index" '
			(if $i < 0 then length + $i else $i end) as $idx |
			if ($idx >= 0 and $idx < length) then
				.[:$idx] + .[$idx+1:]
			else
				empty
			end
		' <<< "$MA_THREAD_JSON")
		if [[ -n "$_updated_json" ]]; then
			MA_THREAD_JSON="$_updated_json"
			info "Message at index $_msg_index deleted.\n\n"
		else
			err "Invalid index $_msg_index (out of bounds).\n\n"
		fi
		return 0
	}


	MA_COMMAND_DESCR["/switch"]="Create or switch to another thread by name, optionally under a given role.\n\nUsage:\n\n  /switch <thread_name> [role_name]"
	command_switch() {
		local args="${1:-}"
		[[ -z "$args" ]] && { info "Current thread: ${A_MARKOV}$MA_THREAD_NAME${A_INFO}.\n\n"; return 0; }
		[[ "$args" == *$'\n'* ]] && { err "This command only accepts single-line arguments.\n\n"; return 1; }

		local role_name="${args#* }"
		[[ "$role_name" == "$args" ]] && role_name="main"   # no second word present
		role_name="${role_name#"${role_name%%[![:space:]]*}"}"
		role_name="${role_name%"${role_name##*[![:space:]]}"}"
		[[ -v 'MA_ROLES[$role_name]' ]] || { err "Unknown role: ${A_MARKOV}$role_name${A_ERR}.\n\n"; return 1; }

		local thread_name="${args%% *}"
		thread_name="${thread_name#"${thread_name%%[![:space:]]*}"}"
		thread_name="${thread_name%"${thread_name##*[![:space:]]}"}"
		[[ $thread_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || { err "Invalid thread name.\n\n"; return 1; }
		local subest_of_all=
		meta_thread_get_subest subest_of_all "$thread_name"

		[[ "$subest_of_all" != "$thread_name" ]] && { local subthread_name=$subest_of_all; }

		local subtask_name=$subest_of_all
		local is_evaluator=0

		[[ -v 'MA_EVALUATED["$subest_of_all@evaluator"]' ]] && {
			subest_of_all=
			meta_thread_get_subest subest_of_all "${MA_EVALUATED["$subtask_name@evaluator"]}"
			is_evaluator=1
		}

		[[ "$subest_of_all" == "$MA_THREAD_NAME" ]] && { info "Alredy in ${A_MARKOV}$MA_THREAD_NAME${A_INFO} thread.\n\n"; return 1; }

		local is_new=1
		[[ -v 'MA_THREADS["$subest_of_all"]' ]] && is_new=0;

		doc_thread_switch "$subest_of_all" true "$role_name" 0
		thread_reprint MA_THREAD_JSON -20
		if (( is_new )); then
			info "Created a new ${A_MARKOV}$MA_THREAD_NAME${A_INFO} thread with the ${A_B}$MA_ROLE_NAME${A_INFO} role.\n";
		else
			info "Switched to the ${A_MARKOV}$MA_THREAD_NAME${A_INFO} thread.\n";
		fi

		[[ -v 'MA_DELEGATED["${subtask_name}@snip"]' ]] && {
			if (( is_evaluator )); then
				info "Evaluating task: ${A_R}${A_I}${MA_DELEGATED["${subtask_name}@snip"]:-'no-summary'}\n"
			else
				info "Sub-thread task: ${A_R}${A_I}${MA_DELEGATED["${subtask_name}@snip"]:-'no-summary'}\n"
			fi
		}
		info "\n"
	}


	_userfacing_roles() { # $1:out_array(ref)
		local -n _cr_out=$1
		_cr_out=()
		local r
		for r in "${!MA_ROLES[@]}"; do 
			case "$r" in 
				call_analyzer|task_evaluator) ;;
				*) _cr_out+=("$r") ;;
			esac
		done
	}

	completion_switch() {
		if [[ "$after_cmd" != *' '* ]]; then
			ma_completion_arg '' '' "${!MA_USER_THREADS[@]}"
			return
		fi
		local arg1="${after_cmd%% *}"
		local rest="${after_cmd#* }"
		local arg_cur="${rest%% *}"

		local -a roles=()
		_userfacing_roles roles
		_completion_resolve_or_pick "$arg_cur" '' '' "${roles[@]}"
		case $? in
			0)	READLINE_LINE="${leading_spaces}${full_cmd} ${arg1} ${REPLY}${tail}"
				READLINE_POINT=$(( ${#leading_spaces} + ${#full_cmd} + 1 + ${#arg1} + 1 + ${#REPLY} ))
				;;
			2) return 1 ;;
		esac
		return 0
	}



	MA_COMMAND_DESCR["/return"]="Return to the parent thread with the current results, even if the task is incomplete."
	command_return() {
		[[ ! -v 'MA_USER_THREADS["$MA_THREAD_NAME"]' ]] || { info "Current thread (${A_MARKOV}$MA_THREAD_NAME${A_INFO}) is not a sub-thread with a delegated task.\n\n"; return 1; }
		thread_add_msg MA_THREAD_JSON "user" "Important: Task must be reported now. Even if task is not complete."
		MA_TRIGGER_LOOP=true
	}

	MA_COMMAND_DESCR["/abort"]="Abort the current sub-task and return to the parent thread immediately."
	command_abort() {
		[[ ! -v 'MA_USER_THREADS["$MA_THREAD_NAME"]' ]] || { info "Current thread (${A_MARKOV}$MA_THREAD_NAME${A_INFO}) is not a sub-thread with a delegated task.\n\n"; return 1; }
		local result="[Task aborted manually by user]" status="aborted" confidence="0" files='Unspecified' verification= caveats=
		local old=$MA_THREAD_NAME
		if [[ ${MA_THREAD_OBJ[task_evaluator]:-} == true ]]; then
			_execute_feedback '{"verdict":"pass"}'
		else
			local cid= d_args=
			for cid in "${!submitted_results[@]}"; do 
				d_args="${submitted_results["$cid"]}";
				break;
			done
			if _execute_submit "{}" "$cid" true; then
				info " • Sub-task aborted\n\n";
			else
				warn "Error returning from ${A_MARKOV}$old${A_WARN} thread.\n\n";
			fi
		fi
	}



}




ma_prompt_cmd_dispatch() { # $1:user_prompt
	local clean_input="${1#"${1%%[![:space:]]*}"}"
	case "$clean_input" in
		'!!'*)
			local cmd="${clean_input#!!}" cmd_out="" ret_status=0 _interrupted=false
			local _old_int; _old_int=$(trap -p INT)
			trap '_interrupted=true' INT
			if script --version 2>&1 | grep -q util-linux; then
				cmd_out=$(set -o pipefail
					script --return -o 100000 -q -f -c "bash --noprofile --norc -c $(printf %q "$cmd")" /dev/null </dev/tty \
					| tee /dev/tty | tr -d '\r') # NOTE: is pseudo-tty, output full of \r\n
			else
				cmd_out=$(set -o pipefail
					bash --noprofile --norc -c "$cmd" </dev/tty 2>&1 | tee /dev/tty)
			fi
			ret_status=$?
			eval "${_old_int:-trap - INT}"
			MA_USER_PROMPT="[shell] $cmd"$'\n'"$cmd_out"$'\n'
			[[ $ret_status != 0 ]] && {
				MA_USER_PROMPT+=$'\n'"[exit code $ret_status (can also be interruption or output size limit reached)]";
			}

			if $_interrupted || (( ret_status == 130 )); then
				ret_status=130
				warn "Shell execution aborted.\n"
			fi
			printf '\n' >&2

			_strip_ansi_sed() {
				local -n _sa_stripped=$1
				local _sa_input="${2:-}"
				_sa_stripped="$(printf '%s' "$_sa_input" | sed -E '
					s/\x1b\[[0-9:;<=>?]*[ -/]*[@-~]//g
					s/\x1b\][^\x07\x1b]*(\x07|\x1b\\)//g
				')"
			}
			_strip_ansi_sed MA_USER_PROMPT "$MA_USER_PROMPT"
			thread_add_msg MA_THREAD_JSON "user" "$MA_USER_PROMPT"
			return 1
			;;

		'!'*)
			local cmd="${clean_input#!}"
			trap 'trap '' INT; warn "Shell execution aborted.\n"' INT
			set +u
			eval "$cmd"
			[[ -n ${MA_DEVELOP:-} ]] && set -u
			printf "\n" >&2
			return 1
			;;

		'/'*)
			local cmd_name="${clean_input#/}"
			[[ -n $cmd_name ]] && {
				cmd_name="${cmd_name%%[[:space:]]*}"
				local cmd_args="${clean_input#/"$cmd_name"}"
				cmd_args="${cmd_args#"${cmd_args%%[![:space:]]*}"}"
				local _handler="command_${cmd_name}"
				MA_USER_PROMPT=
				if declare -F "$_handler" >/dev/null; then
					"$_handler" "${cmd_args:-}";
					[[ ${MA_TRIGGER_LOOP:-} = true ]] && { unset MA_TRIGGER_LOOP; return 0; }
					return 1
				fi
				# prompts
				local prompt_text_out
				if ma_custom_prompt_load prompt_text_out "$cmd_name" "$cmd_args"; then
					ma_editor_on_nameref prompt_text_out "md"
					if [[ ${MA_REPL_STYLE:-} != separator ]]; then
						_draw_user_message prompt_text_out
					else
						printf '%b\n' "$prompt_text_out"
					fi
					thread_add_msg MA_THREAD_JSON "user" "$prompt_text_out"
					return 1
				fi
				# skills
				local skill_content=
				if ma_skill_load skill_content "$cmd_name" "$cmd_args"; then
					if [[ -v 'MA_ACTIVE_SKILLS["$cmd_name"]' ]]; then
						printf "${A_SPECIAL}[Skill disabled: /%s]${A_R}\n\n" "$cmd_name" >&2
						skill_content=$'<deactivated_skill name="'"$cmd_name"$'">\n'"Skill \"$cmd_name\" disabled."$'\n</deactivated_skill>'
						unset 'MA_ACTIVE_SKILLS["$cmd_name"]'
					else
						printf "${A_SPECIAL}[Skill enabled: /%s]${A_R}\n\n" "$cmd_name" >&2
						skill_content=$'<activated_skill name="'"$cmd_name"$'">\n'"$skill_content"$'\n</activated_skill>'
						MA_ACTIVE_SKILLS["$cmd_name"]=1
					fi
					thread_add_msg MA_THREAD_JSON "user" "$skill_content"
					return 0
				fi
				err "Unknown command: $cmd_name\n\n"
				return 1
			}
			;;
	esac

	return 0
}







ma_repl() {
	declare -ga MA_PROMPT_HISTORY_MAIN
	printf "\033]0;markov - ${MA_WORKING_DIR:-$PWD}\a"
	_histcontrol_default=${HISTCONTROL:-}
	HISTCONTROL=erasedups
	if command -v fzf >/dev/null || command -v sk >/dev/null || command -v peco >/dev/null; then
		MA_HAS_PICKERS=${MA_HAS_PICKERS:-true}
	fi

	[[ -v 'MARKOV_PROMPT_PREFIX' ]] || MARKOV_PROMPT_PREFIX="❯ "
	[[ -n "${MARKOV_PROMPT_PREFIX:-}" ]] && _MA_PROMPT_PREFIX="${A_PROMPT_PREFIX}"$MARKOV_PROMPT_PREFIX"${A_PROMPT_PREFIX0}"

	ma_tty_echo_on;
	_stty_base="$(stty -g </dev/tty 2>/dev/null)"
	stty intr undef < /dev/tty 2>/dev/null		# undefine ^C intr, to be able to bind "\C-c" for readline
	_stty_prompt="$(stty -g </dev/tty 2>/dev/null)"

	[[ -n "${_stty_base:-}" ]] && stty "$_stty_base" </dev/tty 2>/dev/null

	[[ -n "${MA_USER_PROMPT:-}" ]] && _PASSTHROUGH_ARGS_PROMPT+=("$MA_USER_PROMPT")

	_ipc_setup

	while true; do

		ma_term_update

		_MA_USE_SHORT_COLUMNS=0
		if [[ ${#_PASSTHROUGH_ARGS_PROMPT[@]} -gt 0 ]]; then
			MA_USER_PROMPT="${_PASSTHROUGH_ARGS_PROMPT[*]}"
			[[ -r "$MA_USER_PROMPT" ]] && MA_USER_PROMPT="$(<"$MA_USER_PROMPT")";
			if [[ ${MA_REPL_STYLE:-} != separator ]]; then
				printf '\n\n' >&2
			else
				printf '\n%s\n' "${_PASSTHROUGH_ARGS_PROMPT[*]}" >&2
			fi
			_PASSTHROUGH_ARGS_PROMPT=()
		else
			ma_reserve_screen;
			if [[ ${MA_USE_IPC:-} == true ]]; then ma_prompt_ipc; else ma_prompt; fi
		fi

		[[ ${MA_REPL_STYLE:-} != separator ]] && {
			printf "\033[$(( ${#MA_PROMPT_HEADER_LINES[@]} + 1 ))A" >&2
			_draw_user_message MA_USER_PROMPT
		}

		[[ ${MA_CATCH_DUMB_MISTAKES:-} != false ]] && {
			if [[ "$MA_USER_PROMPT" =~ ^[[:space:]]*[^![:space:]]+_(KEY|TOKEN|KEY_CLI)= || 
				  "$MA_USER_PROMPT" =~ ^[[:space:]]*!![[:space:]]*[^![:space:]]+_(KEY|TOKEN|KEY_CLI)= ]]; then
				err  "Detected a key or token assignment outside of a Bash command.\n"
				info " Secrets must be passed by executing Bash with a single '${A_R}${A_WARN}${A_B}!${A_INFO}' prefix.\n"
				info " Any other form may expose the secret in the session.\n\n"
				info " To suppress this check use ${A_B}!MA_CATCH_DUMB_MISTAKES=false${A_INFO}.\n"
				printf "\n" >&2
				continue
			fi
		}

		ma_prompt_cmd_dispatch "$MA_USER_PROMPT";
		local ret_cmd=$?

		[[ ${MA_REPL_STYLE:-} == separator ]] && _draw_separator_after_prompt;
		[[ $ret_cmd -eq 1 ]] && continue

		ma_reserve_screen;

		[[ ${MA_IPC_ONLY_MODE:-} == true ]] && {
			if ! _ipc_client_send "$MA_IPC_TOKEN" steer "$MA_USER_PROMPT"; then
				info " Use ${A_B}/ipc-token <ipc-token>${A_INFO} to set a valid token.\n"
			fi
			printf "\n"
			continue
		}

		ma_agent_run
		printf "\n"
	done
}





_ma_tmp_dir=${MA_TMP_DIR:-"${TMPDIR:-/tmp}/markov"}
_ma_cache_dir=${MA_CACHE_DIR:-/var/tmp/markov/cache}
_ma_notes_dir=${MA_NOTES_DIR:-/var/tmp/markov/notes}
mkdir -p "$_ma_tmp_dir" "$_ma_cache_dir" "$_ma_notes_dir" || { err "Could not create directory in $_ma_tmp_dir or $_ma_cache_dir or $_ma_notes_dir\n"; exit 1; }

[[ "${_LIST_MODELS:-}" == "true" ]] && { ma_source_config; _list_provider_models; exit; }

[[ "${_LIST_PROVIDERS:-}" == "true" ]] && { ma_source_config; _list_providers; exit; }

[[ -n ${MA_IPC_SEND_CMD:-} ]] && { _ipc_client_send "${MA_IPC_TOKEN:-}" "$MA_IPC_SEND_CMD" "${MA_IPC_SEND_PAYLOAD:-}"; exit; }

_ma_cleanup() {
    local ret_status=$?
	trap '' INT TERM HUP

	_hook_call cleanup
	set +ue
	[[ ${_stty_default:-} ]] && stty "$_stty_default" </dev/tty 2>/dev/null
	HISTCONTROL=$_histcontrol_default
	ma_spinner_stop
    [[ -n "${_prompt_bg_pid:-}" ]] && kill "$_prompt_bg_pid" 2>/dev/null
	[[ -n "${_ma_saving_pid:-}" ]] && wait "${_ma_saving_pid:-}" 2>/dev/null

	rm -f "$_ma_tmp_dir/bash_$$_*rc" "$_ma_tmp_dir/bash_$$_*out"
	rm -f "$_ma_sleepfifo"

	_ipc_cleanup

	[[ -d "${_ma_cache_dir:-}" ]] && {
		local days=${MA_CACHE_DIR_TTL_DAYS:-60}
		[[ "$days" =~ ^[0-9]+$ ]] && find "${_ma_cache_dir}" -type f -mtime +${days} -delete
	}

	[[ -f $MA_DOC_PATH ]] && info "Session closed: $MA_DOC_NAME\n"

	printf "${A_CURSOR_ON}${A_R}" >&2

    exit "$ret_status"
}
trap _ma_cleanup EXIT TERM HUP

[[ -t 0 ]] && {
	_stty_default="$(stty -g </dev/tty 2>/dev/null)"
	stty discard undef </dev/tty 2>/dev/null
}

[[ ${MA_IPC_ONLY_MODE:-} == true ]] && { 

	MA_USE_CONFIG=false
	MA_USE_MODULES=false
	MA_USE_CONTEXT_FILES=false
	MA_USE_TOOLS=false
	MA_USE_SKILLS=false
	MA_USE_PROMPTS=false
	MA_QUIET=true
	_boot_init
	ma_builtin_tools
	MA_USE_IPC=false
	MA_IPC_TOKEN=${MA_IPC_TOKEN:-}
	declare pid dir
	if ! _ipc_resolve_pid "${MA_IPC_TOKEN:-}" pid dir; then
		info " Use ${A_B}/ipc-token <ipc-token>${A_INFO} or ${A_B}!MA_IPC_TOKEN=<ipc-token>${A_INFO} to set another one\n"
	fi
	ma_term_update
	trap 'ma_term_update' WINCH

	unset -f $(compgen -A function command_)

	declare -gA MA_CUSTOM_PROMPTS
	declare -gA MA_SKILLS_FILES
	declare -gA MA_COMMAND_DESCR
	_builtin_ipc_commands
	ma_repl
	exit
}

ma_tty_echo_off

[[ ! -t 0 && -p /dev/stdin ]] && { MA_ONE_SHOT_MODE=true; MA_USER_PROMPT="$(< /dev/stdin)"; }

[[ "${MA_ONE_SHOT_MODE:-}" == true ]] && {
	[[ -z ${MA_DOC_NAME:-} ]] && MA_DOC_EPHEMERAL=true
	[[ -r "$MA_USER_PROMPT" ]] && MA_USER_PROMPT="$(<"$MA_USER_PROMPT")";
	ma_bootup;
	[[ -n "${_MA_INPUT_FILE_CLI:-}" ]] && thread_add_msg_with_file MA_THREAD_JSON "" "${_MA_INPUT_FILE_CLI}"
	ma_agent_run
	ret=$?
	[[ -t 2 ]] && printf "\n" >&2
	exit $ret
}

[[ "${MA_NO_REPL:-}" != true ]] && {
   	ma_bootup
	[[ -n "${_MA_INPUT_FILE_CLI:-}" ]] && { 
		if thread_add_msg_with_file MA_THREAD_JSON "" "${_MA_INPUT_FILE_CLI}"; then info "File attached: ${_MA_INPUT_FILE_CLI}\n\n"; fi
	}
	ma_repl
}

