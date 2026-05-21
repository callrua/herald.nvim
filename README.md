# herald.nvim

A Neovim plugin that integrates [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) into your editing workflow.

Named after the **Heralds of Galactus** -- beings sent out by an omnipotent entity to do its work. Herald acts as your intermediary to Claude, dispatching tasks and bringing back results without leaving Neovim.

## Features

- **Visual replacement** -- highlight code, describe a change, selection gets replaced inline. Undo with `u`.
- **Semantic search** -- natural language search, results populate the quickfix list.
- **Agentic tasks** -- multi-step work (refactors, test generation, etc.) with full tool access.
- **Session management** -- multi-turn conversations via Claude's `--resume` flag. Name, resume, and persist sessions across restarts.
- **Floating prompt window** -- `w` to submit (normal mode), `q` to cancel.
- **Progress indicators** -- inline spinner for visual ops, fidget.nvim spinner for search/agent.
- **Completions** -- `#rules` and `@files` in the prompt buffer, with project rules overriding global.

## Commands

| Command | Description |
|---------|-------------|
| `:HeraldSearch` | Open prompt, run semantic search, populate quickfix |
| `:HeraldAgent` | Open prompt (or pass inline), run agentic task |
| `:HeraldStop` | Cancel in-flight request(s) |
| `:HeraldNewSession` | Start a new conversation session |
| `:HeraldSession <name>` | Name the current session |
| `:HeraldResume` | Pick and resume a previous session |
| `:HeraldSessionInfo` | Show current session ID, name, created date |

Visual mode replacement is triggered via keymap (see setup below).

## Setup

```lua
require("herald").setup({
  model = "sonnet",                    -- claude model
  permission_mode = "auto",           -- CLI permission mode
  md_files = { "AGENT.md", "CLAUDE.md" }, -- context files to collect
  completion = {
    custom_rules = {},                 -- project-local SKILL.md directories
    global_rules = {},                 -- global SKILL.md directories
  },
})
```

### Suggested keymaps

```lua
vim.keymap.set("v", "<leader>hv", function() require("herald").visual() end)
vim.keymap.set("n", "<leader>hs", function() require("herald").search() end)
vim.keymap.set("n", "<leader>ha", function() require("herald").agent() end)
vim.keymap.set("n", "<leader>hx", function() require("herald").stop() end)
```

## Requirements

- Neovim >= 0.10
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- [fidget.nvim](https://github.com/j-hui/fidget.nvim) (optional, for progress spinners)
