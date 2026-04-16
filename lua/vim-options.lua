vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Point to vim-notes directory
vim.g.notes_directories = {"~/Documents/Notes"}

-- Use vimdiff with diff-so-fancy for git diffs
vim.g.diffopt_external = "git diff --no-index --color-words --color-moved"
vim.g.diffopt_program = "vim-diff-so-fancy"

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true
vim.opt.relativenumber = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

vim.opt.incsearch = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Move line up or down visually
vim.keymap.set("v", "J", ":m '>+1<Return>gv=gv", { desc = "[Motion] Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<Return>gv=gv", { desc = "[Motion] Move selection up" })

-- Scroll down and up half a page
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "[Motion] Half-page down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "[Motion] Half-page up and center" })

-- position cursor to center of screen after n(next) and N(previous) word search
vim.keymap.set("n", "n", "nzzzv", { desc = "[Motion] Next match and center" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "[Motion] Prev match and center" })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "[Motion] Wrap-aware up" })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "[Motion] Wrap-aware down" })

-- Navigate in insert mode with Alt+hjkl
vim.keymap.set("i", "<A-h>", "<Left>", { desc = "[Motion] Insert move left" })
vim.keymap.set("i", "<A-j>", "<Down>", { desc = "[Motion] Insert move down" })
vim.keymap.set("i", "<A-k>", "<Up>", { desc = "[Motion] Insert move up" })
vim.keymap.set("i", "<A-l>", "<Right>", { desc = "[Motion] Insert move right" })

-- Navigating the panes in neovim
vim.keymap.set("n", "<Leader>h", ":wincmd h<Return>", { noremap = true, silent = true, desc = "[Windows] Focus pane left" })
vim.keymap.set("n", "<Leader>j", ":wincmd j<Return>", { noremap = true, silent = true, desc = "[Windows] Focus pane down" })
vim.keymap.set("n", "<Leader>k", ":wincmd k<Return>", { noremap = true, silent = true, desc = "[Windows] Focus pane up" })
vim.keymap.set("n", "<Leader>l", ":wincmd l<Return>", { noremap = true, silent = true, desc = "[Windows] Focus pane right" })

-- Navigating the tabs in neovim
vim.api.nvim_set_keymap('n', '<Leader>tn', ':tabnext<CR>', { noremap = true, silent = true, desc = "[Tabs] Next tab" })
vim.api.nvim_set_keymap('n', '<Leader>tp', ':tabprevious<CR>', { noremap = true, silent = true, desc = "[Tabs] Previous tab" })
vim.api.nvim_set_keymap('n', '<Leader>to', ':tabonly<CR>', { noremap = true, silent = true, desc = "[Tabs] Close other tabs" })
vim.api.nvim_set_keymap('n', '<Leader>tc', ':tabclose<CR>', { noremap = true, silent = true, desc = "[Tabs] Close tab" })


-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})


-- function to toggle scroll bind and cursor bind
vim.api.nvim_create_user_command("ToggleScrollBind", function()
  local scrollbind = vim.wo.scrollbind
  if scrollbind then
    vim.cmd("windo set noscrollbind nocursorbind")
    print("Scrollbind OFF")
  else
    vim.cmd("windo set scrollbind cursorbind")
    print("Scrollbind ON")
  end
end, {})

vim.keymap.set("n", "<leader>sb", ":ToggleScrollBind<CR>", { silent = true, desc = "[Windows] Toggle scroll bind" })

-- Reference Block: toggle a small pinned reference split at the top
-- Each pair is { ref_win, work_win } so multiple vertical splits can each have one
local reference_block_pairs = {}

local function find_reference_pair(win)
  for i, pair in ipairs(reference_block_pairs) do
    if pair.ref == win or pair.work == win then
      return i, pair
    end
  end
  return nil, nil
end

local function toggle_reference_block()
  local cur_win = vim.api.nvim_get_current_win()
  local idx, pair = find_reference_pair(cur_win)

  -- Toggle off: close the reference pane if it belongs to this window pair
  if idx and pair and vim.api.nvim_win_is_valid(pair.ref) then
    local tab = vim.api.nvim_get_current_tabpage()
    local non_float_wins = vim.tbl_filter(function(w)
      return vim.api.nvim_win_get_config(w).relative == ""
    end, vim.api.nvim_tabpage_list_wins(tab))
    if #non_float_wins < 2 then return end
    -- If currently in the reference pane, move to working pane first
    if cur_win == pair.ref and vim.api.nvim_win_is_valid(pair.work) then
      vim.api.nvim_set_current_win(pair.work)
    end
    vim.api.nvim_win_close(pair.ref, false)
    table.remove(reference_block_pairs, idx)
    return
  end

  local height = vim.v.count > 0 and vim.v.count or 15

  -- Split horizontally; cursor stays in top (original) window
  vim.cmd("split")
  local ref_win = vim.api.nvim_get_current_win()

  -- Pin cursor line to top and freeze scroll position
  vim.wo[ref_win].scrolloff = 0
  vim.wo[ref_win].scrollbind = false
  vim.wo[ref_win].cursorbind = false
  vim.cmd("normal! zt")
  vim.api.nvim_win_set_height(ref_win, height)

  -- Make the reference pane a frozen snapshot (scratch buffer with copied content)
  local source_buf = vim.api.nvim_win_get_buf(ref_win)
  local cursor_pos = vim.api.nvim_win_get_cursor(ref_win)
  local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
  vim.bo[scratch].modifiable = false
  vim.bo[scratch].buftype = "nofile"
  vim.bo[scratch].filetype = vim.bo[source_buf].filetype
  vim.api.nvim_win_set_buf(ref_win, scratch)
  -- Restore cursor position and pin view
  vim.api.nvim_win_set_cursor(ref_win, cursor_pos)
  vim.api.nvim_set_current_win(ref_win)
  vim.cmd("normal! zt")

  -- Focus the bottom (working) pane, jump to end, and enter insert mode
  vim.cmd("wincmd w")
  local work_win = vim.api.nvim_get_current_win()
  vim.cmd("normal! G")
  vim.cmd("startinsert")
  table.insert(reference_block_pairs, { ref = ref_win, work = work_win })
end

vim.keymap.set("n", "<leader>rb", toggle_reference_block, { silent = true, desc = "[Windows] Reference block" })

-- Quit Neovim when a terminal closes and it's the last real window
vim.api.nvim_create_autocmd("TermClose", {
  callback = function()
    vim.defer_fn(function()
      local wins = vim.tbl_filter(function(w)
        return vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w).relative == ""
      end, vim.api.nvim_list_wins())
      if #wins <= 1 then
        vim.cmd("qa!")
      end
    end, 100)
  end,
})

