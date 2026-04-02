# Neovim Config

Lua-based neovim configuration using Lazy.nvim plugin manager.

## Structure

- `init.lua` — Bootstraps Lazy.nvim, requires `vim-options` and `plugins/`
- `lua/vim-options.lua` — Core settings (tabs, keybindings, clipboard, mouse)
- `lua/plugins/` — One file per plugin, each returns a Lazy plugin spec

## Plugin Organization

Each file in `lua/plugins/` is auto-loaded by Lazy. To add a plugin, create a new file returning a plugin spec table.

**Categories**:
- LSP & completion: lsp-config, mason, completions
- UI: lualine, alpha, onedark, neo-tree, fidget
- Editing: treesitter, surround, claudecode
- Tools: telescope, floaterm, maximize, debugging, none-ls

## Conventions

- Plugin versions are locked in `lazy-lock.json`. Commit lock file changes when updating plugins.
- Keep plugin configs self-contained in their own files.
- Keybinding conventions: `<leader>` prefix for custom mappings.
